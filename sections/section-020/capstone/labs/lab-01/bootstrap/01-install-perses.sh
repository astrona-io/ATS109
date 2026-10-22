#!/usr/bin/env bash
# Installs Helm, percli, Prometheus, Grafana with the legacy dashboards and
# Perses v0.54.0. Graded lab bootstrap: this prepares the environment ONLY.
set -euo pipefail

HELM_VERSION="3.22.1"
PERSES_VERSION="0.54.0"
PERSES_CHART_VERSION="0.23.3"
PERSES_HOST="perses.localtest.me"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Pin the tools rather than accepting whatever is on the machine.
have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  echo "[lab] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
# percli ships in the Perses release archive, next to the server binary.
have_percli=""
command -v percli >/dev/null 2>&1 && have_percli=$(percli version 2>/dev/null | awk '/[Vv]ersion/{print $NF; exit}' | sed 's/^v//')
if [ "$have_percli" != "$PERSES_VERSION" ]; then
  echo "[lab] Downloading percli ${PERSES_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/perses/perses/releases/download/v${PERSES_VERSION}/perses_${PERSES_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" percli
  install -m 0755 "$WORK/percli" "$BIN_DIR/percli"
fi
helm version --short
percli version || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# One address for the reader's machine and the cluster: perses.localtest.me
# resolves to 127.0.0.1 on the machine (reached through a port-forward), and
# this CoreDNS block sends the same name to the Perses Service in the cluster.
# The answer is rewritten back to the asked name: Go programs ignore DNS
# answers whose name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$PERSES_HOST"; then
  echo "[lab] Adding the CoreDNS rewrite for ${PERSES_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex perses\\.localtest\\.me perses.perses.svc.cluster.local"
        print "        answer name perses\\.perses\\.svc\\.cluster\\.local perses.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
echo "[lab] Starting Prometheus and the tester pod..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n observability rollout status deployment/prometheus --timeout=300s
kubectl -n observability rollout status deployment/tester --timeout=300s

# Grafana holds the legacy dashboards that the course compares and migrates.
echo "[lab] Starting Grafana with the legacy dashboards..."
if ls "$MANIFEST_DIR"/grafana-dashboards/*.json >/dev/null 2>&1; then
  kubectl -n observability create configmap grafana-dashboards \
    --from-file="$MANIFEST_DIR/grafana-dashboards" --dry-run=client -o yaml | kubectl apply -f -
else
  kubectl -n observability create configmap grafana-dashboards \
    --from-literal=README=none --dry-run=client -o yaml | kubectl apply -f -
fi
kubectl apply -f "$MANIFEST_DIR/grafana.yaml"
kubectl -n observability rollout status deployment/grafana --timeout=300s

echo "[lab] Installing Perses (chart ${PERSES_CHART_VERSION})..."
helm repo add perses https://perses.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update perses >/dev/null
helm upgrade --install perses perses/perses --version "$PERSES_CHART_VERSION" \
  --namespace perses --create-namespace \
  --values "$MANIFEST_DIR/perses-values.yaml" \
  --wait --timeout 10m

# Wait until the Perses API answers from inside the cluster.
for _ in $(seq 1 60); do
  kubectl -n observability exec deploy/tester -- curl -fsS http://perses.localtest.me:8080/api/v1/projects >/dev/null 2>&1 && break
  sleep 5
done

echo "[lab] Perses and Grafana ready."

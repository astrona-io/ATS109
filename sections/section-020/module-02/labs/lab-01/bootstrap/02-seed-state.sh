#!/usr/bin/env bash
# Creates the starting state for ats-109-lab-020-02.
#
# The fixed state is NOT created here — producing it is the task.
set -euo pipefail

export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
PERSES_URL="http://perses.localtest.me:8080"
GRAFANA_URL="http://grafana.observability:3000"

# Runs a command in the tester pod, which has curl and jq.
tester() { kubectl -n observability exec -i deploy/tester -- "$@"; }

# perses_get PATH: a GET on the Perses API, sent from the tester pod.
perses_get() { tester curl -fsS "$PERSES_URL$1"; }

# perses_send METHOD PATH: sends the JSON on stdin to the Perses API.
perses_send() { tester curl -fsS -X "$1" -H 'Content-Type: application/json' --data-binary @- "$PERSES_URL$2"; }

# grafana_get PATH: a GET on the Grafana HTTP API (anonymous administrator, lab only).
grafana_get() { tester curl -fsS "$GRAFANA_URL$1"; }

# ensure_project NAME: creates the Perses project if it does not exist yet.
ensure_project() {
  perses_get "/api/v1/projects/$1" >/dev/null 2>&1 && return 0
  printf '{"kind":"Project","metadata":{"name":"%s"}}' "$1" | perses_send POST /api/v1/projects >/dev/null
}

# ensure_datasource PROJECT: creates the default Prometheus datasource
# `prometheus` in PROJECT if it does not exist yet.
ensure_datasource() {
  perses_get "/api/v1/projects/$1/datasources/prometheus" >/dev/null 2>&1 && return 0
  printf '{"kind":"Datasource","metadata":{"name":"prometheus","project":"%s"},"spec":{"default":true,"display":{"name":"Prometheus"},"plugin":{"kind":"PrometheusDatasource","spec":{"proxy":{"kind":"HTTPProxy","spec":{"url":"http://prometheus.observability:9090"}}}}}}' "$1" \
    | perses_send POST "/api/v1/projects/$1/datasources" >/dev/null
}

# put_dashboard PROJECT NAME: creates or replaces a dashboard from the JSON on stdin.
put_dashboard() {
  local body
  body="$(cat)"
  if perses_get "/api/v1/projects/$1/dashboards/$2" >/dev/null 2>&1; then
    printf '%s' "$body" | perses_send PUT "/api/v1/projects/$1/dashboards/$2" >/dev/null
  else
    printf '%s' "$body" | perses_send POST "/api/v1/projects/$1/dashboards" >/dev/null
  fi
}

# instant_query PROJECT DATASOURCE EXPR TIME: runs EXPR through the Perses
# datasource proxy at one point in time and prints one sorted line per series.
instant_query() {
  tester curl -fsS -X POST "$PERSES_URL/proxy/projects/$1/datasources/$2/api/v1/query" \
    --data-urlencode "query=$3" --data-urlencode "time=$4" \
    | tester jq -r '.data.result | map({m: (.metric | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(",")), v: .value[1]}) | sort_by(.m) | .[] | "\(.m) \(.v)"'
}

# with_lab_values EXPR: replaces dashboard variables with fixed values, so the
# same expression can run outside a dashboard.
with_lab_values() {
  printf '%s' "$1" | sed -e 's/\$__rate_interval/5m/g' -e 's/\${handler}/.*/g' -e 's/\$handler/.*/g' \
    -e 's/\${job}/prometheus/g' -e 's/\$job/prometheus/g' -e 's/\${interval}/5m/g' -e 's/\$interval/5m/g'
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$SCRIPT_DIR/../manifests"

# migrate_uid UID: migrates one Grafana dashboard with the default datasource.
migrate_uid() {
  grafana_get "/api/dashboards/uid/$1" \
    | tester jq -c '{grafanaDashboard: .dashboard, useDefaultDatasource: true}' \
    | perses_send POST /api/migrate
}

echo "[lab] Creating the Perses project and its datasource..."
ensure_project legacy
ensure_datasource legacy

echo "[lab] Migrating the Grafana dashboard prometheus-overview into the project legacy as overview-flat..."
# The two placeholder panels get their queries written back, so the dashboard
# starts without placeholders. Only the layout and the variables stay to fix.
migrate_uid prometheus-overview | tester jq -c '
  .metadata.project = "legacy"
  | .metadata.name = "overview-flat"
  | .spec.panels["5"].spec.plugin = {"kind": "TimeSeriesChart", "spec": {"yAxis": {"format": {"unit": "seconds"}}}}
  | .spec.panels["5"].spec.queries = [
      {"kind": "TimeSeriesQuery", "spec": {"plugin": {"kind": "PrometheusTimeSeriesQuery", "spec": {
        "query": "histogram_quantile(0.9, sum by (le) (rate(prometheus_http_request_duration_seconds_bucket{job=\"$job\"}[$interval])))",
        "seriesNameFormat": "p90"}}}}]
  | .spec.panels["6"].spec.plugin = {"kind": "StatusHistoryChart", "spec": {}}
  | .spec.panels["6"].spec.queries = [
      {"kind": "TimeSeriesQuery", "spec": {"plugin": {"kind": "PrometheusTimeSeriesQuery", "spec": {
        "query": "up{job=\"$job\"}",
        "seriesNameFormat": "{{instance}}"}}}}]' \
  | put_dashboard legacy overview-flat

echo "[lab] Starting state ready. The task is in question.md."

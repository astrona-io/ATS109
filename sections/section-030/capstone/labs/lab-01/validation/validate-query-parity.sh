#!/usr/bin/env bash
# PASS when, for each Grafana panel of api-latency, the Perses panel with the
# same title returns the same series as the Grafana expression at the same
# moment, with the dashboard variables fixed.
set -uo pipefail

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

PROJECT="release"
DASHBOARD="$(perses_get "/api/v1/projects/$PROJECT/dashboards/api-latency" 2>/dev/null)"
[ -n "$DASHBOARD" ] || { echo "FAIL: no dashboard api-latency in the project $PROJECT."; exit 1; }
GRAFANA="$(grafana_get /api/dashboards/uid/api-latency 2>/dev/null)"
[ -n "$GRAFANA" ] || { echo "FAIL: could not read the Grafana dashboard api-latency."; exit 1; }

NOW="$(tester date +%s | tr -d '\r')"
FAILED=0
while IFS=$'\t' read -r -u 3 TITLE GRAFANA_EXPR; do
  [ -n "$TITLE" ] || continue
  PERSES_EXPR="$(printf '%s' "$DASHBOARD" | tester jq -r --arg t "$TITLE" \
    '[.spec.panels[] | select(.spec.display.name == $t) | .spec.queries[0].spec.plugin.spec.query][0] // ""')"
  if [ -z "$PERSES_EXPR" ]; then
    echo "FAIL: no Perses panel titled \"$TITLE\" with a query."
    FAILED=1
    continue
  fi
  EXPECTED="$(instant_query "$PROJECT" prometheus "$(with_lab_values "$GRAFANA_EXPR")" "$NOW")"
  ACTUAL="$(instant_query "$PROJECT" prometheus "$(with_lab_values "$PERSES_EXPR")" "$NOW")"
  if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "FAIL: panel \"$TITLE\" returns different series than Grafana's query."
    FAILED=1
  fi
done 3< <(printf '%s' "$GRAFANA" | tester jq -r '.dashboard.panels[] | select(.type != "row") | [.title, .targets[0].expr] | @tsv')

[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: every panel returns the same series as its Grafana panel."
exit 0

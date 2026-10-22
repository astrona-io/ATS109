#!/usr/bin/env bash
# PASS when every Perses panel uses the Perses equivalent of the Grafana unit
# of the panel with the same title.
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

DASHBOARD="$(perses_get /api/v1/projects/release/dashboards/api-latency 2>/dev/null)"
[ -n "$DASHBOARD" ] || { echo "FAIL: no dashboard api-latency in the project release."; exit 1; }
GRAFANA="$(grafana_get /api/dashboards/uid/api-latency 2>/dev/null)"
[ -n "$GRAFANA" ] || { echo "FAIL: could not read the Grafana dashboard api-latency."; exit 1; }

# The Grafana unit to Perses unit mapping used by the migration (the part this dashboard uses).
WANT="$(printf '%s' "$GRAFANA" | tester jq -c '
  {"percentunit":"percent-decimal","percent":"percent","short":"decimal","none":"decimal",
   "reqps":"requests/sec","s":"seconds","ms":"milliseconds","bytes":"bytes"} as $map
  | [.dashboard.panels[] | select(.type != "row") | {(.title): $map[.fieldConfig.defaults.unit // "none"]}] | add')"
WRONG="$(printf '%s' "$DASHBOARD" | tester jq -r --argjson want "$WANT" '
  [.spec.panels[] | {title: .spec.display.name, unit: (.spec.plugin.spec.format.unit // .spec.plugin.spec.yAxis.format.unit // "")}
   | select($want[.title] != null and $want[.title] != .unit)
   | "\(.title): \(.unit) instead of \($want[.title])"] | join("; ")')"
if [ -n "$WRONG" ]; then
  echo "FAIL: units differ from Grafana: $WRONG."
  exit 1
fi
echo "PASS: every panel unit matches the Grafana unit."
exit 0

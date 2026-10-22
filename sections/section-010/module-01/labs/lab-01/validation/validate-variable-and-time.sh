#!/usr/bin/env bash
# PASS when the dashboard has the ListVariable handler filled from the label
# handler with All = .*, and the 6h duration and 30s refresh of Grafana.
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

DASHBOARD="$(perses_get /api/v1/projects/specs/dashboards/http-requests 2>/dev/null)"
[ -n "$DASHBOARD" ] || { echo "FAIL: no dashboard http-requests in the project specs."; exit 1; }

VAR="$(printf '%s' "$DASHBOARD" | tester jq -c '[.spec.variables[]? | select(.spec.name == "handler")][0] // {}')"
CHECK="$(printf '%s' "$VAR" | tester jq -r '
  [ (if .kind == "ListVariable" then empty else "not a ListVariable" end),
    (if .spec.plugin.kind == "PrometheusLabelValuesVariable" then empty else "plugin is not PrometheusLabelValuesVariable" end),
    (if .spec.plugin.spec.labelName == "handler" then empty else "labelName is not handler" end),
    (if .spec.allowAllValue == true then empty else "no All choice" end),
    (if .spec.customAllValue == ".*" then empty else "All value is not .*" end) ] | join(", ")')"
if [ -n "$CHECK" ]; then
  echo "FAIL: variable handler: $CHECK."
  exit 1
fi
TIMES="$(printf '%s' "$DASHBOARD" | tester jq -r '"\(.spec.duration // "") \(.spec.refreshInterval // "")"')"
if [ "$TIMES" != "6h 30s" ]; then
  echo "FAIL: duration and refreshInterval are \"$TIMES\", expected \"6h 30s\" as in Grafana."
  exit 1
fi
echo "PASS: variable handler, 6h duration and 30s refresh match Grafana."
exit 0

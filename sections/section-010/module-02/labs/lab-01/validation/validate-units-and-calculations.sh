#!/usr/bin/env bash
# validate-units-and-calculations
# PASS when: confirms units, calculations, the gauge maximum and the gauge thresholds
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

DASHBOARD="$(perses_get /api/v1/projects/specs/dashboards/runtime-panels 2>/dev/null)"
[ -n "$DASHBOARD" ] || { echo "FAIL: no dashboard runtime-panels in the project specs."; exit 1; }

# panel_field TITLE JQ-PATH: prints one field of the plugin spec of the panel with that title.
panel_field() {
  printf '%s' "$DASHBOARD" | tester jq -r --arg t "$1" "[.spec.panels[] | select(.spec.display.name == \$t) | .spec.plugin.spec | $2][0] // \"none\""
}
FAILED=0
# check TITLE JQ-PATH WANT: compares one field with the value the task asks for.
check() {
  local have
  have="$(panel_field "$1" "$2")"
  if [ "$have" != "$3" ]; then
    echo "FAIL: \"$1\" has $2 = $have, expected $3."
    FAILED=1
  fi
}
check "Resident memory" ".format.unit" "bytes"
check "Resident memory" ".calculation" "last-number"
check "Request rate" ".yAxis.format.unit" "requests/sec"
check "Open file descriptors" ".format.unit" "percent-decimal"
check "Open file descriptors" ".calculation" "last-number"
check "Open file descriptors" ".max" "1"
check "Requests by code" ".calculation" "last-number"

STEPS="$(printf '%s' "$DASHBOARD" | tester jq -c '[.spec.panels[] | select(.spec.display.name == "Open file descriptors") | .spec.plugin.spec.thresholds.steps[]?.value][0:0] + [.spec.panels[] | select(.spec.display.name == "Open file descriptors") | .spec.plugin.spec.thresholds.steps[]?.value]')"
OK="$(printf '%s' "$STEPS" | tester jq '(length >= 3) and (. == (sort)) and (.[-1] <= 0.95) and (.[0] == 0)')"
if [ "$OK" != "true" ]; then
  echo "FAIL: the gauge thresholds are $STEPS; expected at least 3 rising steps, the first at 0 and the last at 0.95 or lower."
  FAILED=1
fi
[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: units, calculations, the gauge maximum and the gauge thresholds are as the task asks."
exit 0

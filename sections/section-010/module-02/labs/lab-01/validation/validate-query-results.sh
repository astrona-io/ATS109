#!/usr/bin/env bash
# validate-query-results
# PASS when: confirms each panel query returns the same series as the expression in the task
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
NOW="$(tester date +%s | tr -d '\r')"
FAILED=0
# check_panel TITLE EXPECTED-EXPRESSION: runs both expressions at the same time and compares the series.
check_panel() {
  local have want actual expected
  have="$(printf '%s' "$DASHBOARD" | tester jq -r --arg t "$1" '[.spec.panels[] | select(.spec.display.name == $t) | .spec.queries[0].spec.plugin.spec.query][0] // ""')"
  if [ -z "$have" ]; then
    echo "FAIL: no panel titled \"$1\" with a query."
    FAILED=1
    return
  fi
  expected="$(instant_query specs prometheus "$2" "$NOW")"
  actual="$(instant_query specs prometheus "$(with_lab_values "$have")" "$NOW")"
  if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    echo "FAIL: the query of \"$1\" does not return the series that the task asks for."
    FAILED=1
  fi
}
check_panel "Resident memory" 'process_resident_memory_bytes{job="prometheus"}'
check_panel "Request rate" 'sum by (handler) (rate(prometheus_http_requests_total[5m]))'
check_panel "Open file descriptors" 'process_open_fds{job="prometheus"} / process_max_fds{job="prometheus"}'
check_panel "Requests by code" 'sum by (code) (prometheus_http_requests_total)'
[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: every panel query returns the series that the task asks for."
exit 0

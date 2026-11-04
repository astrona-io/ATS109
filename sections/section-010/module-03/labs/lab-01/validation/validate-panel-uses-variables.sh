#!/usr/bin/env bash
# validate-panel-uses-variables
# PASS when: confirms the panel Request rate uses all three variables and every variable it uses is defined
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

DASHBOARD="$(perses_get /api/v1/projects/specs/dashboards/variable-panels 2>/dev/null)"
[ -n "$DASHBOARD" ] || { echo "FAIL: no dashboard variable-panels in the project specs."; exit 1; }
EXPR="$(printf '%s' "$DASHBOARD" | tester jq -r '[.spec.panels[] | select(.spec.display.name == "Request rate") | .spec.queries[0].spec.plugin.spec.query][0] // ""')"
[ -n "$EXPR" ] || { echo "FAIL: no panel titled \"Request rate\" with a query."; exit 1; }
KIND="$(printf '%s' "$DASHBOARD" | tester jq -r '[.spec.panels[] | select(.spec.display.name == "Request rate") | .spec.plugin.kind][0]')"
UNIT="$(printf '%s' "$DASHBOARD" | tester jq -r '[.spec.panels[] | select(.spec.display.name == "Request rate") | .spec.plugin.spec.yAxis.format.unit][0] // "none"')"
FAILED=0
[ "$KIND" = "TimeSeriesChart" ] || { echo "FAIL: \"Request rate\" uses the plugin $KIND, expected TimeSeriesChart."; FAILED=1; }
[ "$UNIT" = "requests/sec" ] || { echo "FAIL: \"Request rate\" has the unit $UNIT, expected requests/sec."; FAILED=1; }
for VAR in job handler window; do
  case "$EXPR" in
    *"\$$VAR"*|*"\${$VAR}"*) ;;
    *) echo "FAIL: the query of \"Request rate\" does not use the variable \$$VAR."; FAILED=1 ;;
  esac
done
DEFINED="$(printf '%s' "$DASHBOARD" | tester jq -r '[.spec.variables[]?.spec.name] | join(" ")')"
for USED in $(printf '%s' "$EXPR" | grep -oE '\$\{?[a-zA-Z_][a-zA-Z0-9_]*' | tr -d '${' | sort -u); do
  case "$USED" in __*) continue ;; esac
  case " $DEFINED " in
    *" $USED "*) ;;
    *) echo "FAIL: the query uses \$$USED, but no variable of that name is defined."; FAILED=1 ;;
  esac
done
[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: the panel uses job, handler and window, and every variable it uses is defined."
exit 0

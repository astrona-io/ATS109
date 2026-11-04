#!/usr/bin/env bash
# validate-variables
# PASS when: confirms the variables job, handler and window have the plugins and settings the task asks for
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
FAILED=0
# variable_field NAME JQ-PATH: prints one field of the variable with that name.
variable_field() {
  printf '%s' "$DASHBOARD" | tester jq -r --arg n "$1" "[.spec.variables[]? | select(.spec.name == \$n) | $2][0] // \"none\""
}
# check NAME JQ-PATH WANT: compares one field with the value the task asks for.
check() {
  local have
  have="$(variable_field "$1" "$2")"
  if [ "$have" != "$3" ]; then
    echo "FAIL: variable $1 has $2 = $have, expected $3."
    FAILED=1
  fi
}
check job ".spec.plugin.kind" "PrometheusLabelValuesVariable"
check job ".spec.plugin.spec.labelName" "job"
check handler ".spec.plugin.kind" "PrometheusLabelValuesVariable"
check handler ".spec.plugin.spec.labelName" "handler"
check handler ".spec.allowAllValue" "true"
check handler ".spec.customAllValue" ".*"
check window ".spec.plugin.kind" "StaticListVariable"
check window ".spec.defaultValue" "5m"
VALUES="$(printf '%s' "$DASHBOARD" | tester jq -c '[.spec.variables[]? | select(.spec.name == "window") | .spec.plugin.spec.values[]? | if type == "object" then .value else . end]')"
if [ "$VALUES" != '["1m","5m","15m"]' ]; then
  echo "FAIL: the variable window offers $VALUES, expected [\"1m\",\"5m\",\"15m\"]."
  FAILED=1
fi
# The handler list must depend on the job: its matcher uses $job.
MATCHER="$(printf '%s' "$DASHBOARD" | tester jq -r '[.spec.variables[]? | select(.spec.name == "handler") | .spec.plugin.spec.matchers[]?] | join(" ")')"
case "$MATCHER" in
  *'$job'*|*'${job}'*) ;;
  *) echo "FAIL: the matcher of the variable handler does not use \$job, so the list does not depend on the job."; FAILED=1 ;;
esac
[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: the three variables have the right plugins, the handler list depends on the job."
exit 0

#!/usr/bin/env bash
# validate-layout-groups
# PASS when: confirms the groups Summary, Details and Internals hold the right panels, each panel is placed once and Internals starts closed
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

DASHBOARD="$(perses_get /api/v1/projects/legacy/dashboards/overview-grouped 2>/dev/null)"
[ -n "$DASHBOARD" ] || { echo "FAIL: no dashboard overview-grouped in the project legacy."; exit 1; }
FAILED=0
TITLES="$(printf '%s' "$DASHBOARD" | tester jq -r '[.spec.layouts[].spec.display.title] | join("|")')"
if [ "$TITLES" != "Summary|Details|Internals" ]; then
  echo "FAIL: the groups are \"$TITLES\", expected \"Summary|Details|Internals\" in this order."
  exit 1
fi
# members TITLE: the panel names of one group, sorted and joined.
members() {
  printf '%s' "$DASHBOARD" | tester jq -r --arg g "$1" '
    . as $d
    | [$d.spec.layouts[] | select(.spec.display.title == $g) | .spec.items[].content["$ref"] | sub("^#/spec/panels/"; "")] as $keys
    | [$keys[] | $d.spec.panels[.].spec.display.name] | sort | join("|")'
}
check_group() {
  local have
  have="$(members "$1")"
  if [ "$have" != "$2" ]; then
    echo "FAIL: the group $1 holds \"$have\", expected \"$2\"."
    FAILED=1
  fi
}
check_group Summary "Request rate|Resident memory|Targets up"
check_group Details "Request duration|Scrape targets|Target state|Top handlers"
check_group Internals "Goroutines"
OPEN="$(printf '%s' "$DASHBOARD" | tester jq -r '[.spec.layouts[] | "\(.spec.display.title)=\(.spec.display.collapse.open)"] | join(" ")')"
if [ "$OPEN" != "Summary=true Details=true Internals=false" ]; then
  echo "FAIL: group open flags are \"$OPEN\", expected \"Summary=true Details=true Internals=false\"."
  FAILED=1
fi
PROBLEMS="$(printf '%s' "$DASHBOARD" | tester jq -r '
  (.spec.panels | keys | sort) as $keys
  | ([.spec.layouts[].spec.items[].content["$ref"] | sub("^#/spec/panels/"; "")] | sort) as $refs
  | if $keys == $refs then "" else "panel keys " + ($keys | join(",")) + " but layout refs " + ($refs | join(",")) end')"
[ -z "$PROBLEMS" ] || { echo "FAIL: every panel must be placed exactly once: $PROBLEMS."; FAILED=1; }
[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: three groups with the right panels, Internals starts closed, every panel is placed once."
exit 0

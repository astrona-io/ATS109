#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this. Taken from solution.md: the dashboard runtime-panels sent through the Perses API.
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

cat <<'JSON' | put_dashboard specs runtime-panels
{"kind":"Dashboard","metadata":{"name":"runtime-panels","project":"specs"},"spec":{"display":{"name":"Runtime Panels"},"duration":"1h","panels":{"memory":{"kind":"Panel","spec":{"display":{"name":"Resident memory"},"plugin":{"kind":"StatChart","spec":{"calculation":"last-number","format":{"unit":"bytes"}}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"process_resident_memory_bytes{job=\"prometheus\"}","datasource":{"kind":"PrometheusDatasource","name":"prometheus"}}}}}]}},"rate":{"kind":"Panel","spec":{"display":{"name":"Request rate"},"plugin":{"kind":"TimeSeriesChart","spec":{"legend":{"position":"bottom"},"yAxis":{"format":{"unit":"requests/sec"}}}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"sum by (handler) (rate(prometheus_http_requests_total[5m]))","datasource":{"kind":"PrometheusDatasource","name":"prometheus"},"seriesNameFormat":"{{handler}}"}}}}]}},"fds":{"kind":"Panel","spec":{"display":{"name":"Open file descriptors"},"plugin":{"kind":"GaugeChart","spec":{"calculation":"last-number","format":{"unit":"percent-decimal"},"max":1,"thresholds":{"steps":[{"value":0,"color":"#73bf69"},{"value":0.7,"color":"#ff9830"},{"value":0.9,"color":"#f2495c"}]}}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"process_open_fds{job=\"prometheus\"} / process_max_fds{job=\"prometheus\"}","datasource":{"kind":"PrometheusDatasource","name":"prometheus"}}}}}]}},"codes":{"kind":"Panel","spec":{"display":{"name":"Requests by code"},"plugin":{"kind":"BarChart","spec":{"calculation":"last-number","format":{"unit":"decimal"},"sort":"desc"}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"sum by (code) (prometheus_http_requests_total)","datasource":{"kind":"PrometheusDatasource","name":"prometheus"},"seriesNameFormat":"{{code}}"}}}}]}}},"layouts":[{"kind":"Grid","spec":{"display":{"title":"Runtime","collapse":{"open":true}},"items":[{"x":0,"y":0,"width":6,"height":6,"content":{"$ref":"#/spec/panels/memory"}},{"x":6,"y":0,"width":6,"height":6,"content":{"$ref":"#/spec/panels/fds"}},{"x":12,"y":0,"width":12,"height":8,"content":{"$ref":"#/spec/panels/rate"}},{"x":0,"y":8,"width":12,"height":8,"content":{"$ref":"#/spec/panels/codes"}}]}}]}}
JSON

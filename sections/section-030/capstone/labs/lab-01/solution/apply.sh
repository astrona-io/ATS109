#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this. Taken from solution.md: the release candidate
# with all four differences fixed, sent through the Perses API.
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

cat <<'JSON' | put_dashboard release api-latency
{"kind":"Dashboard","metadata":{"name":"api-latency","project":"release"},"spec":{"display":{"name":"API Latency"},"duration":"6h","variables":[{"kind":"ListVariable","spec":{"name":"handler","display":{"name":"Handler"},"allowAllValue":true,"allowMultiple":false,"plugin":{"kind":"PrometheusLabelValuesVariable","spec":{"labelName":"handler","matchers":["prometheus_http_requests_total"]}},"customAllValue":".*"}}],"panels":{"0":{"kind":"Panel","spec":{"display":{"name":"Request rate by handler"},"plugin":{"kind":"TimeSeriesChart","spec":{"yAxis":{"format":{"unit":"requests/sec"}}}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"sum by (handler) (rate(prometheus_http_requests_total{handler=~\"$handler\"}[$__rate_interval]))","datasource":{"kind":"PrometheusDatasource","name":"prometheus"},"seriesNameFormat":"{{handler}}"}}}}]}},"1":{"kind":"Panel","spec":{"display":{"name":"Request duration p90"},"plugin":{"kind":"TimeSeriesChart","spec":{"yAxis":{"format":{"unit":"seconds"}}}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"histogram_quantile(0.9, sum by (le, handler) (rate(prometheus_http_request_duration_seconds_bucket{handler=~\"$handler\"}[5m])))","datasource":{"kind":"PrometheusDatasource","name":"prometheus"},"seriesNameFormat":"{{handler}} p90"}}}}]}},"2":{"kind":"Panel","spec":{"display":{"name":"Error ratio"},"plugin":{"kind":"StatChart","spec":{"calculation":"last-number","format":{"unit":"percent-decimal"},"thresholds":{"steps":[{"value":0,"color":"#73bf69"},{"value":0.01,"color":"#ff9830"},{"value":0.05,"color":"#f2495c"}]}}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"sum(rate(prometheus_http_requests_total{code=~\"5..\"}[5m])) / sum(rate(prometheus_http_requests_total[5m]))","datasource":{"kind":"PrometheusDatasource","name":"prometheus"}}}}}]}},"3":{"kind":"Panel","spec":{"display":{"name":"Head series"},"plugin":{"kind":"StatChart","spec":{"calculation":"last-number","format":{"unit":"decimal"}}},"queries":[{"kind":"TimeSeriesQuery","spec":{"plugin":{"kind":"PrometheusTimeSeriesQuery","spec":{"query":"prometheus_tsdb_head_series","datasource":{"kind":"PrometheusDatasource","name":"prometheus"}}}}}]}}},"layouts":[{"kind":"Grid","spec":{"display":{"title":"Panel Group 1","collapse":{"open":true}},"items":[{"x":0,"y":0,"width":12,"height":8,"content":{"$ref":"#/spec/panels/0"}},{"x":12,"y":0,"width":12,"height":8,"content":{"$ref":"#/spec/panels/1"}},{"x":0,"y":8,"width":12,"height":6,"content":{"$ref":"#/spec/panels/2"}},{"x":12,"y":8,"width":12,"height":6,"content":{"$ref":"#/spec/panels/3"}}]}}],"refreshInterval":"30s"}}
JSON

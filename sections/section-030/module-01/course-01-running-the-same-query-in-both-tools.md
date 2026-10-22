# Running The Same Query In Both Tools

Two panels that draw similar lines may still show different data, and the eye cannot tell a five-minute rate from a one-minute rate on a busy chart. To prove that a migrated panel shows the same data as the Grafana panel, you need numbers, not pictures. This part runs a Grafana panel's expression and the matching Perses panel's expression at the same moment and compares the results series by series.

## What a fair comparison needs

Query parity means that the Grafana panel and the Perses panel get the same answer from the same data. Three things must be fixed for the comparison to be fair. Both queries must run at the **same moment**, because metrics change every scrape. Every dashboard variable must have the **same value** in both, because `$handler` set to `.*` in one and to `/metrics` in the other gives different answers. And built-in variables such as `$__rate_interval` must be replaced by a **fixed window**, because each tool computes them from the width of the chart.

An **instant query** answers all three. It evaluates an expression at one point in time, given as a Unix timestamp, and returns one value per series.

## The two expressions

Start with the panel `Request rate by handler`. Fetch the Grafana dashboard and read its expression, then read the expression of the Perses panel with the same title:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency | jq '.dashboard' > api-latency.json
jq -r '.panels[] | select(.title == "Request rate by handler") | .targets[0].expr' api-latency.json
percli login http://perses.localtest.me:8080
percli describe dashboard api-latency --project parity -ojson > api-latency-perses.json
jq -r '.spec.panels[] | select(.spec.display.name == "Request rate by handler") | .spec.queries[0].spec.plugin.spec.query' api-latency-perses.json
```

Both expressions are `sum by (handler) (rate(prometheus_http_requests_total{handler=~"$handler"}[$__rate_interval]))`. Equal text is a good start, but a migration can also change an expression on purpose or by mistake, and two different texts can still return the same data. Running both is the only proof.

## Run the Grafana expression through Grafana

Grafana runs panel queries through its own API, `POST /api/ds/query`. The body names the datasource by its uid and gives the expression, and `instant: true` asks for one value per series. Fix the variables first: `.*` for `$handler`, and `5m` for `$__rate_interval`.

```sh
NOW=$(date +%s)
EXPR='sum by (handler) (rate(prometheus_http_requests_total{handler=~".*"}[5m]))'
jq -n --arg expr "$EXPR" --arg now "${NOW}000" \
  '{from: $now, to: $now, queries: [{refId: "A", datasource: {uid: "prom-main"}, expr: $expr, instant: true, range: false}]}' > grafana-query.json
kubectl -n observability exec -i deploy/tester -- curl -s -X POST -H 'Content-Type: application/json' \
  --data-binary @- http://grafana.observability:3000/api/ds/query < grafana-query.json \
  | jq '[.results.A.frames[] | {handler: .schema.fields[1].labels.handler, value: .data.values[1][0]}] | sort_by(.handler)'
```

Grafana takes the time range in milliseconds, so the command adds three zeros to the Unix time. Its answer holds one data frame per series: a table with a time field and a value field, where the labels sit on the value field. The `jq` filter keeps the label `handler` and the value of each frame, and sorts them. You see one entry per HTTP handler of Prometheus, such as `/metrics` and `/api/v1/query`, with its rate in requests per second.

## Run the Perses expression through the Perses proxy

Perses runs panel queries through its datasource proxy: `/proxy/projects/<project>/datasources/<name>/` followed by the Prometheus API path. The Perses server forwards the request to the datasource's URL, so the answer is Prometheus' own answer. Run the Perses panel's expression, with the same variable values, at the same moment:

```sh
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query \
  --data-urlencode "query=$EXPR" --data-urlencode "time=$NOW" \
  | jq '[.data.result[] | {handler: .metric.handler, value: (.value[1] | tonumber)}] | sort_by(.handler)'
```

The answer lists the same handlers with the same values as Grafana's answer. Both tools asked the same Prometheus the same question at the same moment, so they must agree. The values match exactly, not just closely, because the time was fixed.

## Compare two expressions automatically

For a whole dashboard, compare text, not screens. The helper below runs one expression through the Perses proxy at a fixed time and prints one sorted line per series, with all labels and the value. It uses the Perses proxy for both expressions, because only the expression is under test: the datasource behind both tools is the same Prometheus.

```sh
instant_series() {
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" --data-urlencode "time=$NOW" \
    | jq -r '.data.result | map((.metric | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(",")) + " " + .value[1]) | sort | .[]'
}
diff <(instant_series "$EXPR") <(instant_series 'sum by (handler) (rate(prometheus_http_requests_total[5m]))') && echo "same series"
diff <(instant_series "$EXPR") <(instant_series 'sum by (handler) (rate(prometheus_http_requests_total[1m]))') || echo "different series"
```

The first comparison prints `same series`: removing the matcher `handler=~".*"` changes the text but not the data. The second prints the lines that differ and `different series`: a one-minute rate is not a five-minute rate, even though the two lines would look alike on a chart.

You can now prove that two panels get the same data, and you know why the time and the variables must be fixed first. Still open is everything a panel adds on top of the data: names, units, thresholds and the time range it opens on.

## Common pitfalls

> [!WARNING]
> - **Comparing at different moments.** Two runs a few seconds apart give different values. Fix the time with `time=` for Prometheus and `from`/`to` for Grafana.
> - **Leaving variables in the expression.** Neither API knows the dashboard's `$handler` or `$__rate_interval`. Replace them with the same fixed values in both expressions.
> - **Trusting equal text.** Two equal expressions can still run against different datasources. Check which datasource each query names, too.
> - **Mixing seconds and milliseconds.** Prometheus takes Unix seconds; Grafana's `/api/ds/query` takes milliseconds.

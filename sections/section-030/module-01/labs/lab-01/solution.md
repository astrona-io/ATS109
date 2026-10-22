# Solution: Restore Query Parity After A Migration

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

Three things were changed by hand, one in each of three panels. Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Save both dashboards

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency | jq '.dashboard' > api-latency.json
percli login http://perses.localtest.me:8080
percli project parity
percli describe dashboard api-latency -ojson > api-latency-perses.json
```

## Step 2: Compare the queries by running them

Define a helper that runs an expression through the Perses proxy at one fixed time and prints the sorted series, then compare each pair of expressions with the variables fixed (`$handler` is `.*`, `$__rate_interval` is `5m`):

```sh
NOW=$(date +%s)
instant_series() {
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" --data-urlencode "time=$NOW" \
    | jq -r '.data.result | map((.metric | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(",")) + " " + .value[1]) | sort | .[]'
}
fixed() { printf '%s' "$1" | sed -e 's/\$__rate_interval/5m/g' -e 's/\$handler/.*/g'; }
for title in "Request rate by handler" "Request duration p90" "Error ratio" "Head series"; do
  grafana_expr=$(jq -r --arg t "$title" '.panels[] | select(.title == $t) | .targets[0].expr' api-latency.json)
  perses_expr=$(jq -r --arg t "$title" '.spec.panels[] | select(.spec.display.name == $t) | .spec.queries[0].spec.plugin.spec.query' api-latency-perses.json)
  if diff -q <(instant_series "$(fixed "$grafana_expr")") <(instant_series "$(fixed "$perses_expr")") >/dev/null; then echo "same:      $title"; else echo "DIFFERENT: $title"; fi
done
```

`Request rate by handler` is different. Its Grafana expression uses `[$__rate_interval]`, and the Perses one uses `[1m]`: a one-minute rate instead of the window Grafana uses. The other three panels return the same series.

## Step 3: Compare legends and calculations

```sh
jq '[.panels[] | {title, legend: .targets[0].legendFormat, reducer: .options.reduceOptions.calcs[0]?}]' api-latency.json
jq '[.spec.panels[] | {title: .spec.display.name, legend: .spec.queries[0].spec.plugin.spec.seriesNameFormat, calculation: .spec.plugin.spec.calculation}]' api-latency-perses.json
```

`Request duration p90` has the legend `p90` in Perses and `{{handler}} p90` in Grafana: every line of the chart would have the same name. `Error ratio` uses the calculation `mean` in Perses, while Grafana uses `lastNotNull`, which is `last-number` in Perses: the stat would show the average over the time range instead of the latest value.

## Step 4: Fix the three panels and apply

Find the panel keys first, then change exactly those three fields:

```sh
jq '.spec.panels | to_entries | map({key, title: .value.spec.display.name})' api-latency-perses.json
jq '.spec.panels["0"].spec.queries[0].spec.plugin.spec.query = "sum by (handler) (rate(prometheus_http_requests_total{handler=~\"$handler\"}[$__rate_interval]))"
    | .spec.panels["1"].spec.queries[0].spec.plugin.spec.seriesNameFormat = "{{handler}} p90"
    | .spec.panels["2"].spec.plugin.spec.calculation = "last-number"' api-latency-perses.json > api-latency-fixed.json
percli apply -f api-latency-fixed.json
```

The keys are `0` to `3`, the positions of the panels in the Grafana list. Run the loop of Step 2 and the commands of Step 3 again on the applied dashboard (save it again with `percli describe`): every panel is now the same.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change the Grafana dashboard to `[1m]` | Grafana is the reference; the grader compares with Grafana's expression |
| Delete the dashboard and migrate it again | The task forbids it, and a new migration loses the restored time range and refresh |
| Use `last` instead of `last-number` | `last` takes the final point even when it is empty; Grafana's `lastNotNull` skips it |
| Compare the queries by reading them | `[$__rate_interval]` and `[5m]` look different and return the same data here; only running them tells |

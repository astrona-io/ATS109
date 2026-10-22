# Solution: Prove Parity For A Migrated Dashboard

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The release candidate has four independent differences: one in the data, one unit, one set of thresholds, and the time settings. Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Save both dashboards

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency | jq '.dashboard' > api-latency.json
percli login http://perses.localtest.me:8080
percli project release
percli describe dashboard api-latency -ojson > release.json
```

## Step 2: Compare the data

Run each pair of expressions through the Perses proxy at one fixed time, with `$handler` as `.*` and `$__rate_interval` as `5m`:

```sh
NOW=$(date +%s)
instant_series() {
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/release/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" --data-urlencode "time=$NOW" \
    | jq -r '.data.result | map((.metric | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(",")) + " " + .value[1]) | sort | .[]'
}
fixed() { printf '%s' "$1" | sed -e 's/\$__rate_interval/5m/g' -e 's/\$handler/.*/g'; }
for title in "Request rate by handler" "Request duration p90" "Error ratio" "Head series"; do
  grafana_expr=$(jq -r --arg t "$title" '.panels[] | select(.title == $t) | .targets[0].expr' api-latency.json)
  perses_expr=$(jq -r --arg t "$title" '.spec.panels[] | select(.spec.display.name == $t) | .spec.queries[0].spec.plugin.spec.query' release.json)
  if diff -q <(instant_series "$(fixed "$grafana_expr")") <(instant_series "$(fixed "$perses_expr")") >/dev/null; then echo "same:      $title"; else echo "DIFFERENT: $title ($perses_expr)"; fi
done
```

`Head series` is different: the Perses query is `prometheus_tsdb_head_chunks`, a different metric from Grafana's `prometheus_tsdb_head_series`. The numbers are in the same range, which is why nobody noticed on screen.

## Step 3: Compare units, thresholds and time

```sh
jq '[.panels[] | {title, unit: .fieldConfig.defaults.unit, steps: .fieldConfig.defaults.thresholds.steps}], {time, refresh}' api-latency.json
jq '[.spec.panels[] | {title: .spec.display.name, unit: (.spec.plugin.spec.format.unit // .spec.plugin.spec.yAxis.format.unit), steps: .spec.plugin.spec.thresholds.steps}], {duration: .spec.duration, refreshInterval: .spec.refreshInterval}' release.json
```

Three more differences show up:

- `Error ratio` uses the Grafana unit `percentunit`, a fraction shown as a percentage, which is `percent-decimal` in Perses. The release candidate uses `percent`, so an error ratio of `0.02` would print as `0.02 %` instead of `2 %`.
- Its thresholds in Grafana change colour at `0.01` and `0.05`. The release candidate uses `1` and `5`: someone rescaled them to percentages, but thresholds compare the raw value, a fraction, so the stat could never turn orange or red.
- Grafana opens on six hours and refreshes every 30 seconds. The release candidate has the migration's default of one hour and no refresh.

## Step 4: Fix all four and apply

```sh
jq '.spec.panels | to_entries | map({key, title: .value.spec.display.name})' release.json
jq '.spec.panels["3"].spec.queries[0].spec.plugin.spec.query = "prometheus_tsdb_head_series"
    | .spec.panels["2"].spec.plugin.spec.format.unit = "percent-decimal"
    | .spec.panels["2"].spec.plugin.spec.thresholds.steps[1].value = 0.01
    | .spec.panels["2"].spec.plugin.spec.thresholds.steps[2].value = 0.05
    | .spec.duration = "6h" | .spec.refreshInterval = "30s"' release.json > release-fixed.json
percli lint -f release-fixed.json --online
percli apply -f release-fixed.json
```

Save the dashboard again with `percli describe` and repeat Steps 2 and 3: every line now matches.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep `percent` and multiply the query by 100 | The data no longer matches Grafana's query, and the grader compares the data |
| Keep the thresholds at `1` and `5` | Thresholds compare the raw fraction, so the stat stays green whatever the error ratio |
| Check only the charts by eye | `prometheus_tsdb_head_chunks` and `prometheus_tsdb_head_series` are close enough to look right |
| Change the Grafana dashboard to match | Grafana is the reference for the whole team |

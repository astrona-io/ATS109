# Solution: Fix The Display Drift In api-latency

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Sign in and save both dashboards

```sh
percli login http://perses.localtest.me:8080
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency | jq '.dashboard' > api-latency.json
percli describe dashboard api-latency --project parity -ojson > api-latency-perses.json
```

## Step 2: Compare the settings

Print the unit, the thresholds and the time settings of each side:

```sh
jq -c '.panels[] | {title, unit: .fieldConfig.defaults.unit, steps: [.fieldConfig.defaults.thresholds.steps[]? | [.value, .color]]}' api-latency.json
jq -c '.spec.panels | to_entries[] | {title: .value.spec.display.name, unit: (.value.spec.plugin.spec.format.unit // .value.spec.plugin.spec.yAxis.format.unit), steps: [.value.spec.plugin.spec.thresholds.steps[]? | [.value, .color]]}' api-latency-perses.json
jq '{from: .time.from, refresh: .refresh}' api-latency.json
jq '{duration: .spec.duration, refreshInterval: .spec.refreshInterval}' api-latency-perses.json
```

Grafana uses `reqps`, `s` and `percentunit`, which map to `requests/sec`, `seconds` and `percent-decimal`. The Perses side shows `decimal` for the request rate, `milliseconds` for the latency and `percent` for the error ratio, so the first three panels differ. The steps `1` and `5` are written for the unit `percent`; with the unit `percent-decimal` they must be `0.01` and `0.05`. The time range is `6h` with a refresh of `30s` in Grafana, but the Perses dashboard has `1h` and no refresh.

## Step 3: Correct the dashboard

Panel keys are positions: `0` is the request rate, `1` the latency, `2` the error ratio. Save this as `fix.jq`:

```jq
del(.metadata.createdAt, .metadata.updatedAt, .metadata.version)
| .spec.panels["0"].spec.plugin.spec.yAxis.format.unit = "requests/sec"
| .spec.panels["1"].spec.plugin.spec.yAxis.format.unit = "seconds"
| .spec.panels["2"].spec.plugin.spec.format.unit = "percent-decimal"
| .spec.panels["2"].spec.plugin.spec.thresholds.steps = [
    {"value": 0, "color": "#73bf69"},
    {"value": 0.01, "color": "#ff9830"},
    {"value": 0.05, "color": "#f2495c"}]
| .spec.duration = "6h"
| .spec.refreshInterval = "30s"
```

Build the file, validate it and apply it:

```sh
jq -f fix.jq api-latency-perses.json > api-latency-fixed.json
percli lint -f api-latency-fixed.json --online
percli apply -f api-latency-fixed.json
```

## Step 4: Check the result

```sh
percli describe dashboard api-latency --project parity -ojson | jq -c '{duration: .spec.duration, refreshInterval: .spec.refreshInterval, units: [.spec.panels[] | (.spec.plugin.spec.format.unit // .spec.plugin.spec.yAxis.format.unit)]}'
```

The command prints the duration `6h`, the refresh `30s` and the four units `requests/sec`, `seconds`, `percent-decimal` and `decimal`. Send the lab for grading with `astrona submit -c sections/section-030/module-02/labs/lab-01`.

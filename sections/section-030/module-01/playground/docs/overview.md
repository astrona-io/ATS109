# Overview: Check That A Migrated Dashboard Shows The Same Data (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Perses, Prometheus and Grafana, applies a correctly migrated dashboard, and then waits. There is no task, no `astrona submit` and no pass or fail. Compare, change things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, reached at `http://perses.localtest.me:8080`. `percli` v0.54.0 is installed on your machine.
- In Perses, the project **`parity`** with the default datasource `prometheus` and the dashboard **`api-latency`**: a correct migration of the Grafana dashboard, with its time range and refresh restored.
- **Grafana 12.4.13** in the namespace `observability` with the dashboard **`API Latency`** (uid `api-latency`): two time series (request rate per handler, 90th percentile duration), two stats (error ratio with thresholds, head series), and the variable `handler`. Its Prometheus datasource has the uid `prom-main`. Anyone is let in as an administrator: lab only.
- **Prometheus v3.15.1** and a **`tester`** pod with `curl` and `jq` in `observability`.

## Getting started

Start the Perses port-forward in a second terminal and leave it running. For Grafana in the browser, start a third one at `http://localhost:3000`:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
kubectl -n observability port-forward svc/grafana 3000:3000
```

Then sign `percli` in:

```sh
percli login http://perses.localtest.me:8080
```

## Helpers

Paste these once in each new terminal. `save_both` saves the Grafana dashboard to `api-latency.json` and the Perses dashboard to `api-latency-perses.json`. `instant_series` runs one expression through the Perses proxy at the time in `$NOW` and prints one sorted line per series. `panel_settings` prints the legend, unit, calculation and thresholds of every panel in both files.

```sh
save_both() {
  kubectl -n observability exec deploy/tester -- \
    curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency | jq '.dashboard' > api-latency.json
  percli describe dashboard api-latency --project parity -ojson > api-latency-perses.json
}
instant_series() {
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" --data-urlencode "time=$NOW" \
    | jq -r '.data.result | map((.metric | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(",")) + " " + .value[1]) | sort | .[]'
}
panel_settings() {
  jq '[.panels[] | {title, legend: .targets[0].legendFormat, unit: .fieldConfig.defaults.unit, reducer: .options.reduceOptions.calcs[0]?, steps: .fieldConfig.defaults.thresholds.steps}]' api-latency.json
  jq '[.spec.panels[] | {title: .spec.display.name, legend: .spec.queries[0].spec.plugin.spec.seriesNameFormat, unit: (.spec.plugin.spec.format.unit // .spec.plugin.spec.yAxis.format.unit), calculation: .spec.plugin.spec.calculation, steps: .spec.plugin.spec.thresholds.steps}]' api-latency-perses.json
}
```

Use them like this: `save_both`, `NOW=$(date +%s)`, `instant_series 'sum(up)'`, `panel_settings`.

## Practice tasks

- Run every Grafana panel's expression and the matching Perses expression with `instant_series` (replace `$handler` with `.*` and `$__rate_interval` with `5m`) and `diff` the results.
- Change the unit of the stat `Error ratio` in Perses to `percent`, apply it, and compare what the panel shows in both tools.
- Change the calculation of `Head series` to `mean` and find the value it shows. Explain why it differs from Grafana's `lastNotNull`.
- Set the variable `handler` to `/metrics` in both tools and compare the request rate panels in the browser.
- Migrate the Grafana dashboard again with `percli migrate --online` and list every difference between that result and the dashboard in the project `parity`.

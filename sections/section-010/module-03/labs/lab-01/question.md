# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** The dashboard specification

## Scenario

The `drifter` team wants one request-rate chart that an engineer can narrow down in three steps: first the scrape job, then one handler of that job, and then the length of the rate window. The handler list must offer only handlers that exist for the chosen job.

## Your task

In the Perses project `specs`, create a dashboard named `variable-panels` (`metadata.name`) with the display name `Variable Panels`, with these three list variables, in this order:

1. **`job`**: offers the values of the label `job` of the metric `up` (the plugin `PrometheusLabelValuesVariable`). It has no All choice.
2. **`handler`**: offers the values of the label `handler` of `prometheus_http_requests_total` for the chosen job, so its matcher uses `$job`. It has an All choice whose value is `.*`.
3. **`window`**: a fixed list (the plugin `StaticListVariable`) with the values `1m`, `5m` and `15m`. The default value is `5m`.

Add one `TimeSeriesChart` titled `Request rate` with the unit `requests/sec` and the query `sum by (handler) (rate(prometheus_http_requests_total{job="$job",handler=~"$handler"}[$window]))`. Place it in a `Grid` layout.

## Constraints

- Write the dashboard yourself. Do not use `percli migrate` or the Perses import page.
- Do not create other datasources. The project's default datasource `prometheus` answers the queries.
- Keep the variable names and the panel title exactly as written.

## Done when

- The dashboard `variable-panels` exists in the project `specs` and passes the server's validation.
- The three variables use the plugins and settings above, and the matcher of `handler` depends on `$job`.
- The panel `Request rate` uses `$job`, `$handler` and `$window`, and every variable it uses is defined.
- With `job` set to `prometheus`, `handler` to `.*` and `window` to `5m`, the query returns the request rate per handler.

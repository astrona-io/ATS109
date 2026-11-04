# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** The dashboard specification

## Scenario

The `drifter` team needs a small runtime dashboard for the Prometheus server in the `observability` namespace. The team lead wants to see one dashboard that uses four different panel plugins, each with the unit and the calculation that fit its question. Prometheus scrapes itself under the job `prometheus`, so every metric below has the label `job="prometheus"`.

## Your task

In the Perses project `specs`, create a dashboard named `runtime-panels` (`metadata.name`) with the display name `Runtime Panels`, and four panels with exactly these titles:

1. **Resident memory**: a `StatChart` that shows `process_resident_memory_bytes{job="prometheus"}` in the unit `bytes`, reduced with the calculation `last-number`.
2. **Request rate**: a `TimeSeriesChart` that shows `sum by (handler) (rate(prometheus_http_requests_total[5m]))`, with the unit `requests/sec` on the y axis and the series name `{{handler}}`.
3. **Open file descriptors**: a `GaugeChart` that shows `process_open_fds{job="prometheus"} / process_max_fds{job="prometheus"}` in the unit `percent-decimal`, with the calculation `last-number`, the maximum `1` and at least three rising threshold steps. The first step is `0`, and the last step is `0.95` or lower.
4. **Requests by code**: a `BarChart` that shows `sum by (code) (prometheus_http_requests_total)` with the calculation `last-number`.

Place all four panels in a `Grid` layout.

## Constraints

- Write the dashboard yourself. Do not use `percli migrate` or the Perses import page.
- Do not create other datasources. The project's default datasource `prometheus` answers the queries.
- Keep the panel titles exactly as written.

## Done when

- The dashboard `runtime-panels` exists in the project `specs` and passes the server's validation.
- It has one panel of each plugin kind named above, and every layout item points at a panel that exists.
- The units, calculations, gauge maximum and gauge thresholds are as the task asks.
- Each panel's query returns the same series as the expression in the task.

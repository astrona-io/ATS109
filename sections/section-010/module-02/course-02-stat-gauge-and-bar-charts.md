# Stat, Gauge And Bar Charts

Some questions have one answer: how many targets are up, how full is the file limit, which handler gets the most requests. Three panel plugins show such answers, and all three turn a series of values into numbers with a calculation. This part builds a `StatChart`, a `GaugeChart` and a `BarChart` and explains what they share.

## Calculations and formats

A series has many values over time, and a stat shows one. A **calculation** is the rule that reduces the series to that one number. The Perses calculations are `first`, `last`, `first-number`, `last-number`, `mean`, `sum`, `min` and `max`. The `-number` forms skip empty points, so `last-number` shows the last real value while `last` can show nothing when the series ends with a gap.

A **format** says how the number is printed. It has a `unit` and, optionally, `decimalPlaces`. The unit `percent-decimal` prints a fraction such as `0.02` as `2%`, and `percent` prints a number that is already a percentage. The unit `bytes` prints `1048576` as `1 MiB`, and `decimal` prints a plain number.

## Three panels in one dashboard

The dashboard below shows the resident memory of Prometheus, the share of its open file limit that is used, and the number of requests per handler.

<!-- astrona:playground:renew -->

Save this as `dashboard-single-values.yaml`:

```yaml
kind: Dashboard
metadata:
  name: single-values
  project: specs
spec:
  display:
    name: Single Values
  duration: 1h
  panels:
    memory:
      kind: Panel
      spec:
        display:
          name: Memory
        plugin:
          kind: StatChart
          spec:
            calculation: last-number
            format:
              unit: bytes
            sparkline: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: process_resident_memory_bytes
    filesUsed:
      kind: Panel
      spec:
        display:
          name: Open files used
        plugin:
          kind: GaugeChart
          spec:
            calculation: last-number
            format:
              unit: percent-decimal
            max: 1
            thresholds:
              steps:
                - value: 0
                  color: "#73bf69"
                - value: 0.7
                  color: "#ff9830"
                - value: 0.9
                  color: "#f2495c"
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: process_open_fds / process_max_fds
    byHandler:
      kind: Panel
      spec:
        display:
          name: Requests by handler
        plugin:
          kind: BarChart
          spec:
            calculation: last-number
            format:
              unit: decimal
            sort: desc
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (handler) (prometheus_http_requests_total)
                  seriesNameFormat: "{{handler}}"
  layouts:
    - kind: Grid
      spec:
        display:
          title: Single values
        items:
          - x: 0
            y: 0
            width: 8
            height: 6
            content:
              $ref: "#/spec/panels/memory"
          - x: 8
            y: 0
            width: 8
            height: 6
            content:
              $ref: "#/spec/panels/filesUsed"
          - x: 16
            y: 0
            width: 8
            height: 6
            content:
              $ref: "#/spec/panels/byHandler"
```

Apply it:

```sh
percli apply -f dashboard-single-values.yaml
```

Then check the result:

```sh
percli describe dashboard single-values -ojson | jq '.spec.panels | map_values({plugin: .spec.plugin.kind, calculation: .spec.plugin.spec.calculation, unit: .spec.plugin.spec.format.unit})'
```

The answer lists three panels with their plugin, calculation and unit. Open the dashboard in the browser to see a number with a small trend line, a gauge, and a bar for each handler.

## What differs between the three

The `StatChart` shows one big number. Its `sparkline` field adds a small line of the series behind it, and its `thresholds` colour the number. The `GaugeChart` draws the value on a dial between zero and `max`; the thresholds colour the arcs, so the steps at `0.7` and `0.9` turn the gauge orange and then red. A gauge needs a sensible `max`: with the unit `percent-decimal`, the full dial is `1`.

The `BarChart` draws one bar per series, using the calculation to get one value for each. The query returns one series per handler, so the chart shows one bar per handler, and `sort: desc` puts the longest bar first. Without a calculation, Perses cannot decide which point of each series a bar shows.

Compare this with Grafana. A Grafana `stat` and a `gauge` take their calculation from `options.reduceOptions.calcs`, the unit from `fieldConfig.defaults.unit` and the colours from `fieldConfig.defaults.thresholds`. A Grafana `bargauge` becomes the Perses `BarChart`. In Perses all three read their settings from the one `spec` of the plugin.

You can now choose between a stat, a gauge and a bar chart, and set the calculation, the unit and the thresholds of each. Still open are panels that show many rows or free text.

## Common pitfalls

> [!WARNING]
> - **Leaving out `calculation`.** A stat or a gauge then uses the plugin's default, which may not be the value you expect.
> - **Using `last` on a series with gaps.** Use `last-number` to skip empty points.
> - **Wrong threshold scale on a gauge.** With `percent-decimal`, the steps are fractions: `0.9`, not `90`.
> - **Forgetting `max` on a gauge of a fraction.** Without it, the dial may stop at a different end than `1`.

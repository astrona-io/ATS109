# Choose And Configure Panel Plugins

A Perses dashboard is only as useful as its panels. Each panel names a panel plugin, and the plugin decides which settings are valid and how the data is drawn. A migration picks the plugin for you, so you must be able to judge whether the choice and its settings fit the data.

This module goes through the panel plugins that Perses v0.54.0 ships for numbers and text: the time series chart, the stat, gauge, bar and pie charts, the table and the Markdown panel. For each one you write a panel, apply it and read back which setting changed what. Keep one sentence in mind: **the server checks that the settings fit the plugin, and only you can check that the plugin fits the question.**

The module has four parts. **Time Series Chart Settings** covers the legend, the line style, the vertical axis and thresholds. **Stat, Gauge And Bar Charts** covers calculations and formats. **Table, Markdown And Pie Charts** covers the plugins that show rows, text and shares. **Units, Thresholds And Choosing A Plugin** collects the rules that all panels share, and a graded lab follows it.

## Learning objectives

After this module you can:

- Set the legend, the visual style, the axis and the thresholds of a `TimeSeriesChart`.
- Choose a calculation and a format for a `StatChart`, a `GaugeChart` and a `BarChart`.
- Write a `Table`, a `Markdown` panel and a `PieChart`.
- Pick the unit from the scale of the query result, not from the name of the metric.
- Write threshold steps that use the same scale as the value.
- Choose the panel plugin that answers a given question.

## Before you start

You need to read a Perses dashboard: panels as a map of named entries, each with a plugin and a list of queries, and a `Grid` layout whose items point at panels with `$ref`. You also need `jq` and enough PromQL to read the queries.

Your playground is a single-node `kind` cluster with:

| Component | Where | What it holds |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses`, `http://perses.localtest.me:8080` | the project `specs` with the default datasource `prometheus` and the dashboard `example` |
| Prometheus v3.15.1 | namespace `observability` | metrics about Prometheus itself |
| Grafana 12.4.13 | namespace `observability` | the dashboard `HTTP Requests` (uid `http-requests`) |
| `tester` | namespace `observability` | a pod with `curl` and `jq` |

`percli` v0.54.0 is installed on your machine. Before you run any `percli` command, start the port-forward in a second terminal and leave it running, then sign in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
percli login http://perses.localtest.me:8080
percli project specs
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

# Table, Markdown And Pie Charts

Not every panel draws a line. A table lists one row per series, a Markdown panel holds text for the reader, and a pie chart shows shares of a whole. These three plugins have different settings, and the migration produces all of them, so you need to know what a correct one looks like. This part writes one of each.

## A table of targets

A `Table` panel shows the result of its queries as rows and columns. The query below returns one series per scrape target, and the `Table` plugin turns each series into a row.

<!-- astrona:playground:renew -->

Save this as `dashboard-lists-and-text.yaml`:

```yaml
kind: Dashboard
metadata:
  name: lists-and-text
  project: specs
spec:
  display:
    name: Lists And Text
  duration: 1h
  panels:
    targets:
      kind: Panel
      spec:
        display:
          name: Targets
        plugin:
          kind: Table
          spec:
            density: compact
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: up
    notes:
      kind: Panel
      spec:
        display:
          name: Notes
        plugin:
          kind: Markdown
          spec:
            text: |
              ## About this dashboard
              The table lists every scrape target. The pie chart shows requests by code.
    codes:
      kind: Panel
      spec:
        display:
          name: Requests by code
        plugin:
          kind: PieChart
          spec:
            calculation: last-number
            format:
              unit: decimal
            legend:
              position: right
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (code) (prometheus_http_requests_total)
                  seriesNameFormat: "{{code}}"
  layouts:
    - kind: Grid
      spec:
        display:
          title: Overview
        items:
          - x: 0
            y: 0
            width: 12
            height: 8
            content:
              $ref: "#/spec/panels/targets"
          - x: 12
            y: 0
            width: 12
            height: 8
            content:
              $ref: "#/spec/panels/codes"
          - x: 0
            y: 8
            width: 24
            height: 4
            content:
              $ref: "#/spec/panels/notes"
```

Apply it:

```sh
percli apply -f dashboard-lists-and-text.yaml
```

Then check the result:

```sh
percli describe dashboard lists-and-text -ojson | jq '.spec.panels | map_values(.spec.plugin.kind)'
```

The answer maps `targets` to `Table`, `notes` to `Markdown` and `codes` to `PieChart`. Open the dashboard in the browser to see all three.

## Table settings

The `Table` plugin has fields for the layout of the table: `density` (`compact` or `standard`), `pagination` and a list of `columnSettings`, each with the `name` of a column and options such as `header`, `width`, `hide` and `format`. A table built from time series queries has a column for the series name and a column for the value. The names of those columns are part of the plugin, so list them in the browser before you write `columnSettings`.

## Markdown settings

The `Markdown` plugin has one field, `text`. The text is Markdown, and the plugin draws it as formatted text. A Markdown panel has no queries, so the `queries` field is left out. This is the same plugin the migration uses for a Grafana `text` panel, and also, with a warning text, for panels it cannot translate. Because of that, you must read the text of a Markdown panel before you decide that it is a real note.

## Pie chart settings

The `PieChart` plugin works like the bar chart: the query returns one series per slice, and `calculation` reduces each series to one value. Its `format` prints the value, `legend` places the slice names, and `sort` and `mode` choose the order of the slices and whether the values show as numbers or shares. A pie chart is the right choice only when the slices are parts of one total. The metric `prometheus_http_requests_total` is a counter, and the sum by `code` adds up all requests since the start, so the slices are shares of all requests ever answered.

You can now write a table, a text panel and a pie chart. Still open is how units and thresholds are chosen, because they work the same way across all panel plugins.

## Common pitfalls

> [!WARNING]
> - **Adding `queries` to a `Markdown` panel.** The panel does not use them.
> - **Using a pie chart for values that are not parts of a whole.** Memory and CPU do not add up to one total.
> - **Forgetting that a table needs a query.** A `Table` without queries shows no rows.
> - **Reading a Markdown panel by its kind.** The text decides whether it is a note or a migration placeholder.

# Summary

A Perses dashboard is a resource like every other Perses object: a `kind`, a `metadata` block with its `name` and `project`, and a `spec`. The Perses project publishes this data model as an open specification, kept in step in Go, CUE and TypeScript, and a tool is compatible with Perses when `percli` accepts the dashboards it writes. The dashboard `spec` holds a display name, a default time range in `duration`, an optional `refreshInterval`, variables, panels and layouts.

## What you learned

Perses keeps what to show apart from where to show it. Panels live in a map under `spec.panels`, each with a `display`, a panel plugin such as `TimeSeriesChart` or `StatChart`, and a list of queries. Layouts under `spec.layouts` place them: a `Grid` is one titled group, and each of its items gives a position and size on a 24-unit grid and points at a panel key with a `$ref` such as `#/spec/panels/openFiles`. Grafana keeps both in one panel object, with the position in `gridPos`.

A query has an outer kind, `TimeSeriesQuery`, and a plugin, `PrometheusTimeSeriesQuery`, whose `spec` holds the PromQL expression in `query` and the legend in `seriesNameFormat`. A query finds its datasource by kind and an optional name, looking first in the dashboard, then in the project, then in the global datasources, and it falls back to the default datasource of its kind when it gives no name. A name that exists nowhere leaves the panel empty without any error when the dashboard is saved.

Variables are a list under `spec.variables`. A `ListVariable` gets its values from a plugin such as `PrometheusLabelValuesVariable`, and its own fields control the All choice, multiple selection, the default value and sorting. A `TextVariable` holds one typed or constant value.

Every plugin ships a schema in CUE that says what its `spec` may contain, and the Perses server checks each part of a dashboard against it. `percli lint --online` asks the server to check a file without storing it, and `percli apply` stores nothing when a check fails. Grafana's own words, such as `average` or `lastNotNull`, are not valid in Perses plugin specs. The key facts to remember are these:

- `metadata.name` is the identifier for the API and `percli`; `spec.display.name` is only what people see.
- Every layout item must point at a panel key that exists, and every panel needs an item to be drawn.
- `percli lint -f <file> --online` checks a dashboard against the plugins the server really runs.
- Grafana's `time.from` of `now-6h` is Perses' `duration: 6h`, and `refresh` is `refreshInterval`.

<!-- astrona:playground:destroy -->

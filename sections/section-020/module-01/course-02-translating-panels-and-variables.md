# Translating Panels And Variables

A migrated dashboard can look complete and still hide panels that show nothing useful. The migration translates each panel, query and variable with the rules of a plugin, and when no plugin claims one, it writes a placeholder. This part reads a migrated dashboard panel by panel and variable by variable, so you can predict what any Grafana dashboard will become and find every placeholder in seconds.

## Panels: which plugin takes which type

Start from the result. Migrate the dashboard `Prometheus Overview` again, then list each Grafana panel type next to the Perses plugin it became:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-overview | jq '.dashboard' > prometheus-overview.json
percli login http://perses.localtest.me:8080
percli migrate -f prometheus-overview.json --online -o json > overview-migrated.json
jq -r '[.panels[] | select(.type != "row") | .type] + [.panels[] | select(.type == "row") | .panels[].type] | .[]' prometheus-overview.json
jq -r '.spec.panels | to_entries[] | "\(.key)\t\(.value.spec.plugin.kind)\t\(.value.spec.display.name)"' overview-migrated.json
```

The Grafana types are `stat`, `gauge`, `timeseries`, `bargauge`, `table`, `heatmap`, `state-timeline` and, inside the row, `timeseries`. The Perses panels map them to `StatChart`, `GaugeChart`, `TimeSeriesChart`, `BarChart` and `Table`, and the `Goroutines` panel to `TimeSeriesChart`. The `heatmap` panel (`Request duration`) and the `state-timeline` panel (`Target state`) both became `Markdown`.

A Grafana panel type is translated only when a plugin the Perses server runs declares that type in its migration schema. With the plugins bundled in Perses v0.54.0, the table is:

| Grafana panel type | Perses panel plugin |
| --- | --- |
| `timeseries`, `graph` | `TimeSeriesChart` |
| `stat` | `StatChart` |
| `gauge` | `GaugeChart` |
| `bargauge` | `BarChart` |
| `table`, `table-old` | `Table` |
| `piechart` | `PieChart` |
| `status-history` | `StatusHistoryChart` |
| `text` | `Markdown` |
| `logs` | `LogsTable` |
| anything else (`heatmap`, `state-timeline`, `xychart`, `barchart`, `geomap`, ...) | placeholder |

## The three placeholders

When nothing claims a panel, the migration keeps the panel's title and description, and makes it a `Markdown` panel with the text `**Migration from Grafana not supported !**`. Its queries are still translated, so the expression is not lost. Print the two placeholder panels with their queries:

```sh
jq '.spec.panels | to_entries | map(select(.value.spec.plugin.kind == "Markdown" and (.value.spec.plugin.spec.text | test("not supported")))) | map({key, title: .value.spec.display.name, query: .value.spec.queries[0].spec.plugin.spec.query})' overview-migrated.json
```

Panels `5` and `6` are the placeholders, and each still holds its PromQL expression. There are two more kinds of placeholder. A query no plugin claims becomes a `PrometheusTimeSeriesQuery` whose query is `migration_from_grafana_not_supported`. A variable no plugin claims becomes a `StaticListVariable` with the four values `grafana`, `migration`, `not` and `supported`. One `jq` command finds all three kinds in any migrated file:

```sh
jq '[.. | strings | select(test("Migration from Grafana not supported|migration_from_grafana_not_supported"))] | length' overview-migrated.json
jq '[.spec.variables[] | select(.spec.plugin.spec.values? == ["grafana","migration","not","supported"]) | .spec.name]' overview-migrated.json
```

The first count includes the two placeholder panels. The second command names the variable `filter`, a Grafana `adhoc` variable: an ad hoc filter adds label filters to every query of the dashboard, and Perses has no such feature, so no plugin claims it.

## Queries: what a target becomes

Each Grafana target with an `expr` field becomes a `PrometheusTimeSeriesQuery`. Look at one:

```sh
jq '.panels[2].targets[0] | {datasource, expr, legendFormat}' prometheus-overview.json
jq '.spec.panels["2"].spec.queries[0].spec.plugin.spec' overview-migrated.json
```

The Grafana target names the datasource `{"type": "prometheus", "uid": "prom-main"}`, and the Perses query names `{"kind": "PrometheusDatasource", "name": "prom-main"}`. The expression moves to `query` unchanged, `legendFormat` becomes `seriesNameFormat`, and a target `interval` would become `minStep`. Grafana's automatic legend `__auto` is dropped. Expressions keep `$job`, `$handler` and built-in variables such as `$__rate_interval`, which the Perses Prometheus plugin understands too.

The datasource is the catch. The migration copies the Grafana **uid** into the Perses `name`, and the Perses project `legacy` has no datasource called `prom-main`. Every panel of this dashboard would stay empty until you fix that, which is the first job of finishing a migration.

## Variables: which type becomes what

Variables follow the same pattern: the migration keeps the list settings (`includeAll`, `multi`, `allValue`, `sort`, `hide`, the label and the current value) and lets a plugin translate the source. List them:

```sh
jq '.spec.variables | map({name: .spec.name, kind, plugin: .spec.plugin.kind})' overview-migrated.json
```

`job` and `handler` became `PrometheusLabelValuesVariable`, `interval` became a `StaticListVariable` with `1m`, `5m` and `15m`, and `filter` is the placeholder. The full rule set is:

| Grafana variable | Perses variable |
| --- | --- |
| `query` with `label_values(...)` | `ListVariable` with `PrometheusLabelValuesVariable` |
| `query` with `label_names()` | `ListVariable` with `PrometheusLabelNamesVariable` |
| `query` with `query_result(... by (label) ...)` | `ListVariable` with `PrometheusPromQLVariable` |
| `custom`, `interval` | `ListVariable` with `StaticListVariable` |
| `datasource` | `ListVariable` with `DatasourceVariable` |
| `textbox`, `constant` | `TextVariable` (`constant: true` for a constant) |
| anything else (`adhoc`, ...) | placeholder `StaticListVariable` |

A `query_result(...)` expression without a `by (label)` clause still becomes a `PrometheusPromQLVariable`, but with the label name `migration_from_grafana_not_supported`, which you then replace with the label you want.

You can now predict what each panel, query and variable becomes, and find every placeholder with `jq`. The open question is how to finish the job: fix the datasource names, replace the placeholders, and get the result into a project.

## Common pitfalls

> [!WARNING]
> - **Counting only panels.** Placeholders also hide in queries and variables. Search the whole file for all three.
> - **Missing the datasource names.** The migration copies the Grafana uid into every query. A dashboard full of `prom-main` opens without an error and shows nothing.
> - **Expecting ad hoc filters to work.** Perses has no ad hoc filter, so an `adhoc` variable always becomes a placeholder.
> - **Thinking the expression is lost.** A placeholder panel still carries its queries. Read them before you replace the panel.

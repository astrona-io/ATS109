# Summary

Migrating a Grafana dashboard to Perses is a two-step job: the migration translates what it can, and you finish the rest. `percli migrate -f <file> --online` sends the Grafana JSON to the Perses server's `POST /api/migrate` endpoint, which returns a Perses dashboard without storing it. The server translates the frame of the dashboard itself and hands each panel, query and variable to the migration schema of the plugin that claims it, a `migrate.cue` file each plugin ships.

## What you learned

The dashboard's identity carries over: the Grafana `uid` becomes `metadata.name`, the `title` becomes `spec.display.name`, and the tags stay. Its time settings do not: every migrated dashboard has `duration: 1h` and no refresh interval, whatever Grafana used. Panels become a map keyed by their position in the Grafana list, and a collapsed Grafana row becomes its own closed `Grid` with keys such as `7_0`. Panels under an open row sit at the top level of Grafana's JSON, so they land in `Panel Group 1` and the row title is lost.

Common Grafana panel types translate to Perses plugins: `timeseries` and `graph` to `TimeSeriesChart`, `stat` to `StatChart`, `gauge` to `GaugeChart`, `bargauge` to `BarChart`, `table` to `Table`, `piechart` to `PieChart`, `status-history` to `StatusHistoryChart`, `text` to `Markdown` and `logs` to `LogsTable`. Everything else becomes a placeholder: a `Markdown` panel that keeps the title and description but has no queries. The queries of a translated panel keep their expression, `legendFormat` becomes `seriesNameFormat`, and the Grafana datasource uid becomes the Perses datasource name. Variables keep their list settings, and their source is translated by plugin: `label_values` to `PrometheusLabelValuesVariable`, `custom` and `interval` to `StaticListVariable`, `textbox` and `constant` to `TextVariable`.

Finishing a migration means fixing the datasource names, with `--use-default-datasource` or by rewriting the old uid, replacing every placeholder with the closest Perses plugin while keeping its title and writing its queries from the Grafana panel, restoring the time range and any unit the mapping dropped, and applying the result to a project. The key facts to remember are these:

- The three placeholders are the Markdown panel `Migration from Grafana not supported !`, the query `migration_from_grafana_not_supported`, and the static list `grafana migration not supported`.
- `--project` sets `metadata.project`; `--format cr` writes a `PersesDashboard` custom resource instead of a dashboard.
- `--input NAME=VALUE` fills a Grafana input such as `${DS_PROMETHEUS}` in a dashboard exported for sharing.
- A placeholder panel arrives with `queries: null`, so you copy each expression from the Grafana panel at the same position.
- A placeholder panel is replaced, never deleted: it keeps the panel's title and its place in the layout, and the dashboard keeps one Perses panel for each Grafana panel.

<!-- astrona:playground:destroy -->

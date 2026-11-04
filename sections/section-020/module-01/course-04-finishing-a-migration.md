# Finishing A Migration

A migration is finished when the dashboard is in a project, every query reaches a datasource that exists, and no placeholder is left. The migration does none of this for you, because each step needs a decision only you can make: which datasource to use, what should replace a panel Perses cannot draw, and what time range people expect. This part takes the dashboard `Prometheus Storage` from Grafana all the way into the project `legacy`.

## Migrate into a project with the default datasource

Two flags of `percli migrate` save work later. `--project` writes the project into `metadata.project`, so `percli apply` knows where the dashboard goes. `--use-default-datasource` removes the datasource `name` from every query, so each query uses the default datasource of its kind in the project. In the project `legacy`, that is the Prometheus datasource `prometheus`.

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-storage | jq '.dashboard' > prometheus-storage.json
percli login http://perses.localtest.me:8080
percli migrate -f prometheus-storage.json --online --use-default-datasource --project legacy -o json > storage-migrated.json
jq '{project: .metadata.project, datasources: [.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource]}' storage-migrated.json
```

The project is `legacy`, and every query's datasource now holds only `kind: PrometheusDatasource`, without a name. If you would rather keep explicit names, migrate without the flag and rewrite the old uid with `jq`; the next command does that on a copy, so you can compare the two results:

```sh
percli migrate -f prometheus-storage.json --online --project legacy -o json \
  | jq '(.. | objects | select(.kind? == "PrometheusDatasource" and .name? == "prom-main") | .name) = "prometheus"' > storage-renamed.json
jq '[.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource.name] | unique' storage-renamed.json
```

Every query in the copy now names `prometheus`. Both results work; keep using `storage-migrated.json` below. Do not create a Perses datasource called `prom-main` to make the old name work: that adds a second name for the same Prometheus, and every future migration keeps depending on it.

## Find and replace the placeholders

List all three kinds of placeholder in the file:

```sh
jq '{panels: [.spec.panels | to_entries[] | select(.value.spec.plugin.kind == "Markdown" and (.value.spec.plugin.spec.text | test("not supported"))) | {key, title: .value.spec.display.name, queries: [.value.spec.queries[]?.spec.plugin.spec.query]}],
     queries: [.. | strings | select(. == "migration_from_grafana_not_supported")],
     variables: [.spec.variables[] | select(.spec.plugin.spec.values? == ["grafana","migration","not","supported"]) | .spec.name]}' storage-migrated.json
```

One panel is a placeholder: key `4`, `Series against chunks`, a Grafana `xychart` that plotted one metric against another. Its `queries` list is empty, because the migration does not migrate the queries of a panel it cannot translate. No query and no variable is a placeholder here; the `text` panel `About` became a real `Markdown` panel with its content, which is not a placeholder.

The two expressions are still in the Grafana file. The panel key `4` is the panel's position in Grafana's `panels` list, so read that panel:

```sh
jq -c '.panels[4] | {title, type, expr: [.targets[].expr]}' prometheus-storage.json
```

The Grafana panel runs `prometheus_tsdb_head_series` and `prometheus_tsdb_head_chunks`. You cannot get an X-Y chart in Perses v0.54.0, so choose the closest panel that shows the same data. A `TimeSeriesChart` with both queries draws both metrics over time. Set the plugin and the whole `queries` list, and keep the title. Each query leaves out `datasource`, so it uses the default datasource of the project:

```sh
jq '.spec.panels["4"].spec.plugin = {"kind": "TimeSeriesChart", "spec": {"legend": {"position": "bottom"}}}
    | .spec.panels["4"].spec.queries = [
        {"kind": "TimeSeriesQuery", "spec": {"plugin": {"kind": "PrometheusTimeSeriesQuery", "spec": {"query": "prometheus_tsdb_head_series"}}}},
        {"kind": "TimeSeriesQuery", "spec": {"plugin": {"kind": "PrometheusTimeSeriesQuery", "spec": {"query": "prometheus_tsdb_head_chunks"}}}}]' storage-migrated.json > storage-finished.json
```

The same pattern works for every placeholder panel: decide on a Perses plugin, set `plugin`, write `queries` from the Grafana panel's targets, and keep `display`. For a placeholder variable, either write the Perses variable by hand or remove it, together with its use in the queries, when Perses has no equivalent.

## Restore what the migration dropped

The Grafana dashboard opened on the last 24 hours, and the migration set one hour. Look for other things it dropped, such as a unit the shared mapping does not know:

```sh
jq '{time, units: [.panels[] | {title, unit: .fieldConfig.defaults.unit?}]}' prometheus-storage.json
jq '{duration: .spec.duration, units: [.spec.panels[] | {title: .spec.display.name, format: .spec.plugin.spec.format?}]}' storage-finished.json
```

The Grafana panel `Block storage` uses the unit `kbytes`, and the Perses panel has no `format` at all: `kbytes` is not in the shared mapping from Grafana units to Perses units, so the migration dropped it. Set the time range back, then apply the dashboard:

```sh
jq '.spec.duration = "24h"' storage-finished.json > storage-ready.json
percli lint -f storage-ready.json --online
percli apply -f storage-ready.json
percli get dashboards --project legacy
```

The linter is silent, `percli apply` reports that the dashboard `prometheus-storage` has been applied, and the list shows it in the project `legacy`. Open it in Perses: all five panels draw data.

You can now finish a migration: datasource names fixed, placeholders replaced with the closest Perses plugin, time settings restored, and the result applied to a project. Checking that the data really matches the Grafana dashboard is the next step after this one.

## Common pitfalls

> [!WARNING]
> - **Deleting a placeholder panel.** It hides the problem and removes the panel's title and its place in the layout. Replace the plugin and keep the panel.
> - **Editing a query the placeholder does not have.** A placeholder panel has no queries, so `.spec.queries[0].spec.plugin.spec.query = ...` creates a query without `kind`, and the server refuses it. Set the whole `queries` list.
> - **Creating a datasource named after the Grafana uid.** It works today and ties every dashboard to an old name. Rename the references or use the default datasource.
> - **Forgetting `--project`.** Without it, `metadata.project` is empty, and `percli apply` needs the project from `percli project` or `--project`.
> - **Taking `kbytes` and other units for granted.** A unit outside the shared mapping disappears, and the panel shows raw numbers.

## Your mission: Migrate Two Grafana Dashboards

You can now migrate a Grafana dashboard, find every placeholder and finish the result. The graded lab asks you to migrate `Prometheus Overview` and `Prometheus Storage` into the project `legacy`, replace every placeholder instead of deleting it, and make every query use the datasource `prometheus`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-109-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-109-lab-020-01
astrona start ats-109-playground-020-01
```

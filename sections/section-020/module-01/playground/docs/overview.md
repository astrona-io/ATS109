# Overview: Migrate Grafana Dashboards With percli (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Perses, Prometheus and Grafana, and then waits. There is no task, no `astrona submit` and no pass or fail. Migrate, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, reached at `http://perses.localtest.me:8080`. `percli` v0.54.0 is installed on your machine.
- In Perses, the empty project **`legacy`** with the default datasource `prometheus`.
- **Grafana 12.4.13** in the namespace `observability` with two dashboards in the folder `Legacy`. Its Prometheus datasource has the uid `prom-main`. Anyone is let in as an administrator: lab only.
  - **`Prometheus Overview`** (uid `prometheus-overview`): `stat`, `gauge`, `timeseries`, `bargauge`, `table`, `heatmap` and `state-timeline` panels, a collapsed row `Internals`, and the variables `job`, `handler`, `interval` and `filter` (an `adhoc` filter).
  - **`Prometheus Storage`** (uid `prometheus-storage`): `text`, `timeseries`, `stat` (unit `kbytes`), `piechart` and `xychart` panels, and the variables `job` (a `query_result` query), `retention` (a `textbox`) and `source` (a `datasource`).
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

Paste these once in each new terminal. `grafana_dashboard` saves a Grafana dashboard by its uid to `<uid>.json`. `migrate_dashboard` migrates that file into the project `legacy` with the default datasource and saves `<uid>-migrated.json`. `find_placeholders` lists every placeholder panel, query and variable in a migrated file.

```sh
grafana_dashboard() {
  kubectl -n observability exec deploy/tester -- \
    curl -s "http://grafana.observability:3000/api/dashboards/uid/$1" | jq '.dashboard' > "$1.json"
}
migrate_dashboard() {
  percli migrate -f "$1.json" --online --use-default-datasource --project legacy -o json > "$1-migrated.json"
}
find_placeholders() {
  jq '{panels: [.spec.panels | to_entries[] | select(.value.spec.plugin.kind == "Markdown" and (.value.spec.plugin.spec.text | test("not supported"))) | .key],
       queries: [.. | strings | select(. == "migration_from_grafana_not_supported")] | length,
       variables: [.spec.variables[] | select(.spec.plugin.spec.values? == ["grafana","migration","not","supported"]) | .spec.name]}' "$1"
}
```

Use them like this: `grafana_dashboard prometheus-overview`, `migrate_dashboard prometheus-overview`, `find_placeholders prometheus-overview-migrated.json`.

## Practice tasks

- Migrate `prometheus-overview` without `--use-default-datasource` and list the datasource names of all queries. Then migrate it with the flag and compare.
- In Grafana, open the row `Internals` of `Prometheus Overview`, save the dashboard JSON from the Grafana interface, and migrate that file. Find where the `Goroutines` panel went and whether the group `Internals` still exists.
- Migrate `prometheus-storage` and compare the variable `job` with its Grafana `query_result` expression. Find the expression and the label name in the `PrometheusPromQLVariable`.
- Migrate with `--format cr` and look at the `apiVersion`, `kind` and `metadata` of the result.
- Edit a copy of the Grafana file so the `heatmap` panel becomes `status-history`, migrate it, and see which plugin it gets now.

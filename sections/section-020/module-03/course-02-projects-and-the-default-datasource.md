# Projects And The Default Datasource

A migrated dashboard has to end up in a Perses project, and its queries have to reach a datasource. Two flags set both: `--project` for the project and `--use-default-datasource` for the datasource. This part runs the same migration three times with different flags and compares what each produces, so you can choose on purpose.

## Three migrations of the same file

Start from the Grafana dashboard `Prometheus Storage`. Its queries name the Grafana datasource uid `prom-main`. Run three migrations and print the project and the datasource names of each:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-storage | jq '.dashboard' > prometheus-storage.json
percli migrate -f prometheus-storage.json --online -o json > plain.json
percli migrate -f prometheus-storage.json --online --project legacy --input prom-main=prometheus -o json > named.json
percli migrate -f prometheus-storage.json --online --project legacy --use-default-datasource -o json > default.json
for f in plain named default; do
  echo "$f: project=$(jq -r '.metadata.project // "none"' $f.json) datasources=$(jq -c '[.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource.name // "none"] | unique' $f.json)"
done
```

The first file has no project and the datasource name `prom-main`, copied from Grafana. The second has the project `legacy` and the name `prometheus`. The third has the project `legacy` and no datasource name at all, so each query follows the default datasource of the project.

## What --project does

The flag `--project` writes the project into the metadata of the result. Without it, the metadata has no project, and `percli apply` falls back on the project you selected with `percli project`. Setting it in the file is safer, because a file with its project can be applied by someone who has another project selected, and it is the field that a dashboard in a custom resource needs.

## Name or default

The datasource can be handled in two ways. With a name, the query says exactly which datasource it uses, even if the project later gets a second one. With the default, the query follows whatever the project marks as default, and you can change the default without touching the dashboards. For a team that moves all its dashboards into one project, the default is the simpler choice. For a project that holds more than one datasource, use names.

The rule that decides it is in the lookup order: a query that names a datasource looks it up in the dashboard, the project and the global scope, and a query that names none takes the default of the first scope that has one. A name that exists nowhere fails silently, which is the case with `prom-main` in the first file.

## Apply and read back

Apply the third file and check that its panels show the project datasource, using the proxy from the `tester` pod to run one of its queries:

```sh
percli apply -f default.json
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  http://perses.localtest.me:8080/proxy/projects/legacy/datasources/prometheus/api/v1/query \
  --data-urlencode 'query=prometheus_tsdb_head_series' | jq '.data.result | length'
```

The answer is a number greater than zero: one series for each scrape job that exposes the metric. This proves that the project datasource reaches Prometheus, which is the same datasource that the default queries use.

You can now set the project and the datasource at migration time and explain the trade-off. Still open is the format of the result.

## Common pitfalls

> [!WARNING]
> - **Leaving out `--project` and applying with the wrong project selected.** The dashboard lands in the wrong place.
> - **Using `--input` and `--use-default-datasource` together without knowing which wins.** Pick one way for each migration.
> - **Assuming that the default stays the same.** A second default in the project makes the lookup ambiguous.
> - **Testing only that the dashboard applies.** Run one query through the proxy to prove the datasource works.

# Grafana Inputs And The Input Flag

A dashboard that someone exported to share with other teams does not name their datasource. It carries a placeholder such as `${DS_PROMETHEUS}` and asks the importer to fill it in. If you migrate such a file as it is, the placeholder ends up in every query as the name of a datasource that does not exist. This part builds such a file, shows what goes wrong, and fixes it with the `--input` flag.

## What an input is

A **Grafana input** is a named value that an exported dashboard asks for when it is imported. The export lists the inputs in a top-level `__inputs` field. Each entry has a `name` such as `DS_PROMETHEUS`, a `type` of `datasource` and the plugin it expects. Everywhere the dashboard needs that value, it writes `${DS_PROMETHEUS}` instead, for example in the datasource uid of a panel.

Make such a file from the playground dashboard. The `sed` command replaces the datasource uid `prom-main` with the input reference, and `jq` adds the `__inputs` list:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-storage | jq '.dashboard' \
  | sed 's/prom-main/${DS_PROMETHEUS}/g' \
  | jq '. + {__inputs: [{name: "DS_PROMETHEUS", label: "Prometheus", type: "datasource", pluginId: "prometheus"}]}' > storage-export.json
jq '.panels[1].targets[0].datasource' storage-export.json
```

The last command prints the datasource of the panel `Head series`: a uid with the text `${DS_PROMETHEUS}`. This is what a shared export looks like.

## What goes wrong without the flag

Migrate the file as it is and read the datasource name of the first query:

```sh
percli migrate -f storage-export.json --online --project legacy -o json > storage-no-input.json
jq -r '[.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource.name] | unique | .[]' storage-no-input.json
```

The command prints the text `${DS_PROMETHEUS}` as the name of the datasource. No datasource has that name in Perses, so each panel shows no data even though the dashboard is valid. The migration copied the text exactly as it was.

## Fix it with --input

The flag `--input NAME=VALUE` replaces the input `NAME` with `VALUE` before the migration runs. You can repeat it for each input. Give it the name of the Perses datasource:

```sh
percli migrate -f storage-export.json --online --project legacy --input DS_PROMETHEUS=prometheus -o json > storage-with-input.json
jq -r '[.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource.name] | unique | .[]' storage-with-input.json
```

The command prints `prometheus`, which is the name of the project datasource. The queries now name a datasource that exists. The same fix is available in the migrate API, which takes the inputs in the request body, and `--use-default-datasource` is another way to avoid the name; the next part compares them.

## When to use which

Use `--input` when the datasource has a name in Perses that you want in the queries. It leaves a trace in the dashboard: the name is written out, so a later change of the default does not affect the dashboard. An export can have more than one input. If you forget one, the same fault comes back for the queries that use it, so list the inputs first with `jq '.__inputs[].name' storage-export.json`.

You can now spot an export with inputs and replace each input with a name from Perses. Still open is the third option, which uses no name at all.

## Common pitfalls

> [!WARNING]
> - **Migrating an export without `--input`.** The dashboard is valid, and every panel is empty.
> - **Replacing only one of several inputs.** List the names with `jq '.__inputs[].name'`.
> - **Giving `--input` the Grafana uid.** The value must be a name that exists in Perses.
> - **Checking only that the command succeeded.** Read the datasource names of the result.

# Solution: Migrate A Shared Dashboard Export

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Read the export

```sh
kubectl -n perses get configmap shared-export -o jsonpath='{.data.http-overview-export\.json}' > http-overview-export.json
jq '{uid, title, time, inputs: [.__inputs[].name], panels: [.panels[] | {type, title, collapsed, inner: [.panels[]?.type]}]}' http-overview-export.json
```

The file has the uid `http-overview`, a time range of six hours, and one input, `DS_PROMETHEUS`. Its panels are a `text` panel, an old `graph` panel, and a collapsed row `Details` holding a `stat` and a `timeseries` panel. Every target and the variable `job` name the datasource uid `${DS_PROMETHEUS}`.

## Step 2: Migrate with the input filled in

`--input NAME=VALUE` replaces `${NAME}` everywhere in the Grafana file before the translation, so the datasource uid becomes the name of the Perses datasource:

```sh
percli login http://perses.localtest.me:8080
percli migrate -f http-overview-export.json --online --input DS_PROMETHEUS=prometheus --project shared -o json > http-overview.json
jq '{name: .metadata.name, project: .metadata.project, datasources: ([.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource.name] | unique)}' http-overview.json
```

The name is `http-overview`, the project is `shared`, and every query names the datasource `prometheus`. Without `--input`, every query would name `${DS_PROMETHEUS}` and every panel would stay empty.

## Step 3: Check the panels, the row and the placeholders

```sh
jq '{panels: (.spec.panels | to_entries | map({key, kind: .value.spec.plugin.kind, title: .value.spec.display.name})),
     layouts: [.spec.layouts[] | {title: .spec.display.title, open: .spec.display.collapse.open, items: [.spec.items[].content["$ref"]]}],
     placeholders: [.. | strings | select(test("not supported|migration_from_grafana_not_supported"))] | length}' http-overview.json
```

The `graph` panel became a `TimeSeriesChart` and the `text` panel a `Markdown` panel with its own text, so there is no placeholder. The two top-level panels sit in `Panel Group 1`, and the collapsed row became a closed `Grid` titled `Details` with the panels `2_0` and `2_1`. The row was collapsed in Grafana, so its panels were stored inside it and the migration kept the group; an open row would have been lost.

## Step 4: Restore the time range and apply

```sh
jq '.spec.duration = "6h"' http-overview.json > http-overview-ready.json
percli lint -f http-overview-ready.json --online
percli apply -f http-overview-ready.json
```

## Step 5: Produce the custom resource

`--format cr` writes the migrated dashboard as a `PersesDashboard` custom resource, with the project as its namespace. Create it, set the same time range, and store it in the ConfigMap:

```sh
percli migrate -f http-overview-export.json --online --input DS_PROMETHEUS=prometheus --project shared --format cr -o json \
  | jq '.spec.duration = "6h"' > http-overview-cr.json
jq '{apiVersion, kind, metadata}' http-overview-cr.json
kubectl -n perses create configmap http-overview-cr --from-file=dashboard.yaml=http-overview-cr.json
```

The resource has `apiVersion: perses.dev/v1alpha1`, `kind: PersesDashboard`, and the name `http-overview` in the namespace `shared`. JSON is valid YAML, so the key `dashboard.yaml` can hold it as it is.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Replace `${DS_PROMETHEUS}` in the file with `sed` | It works, but the task asks you to let the migration do it, and `--input` is the tool built for it |
| Create a datasource called `DS_PROMETHEUS` | The queries name `${DS_PROMETHEUS}`, not `DS_PROMETHEUS`, so the panels stay empty anyway |
| Expand the row in Grafana's file before migrating | The row's panels move to the top level and land in `Panel Group 1`; the group `Details` is lost |
| Apply the custom resource with `kubectl` | There is no Perses Operator in this cluster; the task is to store the resource in a ConfigMap |

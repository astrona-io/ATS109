# Solution: Repair A Hand-Written Dashboard

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The file has four independent faults, and each one shows up at a different stage: the server refuses the first, the web interface hides the second, and the last two only show as empty panels. Start the Perses port-forward in a second terminal before you begin, and sign `percli` in:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project capstone
```

## Step 1: Let the server tell you what it refuses

Save the file, then let the server check it without storing it:

```sh
kubectl -n perses get configmap broken-dashboard -o jsonpath='{.data.process-health\.json}' > process-health.json
percli lint -f process-health.json --online
```

The linter reports an error on the panel `mem`: its `StatChart` `calculation` is `average`, a value the plugin schema does not allow. The Grafana panel `Resident memory` uses the reducer `mean`, and the Perses word for it is also `mean`. Fix it:

```sh
jq '.spec.panels.mem.spec.plugin.spec.calculation = "mean"' process-health.json > fixed.json && mv fixed.json process-health.json
percli lint -f process-health.json --online
```

The linter is now silent. A file that passes the schema can still be wrong in ways no schema checks, so look further before you apply it.

## Step 2: Check that every layout item finds its panel

List the panel keys and the references of the layout side by side:

```sh
jq '{panels: (.spec.panels | keys), refs: [.spec.layouts[].spec.items[].content["$ref"]]}' process-health.json
```

The panels are `cpu`, `fds` and `mem`, but the first reference is `#/spec/panels/memory`. That item draws nothing, and the panel `mem` is placed nowhere. Point the reference at the real key:

```sh
jq '.spec.layouts[0].spec.items[0].content["$ref"] = "#/spec/panels/mem"' process-health.json > fixed.json && mv fixed.json process-health.json
```

## Step 3: Check which datasource each query uses

List the datasource each query asks for:

```sh
jq '.spec.panels | to_entries | map({key, datasource: .value.spec.queries[0].spec.plugin.spec.datasource})' process-health.json
```

`mem` and `fds` use `prometheus`, but `cpu` asks for `prom-main`: the uid of the Grafana datasource, copied from the old dashboard. No Perses datasource has that name, so the panel would stay empty. Point it at `prometheus`:

```sh
jq '.spec.panels.cpu.spec.queries[0].spec.plugin.spec.datasource.name = "prometheus"' process-health.json > fixed.json && mv fixed.json process-health.json
```

## Step 4: Apply, then run every query

Apply the dashboard, then run each panel's query once through the Perses datasource proxy:

```sh
percli apply -f process-health.json
for key in mem cpu fds; do
  expr=$(jq -r --arg k "$key" '.spec.panels[$k].spec.queries[0].spec.plugin.spec.query' process-health.json)
  echo "$key: $expr"
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/capstone/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$expr" | jq '.data.result | length'
done
```

`mem` and `cpu` return one series each, and `fds` returns `0`: its query is `process_open_fd`, and Prometheus has no metric with that name. The Grafana panel `Open file descriptors` uses `process_open_fds`. Fix the name and apply again:

```sh
jq '.spec.panels.fds.spec.queries[0].spec.plugin.spec.query = "process_open_fds"' process-health.json > fixed.json && mv fixed.json process-health.json
percli apply -f process-health.json
```

Run the loop again: every query now returns one series. Open `Process Health` in Perses to see all three panels draw.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the panel `mem` because it is refused | The dashboard loses a panel; the grader counts three |
| Create a datasource named `prom-main` | The query works, but the project now has two names for one Prometheus, and the task forbids it |
| Remove the layout item with the wrong `$ref` | The panel `mem` is stored but never drawn |
| Trust a clean lint | The lint only checks the schema; it cannot know that `memory` is not a panel or that `process_open_fd` has no data |

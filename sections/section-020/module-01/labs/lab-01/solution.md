# Solution: Migrate Two Grafana Dashboards

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: both dashboards exist and validate, no placeholder is left, every query uses `prometheus`, and no panel was deleted. Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Fetch and migrate both dashboards

Migrate both with the default datasource and the project set, so the datasource names and the project are right from the start:

```sh
percli login http://perses.localtest.me:8080
for uid in prometheus-overview prometheus-storage; do
  kubectl -n observability exec deploy/tester -- \
    curl -s "http://grafana.observability:3000/api/dashboards/uid/$uid" | jq '.dashboard' > "$uid.json"
  percli migrate -f "$uid.json" --online --use-default-datasource --project legacy -o json > "$uid-migrated.json"
done
```

## Step 2: Find every placeholder

```sh
for f in prometheus-overview-migrated.json prometheus-storage-migrated.json; do
  echo "== $f"
  jq '{panels: [.spec.panels | to_entries[] | select(.value.spec.plugin.kind == "Markdown" and (.value.spec.plugin.spec.text | test("not supported"))) | {key, title: .value.spec.display.name}],
       queries: [.. | strings | select(. == "migration_from_grafana_not_supported")] | length,
       variables: [.spec.variables[] | select(.spec.plugin.spec.values? == ["grafana","migration","not","supported"]) | .spec.name]}' "$f"
done
```

`prometheus-overview` has two placeholder panels, `5` (`Request duration`, a Grafana `heatmap`) and `6` (`Target state`, a Grafana `state-timeline`), and one placeholder variable, `filter` (a Grafana `adhoc` filter). `prometheus-storage` has one placeholder panel, `4` (`Series against chunks`, a Grafana `xychart`). No query is a placeholder.

## Step 3: Replace the placeholders

Choose a Perses plugin for each placeholder panel:

- `Request duration` showed the distribution of request durations. A `TimeSeriesChart` of the 90th percentile shows the same histogram as one line, so replace its query with a `histogram_quantile` over the same buckets.
- `Target state` showed whether each target was up over time. `StatusHistoryChart` draws exactly that from the same query.
- `Series against chunks` plotted two metrics against each other. A `TimeSeriesChart` with both queries shows both over time.

The `filter` variable has no Perses equivalent, and no query uses it, so remove it. Apply the changes with `jq`:

```sh
jq '.spec.panels["5"].spec.plugin = {"kind": "TimeSeriesChart", "spec": {"yAxis": {"format": {"unit": "seconds"}}}}
    | .spec.panels["5"].spec.queries[0].spec.plugin.spec.query = "histogram_quantile(0.9, sum by (le) (rate(prometheus_http_request_duration_seconds_bucket{job=\"$job\"}[$interval])))"
    | .spec.panels["5"].spec.queries[0].spec.plugin.spec.seriesNameFormat = "p90"
    | .spec.panels["6"].spec.plugin = {"kind": "StatusHistoryChart", "spec": {}}
    | .spec.variables |= map(select(.spec.name != "filter"))
    | .spec.duration = "3h" | .spec.refreshInterval = "1m"' prometheus-overview-migrated.json > prometheus-overview-ready.json
jq '.spec.panels["4"].spec.plugin = {"kind": "TimeSeriesChart", "spec": {"legend": {"position": "bottom"}}}
    | .spec.duration = "24h"' prometheus-storage-migrated.json > prometheus-storage-ready.json
```

The last line of each command also restores the Grafana time range and refresh, which the migration always resets to one hour. The grader does not check them, but the dashboards should open the way people know them.

## Step 4: Check and apply

```sh
for f in prometheus-overview-ready.json prometheus-storage-ready.json; do
  percli lint -f "$f" --online && percli apply -f "$f"
done
percli get dashboards --project legacy
```

Both files pass the linter and are applied, and the list shows `prometheus-overview` and `prometheus-storage` in the project `legacy`. Open both in Perses: every panel draws data.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the placeholder panels | The panel count no longer matches Grafana, and their queries are lost |
| Create a datasource `prom-main` | Every query works, but the project has two names for one Prometheus; the task forbids it |
| Leave the `filter` variable | It offers the values `grafana migration not supported` above the dashboard |
| Migrate without `--online` and without `--plugin.path` | `percli` refuses: offline migration needs the plugins on your machine |

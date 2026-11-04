# What To Check Before A Release

A team that moves its dashboards from Grafana to Perses has one question before it switches off Grafana: does the new dashboard tell the same story? The answer comes from a short list of checks, run in a fixed order, where each check is cheap and each one catches a different kind of fault. This part names the checks and runs the first one by hand.

## Four checks, in order

The order goes from the cheapest check to the most expensive one, and a later check makes no sense if an earlier one fails.

1. **Validity.** The server accepts the dashboard. `POST /api/validate/dashboards` answers `200` when every panel, query and variable matches its plugin schema.
2. **No placeholders.** The dashboard has no Markdown panel with the text `Migration from Grafana not supported !`, no query with the text `migration_from_grafana_not_supported`, and no variable with the values `grafana`, `migration`, `not`, `supported`.
3. **Datasources resolve.** Every query either names a datasource that exists in the dashboard, the project or the global scope, or names none and uses the project default.
4. **Parity.** For every panel, the Perses query returns the same series and values as the Grafana query at the same time.

The first three are structural: they read the dashboard and need no data. The fourth runs queries and costs the most, so it comes last.

## Run the first check

Ask the server to validate the dashboard in the playground. The `tester` pod posts the JSON that `percli` reads from the API:

<!-- astrona:playground:renew -->

```sh
percli describe dashboard service-health --project release -ojson > service-health.perses.json
kubectl -n observability exec -i deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' --data-binary @- \
  http://perses.localtest.me:8080/api/validate/dashboards < service-health.perses.json
```

The answer is `200`. The dashboard is valid, which says only that its shape is correct. A valid dashboard can still hold a placeholder, a query on a missing datasource, or a query for the wrong metric. The next three checks look for those.

## Why the checks are separate

One script that only compares data would report a mismatch for a placeholder panel, but the reason would be hidden: the placeholder has no query, so there is nothing to compare. A separate check says what is wrong. A placeholder is a missing panel to write. A datasource fault is a name to change. A parity fault is a query to correct. Each has a different fix, so each gets its own line in the report.

## Define the list of panels

All checks work on a list of panels with a name, a Grafana expression and a Perses expression. Build the Perses side from the dashboard:

```sh
jq -r '.spec.panels | to_entries[] | "\(.value.spec.display.name)\t\(.value.spec.queries[0].spec.plugin.spec.query // "no query")"' service-health.perses.json
```

The output has one line for each panel: a name, a tab, and the expression. Panels with the text `no query` have no first query, which is the sign of a placeholder, and the next part uses this to detect them.

You can now name the four checks and say why they run in that order. Still open is how to write the structural checks so that a computer runs them.

## Common pitfalls

> [!WARNING]
> - **Stopping after the validity check.** A valid dashboard can still show the wrong data.
> - **Running the parity check first.** A placeholder panel has no query to compare.
> - **Reporting failures without panel names.** The person who fixes it needs the name.
> - **Mixing structural and data checks in one line.** The fix differs for each.

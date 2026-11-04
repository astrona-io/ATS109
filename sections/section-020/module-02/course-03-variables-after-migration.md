# Variables After Migration

A dashboard without its variables shows one fixed view. A migration copies most Grafana variables, but each type goes through a different rule, and some types become placeholders. This part lists the variables of both playground dashboards, shows what each became, and explains which settings survive.

## Read the variables of a migration

Migrate the dashboard `Prometheus Storage`, which has three variables of three different types, and list what each became:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-storage | jq '.dashboard' > prometheus-storage.json
percli migrate -f prometheus-storage.json --online --project legacy --use-default-datasource -o json > storage.json
jq '.spec.variables | map({kind, name: .spec.name, plugin: (.spec.plugin.kind // "none")})' storage.json
```

The list has three entries. The Grafana variable `job` came from `query_result(count by (job) (up))` and became a `ListVariable` with the plugin `PrometheusPromQLVariable`. The variable `retention` is a text box and became a `TextVariable`. The variable `source` has the type `datasource` and became a `ListVariable` with the plugin `DatasourceVariable`.

## The rules by type

The table lists the rule for each Grafana variable type.

| Grafana type | Perses result |
| --- | --- |
| `query` with `label_values(...)` | `PrometheusLabelValuesVariable` |
| `query` with `label_names()` | `PrometheusLabelNamesVariable` |
| `query` with `query_result(... by (label) ...)` | `PrometheusPromQLVariable` |
| `custom` and `interval` | `StaticListVariable` |
| `datasource` | `DatasourceVariable` |
| `textbox` and `constant` | `TextVariable`, with `constant: true` for a constant |
| any other type, such as `adhoc` | `StaticListVariable` with the values `grafana`, `migration`, `not`, `supported` |

A `query_result` query that has no `by (label)` form gets the label name `migration_from_grafana_not_supported`. That is a placeholder too, and it is easy to miss because the kind is correct.

## Settings that are carried over

The migration carries over `includeAll` as `allowAllValue`, `multi` as `allowMultiple`, `allValue` as `customAllValue`, `sort`, `hide`, `label`, `description` and the current value. Check them against the Grafana file:

```sh
jq '[.templating.list[] | {name, includeAll, multi, allValue}]' prometheus-storage.json
jq '[.spec.variables[] | {name: .spec.name, all: .spec.allowAllValue, multi: .spec.allowMultiple, customAll: .spec.customAllValue}]' storage.json
```

The two lists agree for the variables that have these fields. A Grafana variable with `includeAll` set and no `allValue` gets an All choice without a custom value, and then the query receives the full list. Decide for each such variable whether the query needs `.*`.

## Variables that the panels use

A migrated query keeps the Grafana text, so it uses `$job`, `$handler` or `$interval` unchanged. Perses replaces those names with the value of the variable that has the same name. A query that uses a variable nobody defined keeps the text `$name` and returns an error. The next part finds those names with a script.

You can now say what each variable type became and which settings are kept. Still open is how to find the variables that are wrong or missing.

## Common pitfalls

> [!WARNING]
> - **Trusting the kind of a variable.** `PrometheusPromQLVariable` can still hold a placeholder label name.
> - **Forgetting `adhoc`.** Perses v0.54.0 has no equivalent, and the migration writes a placeholder list.
> - **Copying `allValue` without checking the query.** An equality match never works with `.*`.
> - **Assuming `current` is a list.** A single choice becomes a single default value.

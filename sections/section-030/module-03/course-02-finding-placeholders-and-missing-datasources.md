# Finding Placeholders And Missing Datasources

The structural checks read only the dashboard JSON, so they run in a fraction of a second and need no data. They find the three things a migration leaves for a person: a placeholder, a query without a datasource that exists, and a variable that nothing defines. This part writes each check as a `jq` filter that prints panel names, because a report must name what to fix.

## Placeholder panels and queries

A placeholder panel is a `Markdown` panel whose text is `**Migration from Grafana not supported !**`. A placeholder query has the text `migration_from_grafana_not_supported`. Print the names of panels that have either:

<!-- astrona:playground:renew -->

```sh
percli describe dashboard service-health --project release -ojson > service-health.perses.json
jq -r '.spec.panels | to_entries[]
  | select(
      (.value.spec.plugin.kind == "Markdown" and ((.value.spec.plugin.spec.text // "") | contains("not supported")))
      or ((.value.spec.queries // []) | map(.spec.plugin.spec.query // "") | any(contains("migration_from_grafana_not_supported")))
    )
  | .value.spec.display.name' service-health.perses.json
```

The command prints nothing for a finished dashboard. If it prints a name, that panel is a placeholder or runs a placeholder query. Notice that a real Markdown panel with a note for the reader is not matched, because the filter looks for the migration text.

## Placeholder variables

A placeholder variable is a `StaticListVariable` with the values `grafana`, `migration`, `not` and `supported`. Check the variables the same way:

```sh
jq -r '.spec.variables[]? | select(.spec.plugin.kind == "StaticListVariable")
  | select([.spec.plugin.spec.values[]? | if type == "object" then .value else . end] | sort == ["grafana","migration","not","supported"])
  | .spec.name' service-health.perses.json
```

The filter sorts the values and compares the list. A variable with a real list of values does not match. For the dashboard in the playground, the answer is empty.

## Datasources that do not exist

A query names a datasource in `spec.plugin.spec.datasource.name`. The name must exist in the dashboard, the project or the global scope. List the datasources of the project and then the names the queries use:

```sh
kubectl -n observability exec deploy/tester -- curl -s http://perses.localtest.me:8080/api/v1/projects/release/datasources | jq -r '.[].metadata.name'
jq -r '[.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource.name // empty] | unique | .[]' service-health.perses.json
```

The first command prints `prometheus`. The second prints nothing when all queries use the project default, or a list of names. Every name in the second list must be in the first, or in the dashboard-level `datasources` field, or in the global datasources. A name that is in none of them is a fault, and Grafana uid values such as `prom-main` are the usual case.

Write the comparison as one command so a script can use it:

```sh
comm -13 \
  <(kubectl -n observability exec deploy/tester -- curl -s http://perses.localtest.me:8080/api/v1/projects/release/datasources | jq -r '.[].metadata.name' | sort) \
  <(jq -r '[.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource.name // empty] | unique | .[]' service-health.perses.json | sort)
```

`comm -13` prints the lines that only the second list has. An empty answer means that every named datasource is in the project. It does not look at global datasources or at the dashboard-level ones, so a name printed here needs one more look before you call it a fault.

## Variables used but not defined

A query that uses `$job` needs a variable `job`. List the variable names used in the queries and the names defined:

```sh
jq -r '[.spec.panels[].spec.queries[]?.spec.plugin.spec.query // empty | scan("\\$([a-zA-Z_][a-zA-Z0-9_]*)") | .[0]] | unique | .[]' service-health.perses.json
jq -r '.spec.variables[]?.spec.name' service-health.perses.json
```

Names that start with two underscores, such as `__rate_interval`, are built in and need no definition. Any other name in the first list that is not in the second is a query that will fail.

You can now find each kind of structural fault and print the panel that has it. Still open is how to join these with the data check into a single run.

## Common pitfalls

> [!WARNING]
> - **Matching every Markdown panel as a placeholder.** Match the migration text.
> - **Treating the values `grafana migration not supported` as a regular list.** It is a placeholder variable.
> - **Checking datasource names against the project only.** Dashboard and global datasources also count.
> - **Counting built-in variables as undefined.** Names with two underscores are built in.

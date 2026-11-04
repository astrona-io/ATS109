# Cleaning Up Variables

A placeholder variable shows the reader a list with the words `grafana`, `migration`, `not` and `supported`. A query that uses an undefined variable returns an error. Both survive a migration, and neither makes the dashboard invalid. This part finds them with a script and removes them without breaking a query.

## Find the placeholder variables

A placeholder variable has a recognisable list. Search the migrated `Prometheus Overview` for static lists that hold the word `migration`, and print the variables that the migration could not translate:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-overview | jq '.dashboard' > prometheus-overview.json
percli migrate -f prometheus-overview.json --online --project legacy --use-default-datasource -o json > overview.json
jq -r '.spec.variables[] | select((.spec.plugin.spec.values // []) | tostring | test("migration")) | .spec.name' overview.json
```

The answer is `filter`, the Grafana `adhoc` variable. Perses v0.54.0 has no equivalent of an ad hoc filter, which adds label filters to every query, so there is nothing to translate it to.

## Find the variables that queries use

List every `$name` and `${name}` in the queries, and compare the list with the defined variables. The first command extracts the names that the queries use, the second lists the defined ones:

```sh
jq -r '[.spec.panels[].spec.queries[]?.spec.plugin.spec.query // empty] | join("\n")' overview.json \
  | grep -oE '\$\{?[a-zA-Z_]+' | tr -d '${' | sort -u
jq -r '.spec.variables[].spec.name' overview.json | sort -u
```

The queries use `handler`, `interval` and `job`, and `__rate_interval` is a built-in variable that Perses fills itself. The defined variables are `filter`, `handler`, `interval` and `job`. Every name that a query uses is defined, and `filter` is defined but no query uses it, which is what a placeholder looks like.

## Remove the placeholder safely

A variable that no query uses can go without any other change. Remove it by name, not by position:

```sh
jq '.spec.variables |= map(select(.spec.name != "filter"))' overview.json > overview-clean.json
jq -r '.spec.variables[].spec.name' overview-clean.json
```

The list now holds `handler`, `interval` and `job`. If a query did use the variable, removing it would leave the text `$filter` in that query. Check the list of used names again after every removal, and replace the text in the queries that used it.

## What to do with a variable that has no equivalent

Removing an ad hoc filter changes what the readers can do: they can no longer add filters to every panel. Tell the team before you do it, and offer a replacement where one exists. A `ListVariable` over `PrometheusLabelValuesVariable` gives a fixed filter on one label, and a `TextVariable` with a regular expression gives a free one, if the queries use it in a matcher.

You can now find placeholder variables and undefined variable names, and remove a placeholder without breaking a query. The lab that follows asks you to reorganise a migrated dashboard and clean its variables.

## Common pitfalls

> [!WARNING]
> - **Removing a variable that a query still uses.** The query keeps the raw text and fails.
> - **Counting `__rate_interval` as undefined.** Perses fills the built-in variables itself.
> - **Removing by position.** Select by name, so the edit keeps working after a new migration.
> - **Leaving the placeholder because the dashboard is valid.** Readers see a list with nonsense words.

## Your mission: Group Migrated Panels Into Rows

You can now read the keys and groups of a migrated dashboard, split a flat group and clean its variables. The graded lab starts with the migrated dashboard `overview-flat` in the project `legacy`. It asks you to write a dashboard `overview-grouped` with the groups `Summary`, `Details` and `Internals`, and without the placeholder variable.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-109-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-109-lab-020-02
astrona start ats-109-playground-020-02
```

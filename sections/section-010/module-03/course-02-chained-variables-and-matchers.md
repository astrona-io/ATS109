# Chained Variables And Matchers

A list of handlers is only useful when it shows handlers that exist for the job the reader picked. A second list that depends on the first one solves this. This part chains two variables with a matcher, adds an All choice that a query can use, and adds a fixed list for the time window.

## A matcher uses another variable

A **matcher** is a selector that limits which series the label values plugin looks at. In the `PrometheusLabelValuesVariable` it is an entry of the `matchers` list, written as a PromQL selector. The selector may contain another variable. Perses then fills the second list only after the first variable has a value, and it refills the list every time the first variable changes.

<!-- astrona:playground:renew -->

Save this as `dashboard-variables-chained.yaml`:

```yaml
kind: Dashboard
metadata:
  name: variables-chained
  project: specs
spec:
  display:
    name: Variables Chained
  duration: 1h
  variables:
    - kind: ListVariable
      spec:
        name: job
        display:
          name: Job
        allowMultiple: false
        allowAllValue: false
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: job
            matchers:
              - up
    - kind: ListVariable
      spec:
        name: handler
        display:
          name: Handler
        allowMultiple: false
        allowAllValue: true
        customAllValue: ".*"
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: handler
            matchers:
              - prometheus_http_requests_total{job="$job"}
    - kind: ListVariable
      spec:
        name: window
        display:
          name: Window
        defaultValue: 5m
        allowAllValue: false
        allowMultiple: false
        plugin:
          kind: StaticListVariable
          spec:
            values:
              - 1m
              - 5m
              - 15m
  panels:
    requestRate:
      kind: Panel
      spec:
        display:
          name: Request rate
        plugin:
          kind: TimeSeriesChart
          spec:
            yAxis:
              format:
                unit: requests/sec
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (handler) (rate(prometheus_http_requests_total{job="$job",handler=~"$handler"}[$window]))
                  seriesNameFormat: "{{handler}}"
  layouts:
    - kind: Grid
      spec:
        display:
          title: Requests
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/requestRate"
```

Apply it:

```sh
percli apply -f dashboard-variables-chained.yaml
```

Then check the result:

```sh
percli describe dashboard variables-chained -ojson | jq '.spec.variables | map({name: .spec.name, plugin: .spec.plugin.kind, matchers: .spec.plugin.spec.matchers, all: .spec.customAllValue})'
```

The answer shows that `handler` has a matcher with `$job` in it, and that its All value is `.*`. Open the dashboard and change the `Job` choice: the `Handler` list is filled again from the new job.

## Why the All value needs a custom text

The query uses `handler=~"$handler"`, which is a regular expression match. When the reader picks All, Perses must send one value that matches every handler. Without `customAllValue`, Perses builds the value from the full list of choices, which makes a long expression that can break the query or hit a size limit. The custom value `.*` is short and always matches. If the query used `handler="$handler"` with an equality match, All could never work, because no single handler name equals `.*`.

Grafana does the same with the setting `allValue`, and the migration copies it into `customAllValue`.

## The fixed list for the window

The variable `window` uses `StaticListVariable`, whose `values` field is a fixed list of choices. A Grafana variable of the type `custom` or `interval` becomes this plugin when you migrate it. A plain string is enough as a value. The `defaultValue` must be one of the listed values.

You can now chain two lists with a matcher and offer an All choice that a query can match. Still open is where the datasource of the query is defined.

## Common pitfalls

> [!WARNING]
> - **Using an equality match with All.** Write `handler=~"$handler"` and set `customAllValue` to `.*`.
> - **A matcher that names no metric.** `{job="$job"}` alone selects every series, so the list can be slow and long.
> - **A default value that is not in the list.** The reader sees an empty choice.
> - **Making two variables depend on each other.** The dashboard can never fill either list.

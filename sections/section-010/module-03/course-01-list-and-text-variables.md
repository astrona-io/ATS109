# List And Text Variables

A dashboard with fixed queries answers one question. A dashboard with variables answers the same question for any job, handler or time window the reader picks. This part defines the two variable kinds that Perses has, shows how a query uses them, and proves with the datasource proxy that the query still runs once the variable has a value.

## Two kinds of variable

A **variable** is a named value that a query can use. It sits in the `spec.variables` list of the dashboard. A `ListVariable` offers the reader a list of values to choose from, and a plugin fills the list. A `TextVariable` holds one value, which the reader types into a box, or which stays fixed when `constant` is true.

The dashboard below has one of each. The list `job` takes its values from the label `job` of the metric `up`. The text variable `window` starts as `5m` and sets the time window of the `rate` function.

<!-- astrona:playground:renew -->

Save this as `dashboard-variables-basic.yaml`:

```yaml
kind: Dashboard
metadata:
  name: variables-basic
  project: specs
spec:
  display:
    name: Variables Basic
  duration: 1h
  variables:
    - kind: ListVariable
      spec:
        name: job
        display:
          name: Job
        allowMultiple: false
        allowAllValue: false
        sort: alphabetical-asc
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: job
            matchers:
              - up
    - kind: TextVariable
      spec:
        name: window
        display:
          name: Window
        value: 5m
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
                  query: sum by (handler) (rate(prometheus_http_requests_total{job="$job"}[$window]))
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
percli apply -f dashboard-variables-basic.yaml
```

Then check the result:

```sh
percli describe dashboard variables-basic -ojson | jq '.spec.variables | map({kind, name: .spec.name, plugin: .spec.plugin.kind})'
```

The answer lists two variables: the `ListVariable` `job` with the plugin `PrometheusLabelValuesVariable`, and the `TextVariable` `window`, which has no plugin. Open the dashboard in the browser and you see a drop-down for `Job` and a box for `Window` above the chart.

## What a list variable can do

The fields of a `ListVariable` decide how the choice behaves. `allowMultiple` lets the reader pick more than one value, and `allowAllValue` adds an All choice. `defaultValue` sets the choice when the dashboard opens, and `sort` orders the list; `alphabetical-asc` is one of the sort values. The `plugin` decides where the values come from, and this module uses `PrometheusLabelValuesVariable` and `StaticListVariable`.

A Grafana `query` variable with `label_values(up, job)` becomes exactly this plugin when you migrate it. The Grafana flags `includeAll` and `multi` become `allowAllValue` and `allowMultiple`.

## How a query uses a variable

Perses replaces `$job` and `$window` in the query text before it sends the query to the datasource. `${job}` means the same as `$job` and is useful when a letter follows the name. Before you trust the dashboard, run the query with fixed values through the datasource proxy of the project, as the browser does:

```sh
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  http://perses.localtest.me:8080/proxy/projects/specs/datasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (handler) (rate(prometheus_http_requests_total{job="prometheus"}[5m]))' | jq '.data.result | length'
```

The answer is a number greater than zero: one series for each handler that served a request in the last five minutes. If it prints `0`, the job name or the metric is wrong, and the dashboard would show an empty chart even though it is valid.

You can now define a list variable and a text variable and use both in a query. Still open is a list that depends on another list, which is the subject of the next part.

## Common pitfalls

> [!WARNING]
> - **Using a variable that is not defined.** The dashboard is stored, but the query keeps the text `$job` and the panel is empty.
> - **Writing a variable name in the plugin settings of the wrong variable.** `name` belongs to the variable `spec`, not to the plugin `spec`.
> - **Putting a `plugin` on a `TextVariable`.** A text variable has a `value` and no plugin.
> - **Testing the query with the variable text still in it.** Replace `$job` with a real value before you run it through the proxy.

# Solution: Build A Dashboard With Chained Variables

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Sign in and select the project

```sh
percli login http://perses.localtest.me:8080
percli project specs
```

## Step 2: Write the dashboard

Perses evaluates the variables in the order of the list and fills `$job` before the matcher of `handler` is used, so `job` comes first. The matcher of `handler` is a series selector with `$job` in it, which narrows the handler values to the chosen job. The All choice of `handler` needs `customAllValue: ".*"`, because the query uses the regular expression match `=~`. The variable `window` is a fixed list, so it needs no query, and `defaultValue` selects `5m` when the dashboard opens.

Save this as `dashboard-variable-panels.yaml`:

```yaml
kind: Dashboard
metadata:
  name: variable-panels
  project: specs
spec:
  display:
    name: Variable Panels
  duration: 1h
  variables:
  - kind: ListVariable
    spec:
      name: job
      display:
        name: Job
      allowAllValue: false
      allowMultiple: false
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
      allowAllValue: true
      allowMultiple: false
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
      allowAllValue: false
      allowMultiple: false
      defaultValue: 5m
      plugin:
        kind: StaticListVariable
        spec:
          values:
          - 1m
          - 5m
          - 15m
  panels:
    rate:
      kind: Panel
      spec:
        display:
          name: Request rate
        plugin:
          kind: TimeSeriesChart
          spec:
            legend:
              position: bottom
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
                datasource:
                  kind: PrometheusDatasource
                  name: prometheus
                seriesNameFormat: "{{handler}}"
  layouts:
  - kind: Grid
    spec:
      display:
        title: Requests
        collapse:
          open: true
      items:
      - x: 0
        y: 0
        width: 24
        height: 8
        content:
          "$ref": "#/spec/panels/rate"
```

## Step 3: Check and apply it

Ask the server to validate the file without storing it:

```sh
percli lint -f dashboard-variable-panels.yaml --online
```

Apply it:

```sh
percli apply -f dashboard-variable-panels.yaml
```

## Step 4: Check the result

```sh
percli describe dashboard variable-panels -ojson | jq -r '.spec.variables[] | "\(.spec.name) \(.spec.plugin.kind)"'
```

The command prints the three variables in order with their plugin kinds. Send the lab for grading with `astrona submit -c sections/section-010/module-03/labs/lab-01`.

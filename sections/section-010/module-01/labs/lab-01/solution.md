# Solution: Write A Perses Dashboard By Hand

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the dashboard exists and validates, its panels and layout, its variable and time settings, and that both queries return the same series as the Grafana queries.

## Step 1: Read the Grafana dashboard

Fetch the Grafana dashboard and pick out what matters for the Perses version:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/http-requests | jq '.dashboard' > http-requests.json
jq '{uid, title, time, refresh}' http-requests.json
jq '.templating.list[] | {name, query: .query.query, includeAll, allValue}' http-requests.json
jq '.panels[] | {type, title, gridPos, expr: .targets[0].expr, legend: .targets[0].legendFormat, unit: .fieldConfig.defaults.unit}' http-requests.json
```

The time range starts at `now-6h` and the refresh is `30s`, so the Perses dashboard needs `duration: 6h` and `refreshInterval: 30s`. The variable `handler` runs `label_values(prometheus_http_requests_total, handler)`, with the All choice and the all value `.*`. The two panels are a `timeseries` called `Request rate` and a `stat` called `Targets up`, with their expressions, legend and unit.

## Step 2: Write the Perses dashboard

Each Grafana part has a Perses counterpart: `label_values(<selector>, <label>)` becomes a `PrometheusLabelValuesVariable` with `labelName` and `matchers`; `legendFormat` becomes `seriesNameFormat`; `gridPos` becomes a layout item; the unit `reqps` becomes `requests/sec` and `none` becomes `decimal`; the reducer `lastNotNull` becomes the calculation `last-number`.

Save this as `dashboard-http-requests.yaml`:

```yaml
kind: Dashboard
metadata:
  name: http-requests
  project: specs
spec:
  display:
    name: HTTP Requests
  duration: 6h
  refreshInterval: 30s
  variables:
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
              - prometheus_http_requests_total
  panels:
    requestRate:
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
                  datasource:
                    kind: PrometheusDatasource
                    name: prometheus
                  query: sum by (handler) (rate(prometheus_http_requests_total{handler=~"$handler"}[5m]))
                  seriesNameFormat: "{{handler}}"
    targetsUp:
      kind: Panel
      spec:
        display:
          name: Targets up
        plugin:
          kind: StatChart
          spec:
            calculation: last-number
            format:
              unit: decimal
            thresholds:
              steps:
                - value: 0
                  color: "#f2495c"
                - value: 1
                  color: "#73bf69"
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource
                    name: prometheus
                  query: sum(up)
  layouts:
    - kind: Grid
      spec:
        display:
          title: HTTP Requests
          collapse:
            open: true
        items:
          - x: 0
            y: 0
            width: 16
            height: 8
            content:
              $ref: "#/spec/panels/requestRate"
          - x: 16
            y: 0
            width: 8
            height: 8
            content:
              $ref: "#/spec/panels/targetsUp"
```

## Step 3: Check it and apply it

With the Perses port-forward running in a second terminal, lint the file against the server's plugins, then apply it:

```sh
percli login http://perses.localtest.me:8080
percli lint -f dashboard-http-requests.yaml --online
percli apply -f dashboard-http-requests.yaml
```

The linter reports no problem, and `percli apply` reports that the dashboard `http-requests` has been applied to the project `specs`.

## Step 4: Prove the data matches

Open `HTTP Requests` in Perses and in Grafana side by side: both show the request rate per handler and the number of targets that are up. To compare the data exactly, run each expression through the Perses datasource proxy at the same moment:

```sh
NOW=$(date +%s)
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  http://perses.localtest.me:8080/proxy/projects/specs/datasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum(up)' --data-urlencode "time=$NOW" | jq '.data.result'
```

The result holds one series without labels and the value `1`: one target, Prometheus itself, is up. That is what the Grafana stat panel shows too.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Run `percli migrate` on the Grafana file | The task is to write the dashboard by hand; the migrated dashboard is also named after the uid but keeps `prom-main` as its datasource and a `1h` duration |
| Copy Grafana's `lastNotNull` and `reqps` into the plugin specs | The plugin schemas refuse them; `percli lint --online` names the field |
| Leave out the layout | The panels are stored but never drawn, and the grader finds no layout item for them |
| Point the queries at `prom-main` | No datasource has that name in Perses, so the queries return nothing |

## Common mistakes

- Writing `panels` as a YAML list instead of a map.
- An unquoted `$ref` value: in YAML, `#` starts a comment.
- `duration: 1h`, the default, instead of the Grafana range of six hours.
- A variable name that differs from the one the query uses (`$handler`).

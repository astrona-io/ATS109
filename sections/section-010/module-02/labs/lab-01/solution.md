# Solution: Build A Runtime Dashboard With Four Panel Plugins

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

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

Each panel has a display name, a plugin with its settings and a list of queries. The stat, the gauge and the bar chart need a `calculation`, because their query returns a series and the panel shows one number for each series. The gauge needs `max: 1`, because its value is a fraction, and its thresholds are written in the same unit, so the steps are fractions too.

Save this as `dashboard-runtime-panels.yaml`:

```yaml
kind: Dashboard
metadata:
  name: runtime-panels
  project: specs
spec:
  display:
    name: Runtime Panels
  duration: 1h
  panels:
    memory:
      kind: Panel
      spec:
        display:
          name: Resident memory
        plugin:
          kind: StatChart
          spec:
            calculation: last-number
            format:
              unit: bytes
        queries:
        - kind: TimeSeriesQuery
          spec:
            plugin:
              kind: PrometheusTimeSeriesQuery
              spec:
                query: process_resident_memory_bytes{job="prometheus"}
                datasource:
                  kind: PrometheusDatasource
                  name: prometheus
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
                query: sum by (handler) (rate(prometheus_http_requests_total[5m]))
                datasource:
                  kind: PrometheusDatasource
                  name: prometheus
                seriesNameFormat: "{{handler}}"
    fds:
      kind: Panel
      spec:
        display:
          name: Open file descriptors
        plugin:
          kind: GaugeChart
          spec:
            calculation: last-number
            format:
              unit: percent-decimal
            max: 1
            thresholds:
              steps:
              - value: 0
                color: "#73bf69"
              - value: 0.7
                color: "#ff9830"
              - value: 0.9
                color: "#f2495c"
        queries:
        - kind: TimeSeriesQuery
          spec:
            plugin:
              kind: PrometheusTimeSeriesQuery
              spec:
                query: process_open_fds{job="prometheus"} / process_max_fds{job="prometheus"}
                datasource:
                  kind: PrometheusDatasource
                  name: prometheus
    codes:
      kind: Panel
      spec:
        display:
          name: Requests by code
        plugin:
          kind: BarChart
          spec:
            calculation: last-number
            format:
              unit: decimal
            sort: desc
        queries:
        - kind: TimeSeriesQuery
          spec:
            plugin:
              kind: PrometheusTimeSeriesQuery
              spec:
                query: sum by (code) (prometheus_http_requests_total)
                datasource:
                  kind: PrometheusDatasource
                  name: prometheus
                seriesNameFormat: "{{code}}"
  layouts:
  - kind: Grid
    spec:
      display:
        title: Runtime
        collapse:
          open: true
      items:
      - x: 0
        y: 0
        width: 6
        height: 6
        content:
          "$ref": "#/spec/panels/memory"
      - x: 6
        y: 0
        width: 6
        height: 6
        content:
          "$ref": "#/spec/panels/fds"
      - x: 12
        y: 0
        width: 12
        height: 8
        content:
          "$ref": "#/spec/panels/rate"
      - x: 0
        y: 8
        width: 12
        height: 8
        content:
          "$ref": "#/spec/panels/codes"
```

## Step 3: Check and apply it

Ask the server to validate the file without storing it:

```sh
percli lint -f dashboard-runtime-panels.yaml --online
```

Apply it:

```sh
percli apply -f dashboard-runtime-panels.yaml
```

## Step 4: Check the result

```sh
percli describe dashboard runtime-panels -ojson | jq -r '.spec.panels[] | "\(.spec.display.name) \(.spec.plugin.kind)"'
```

The command prints the four panel titles with their plugin kinds. Send the lab for grading with `astrona submit -c sections/section-010/module-02/labs/lab-01`.

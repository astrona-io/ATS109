# Datasources And Scopes

A query that returns nothing is often not a query problem. The panel may point at a datasource that does not exist in the place where Perses looks for it. This part lists where a datasource can be defined, shows the order of the lookup, and defines a datasource inside one dashboard.

## Where a datasource is defined

A **datasource** is the Perses object that holds the address of a data service, here Prometheus, and how Perses reaches it. It can be defined in three scopes. A **global datasource** is available to every project and is managed through `/api/v1/globaldatasources`. A **project datasource** belongs to one project, and the project `specs` already has one named `prometheus`. A **dashboard datasource** sits inside the dashboard in its `datasources` field and exists only for that dashboard.

List the first two from the `tester` pod:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- curl -s \
  http://perses.localtest.me:8080/api/v1/projects/specs/datasources | jq 'map({name: .metadata.name, default: .spec.default, kind: .spec.plugin.kind})'
kubectl -n observability exec deploy/tester -- curl -s \
  http://perses.localtest.me:8080/api/v1/globaldatasources | jq 'length'
```

The first answer lists one project datasource, `prometheus`, of the kind `PrometheusDatasource`, with `default` set to true. The second answer is the number of global datasources, which is `0` in this environment.

## How a query finds its datasource

A query names a datasource in its plugin `spec` with a `datasource` object that has a `kind` and a `name`. When the query names one, Perses looks for that name in the dashboard first, then in the project, and then in the global scope. The first match wins. When the query names none, Perses uses the default datasource of the same kind, again looking in the dashboard, then the project, then the global scope.

This is why a migrated query that keeps the Grafana datasource name `prom-main` shows no data. No scope has a datasource with that name, and the name takes the place of the default.

## A datasource inside a dashboard

A dashboard datasource lets one dashboard use its own address without touching the project. Save this as `dashboard-own-datasource.yaml`:

```yaml
kind: Dashboard
metadata:
  name: own-datasource
  project: specs
spec:
  display:
    name: Own Datasource
  duration: 1h
  datasources:
    local-prom:
      default: false
      plugin:
        kind: PrometheusDatasource
        spec:
          proxy:
            kind: HTTPProxy
            spec:
              url: http://prometheus.observability:9090
  panels:
    goroutines:
      kind: Panel
      spec:
        display:
          name: Goroutines
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: go_goroutines
                  datasource:
                    kind: PrometheusDatasource
                    name: local-prom
  layouts:
    - kind: Grid
      spec:
        display:
          title: Runtime
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/goroutines"
```

Apply it:

```sh
percli apply -f dashboard-own-datasource.yaml
```

Then check the result:

```sh
percli describe dashboard own-datasource -ojson | jq '{datasources: (.spec.datasources | keys), queryDatasource: .spec.panels.goroutines.spec.queries[0].spec.plugin.spec.datasource.name}'
```

The answer shows the datasource `local-prom` defined in the dashboard, and the query that names it. Open the dashboard in the browser: the chart draws, so the lookup found the name in the first scope. Change the name in the query to `missing`, apply again and reload: the chart is empty, because no scope has that name, but the server did not refuse the dashboard.

## Which scope to choose

Use the project scope for the datasource that most dashboards share. Use the dashboard scope when one dashboard needs its own address or settings, and the global scope for a datasource that every project must see. When you migrate a dashboard, `--use-default-datasource` removes the name from each query, so the query follows whichever scope holds the default.

You can now say where a datasource is defined and which one a query uses. Still open is how to ask the server whether a dashboard is valid before you apply it.

## Common pitfalls

> [!WARNING]
> - **Assuming the server checks datasource names.** A name that exists nowhere is stored without an error.
> - **Two defaults in one scope.** Perses cannot tell which one a query without a name should use.
> - **Forgetting the order.** A dashboard datasource hides a project datasource of the same name.
> - **Copying the Grafana datasource uid.** A Grafana uid such as `prom-main` is not a Perses name.

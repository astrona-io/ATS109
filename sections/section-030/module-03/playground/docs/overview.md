# Overview: Run A Release Check On A Migrated Dashboard (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Perses, Prometheus and Grafana, applies a migrated dashboard that has one wrong query, and then waits. There is no task, no `astrona submit` and no pass or fail. Run checks, change things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, reached at `http://perses.localtest.me:8080`. `percli` v0.54.0 is installed on your machine.
- In Perses, the project **`release`** with the default datasource `prometheus` and the dashboard **`service-health`**: five panels (`Memory`, `Goroutines`, `Open files`, `CPU`, `Head series`). The query of the panel `Goroutines` uses `go_threads`, while the Grafana panel uses `go_goroutines`.
- **Grafana 12.4.13** in the namespace `observability` with the dashboard **`Service Health`** (uid `service-health`). Its Prometheus datasource has the uid `prom-main`. Anyone is let in as an administrator: lab only.
- **Prometheus v3.15.1** and a **`tester`** pod with `curl` and `jq` in `observability`.

## Getting started

Start the Perses port-forward in a second terminal and leave it running. For Grafana in the browser, start a third one at `http://localhost:3000`:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
kubectl -n observability port-forward svc/grafana 3000:3000
```

Then sign `percli` in:

```sh
percli login http://perses.localtest.me:8080
```

## Things to try

Save both dashboards:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/service-health | jq '.dashboard' > service-health.grafana.json
percli describe dashboard service-health --project release -ojson > service-health.perses.json
```

- Check that the server accepts the Perses dashboard with `POST /api/validate/dashboards`.
- Search the Perses file for placeholders and for datasource names that the project does not have.
- Run the Grafana and the Perses expression of one panel through the datasource proxy `/proxy/projects/release/datasources/prometheus/api/v1/query` at the same time, and compare the series.
- Change the query of the panel `Goroutines` to `go_goroutines{job="prometheus"}`, apply the file with `percli apply`, and check the panel again.
- Add a placeholder panel or a wrong datasource name on purpose, and see which check finds it.

## Cleaning up

```sh
astrona destroy ats-109-playground-030-03
```

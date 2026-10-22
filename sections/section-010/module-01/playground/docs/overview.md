# Overview: Read And Write The Perses Dashboard Specification (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Perses, Prometheus and Grafana, creates one example dashboard, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, reached at `http://perses.localtest.me:8080`. `percli` v0.54.0 is installed on your machine.
- In Perses, the project **`specs`** with the default datasource `prometheus` and the dashboard **`example`** (display name `Example: Prometheus At A Glance`): a `StatChart` and a `TimeSeriesChart` in one `Grid`.
- **Prometheus v3.15.1** in the namespace `observability`. It collects metrics about itself, such as `up`, `prometheus_http_requests_total` and `go_goroutines`.
- **Grafana 12.4.13** in the namespace `observability` with the dashboard **`HTTP Requests`** (uid `http-requests`) in the folder `Legacy`. Its Prometheus datasource has the uid `prom-main`. Anyone is let in as an administrator: lab only.
- A **`tester`** pod in `observability` with `curl` and `jq`.

## Getting started

Start the Perses port-forward in a second terminal and leave it running. For Grafana in the browser, start a third one:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
kubectl -n observability port-forward svc/grafana 3000:3000
```

Then sign `percli` in and select the project:

```sh
percli login http://perses.localtest.me:8080
percli project specs
```

## Helpers

Paste these once in each new terminal. `grafana_dashboard` saves a Grafana dashboard by its uid to `<uid>.json`. `perses_dashboard` prints a Perses dashboard of the project `specs` as JSON. `panel_kinds` lists the panel keys and plugin kinds of a Perses dashboard.

```sh
grafana_dashboard() {
  kubectl -n observability exec deploy/tester -- \
    curl -s "http://grafana.observability:3000/api/dashboards/uid/$1" | jq '.dashboard' > "$1.json"
}
perses_dashboard() { percli describe dashboard "$1" --project specs -ojson; }
panel_kinds() { perses_dashboard "$1" | jq '.spec.panels | to_entries | map({key, kind: .value.spec.plugin.kind})'; }
```

Use them like this: `grafana_dashboard http-requests`, `perses_dashboard example`, `panel_kinds example`.

## Practice tasks

- Read the dashboard `example` with `perses_dashboard example` and draw on paper which layout item points at which panel.
- Save `http-requests` with `grafana_dashboard http-requests` and list, for each Grafana panel, its `type`, `gridPos` and `targets[].expr`. Write down the Perses field each one would become.
- Change the `$ref` of one item of `example` to a key that does not exist, apply the dashboard, and look at it in the browser. Put it back.
- Write a `StatChart` with `calculation: lastNotNull` and run `percli lint --online` on it. Find the Perses word for the same calculation in the error.
- Add a `datasource` with the name `prom-main` to one query of `example` and apply it. Look at the panel, then remove the name again.

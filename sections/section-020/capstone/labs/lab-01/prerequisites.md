# Prerequisites

Before starting this capstone you should be able to:

- Read and write JSON, and pick fields out of it with `jq`.
- Use `percli` to log in, select a project and apply a resource.
- Read a PromQL query and say what it returns.

## What the environment gives you

The environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, and `percli` v0.54.0 on your machine.
  Authentication is off.
- **Prometheus v3.15.1** and **Grafana 12.4.13** in the namespace `observability`. Grafana
  holds the legacy dashboards; its Prometheus datasource has the uid `prom-main`.
- A `tester` pod in `observability` with `curl` and `jq`.

Nothing the task asks you to create has been created for you.

## Working rules

- Start `kubectl -n perses port-forward svc/perses 8080:8080` in a second terminal
  before you use `percli`, and log in with `percli login http://perses.localtest.me:8080`.
  If the name does not resolve, add `127.0.0.1 perses.localtest.me` to `/etc/hosts`.
- Everything is graded on the **final state** of Perses.
- Change one thing at a time, and check it with the Perses API or `percli` before the next.

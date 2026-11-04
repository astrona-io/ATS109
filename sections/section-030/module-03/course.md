# Build A Release Check

A migrated dashboard is ready to release when three things are true: nothing is left that the migration could not translate, every query reaches a datasource, and every panel returns the same data as its Grafana panel. Checking this by eye for each dashboard is slow, and a person misses the panel that shows the right shape with the wrong metric. This module turns the checks into one script that prints a report.

Keep one sentence in mind: **a release check lists the panels that differ, by name, and gives a reason for each.**

The module has four parts. **What To Check Before A Release** lists the checks and the order to run them in. **Finding Placeholders And Missing Datasources** writes the structural checks with `jq`. **One Check Script** joins the checks with the parity query into one script. **Reading The Report** explains how to act on each kind of line. A graded lab follows the last part.

## Learning objectives

After this module you can:

- List the checks that decide whether a migrated dashboard can be released.
- Find placeholder panels, placeholder queries and placeholder variables with `jq`.
- Find a query that names a datasource that does not exist.
- Compare a Grafana expression and a Perses expression with instant queries at one time.
- Write a script that reports the names of the panels that differ.
- Tell a metric fault from a query window fault in a report.

## Before you start

You need to know how to run a query through the Perses datasource proxy and how to read a migrated dashboard. You also need `jq` and a shell loop.

Your playground is a single-node `kind` cluster with:

| Component | Where | What it holds |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses`, `http://perses.localtest.me:8080` | the project `release` with the dashboard `service-health` |
| Grafana 12.4.13 | namespace `observability` | the dashboard `Service Health` (uid `service-health`) |
| Prometheus v3.15.1 | namespace `observability` | metrics about Prometheus itself |
| `tester` | namespace `observability` | a pod with `curl` and `jq` |

Start a port-forward in a second terminal and leave it running before you use `percli`:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
percli login http://perses.localtest.me:8080
percli project release
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

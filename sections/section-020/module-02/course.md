# Read And Reshape A Migrated Dashboard

A migrated dashboard works, but it does not look the way the team built it. All panels sit in one group, the keys are numbers, and a few variables are placeholders. Finishing a migration means turning that output into a dashboard the team can maintain.

This module reads the parts of a migrated dashboard that decide how it is organised: the panel keys, the layout groups and the variables. Keep one sentence in mind: **a migration keeps the data and the order of the panels, and it is your job to restore the structure that people used to find their way around.**

The module has four parts. **Panel Keys And Layout Items** reads how panels are keyed and placed. **Splitting Layout Groups** builds named groups from one flat group. **Variables After Migration** lists what each Grafana variable type became. **Cleaning Up Variables** removes placeholders and checks that every variable a query uses exists; a graded lab follows it.

## Learning objectives

After this module you can:

- Read the key of a panel and the layout item that points at it.
- Join a Grafana panel to its Perses panel by title.
- Build named `Grid` groups from a flat migrated layout and set which ones start closed.
- Name the Perses variable plugin each Grafana variable type becomes.
- Find placeholder variables and variables that a query uses but nobody defined.
- Remove a placeholder variable without breaking a query.

## Before you start

You need to know the shape of a Perses dashboard and what `percli migrate` does. You also need `jq`.

Your playground is a single-node `kind` cluster with:

| Component | Where | What it holds |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses`, `http://perses.localtest.me:8080` | the empty project `legacy` with the default datasource `prometheus` |
| Grafana 12.4.13 | namespace `observability` | `Prometheus Overview` (uid `prometheus-overview`) and `Prometheus Storage` (uid `prometheus-storage`) in the folder `Legacy` |
| Prometheus v3.15.1 | namespace `observability` | metrics about Prometheus itself |
| `tester` | namespace `observability` | a pod with `curl` and `jq` |

`percli` v0.54.0 is installed on your machine. Before you run any `percli` command, start the port-forward in a second terminal and leave it running, then sign in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
percli login http://perses.localtest.me:8080
percli project legacy
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

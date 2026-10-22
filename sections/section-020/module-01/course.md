# Migrate Grafana Dashboards With percli

A migration tool is only as good as your understanding of what it did. `percli migrate` turns a Grafana dashboard into a Perses dashboard in one command, and the result usually opens without an error. Some of its panels, though, may show a line of bold text instead of a chart, and some of its queries may point at a datasource that does not exist in Perses.

This module runs the migration on two Grafana dashboards and reads the result field by field. Keep one sentence in mind: **the migration translates what a plugin knows how to translate, marks everything else with a placeholder, and leaves the finishing to you.** The translation rules are not inside `percli`; each Perses plugin ships its own migration rules, and the Perses server runs them.

The module has three parts. **How Migration Works** runs `percli migrate` against the Perses server and follows the dashboard's name, time range, panels and rows through the translation. **Translating Panels And Variables** goes through which Grafana panel types, queries and variables become which Perses plugins, and what the placeholders look like. **Finishing A Migration** replaces the placeholders, fixes the datasource names, and applies the result to a project; a graded lab follows it.

## Learning objectives

After this module you can:

- Run `percli migrate --online` and explain what the Perses server does with the Grafana JSON.
- Predict the name, display name, tags and time range of a migrated dashboard.
- Name the Perses plugin each common Grafana panel type, query and variable type becomes.
- Find every placeholder in a migrated dashboard with `jq`.
- Explain why panels under an open Grafana row land in `Panel Group 1`.
- Fix the datasource names a migration copies from Grafana, by renaming or with `--use-default-datasource`.
- Replace placeholder panels and variables, migrate into a project and apply the result.

## Before you start

You need to read a Perses dashboard: panels as a map of named entries with a plugin and queries, `Grid` layouts whose items point at panels with `$ref`, and variables with a plugin. You also need `jq` and enough PromQL to read the queries.

Your playground is a single-node `kind` cluster with:

| Component | Where | What it holds |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses`, `http://perses.localtest.me:8080` | the empty project `legacy` with the default datasource `prometheus` |
| Grafana 12.4.13 | namespace `observability` | `Prometheus Overview` (uid `prometheus-overview`) and `Prometheus Storage` (uid `prometheus-storage`) in the folder `Legacy`; datasource uid `prom-main` |
| Prometheus v3.15.1 | namespace `observability` | metrics about Prometheus itself |
| `tester` | namespace `observability` | a pod with `curl` and `jq` |

`percli` v0.54.0 is installed on your machine. Before you run any `percli` command, start the port-forward in a second terminal and leave it running:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

# Read And Write The Perses Dashboard Specification

A Grafana dashboard and a Perses dashboard can draw the same picture from the same data, and still look nothing alike as files. Grafana keeps a list of panels, and each panel carries its own position. Perses keeps a map of named panels and describes their positions in a separate place. Before you can migrate dashboards, or check a migration, you need to read the Perses format as easily as you read Grafana's.

The Perses dashboard specification is the data model of a Perses dashboard. The Perses project publishes it as an **open specification**, so that other tools can produce and use the same files. Keep one sentence in mind for this module: **a Perses dashboard keeps what to show (panels and queries) apart from where to show it (layouts), and each plugin decides what its own part may contain.**

The module has three parts. **What The Open Specification Is** reads a real dashboard through the Perses API and `percli`, the Perses command-line tool, and names its top-level fields. **Panels, Queries And Layouts** writes a small dashboard by hand and applies it. **Variables, Datasources And Plugin Schemas** adds a variable, shows how a query finds its datasource, and makes the Perses server refuse a value that breaks a plugin's rules; a graded lab follows it.

## Learning objectives

After this module you can:

- Explain what the Perses open specification is and how a tool shows it is compatible.
- Name the fields of the resource envelope (`kind`, `metadata`, `spec`) and of a dashboard `spec`.
- Write a panel with a panel plugin and a Prometheus query, and place it with a `Grid` layout and a `$ref`.
- Define a list variable filled by a Prometheus variable plugin, and use it in a query.
- Explain how a query selects its datasource, and the order of the dashboard, project and global scopes.
- Read the server's answer when a plugin schema refuses a value, and fix the value.
- Map each part of a Grafana dashboard JSON file to its Perses counterpart.

## Before you start

You need Kubernetes basics (namespaces, Services, `kubectl exec`), JSON and YAML, `jq`, and enough PromQL to read `rate(...)` and `sum by (...)`. You do not need to know Perses.

Your playground is a single-node `kind` cluster with:

| Component | Where | What it holds |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses`, `http://perses.localtest.me:8080` | the project `specs`, its datasource `prometheus`, the dashboard `example` |
| Prometheus v3.15.1 | namespace `observability` | metrics about Prometheus itself |
| Grafana 12.4.13 | namespace `observability` | the dashboard `HTTP Requests` (uid `http-requests`) in the folder `Legacy` |
| `tester` | namespace `observability` | a pod with `curl` and `jq` |

`percli` v0.54.0 is installed on your machine. Authentication is off in this Perses, so `percli` needs no password. Before you run any `percli` command, start the port-forward in a second terminal and leave it running:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

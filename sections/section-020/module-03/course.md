# Migrate With Inputs, Projects And Output Formats

One dashboard is a command. A whole Grafana folder is a project, and a project needs repeatable choices: which datasource the queries use, which Perses project receives the dashboards, and in which format the result is written. A wrong choice does not stop the migration. It produces dashboards that open and show nothing.

This module goes through the flags and the API fields that make a migration repeatable. Keep one sentence in mind: **the migration copies the datasource names from Grafana, so you decide how to replace them before you run it, not after.**

The module has four parts. **Grafana Inputs And The Input Flag** explains the placeholders in a shared export. **Projects And The Default Datasource** compares the three ways to set the datasource and the project. **Output Formats And Custom Resources** writes the result as a native dashboard and as a Kubernetes custom resource. **Migrating A Whole Folder** loops over every dashboard of a Grafana folder; a graded lab follows it.

## Learning objectives

After this module you can:

- Recognise a Grafana export that uses inputs, and replace them with `--input`.
- Explain what `--project` and `--use-default-datasource` change in the result.
- Choose between the native format and the custom resource format.
- Find the dashboards of a Grafana folder through the Grafana search API.
- Migrate and apply every dashboard of a folder in one loop.
- Check the result with panel counts and datasource names.

## Before you start

You need to know what `percli migrate` does and how to read a migrated dashboard. You also need `jq` and a shell loop.

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

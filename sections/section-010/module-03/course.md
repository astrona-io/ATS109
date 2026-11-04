# Work With Variables, Datasources And Validation

Most real dashboards are not fixed. A reader picks a job or a handler from a list, and every query on the page changes with the choice. The queries also need a datasource, and the datasource can be defined in more than one place. When a dashboard is wrong, you need a way to ask the server whether it is valid before you apply it.

This module goes deeper into three parts of the specification: variables, datasources and validation. Keep one sentence in mind: **a query is only valid when every variable it uses is defined and every datasource it names exists in a scope the dashboard can reach.**

The module has four parts. **List And Text Variables** defines the two variable kinds and how a query uses them. **Chained Variables And Matchers** makes one list depend on another. **Datasources And Scopes** explains where a datasource can be defined and which one wins. **Validating A Dashboard Without Applying It** asks the server and `percli` to check a file, and a graded lab follows it.

## Learning objectives

After this module you can:

- Write a `ListVariable` and a `TextVariable` and use them in a query.
- Make a variable depend on another variable with a matcher.
- Offer an All choice with a custom value that a query can match.
- Name the three datasource scopes and the order in which a name is looked up.
- Define a datasource inside a dashboard.
- Validate a dashboard with `percli lint --online` and with the validation endpoint, and read the error.

## Before you start

You need to read a Perses dashboard and know the parts of a panel. You also need `jq` and enough PromQL to read the queries.

Your playground is a single-node `kind` cluster with:

| Component | Where | What it holds |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses`, `http://perses.localtest.me:8080` | the project `specs` with the default datasource `prometheus` and the dashboard `example` |
| Prometheus v3.15.1 | namespace `observability` | metrics about Prometheus itself |
| Grafana 12.4.13 | namespace `observability` | the dashboard `HTTP Requests` (uid `http-requests`) |
| `tester` | namespace `observability` | a pod with `curl` and `jq` |

`percli` v0.54.0 is installed on your machine. Before you run any `percli` command, start the port-forward in a second terminal and leave it running, then sign in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
percli login http://perses.localtest.me:8080
percli project specs
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

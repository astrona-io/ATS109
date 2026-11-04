# Compare What The Reader Sees

A migrated panel can run the same query as the Grafana panel and still show something different. The number can have another unit, the lines can have other names, the colour can change at another value, and the time window can be shorter. The reader sees these, not the query. This module compares the display settings of a Grafana panel and a Perses panel, one setting at a time.

Keep one sentence in mind: **equal query results do not mean equal panels; the unit, the legend, the thresholds and the time range decide what a person reads.**

The module has four parts. **Units And Number Formats** compares how a number is written. **Legends And Series Names** compares the names of the lines. **Thresholds And Calculations** compares colours and the single value of a stat. **Time Range, Step And Refresh** compares the window and the sample spacing. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Read the unit of a Grafana panel and of a Perses panel and map one to the other.
- Explain why a value in seconds shown as milliseconds is a fault, not a style choice.
- Compare legend formats and series names between the two tools.
- Compare threshold steps, including the unit they are written in.
- Explain what a calculation such as last or mean does to a single value.
- Find the time range, refresh and step settings that a migration changes.

## Before you start

You need to know how to migrate a dashboard and how to run a query through the Perses proxy. You also need `jq`.

Your playground is a single-node `kind` cluster with:

| Component | Where | What it holds |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses`, `http://perses.localtest.me:8080` | the project `parity` with the dashboard `api-latency` |
| Grafana 12.4.13 | namespace `observability` | the dashboard `API Latency` (uid `api-latency`) |
| Prometheus v3.15.1 | namespace `observability` | metrics about Prometheus itself |
| `tester` | namespace `observability` | a pod with `curl` and `jq` |

Start a port-forward in a second terminal and leave it running before you use `percli`:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
percli login http://perses.localtest.me:8080
percli project parity
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

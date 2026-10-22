# Check That A Migrated Dashboard Shows The Same Data

The last step of a migration is the one most teams skip: proving that the new dashboard shows what the old one showed. Looking at two charts side by side is not proof. Two lines can look alike while one averages over a minute and the other over five, and a stat can show the same number in a different unit.

This module turns "it looks the same" into a check. Keep one sentence in mind: **query parity means the same expression, with the same variable values, at the same moment, returns the same series and values; everything else a panel shows has to be checked separately.** You will run expressions through Grafana and through Perses, compare the results with `jq`, and then go through the panel settings that change the picture without changing the data.

The module has two parts. **Running The Same Query In Both Tools** sends a Grafana panel's expression through Grafana's query API and the Perses panel's expression through the Perses datasource proxy, and compares them. **What Changes The Picture Besides The Query** covers legends, units, calculations, thresholds and time settings, and ends with a parity checklist; a graded lab follows it.

## Learning objectives

After this module you can:

- Explain query parity and why a comparison must fix the time and the variable values.
- Run a Grafana panel's expression through Grafana's `/api/ds/query` endpoint.
- Run a Perses panel's expression through the Perses datasource proxy at a fixed time.
- Compare two query results series by series with `jq`.
- Map Grafana units and reducers to Perses units and calculations, and spot the ones the migration drops.
- Check legends, thresholds, the default time range and the refresh interval of a migrated dashboard.

## Before you start

You need to read a Perses dashboard (panels with a plugin and queries) and a Grafana dashboard (panels with `targets`, `fieldConfig` and `options`), and to use `jq` and PromQL. You should know that a migration copies Grafana's `legendFormat` into `seriesNameFormat` and Grafana's datasource uid into the query's datasource name.

Your playground is a single-node `kind` cluster with:

| Component | Where | What it holds |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses`, `http://perses.localtest.me:8080` | the project `parity` with the datasource `prometheus` and the migrated dashboard `api-latency` |
| Grafana 12.4.13 | namespace `observability` | the dashboard `API Latency` (uid `api-latency`); datasource uid `prom-main` |
| Prometheus v3.15.1 | namespace `observability` | metrics about Prometheus itself |
| `tester` | namespace `observability` | a pod with `curl` and `jq` |

The Perses dashboard in the playground is a correct migration, so every comparison you run here should match. Before you run any `percli` command, start the port-forward in a second terminal and leave it running:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

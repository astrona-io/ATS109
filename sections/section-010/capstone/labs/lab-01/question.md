# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** The dashboard specification

## Scenario

A colleague replaced the Grafana dashboard `Process Health` (uid `process-health`) with a Perses dashboard written by hand, then went on holiday. The file never made it into Perses: the server refuses it. When you get it in, you will find that some of its panels stay empty. The file is stored in the ConfigMap `broken-dashboard` in the namespace `perses`, under the key `process-health.json`.

Save it on your machine:

```sh
kubectl -n perses get configmap broken-dashboard -o jsonpath='{.data.process-health\.json}' > process-health.json
```

## Your task

Get the dashboard into the Perses project `capstone` as `process-health`, working:

1. Find out why the server refuses the file, and fix it.
2. Make sure every panel is drawn: every layout item must point at a panel that exists, and every panel must be placed.
3. Make every query use the project datasource `prometheus`, either by name or as the default.
4. Make every query return data. The Grafana dashboard `Process Health` shows what each panel is meant to show.

## Constraints

- Keep all three panels with their titles. Do not delete a panel to get rid of a problem.
- Do not create a datasource called `prom-main` or change the datasource `prometheus`.
- Do not change the Grafana dashboard.

## Done when

- `process-health` exists in the project `capstone` and passes the server's validation.
- All three panels are placed, and every layout item points at a panel that exists.
- No query names a datasource other than `prometheus`.
- Every panel query returns at least one series through the Perses datasource proxy.

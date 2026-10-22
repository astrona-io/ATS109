# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** `percli migrate` and finishing a migration

## Scenario

The platform team shared its Grafana dashboard `HTTP Overview` with every other team. They exported it from Grafana "for sharing externally", so the file does not name their datasource: every query uses the input `${DS_PROMETHEUS}` instead. Your team wants it in Perses, in the project `shared`, and also as a Kubernetes custom resource that the Perses Operator can deploy later. The file is stored in the ConfigMap `shared-export` in the namespace `perses`, under the key `http-overview-export.json`.

Save it on your machine:

```sh
kubectl -n perses get configmap shared-export -o jsonpath='{.data.http-overview-export\.json}' > http-overview-export.json
```

## Your task

1. Migrate the file with `percli migrate --online`, so that every query uses the Perses datasource `prometheus` in the project `shared`.
2. Keep the collapsed Grafana row `Details` as its own closed group with its two panels.
3. Leave no migration placeholder and no `${DS_PROMETHEUS}` anywhere, and set the dashboard's default time range to the six hours of the Grafana file.
4. Apply the dashboard to the project `shared` with the name `http-overview`.
5. Produce the same dashboard as a `PersesDashboard` custom resource for the namespace `shared`, and store it in a ConfigMap `http-overview-cr` in the namespace `perses`, under the key `dashboard.yaml`.

## Constraints

- Do not edit the export file by hand to replace the input; let the migration fill it in.
- Do not create a datasource called `${DS_PROMETHEUS}` or `DS_PROMETHEUS`.
- Keep all four panels.

## Done when

- `http-overview` exists in the project `shared` and passes the server's validation.
- No query or variable names `${DS_PROMETHEUS}`, and no placeholder is left.
- A closed `Grid` titled `Details` holds the two panels of the Grafana row.
- The ConfigMap `http-overview-cr` holds a `PersesDashboard` (`apiVersion: perses.dev/v1alpha1`) named `http-overview` for the namespace `shared`.

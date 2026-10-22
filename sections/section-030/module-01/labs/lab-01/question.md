# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Proving a migrated dashboard shows the same data

## Scenario

Last month a colleague migrated the Grafana dashboard `API Latency` (uid `api-latency`) to the Perses project `parity` and then "tidied it up" by hand. Since then the on-call team says the Perses dashboard disagrees with Grafana, but nobody can say where. Grafana is still the reference: its dashboard is correct.

## Your task

Compare the Perses dashboard `api-latency` in the project `parity` with the Grafana dashboard `API Latency`, panel by panel, and fix the Perses dashboard so that:

1. Every panel's query returns the same series as the Grafana panel with the same title, when both run at the same moment with the same variable values.
2. Every panel names its series the same way as the Grafana panel's legend.
3. Every stat panel reduces its series to one value the same way as the Grafana panel.

## Constraints

- Change only the Perses dashboard `api-latency`. Do not change the Grafana dashboard.
- Keep the panel titles, the variable `handler` and the datasource `prometheus`.
- Fix the dashboard in place; do not delete it and migrate it again.

## Done when

- Every Perses panel query returns the same series and values as its Grafana panel at a fixed time.
- Every `seriesNameFormat` matches the Grafana `legendFormat` of the same panel.
- Every stat calculation matches the Grafana reducer (`lastNotNull` is `last-number` in Perses).

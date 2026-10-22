# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Proving a migrated dashboard shows the same data

## Scenario

A release candidate of the migrated dashboard `api-latency` waits in the Perses project `release`. Next week it replaces the Grafana dashboard `API Latency` (uid `api-latency`) for every on-call engineer. The team lead wants proof that nobody will see anything different: not in the data, not in how the numbers are printed, not in the colours, and not in the time window the dashboard opens on. Grafana is the reference: its dashboard is correct.

## Your task

Check the Perses dashboard `api-latency` in the project `release` against the Grafana dashboard, panel by panel and as a whole, and fix every difference in Perses:

1. Every panel's query must return the same series as the Grafana panel with the same title, at the same moment and with the same variable values.
2. Every panel must use the Perses unit that matches the Grafana unit.
3. The thresholds of the stat `Error ratio` must change colour at the same values as in Grafana.
4. The dashboard must open on the same time range and refresh at the same interval as the Grafana dashboard.

## Constraints

- Change only the Perses dashboard `api-latency` in the project `release`. Do not change the Grafana dashboard.
- Keep the panel titles, the variable `handler` and the datasource `prometheus`.
- Fix the dashboard in place; do not delete it and migrate it again.

## Done when

- Every Perses panel query returns the same series and values as its Grafana panel at a fixed time.
- Every panel unit is the Perses equivalent of the Grafana unit.
- The `Error ratio` threshold steps have the same values as Grafana's (the base step `null` is `0` in Perses).
- `duration` and `refreshInterval` match Grafana's time range and refresh.

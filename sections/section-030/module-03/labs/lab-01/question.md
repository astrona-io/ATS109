# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Release check

## Scenario

The `drifter` team will switch off the Grafana dashboard `Service Health` after the release and use the Perses copy. The release manager asks for a parity check first and wants a list of the panels that did not show the same data.

## Your task

The project `release` holds the Perses dashboard `service-health`, migrated from the Grafana dashboard with the uid `service-health`. Both have five panels with the same titles: `Memory`, `Goroutines`, `Open files`, `CPU` and `Head series`.

1. For every panel, run the Grafana expression and the Perses expression through the Perses datasource proxy at the same time, and find the panels that return different data. Replace `$__rate_interval` with `5m` on both sides before you run them.
2. Write the titles of the panels that differed into a ConfigMap named `parity-report` in the namespace `perses`, under the key `mismatches`, one title per line.
3. Correct the Perses queries of those panels so that every panel returns the same data as Grafana.

## Constraints

- Do the check before you correct anything. The report lists the panels that differed at the start.
- Do not change Grafana. Grafana is the reference.
- Do not delete or rename a panel to make the check pass.
- Do not change the dashboard in any other way.

## Done when

- The dashboard `service-health` in the project `release` passes the server's validation and still has its five panels.
- Every panel query returns the same series and values as the Grafana query of the panel with the same title.
- The ConfigMap `parity-report` has the key `mismatches` with exactly the titles of the panels that differed at the start.
- The Grafana dashboard is unchanged.

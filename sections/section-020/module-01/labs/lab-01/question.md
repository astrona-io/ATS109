# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** `percli migrate` and finishing a migration

## Scenario

The Prometheus team is leaving Grafana. Their two dashboards, `Prometheus Overview` (uid `prometheus-overview`) and `Prometheus Storage` (uid `prometheus-storage`) in the Grafana folder `Legacy`, must move to the Perses project `legacy`. The project already has the default datasource `prometheus`. The team wants the dashboards finished, not just converted: no panel may show "Migration from Grafana not supported", and no panel may stay empty because of a datasource name.

## Your task

1. Migrate both Grafana dashboards with `percli migrate --online` against the running Perses server.
2. Replace every placeholder the migration wrote: placeholder panels with a Perses panel plugin that shows the same queries, placeholder variables with a working Perses variable or by removing them when Perses has no equivalent.
3. Make every query use the datasource `prometheus`, by name or as the project default.
4. Apply both dashboards to the project `legacy`, keeping their names `prometheus-overview` and `prometheus-storage`.

## Constraints

- Keep every panel. A dashboard must have as many panels in Perses as it has in Grafana (not counting rows). Do not delete a placeholder panel to get rid of it.
- Do not create a datasource called `prom-main`, and do not change the datasource `prometheus`.
- Do not change the Grafana dashboards.

## Done when

- Both dashboards exist in the project `legacy` and pass the server's validation.
- No panel, query or variable is a migration placeholder.
- Every query uses the datasource `prometheus`.
- Each Perses dashboard has one panel for every Grafana panel.

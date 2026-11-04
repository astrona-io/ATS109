# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Migrating dashboards

## Scenario

The `drifter` team is moving the dashboards of its Grafana folder `Legacy` to Perses. Grafana also holds a scratch dashboard outside that folder, and the team does not want that one in Perses. The target is the Perses project `shared`, which already exists with its default datasource `prometheus`.

## Your task

Migrate every dashboard of the Grafana folder `Legacy` into the Perses project `shared`:

1. Find the dashboards of the folder `Legacy` through the Grafana search API.
2. Migrate each one with `percli migrate --online` so that the Perses dashboard name equals the Grafana `uid`.
3. Make the queries use the project's default datasource.
4. Apply the results to the project `shared`.

## Constraints

- Migrate only the folder `Legacy`. Do not migrate the dashboard `scratch-notes`.
- Do not change anything in Grafana.
- Do not edit the migrated JSON by hand to remove the placeholders. Finishing them is not part of this task.

## Done when

- The project `shared` holds the dashboards `prometheus-overview` and `prometheus-storage`, and no other dashboard. Both pass the server's validation and keep their Grafana titles.
- Each has as many panels as its Grafana dashboard: 8 and 5.
- No query names a datasource that does not exist in the project `shared`.
- Grafana still holds the same dashboards.

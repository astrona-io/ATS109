# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Finishing a migration

## Scenario

The `drifter` team migrated its Grafana dashboard `Prometheus Overview` into the Perses project `legacy`. The migration put all top-level panels into one group and kept a placeholder variable. The team lead wants the panels grouped by purpose and the dead variable gone.

## Your task

The project `legacy` already holds the migrated dashboard `overview-flat`. Leave it as it is. Create a second dashboard in the same project with the name `overview-grouped` (`metadata.name`), built from `overview-flat`, with these changes:

1. Replace the single layout group with three `Grid` groups, in this order:
   - **Summary**: `Targets up`, `Resident memory`, `Request rate`. Starts open.
   - **Details**: `Top handlers`, `Scrape targets`, `Request duration`, `Target state`. Starts open.
   - **Internals**: `Goroutines`. Starts closed.
2. Remove the placeholder variable `filter`.

## Constraints

- Keep all eight panels with the same titles, plugins and queries. Do not delete or rewrite a panel.
- Keep the variables `job`, `handler` and `interval`, because the queries use them.
- Keep the dashboard `overview-flat` unchanged.

## Done when

- The dashboard `overview-grouped` exists in the project `legacy` and passes the server's validation.
- It has exactly the three groups above, with the right panels in each, and the `Internals` group starts closed. Every panel appears in the layout exactly once.
- The variable `filter` is gone and no query uses a variable that is not defined.
- The eight panels equal those of `overview-flat`.

# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Display settings

## Scenario

The `drifter` team migrated its Grafana dashboard `API Latency` into the Perses project `parity` and applied it. The queries are right, but a reviewer says that the numbers look different from Grafana: a rate shows a plain number, a latency shows the wrong unit, the error ratio turns orange and red far too early, and the dashboard shows only the last hour and never reloads.

## Your task

The Perses dashboard `api-latency` in the project `parity` has display settings that differ from the Grafana dashboard `api-latency`. Find every difference between the two and correct the Perses dashboard so that a reader sees the same numbers, colours and time range:

1. Each panel has the Perses unit that matches its Grafana unit. The Perses unit names are `requests/sec`, `seconds`, `percent-decimal` and `decimal`.
2. The panel `Error ratio` colours its value at the same limits as in Grafana: green below one percent, orange from one percent and red from five percent. Write the limits in the unit of the panel, and write the colours as hex codes (`#73bf69`, `#ff9830`, `#f2495c`).
3. The dashboard shows the same time range and reloads at the same interval as Grafana.

## Constraints

- Do not change a query, a panel title or the variable `handler`.
- Do not change anything in Grafana. Grafana is the reference.
- Work on the existing dashboard; do not delete it and create a new one with another name.

## Done when

- The dashboard `api-latency` in the project `parity` passes the server's validation and still has its four panels.
- Every panel unit equals the mapped Grafana unit.
- The `Error ratio` steps are `0`, `0.01` and `0.05` with the three hex colours.
- The duration and the refresh interval equal the time range and the refresh of the Grafana dashboard.
- Every panel query still returns the same series as its Grafana query.

# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** The dashboard specification

## Scenario

Your team is moving its dashboards from Grafana to Perses. The small Grafana dashboard `HTTP Requests` (uid `http-requests`, folder `Legacy`) is the first one, and the team lead wants it written by hand, so that everyone can see what a clean Perses dashboard looks like before any tool writes one.

Fetch the Grafana dashboard and read it before you start:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/http-requests | jq '.dashboard' > http-requests.json
```

## Your task

In the Perses project `specs`, create a dashboard that matches the Grafana dashboard:

1. Name it `http-requests` (`metadata.name`) and give it the display name `HTTP Requests`.
2. Give it the same default time range and refresh interval as the Grafana dashboard.
3. Add a list variable named `handler` that offers the values of the label `handler`, with an All choice whose value is `.*`.
4. Add one panel for each Grafana panel, with the same panel title, the matching Perses panel plugin (`TimeSeriesChart` for `timeseries`, `StatChart` for `stat`) and a query that returns the same data as the Grafana panel's query.
5. Place both panels in a `Grid` layout.

## Constraints

- Write the dashboard yourself. Do not use `percli migrate` or the Perses import page.
- Do not change the Grafana dashboard, and do not create other datasources: the project's default datasource `prometheus` answers the queries.

## Done when

- The dashboard `http-requests` exists in the project `specs` and passes the server's validation.
- It has exactly one `TimeSeriesChart` and one `StatChart`, and every layout item points at a panel that exists.
- The variable `handler` and the time settings match the Grafana dashboard.
- Each panel's query returns the same series as the Grafana panel with the same title.

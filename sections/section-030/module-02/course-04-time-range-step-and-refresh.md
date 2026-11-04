# Time Range, Step And Refresh

The time range says how far back a panel looks. The step says how far apart the points are. The refresh says how often the panel asks again. A migration changes the first and the third, and the step can differ without any setting being wrong. This part reads all three and shows what each does to the picture.

## What the migration changes

The Perses migration always writes the duration `1h` for the dashboard. Whatever the Grafana dashboard used, such as `now-6h` or `now-7d`, is not copied. The refresh interval of Grafana is dropped as well, so the Perses dashboard does not reload on its own until you set `refresh` on the dashboard.

Read both sides:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency \
  | jq '{from: .dashboard.time.from, to: .dashboard.time.to, refresh: .dashboard.refresh}'
percli describe dashboard api-latency --project parity -ojson | jq '{duration: .spec.duration, refreshInterval: .spec.refreshInterval}'
```

If the first answer is `now-6h` and the second is `1h`, the Perses dashboard shows one sixth of the history. A spike from three hours ago does not appear, and the panel looks calm. The fault is in the dashboard settings, not in a query.

## The step

The **step** is the distance in seconds between two points that Prometheus returns for a range query. A tool picks it from the width of the panel and the length of the time range, so a short range gives a short step. Rates are computed over a window, such as `[5m]`, and a step longer than the window leaves gaps between the points the rate has seen.

Show the effect with the same query at two steps:

```sh
for step in 15 300; do
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query_range \
    --data-urlencode 'query=sum(rate(prometheus_http_requests_total[1m]))' \
    --data-urlencode "start=$(date -v-1H +%s 2>/dev/null || date -d '-1 hour' +%s)" \
    --data-urlencode "end=$(date +%s)" --data-urlencode "step=$step" \
    | jq --arg s "$step" '{step: $s, points: (.data.result[0].values | length)}'
done
```

The step 15 gives about 240 points and the step 300 gives about 12. The line drawn from 12 points hides short spikes that the line from 240 points shows. A window of `1m` with a step of 300 seconds also skips four minutes out of every five.

## Variables that carry the window

Grafana has the variables `$__rate_interval` and `$interval`, which the tool sets from the step. Perses has no variable of the same name, and the migration leaves the text in the query. A query with a variable that nobody defines fails in Perses. A query with a fixed `[5m]` works but no longer follows the step. If the lab environment replaces the variable with a fixed `5m`, compare against `5m` on both sides.

## Set the values on purpose

After a migration, set the duration to the range the Grafana dashboard used and set a refresh interval if it had one. Both are fields on the dashboard spec: `duration` and `refreshInterval`. Decide on the step by looking at the panel: if short spikes matter, keep the step smaller than the window of the rate.

You can now read the time range, the refresh and the step of both dashboards and predict what a reader will miss. The lab that follows asks you to fix several differences in one dashboard.

## Common pitfalls

> [!WARNING]
> - **Leaving the migrated duration at `1h`.** Older events vanish from the picture.
> - **Expecting the refresh to carry over.** The migration drops it.
> - **Choosing a step longer than the rate window.** The line skips data.
> - **Leaving `$__rate_interval` in a query.** Perses does not define it.

## Your mission: Fix The Display Drift In api-latency

You can now compare units, legends, thresholds, calculations and the time range between a Grafana panel and a Perses panel. The graded lab seeds a Perses dashboard `api-latency` in the project `parity` with display settings that differ from Grafana. You find the differences and correct the Perses dashboard so that the reader sees the same numbers and colours.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-109-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-109-lab-030-02
astrona start ats-109-playground-030-02
```

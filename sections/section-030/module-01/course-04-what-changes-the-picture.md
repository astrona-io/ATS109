# What Changes The Picture Besides The Query

Two panels can get exactly the same data and still tell people different things. A stat that shows the error ratio as 0.02 instead of 2 %, a legend that says "p90" for every line, a threshold that turns red at 5 instead of 0.05: the numbers underneath are right, and the panel is wrong. This part goes through the settings that sit between the data and the screen, maps each Grafana setting to its Perses counterpart, and ends with a checklist for every migrated panel.

## Legends

A **legend** is the name a chart gives each series. Grafana builds it from `legendFormat`, and Perses from `seriesNameFormat`, with the same `{{label}}` syntax. The migration copies one into the other, except Grafana's automatic legend `__auto`, which it drops so Perses uses its own default. Compare them for every query:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency | jq '.dashboard' > api-latency.json
percli login http://perses.localtest.me:8080
percli describe dashboard api-latency --project parity -ojson > api-latency-perses.json
jq '[.panels[] | {title, legend: .targets[0].legendFormat}]' api-latency.json
jq '[.spec.panels[] | {title: .spec.display.name, legend: .spec.queries[0].spec.plugin.spec.seriesNameFormat}]' api-latency-perses.json
```

Both lists match: `{{handler}}` for the request rate, `{{handler}} p90` for the duration, and no legend for the two stats. A legend that loses its label, such as plain `p90`, gives every line the same name, and the chart becomes unreadable even though its data is right.

## Units and calculations

A **unit** tells the panel how to print a number: `0.02` as `2 %`, or `1048576` as `1 MiB`. Grafana keeps it in `fieldConfig.defaults.unit`, and Perses in the plugin's `format.unit`. A **calculation** (Grafana: a reducer) turns a series into the one number a stat shows. Print both side by side:

```sh
jq '[.panels[] | {title, unit: .fieldConfig.defaults.unit, reducer: .options.reduceOptions.calcs[0]?}]' api-latency.json
jq '[.spec.panels[] | {title: .spec.display.name, unit: (.spec.plugin.spec.format.unit // .spec.plugin.spec.yAxis.format.unit), calculation: .spec.plugin.spec.calculation}]' api-latency-perses.json
```

The migration maps the names with a shared table. These are the pairs you will meet most:

| Grafana unit | Perses unit | Grafana reducer | Perses calculation |
| --- | --- | --- | --- |
| `percentunit` (0 to 1) | `percent-decimal` | `lastNotNull` | `last-number` |
| `percent` (0 to 100) | `percent` | `last`, `current` | `last` |
| `short`, `none` | `decimal` | `mean`, `avg` | `mean` |
| `bytes` | `bytes` | `firstNotNull` | `first-number` |
| `s`, `ms` | `seconds`, `milliseconds` | `min`, `max` | `min`, `max` |
| `reqps` | `requests/sec` | `sum`, `total` | `sum` |

The pairs are easy to confuse. `percentunit` and `percent-decimal` both mean "a fraction shown as a percentage", so `0.02` prints as `2 %`; `percent` means the number already is a percentage, so `0.02` prints as `0.02 %`. `lastNotNull` skips empty points at the end of a series and `last` does not, so a stat can show nothing where Grafana showed a number. A Grafana unit missing from the table, such as `kbytes`, is dropped, and the panel shows raw numbers.

## Thresholds

**Thresholds** colour a value by the range it falls in. Grafana lists steps with a `value` and a named `color`; the first step has the value `null` and means "everything below the next step". Perses lists steps with a `value` and a colour code:

```sh
jq '.panels[] | select(.title == "Error ratio") | .fieldConfig.defaults.thresholds.steps' api-latency.json
jq '.spec.panels[] | select(.spec.display.name == "Error ratio") | .spec.plugin.spec.thresholds.steps' api-latency-perses.json
```

Grafana has green from `null`, orange from `0.01` and red from `0.05`. Perses has `#73bf69` from `0`, `#ff9830` from `0.01` and `#f2495c` from `0.05`. The migration turns the base step's `null` into `0`, and the named colours into the hex codes Grafana uses for them. Check the values against the unit: thresholds are compared with the raw value, so with `percent-decimal` they must be fractions such as `0.05`, not `5`.

## Time range and refresh

The last difference is the dashboard itself. The migration always sets `duration: 1h` and no refresh interval, whatever Grafana used:

```sh
jq '{time, refresh}' api-latency.json
jq '{duration: .spec.duration, refreshInterval: .spec.refreshInterval}' api-latency-perses.json
```

The Grafana dashboard opens on six hours and refreshes every 30 seconds, and the Perses dashboard in the playground does the same, because whoever finished its migration set both. On a dashboard that still opens on one hour, people see a different window of the same data and may think the history is gone.

## A parity checklist

Work through this list for every panel of a migrated dashboard. Each line names what to compare and where it lives:

| Check | Grafana | Perses |
| --- | --- | --- |
| Same data at a fixed time | `targets[].expr` | `queries[].spec.plugin.spec.query` |
| Same datasource | `targets[].datasource.uid` | `datasource.name` (or the default) |
| Same series names | `legendFormat` | `seriesNameFormat` |
| Same unit | `fieldConfig.defaults.unit` | `format.unit` (stat) or `yAxis.format.unit` (chart) |
| Same single value | `options.reduceOptions.calcs[0]` | `calculation` |
| Same colours | `fieldConfig.defaults.thresholds.steps` | `thresholds.steps` |
| Same window | `time.from`, `refresh` | `duration`, `refreshInterval` |
| Same rate window | `[$__rate_interval]`, `[5m]` | the same text in the query |

You can now check every part of a migrated panel, from the data to the colours. Whether a migration is finished is no longer a matter of opinion: each line of the checklist either matches or does not.

## Common pitfalls

> [!WARNING]
> - **`percent` for a fraction.** A query that returns `0.02` needs `percent-decimal`; `percent` prints `0.02 %`.
> - **Thresholds in the wrong scale.** Thresholds compare raw values. A ratio from 0 to 1 needs thresholds such as `0.05`, whatever the unit prints.
> - **`last` for `lastNotNull`.** `last` takes the final point even when it is empty; the matching calculation is `last-number`.
> - **Leaving `duration: 1h`.** The migration always writes it. Set it back to the Grafana time range.

## Your mission: Restore Query Parity After A Migration

You can now compare every panel of a migrated dashboard with its Grafana original, from the data to the legend and the calculation. The graded lab gives you a migrated `API Latency` dashboard that a colleague edited by hand afterwards, and asks you to find the panels that no longer show what Grafana shows and fix them in Perses.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-109-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-109-lab-030-01
astrona start ats-109-playground-030-01
```

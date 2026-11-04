# Units And Number Formats

A unit decides how a raw number is written. The query returns `0.25`. With the unit seconds the panel can show `250 ms`. With the unit percent it shows `0.25%`. With percent-decimal it shows `25%`. The query is the same in all three, and only one of them is right. This part lists the units of both tools and shows how a wrong unit changes what a reader sees.

## Where the unit lives

In Grafana the unit is in `fieldConfig.defaults.unit` of the panel, with short codes such as `s`, `ms`, `percent`, `percentunit`, `bytes` and `reqps`. In Perses the unit is in the plugin settings under `yAxis.format` for a time series, and under `format` for a stat or gauge. It is an object with a `unit` and, for some units, more fields such as `decimalPlaces`. The Perses names are `seconds`, `milliseconds`, `percent`, `percent-decimal`, `bytes`, `requests/sec` and `decimal`.

The mapping you use most is short:

| Grafana | Perses | Reads as |
| --- | --- | --- |
| `s` | `seconds` | 0.25 becomes 250 ms |
| `ms` | `milliseconds` | 250 stays 250 ms |
| `percent` | `percent` | 25 becomes 25% |
| `percentunit` | `percent-decimal` | 0.25 becomes 25% |
| `bytes` | `bytes` | 1048576 becomes 1 MiB |
| `reqps` | `requests/sec` | 12 becomes 12 req/s |

## Read both units for one panel

Print the unit of each panel in the Grafana dashboard, and then in the Perses dashboard:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency \
  | jq -r '.dashboard.panels[] | "\(.title)\t\(.fieldConfig.defaults.unit)"'
percli describe dashboard api-latency --project parity -ojson \
  | jq -r '.spec.panels | to_entries[] | "\(.value.spec.display.name)\t\(.value.spec.plugin.spec.yAxis.format.unit // .value.spec.plugin.spec.format.unit // "none")"'
```

Put the two lists next to each other and compare them by panel title. Two differences are common. A panel with the Grafana unit `reqps` and the Perses unit `decimal` shows the same number but loses the label `req/s`. A panel with the Grafana unit `s` and the Perses unit `milliseconds` is the worse fault.

## Why seconds as milliseconds is wrong

A duration metric from Prometheus is in seconds. A value of `0.25` means a quarter of a second. A panel set to milliseconds treats `0.25` as a quarter of a millisecond and writes `0.25 ms`. The reader sees a service that is a thousand times faster than it is. No error appears, and no line is empty. This is the kind of fault that survives a visual check by someone who does not know the expected value.

Prove the real value with one query through the proxy:

```sh
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query \
  --data-urlencode 'query=histogram_quantile(0.9, sum(rate(prometheus_http_request_duration_seconds_bucket[5m])) by (le))' \
  | jq -r '.data.result[0].value[1]'
```

The command prints a small number below one, such as `0.0975`. That is seconds. With the unit seconds, the panel writes `97.5 ms`, and with the wrong unit it writes `0.0975 ms`.

## Decimal places and compact numbers

The unit also carries `decimalPlaces` in Perses and `decimals` in Grafana. If one side has a fixed number of decimals and the other has none, the same value reads differently, such as `0.1` and `0.097523`. Compare this field when the unit is equal and the numbers still look different.

You can now read a unit in both tools and tell a harmless difference, such as a lost label, from a harmful one, such as a wrong scale. Still open is how the lines are named.

## Common pitfalls

> [!WARNING]
> - **Comparing only the query.** Equal queries can hide unequal units.
> - **Treating `percent` and `percent-decimal` as the same.** One divides by one hundred and the other does not.
> - **Choosing milliseconds for a seconds metric.** The scale is wrong by a factor of one thousand.
> - **Ignoring decimal places.** Equal units can still print different text.

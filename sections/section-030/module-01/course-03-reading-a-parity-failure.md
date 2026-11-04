# Reading A Parity Failure

A check that always says `MATCH` is not yet a check. You only trust it after you have seen it say `DIFFER` for a real fault, and after you can read why. This part changes one query in a copy of the playground dashboard, runs the comparison again, reads the difference and fixes it.

## Make a copy with one fault

Work on a copy, so the correct dashboard stays as the reference. The command below reads the Perses dashboard, gives the copy a new name, and changes the rate window of the `Error ratio` query from `5m` to `1m`. `gsub` replaces every match of the pattern in the text.

<!-- astrona:playground:renew -->

```sh
percli describe dashboard api-latency --project parity -ojson \
  | jq '.metadata.name = "api-latency-copy"
        | (.spec.panels[] | select(.spec.display.name == "Error ratio") | .spec.queries[0].spec.plugin.spec.query) |= gsub("\\[5m\\]"; "[1m]")' \
  > api-latency-copy.json
percli apply -f api-latency-copy.json
```

The second command stores the dashboard `api-latency-copy` in the project `parity`. It still validates, because `[1m]` is a valid PromQL range. This is the kind of fault a server cannot find.

## Compare one panel

Paste the two helper functions from the loop, or define them again: `series_at` runs an expression through the datasource proxy of the project `parity` at a Unix time, and prints one sorted line for each series.

```sh
series_at() {
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" --data-urlencode "time=$2" \
  | jq -r '.data.result | map({m: (.metric | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(",")), v: .value[1]}) | sort_by(.m) | .[] | "\(.m) \(.v)"'
}
```

Then run the Grafana expression and the expression of the copy at the same moment:

```sh
NOW=$(date +%s)
series_at 'sum(rate(prometheus_http_requests_total{code=~"5.."}[5m])) / sum(rate(prometheus_http_requests_total[5m]))' "$NOW"
series_at 'sum(rate(prometheus_http_requests_total{code=~"5.."}[1m])) / sum(rate(prometheus_http_requests_total[5m]))' "$NOW"
```

Each command prints one line with no labels, because `sum` removes them, and a number. The two numbers differ, or one of them is empty. Prometheus in this environment has few errors, so the numerator can be zero or missing at one window and not at the other. A missing series is the most common reason for a difference you cannot explain, so look at the line count first and the values second.

## How to read a difference

Ask three questions in this order. Do both results have the same number of lines? If not, a label or a filter differs, or a series exists in one window and not in the other. Do the labels match line by line? If not, a `by` clause or a metric name differs. Do the labels match but the numbers differ? Then the function, the window or a unit conversion differs.

Here the line count and the labels are the same or both empty, and only the value differs. The fault is in the window. When you find the cause, write it down as a sentence: "the numerator uses a one-minute window and the Grafana panel uses five minutes".

## Fix and prove

Apply the same query as the original to the copy and compare again:

```sh
percli describe dashboard api-latency --project parity -ojson \
  | jq '.metadata.name = "api-latency-copy"' > api-latency-copy.json
percli apply -f api-latency-copy.json
percli describe dashboard api-latency-copy --project parity -ojson \
  | jq -r '.spec.panels[] | select(.spec.display.name == "Error ratio") | .spec.queries[0].spec.plugin.spec.query'
```

The last command prints the query with `[5m]` in both places. The fix is proved by the comparison, not by reading the query: run `series_at` for both expressions again and the lines are equal.

You can now cause a parity fault, find it by comparing and read what the difference says. Still open is the part of the picture that a query comparison never shows, which the next part covers.

## Common pitfalls

> [!WARNING]
> - **Comparing before you look at the line count.** A missing series is a difference too.
> - **Fixing the Grafana dashboard.** Grafana is the reference in this check.
> - **Calling a small number difference noise.** At one fixed time, equal queries return equal values.
> - **Leaving the copy behind.** Delete `api-latency-copy` with `percli delete dashboard api-latency-copy --project parity` when you are done.

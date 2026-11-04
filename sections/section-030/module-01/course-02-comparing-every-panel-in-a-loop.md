# Comparing Every Panel In A Loop

Checking one panel by hand proves one panel. A dashboard has many, and a check that takes five minutes for each panel is a check people skip. This part turns the comparison into a loop that goes through every Grafana panel, finds the Perses panel with the same title and says whether the two queries return the same series.

## What the loop needs

The loop needs three things. It needs the Grafana dashboard as a file, the Perses dashboard as a file, and one fixed moment for all queries, so a counter that grows does not make equal queries look different. It also needs a function that runs an expression and prints a comparable result.

Save both dashboards and start with the files. `jq` runs on your machine, and the Grafana API is reached from the `tester` pod:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency | jq '.dashboard' > api-latency.json
percli describe dashboard api-latency --project parity -ojson > perses-api-latency.json
jq -r '.panels[].title' api-latency.json
jq -r '.spec.panels[].spec.display.name' perses-api-latency.json
```

Both lists hold the same four titles: `Request rate by handler`, `Request duration p90`, `Error ratio` and `Head series`. The title is the key that joins a Grafana panel to a Perses panel, because Perses keys are only indexes.

## The function that runs an expression

Paste these two functions into your terminal. `series_at` runs an expression through the datasource proxy of the project `parity` at the Unix time given as the second argument, and prints one sorted line for each series. `with_values` replaces the dashboard variables with fixed values, as a grader does: `$__rate_interval` becomes `5m` and `$handler` becomes `.*`.

```sh
series_at() {
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" --data-urlencode "time=$2" \
  | jq -r '.data.result | map({m: (.metric | to_entries | sort_by(.key) | map("\(.key)=\(.value)") | join(",")), v: .value[1]}) | sort_by(.m) | .[] | "\(.m) \(.v)"'
}
with_values() { printf '%s' "$1" | sed -e 's/\$__rate_interval/5m/g' -e 's/\$handler/.*/g'; }
```

Try them on one expression before you loop, so a typo shows up on a single line:

```sh
series_at "$(with_values 'prometheus_tsdb_head_series')" "$(date +%s)"
```

The answer is one line with the labels of the series and a number. If you get no line, the datasource proxy did not answer, and the loop would report every panel as a match between two empty results.

## The loop

The loop reads each Grafana title and expression, looks up the Perses expression of the panel with the same title, runs both at the same moment and compares the output.

```sh
NOW=$(date +%s)
jq -r '.panels[] | [.title, .targets[0].expr] | @tsv' api-latency.json | while IFS=$'\t' read -r title expr; do
  perses_expr=$(jq -r --arg t "$title" '.spec.panels[] | select(.spec.display.name == $t) | .spec.queries[0].spec.plugin.spec.query' perses-api-latency.json)
  if diff <(series_at "$(with_values "$expr")" "$NOW") <(series_at "$(with_values "$perses_expr")" "$NOW") >/dev/null; then
    echo "MATCH   $title"
  else
    echo "DIFFER  $title"
  fi
done
```

On the playground dashboard every line says `MATCH`, because the Perses dashboard there is a correct migration. The loop shows a `DIFFER` line only when the series or a value differs, and the variable `NOW` makes both queries use the same moment.

## What the loop does not check

The loop compares the first query of each panel. A panel with more than one query needs a second pass over `.targets[1]` and the second Perses query. It also compares data, not appearance: a wrong unit, a changed legend or a lost threshold gives `MATCH`. Compare those settings with `jq` on the two files.

You can now check every panel of a dashboard with one command. Still open is what to do when a line says `DIFFER`.

## Common pitfalls

> [!WARNING]
> - **Running the two queries at two moments.** Use one `NOW` for both, or a counter looks different.
> - **Matching panels by position.** Perses keys are indexes, so match on the title.
> - **Trusting a loop over empty results.** Two empty answers are equal, so test one expression first.
> - **Forgetting the variables.** An expression with `$handler` left in it returns an error, not a series.

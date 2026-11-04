# One Check Script

Checks that live in a terminal history get skipped. A script runs the same checks in the same order for every dashboard and prints one report. This part joins the structural checks and the parity check into one shell script that you can run before each release and read in under a minute.

## The parity step

The parity step runs one expression through the datasource proxy and prints the sorted series with their values. Both the Grafana and the Perses expression go through the same proxy at the same Unix time, so the data is the same and only the expression can differ. A helper function holds the call:

<!-- astrona:playground:renew -->

```sh
run_query() {
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/release/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" --data-urlencode "time=$2" \
    | jq -c '[.data.result[] | {m: .metric, v: (.value[1] | tonumber | . * 1000000 | round)}] | sort_by(.m | tostring)'
}
```

The function rounds each value to six decimals by multiplying by 1000000, so that a tiny difference in the last digits does not count as a mismatch. It sorts by the label set, so the order of the series does not matter.

## Replace Grafana variables

A Grafana expression can hold variables that a Perses query does not need. Replace them with fixed values before running it. The rule is the same for every dashboard: `$__rate_interval` and `$interval` become `5m`, `$job` becomes `prometheus`.

```sh
fix_variables() {
  sed -e 's/\$__rate_interval/5m/g' -e 's/\$interval/5m/g' -e 's/\$job/prometheus/g'
}
```

## The script

The script takes the Grafana file and the Perses file. For each Grafana panel it finds the Perses panel with the same title, runs both expressions and prints one line if they differ.

Save this as `release-check.sh`:

```sh
#!/usr/bin/env bash
set -u
GRAFANA_FILE=$1
PERSES_FILE=$2
NOW=$(date +%s)
mismatches=""

run_query() {
  kubectl -n observability exec deploy/tester -- curl -s -X POST \
    http://perses.localtest.me:8080/proxy/projects/release/datasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" --data-urlencode "time=$2" \
    | jq -c '[.data.result[] | {m: .metric, v: (.value[1] | tonumber | . * 1000000 | round)}] | sort_by(.m | tostring)'
}

fix_variables() {
  sed -e 's/\$__rate_interval/5m/g' -e 's/\$interval/5m/g' -e 's/\$job/prometheus/g'
}

while IFS= read -r title; do
  grafana_expr=$(jq -r --arg t "$title" '.panels[] | select(.title == $t) | .targets[0].expr' "$GRAFANA_FILE" | fix_variables)
  perses_expr=$(jq -r --arg t "$title" '.spec.panels[] | select(.spec.display.name == $t) | .spec.queries[0].spec.plugin.spec.query // ""' "$PERSES_FILE" | fix_variables)
  if [ -z "$perses_expr" ]; then
    echo "PLACEHOLDER  $title"
    mismatches="$mismatches$title"$'\n'
    continue
  fi
  if [ "$(run_query "$grafana_expr" "$NOW")" != "$(run_query "$perses_expr" "$NOW")" ]; then
    echo "MISMATCH     $title"
    mismatches="$mismatches$title"$'\n'
  else
    echo "OK           $title"
  fi
done < <(jq -r '.panels[] | select(.type != "row") | .title' "$GRAFANA_FILE")

printf '%s' "$mismatches" > mismatches.txt
```

The script does not stop at the first failure. It prints one line for every panel and keeps the list of failing names in `mismatches.txt`, one per line. Run it:

```sh
chmod +x release-check.sh
./release-check.sh service-health.grafana.json service-health.perses.json
```

The first file comes from the Grafana API with `jq .dashboard`, the second from `percli get dashboard`. The output has one line for each of the five panels, each starting with `OK`, `MISMATCH` or `PLACEHOLDER`.

## Why a time argument matters

A counter keeps growing, so two queries a second apart return different values even if the expressions are equal. The script reads the clock once and sends the same `time` to every query. Without this, a correct panel fails the check for no reason.

## Keep the script small

The script compares only the first query of each panel and works on instant queries. It does not compare units, legends or time ranges, because those are display settings and have their own comparison. A release process that needs them runs the display comparison separately.

You can now run the checks as one command and keep the names of the failing panels. Still open is what to do with each line of the report.

## Common pitfalls

> [!WARNING]
> - **Calling `date` once for each query.** The two times differ and a counter looks different.
> - **Comparing the raw floating point text.** Round before you compare.
> - **Stopping on the first mismatch.** A report lists every failing panel.
> - **Matching panels by position.** Match by title, because the keys are positions that change.

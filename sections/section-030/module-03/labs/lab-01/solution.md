# Solution: Find And Fix The Panels That Differ

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass.

Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Sign in and save both dashboards

```sh
percli login http://perses.localtest.me:8080
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/service-health | jq '.dashboard' > service-health.grafana.json
percli describe dashboard service-health --project release -ojson > service-health.perses.json
```

## Step 2: Write the check

The script reads the clock once, so every query runs at the same time. It runs the Grafana expression and the Perses expression of each panel through the Perses datasource proxy, with `$__rate_interval` replaced by `5m`, and compares the series and values. It prints one line per panel and writes the titles that differ to `mismatches.txt`. Save this as `release-check.sh`:

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

## Step 3: Run it before you correct anything

```sh
chmod +x release-check.sh
./release-check.sh service-health.grafana.json service-health.perses.json
cat mismatches.txt
```

The output has one line for each of the five panels. `Goroutines` and `CPU` start with `MISMATCH`, and the other three start with `OK`. The Perses panel `Goroutines` queries `go_threads` instead of `go_goroutines`, and the panel `CPU` uses the window `[1m]` instead of the Grafana window. The file `mismatches.txt` holds the two titles.

## Step 4: Store the report

The ConfigMap must be created now, from the file written by the first run:

```sh
kubectl -n perses create configmap parity-report --from-file=mismatches=mismatches.txt
```

## Step 5: Correct the two queries

Save this as `fix.jq`:

```jq
(.spec.panels[] | select(.spec.display.name == "Goroutines") | .spec.queries[0].spec.plugin.spec.query) = "go_goroutines{job=\"prometheus\"}"
| (.spec.panels[] | select(.spec.display.name == "CPU") | .spec.queries[0].spec.plugin.spec.query) = "rate(process_cpu_seconds_total{job=\"prometheus\"}[$__rate_interval])"
```

Build the file, validate it and apply it:

```sh
jq -f fix.jq service-health.perses.json > service-health-fixed.json
percli lint -f service-health-fixed.json --online
percli apply -f service-health-fixed.json
```

## Step 6: Run the check again

```sh
percli describe dashboard service-health --project release -ojson > service-health.perses.json
./release-check.sh service-health.grafana.json service-health.perses.json
```

All five lines start with `OK`. Send the lab for grading with `astrona submit -c sections/section-030/module-03/labs/lab-01`.

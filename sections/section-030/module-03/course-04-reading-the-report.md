# Reading The Report

A report is useful when each line tells the reader what to do. The script prints one of three words for each panel, and each word has its own kind of fix. This part reads a report line by line, finds the cause of a mismatch with two queries, and ends with the lab that asks you to fix a dashboard and write the report.

## The three words

`OK` means that the two expressions returned the same series and values at the same time. Nothing to do.

`PLACEHOLDER` means that the Perses panel has no query. The migration could not translate the panel, and a person must write the panel and its whole `queries` list from the Grafana targets.

`MISMATCH` means that both panels have a query and the data differs. The cause is in the expression, and a short comparison finds it.

## Find the cause of a mismatch

When a panel shows `MISMATCH`, print the two expressions next to each other. The Grafana side comes from the Grafana JSON and the Perses side from the Perses JSON:

<!-- astrona:playground:renew -->

```sh
TITLE=Goroutines
jq -r --arg t "$TITLE" '.panels[] | select(.title == $t) | .targets[0].expr' service-health.grafana.json
jq -r --arg t "$TITLE" '.spec.panels[] | select(.spec.display.name == $t) | .spec.queries[0].spec.plugin.spec.query' service-health.perses.json
```

Read both lines. The two common causes show up at once.

The first is **a different metric**. The Grafana panel reads `go_goroutines` and the Perses panel reads `go_threads`. Both are numbers about the Go runtime of Prometheus, both look plausible on a chart, and they are not the same. A person who looks at the chart cannot tell. The fix is to put the Grafana metric in the Perses query.

The second is **a different window**. The Grafana panel has `rate(process_cpu_seconds_total[5m])` and the Perses panel has `rate(process_cpu_seconds_total[1m])`. The shape is the same, and the numbers differ because a shorter window follows the changes more closely. The fix is to put the same window in the Perses query.

## Check a fix

After you change the Perses query, run the check again, and read the line for that panel. Changing the query text is not a fix until the report says `OK`. To check one panel without the whole script, run both expressions at the same time:

```sh
NOW=$(date +%s)
run_query 'go_goroutines' "$NOW"
run_query 'go_goroutines' "$NOW"
```

Two equal outputs prove the data is the same. Replace the second expression with the one from the Perses panel to compare real queries.

## The wrong fixes

Three changes make the report clean without making the dashboard right. Deleting the failing panel from the Perses dashboard removes the line. Changing the Grafana dashboard to match the Perses one makes the two equal, but Grafana is the reference. Pointing the check at a different time hides a counter difference. A report shows the truth only if the reference does not change.

## Write the list of mismatches

The release process asks for the names of the panels that failed before the fix, one per line. The script writes `mismatches.txt` for this. Store it in the cluster where the next person can read it, as a ConfigMap, a Kubernetes object that holds small files as key-value pairs:

```sh
kubectl -n perses create configmap parity-report --from-file=mismatches=mismatches.txt
kubectl -n perses get configmap parity-report -o jsonpath='{.data.mismatches}'
```

The second command prints the two names, one per line. The report is now stored with the cluster and not in the shell history of one person.

You can now read a report, find the cause of a mismatch and store the list of failing panels. The lab that follows asks you to do all three for a dashboard with two faults.

## Common pitfalls

> [!WARNING]
> - **Calling a panel fixed because it looks the same.** Run the check again.
> - **Deleting a failing panel.** The report then hides a missing panel.
> - **Editing the Grafana dashboard to match.** Grafana is the reference.
> - **Storing the report after the fix.** The list must name the panels that failed before.

## Your mission: Find And Fix The Panels That Differ

You can now run a release check and read its report. The graded lab seeds the project `release` with a Grafana and a Perses `service-health` dashboard of five panels. Two Perses panels return different data from their Grafana panels. You find them, fix them in Perses and store the names of the two panels in a ConfigMap.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-109-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-109-lab-030-03
astrona start ats-109-playground-030-03
```

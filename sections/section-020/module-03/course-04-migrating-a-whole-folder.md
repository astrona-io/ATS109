# Migrating A Whole Folder

A team rarely moves one dashboard. It moves a folder of them, and a manual run for each is slow and easy to get wrong. This part finds the dashboards of a Grafana folder through the search API, migrates and applies each one in a loop, and checks the result with counts.

## Find the dashboards

The Grafana search API lists dashboards and the folder each one is in. Ask for all dashboards and keep those in the folder `Legacy`:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s 'http://grafana.observability:3000/api/search?type=dash-db' | jq -r '.[] | select(.folderTitle == "Legacy") | .uid'
```

The answer lists the two uids `prometheus-overview` and `prometheus-storage`. The filter uses the folder title, so a dashboard outside the folder is not migrated. A dashboard in the root of Grafana has no `folderTitle`, and the filter skips it as well.

## The loop

For each uid the loop saves the Grafana dashboard, migrates it into the project `legacy` with the default datasource and applies the result. The `jq` that saves the file runs on your machine.

```sh
for uid in $(kubectl -n observability exec deploy/tester -- curl -s 'http://grafana.observability:3000/api/search?type=dash-db' | jq -r '.[] | select(.folderTitle == "Legacy") | .uid'); do
  kubectl -n observability exec deploy/tester -- curl -s "http://grafana.observability:3000/api/dashboards/uid/$uid" | jq '.dashboard' > "$uid.json"
  percli migrate -f "$uid.json" --online --project legacy --use-default-datasource -o json > "$uid.perses.json"
  percli apply -f "$uid.perses.json"
done
```

Each pass prints the line from `percli apply` for one dashboard. The loop stops being useful the moment one step fails silently, so look at the number of lines: two dashboards need two lines.

## Check the result with counts

A loop that ran is not a loop that worked. Compare the number of dashboards, and for each dashboard the number of panels on both sides:

```sh
percli get dashboards --project legacy
for uid in prometheus-overview prometheus-storage; do
  grafana=$(jq '[.panels[] | select(.type != "row")] + [.panels[] | select(.type == "row") | .panels[]?] | length' "$uid.json")
  perses=$(jq '.spec.panels | length' "$uid.perses.json")
  echo "$uid grafana=$grafana perses=$perses"
done
```

The first command lists the two dashboards in the project. The loop prints `grafana=8 perses=8` for the overview and `grafana=5 perses=5` for the storage dashboard. If a count differs, the migration lost a panel, and you look at that dashboard first.

Then count the datasource names, since a name that does not exist in Perses is the other fault a loop produces:

```sh
jq -r '[.spec.panels[].spec.queries[]?.spec.plugin.spec.datasource.name // "default"] | unique | .[]' prometheus-overview.perses.json prometheus-storage.perses.json
```

The only value printed is `default`, which means that no query names a datasource and all follow the project default.

## What the loop leaves for you

The loop applies dashboards that still hold placeholders: Markdown panels with the text `Migration from Grafana not supported !` and placeholder variables. The migration is complete only when those are replaced. Count them with `grep -c 'not supported' *.perses.json` before you tell the team that a folder is done, and keep the number in the hand-over note.

You can now migrate a folder with one loop and prove that no panel and no datasource name was lost. The lab that follows asks you to do this for the project `shared`.

## Common pitfalls

> [!WARNING]
> - **Filtering by the folder id.** The title is stable between Grafana installs; ids are not.
> - **Applying inside a loop without checking the count.** One failed pass is easy to miss.
> - **Calling the folder done while placeholders remain.** Count them and report the number.
> - **Reusing the file names of an earlier run.** Remove old `.perses.json` files first.

## Your mission: Migrate Every Dashboard In A Folder

You can now find the dashboards of a Grafana folder and migrate them in one loop. The graded lab asks you to move every dashboard of the folder `Legacy` into the project `shared`, keeping the Grafana uid as the dashboard name, with no query that names a datasource that does not exist.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-109-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-109-lab-020-03
astrona start ats-109-playground-020-03
```

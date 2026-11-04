# Solution: Migrate Every Dashboard In A Folder

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass.

Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Sign in

```sh
percli login http://perses.localtest.me:8080
```

## Step 2: Find the dashboards of the folder

The search API returns the folder title of each dashboard. A dashboard in the General folder has none, so the filter skips `scratch-notes`:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s 'http://grafana.observability:3000/api/search?type=dash-db' | jq -r '.[] | select(.folderTitle == "Legacy") | .uid'
```

The command prints `prometheus-overview` and `prometheus-storage`.

## Step 3: Migrate and apply each dashboard

`--project shared` puts the dashboard in the right project, and `--use-default-datasource` removes the datasource name `prom-main` that the Grafana panels carry, because that name does not exist in Perses. Save this as `migrate-folder.sh`:

```sh
for uid in $(kubectl -n observability exec deploy/tester -- curl -s 'http://grafana.observability:3000/api/search?type=dash-db' | jq -r '.[] | select(.folderTitle == "Legacy") | .uid'); do
  kubectl -n observability exec deploy/tester -- curl -s "http://grafana.observability:3000/api/dashboards/uid/$uid" | jq '.dashboard' > "$uid.json"
  percli migrate -f "$uid.json" --online --project shared --use-default-datasource -o json > "$uid.perses.json"
  percli apply -f "$uid.perses.json"
done
```

Run it:

```sh
sh migrate-folder.sh
```

## Step 4: Check the result

```sh
percli get dashboards --project shared
for uid in prometheus-overview prometheus-storage; do
  echo "$uid perses=$(jq '.spec.panels | length' "$uid.perses.json")"
done
```

The list shows the two dashboards, and the panel counts are 8 and 5. Send the lab for grading with `astrona submit -c sections/section-020/module-03/labs/lab-01`.

# Checking The Layout And Counts Of A Migrated Dashboard

A migration that ends without an error can still lose panels or put them in the wrong place. Before you replace a single placeholder, count what you have. This part counts the panels of a Grafana dashboard and of its migrated copy, reads the layout groups, and explains the one difference that is correct.

## Count the panels in Grafana

A Grafana dashboard stores a row as a panel of the type `row`. A collapsed row keeps its panels inside it, and an open row does not. A count of the top-level `panels` list therefore gives the wrong number. Save the dashboard and count the panels that are not rows, at both levels:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-overview | jq '.dashboard' > prometheus-overview.json
jq '[.panels[] | select(.type != "row")] + [.panels[] | select(.type == "row") | .panels[]?] | length' prometheus-overview.json
```

The answer is `8`: seven panels at the top level and one panel inside the collapsed row `Internals`.

## Migrate and count in Perses

Migrate the dashboard through the Perses server and keep the result in a file. The flag `--project legacy` sets the project in the metadata, and `--use-default-datasource` removes the datasource names:

```sh
percli migrate -f prometheus-overview.json --online --project legacy --use-default-datasource -o json > prometheus-overview.perses.json
jq '.spec.panels | length' prometheus-overview.perses.json
jq '.spec.panels | keys' prometheus-overview.perses.json
```

The count is also `8`, so no panel was lost. The keys are the indexes of the top-level panels, `0` to `6`, plus one key for the panel from the collapsed row. That key joins the row index and the position inside the row with an underscore.

## Read the layout groups

The migration makes one `Grid` for all top-level panels and one `Grid` for each collapsed row. List the titles, the number of items and whether each group starts open:

```sh
jq '.spec.layouts | map({title: .spec.display.title, items: (.spec.items | length), open: .spec.display.collapse.open})' prometheus-overview.perses.json
```

The answer has two groups. The group `Panel Group 1` holds seven items and the group `Internals` holds one. The group `Internals` is closed, because the Grafana row was collapsed. An open Grafana row would not make a group at all: its title is lost, and its panels would sit in `Panel Group 1`.

Every item points at a panel with `$ref`. Check that every reference resolves, and that every panel is used once:

```sh
jq -r '[.spec.layouts[].spec.items[].content["$ref"]] | map(split("/")[-1]) | sort' prometheus-overview.perses.json
jq -r '.spec.panels | keys | sort' prometheus-overview.perses.json
```

The two lists are equal. If a list had a key the other lacks, the dashboard would show a gap or fail to draw a panel.

## What is a correct difference

Not every difference between the two dashboards is a fault. The Grafana time range `now-6h`, the refresh interval and the `gridPos` numbers do not come across unchanged. The duration of a migrated dashboard is always `1h`, the refresh is dropped, and the sizes are recalculated for the Perses grid. Only a lost panel, a lost variable or a lost group is a fault.

You can now count panels on both sides and read the groups of a migrated dashboard. Still open is the content of the placeholders, which the next parts replace.

## Common pitfalls

> [!WARNING]
> - **Counting only `.panels` in Grafana.** A collapsed row hides its panels one level deeper.
> - **Expecting the open row to survive.** Only collapsed rows become groups.
> - **Counting rows as panels.** A row is a layout group in Perses, not a panel.
> - **Treating the `1h` duration as a bug.** The migration always writes it.

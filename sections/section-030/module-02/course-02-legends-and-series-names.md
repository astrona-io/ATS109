# Legends And Series Names

A time series chart draws one line per series, and the legend names each line. If the names differ between the two tools, a reader cannot match a line to what they saw in Grafana. This part compares how each tool builds a name, and where the migration leaves the name unset.

## Where the name comes from

In Grafana the name of a line comes from `legendFormat` in the query target. The text `{{handler}}` is replaced with the value of the label `handler`. Without a format, Grafana writes the full metric name and all labels. In Perses the same text is `seriesNameFormat` in the query plugin, with the same double-brace placeholders. Without it, Perses builds a name from the metric name and labels as well.

A query can return many series, so the format decides whether the legend lists ten readable names or ten long strings.

## Compare the formats

Print the format of each query on both sides. Grafana first:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency \
  | jq -r '.dashboard.panels[] | .title as $t | .targets[]? | "\($t)\t\(.legendFormat // "none")"'
```

Then the Perses dashboard:

```sh
percli describe dashboard api-latency --project parity -ojson \
  | jq -r '.spec.panels | to_entries[] | .value.spec.display.name as $n | .value.spec.queries[]? | "\($n)\t\(.spec.plugin.spec.seriesNameFormat // "none")"'
```

Compare the two lists by title. A panel that has `{{handler}}` on one side and `none` on the other will show a legend of long metric strings in one tool and short names in the other. Print both lists for every dashboard you migrate.

## Legend position and values

The legend itself has settings too. In Perses the TimeSeriesChart has `legend.position`, with `bottom` and `right`, and `legend.mode`, with `list` and `table`. A table legend can show values such as `last` and `mean` next to each name. In Grafana the same choices are in `options.legend` with `placement`, `displayMode` and `calcs`. A migration copies the position and the mode, but a table legend loses a calculation that Perses does not have under that name. Check the calculations in the legend when a reader depends on them.

Read the legend settings of the Perses panels:

```sh
percli describe dashboard api-latency --project parity -ojson \
  | jq -r '.spec.panels | to_entries[] | "\(.value.spec.display.name)\t\(.value.spec.plugin.spec.legend // "no legend")"'
```

A panel without a legend object has the tool default, which can differ from the Grafana panel. If Grafana hid the legend on purpose, a missing object in Perses shows it again.

## Names in a single value

A stat or gauge shows one number and a title. If the query returns more than one series, the panel shows one box for each, named by the format. Without a format, the box carries the full label set. Set a format with a short placeholder so that each box reads as a name.

You can now compare how lines and boxes are named, and spot a legend that differs. Still open is the colour that a value turns.

## Common pitfalls

> [!WARNING]
> - **Leaving the series name unset on a query with many series.** The legend becomes a list of long strings.
> - **Assuming an absent legend object means a hidden legend.** It means the default.
> - **Relying on legend calculations after a migration.** Check each one.
> - **Using a label in the format that the query dropped.** The placeholder prints as empty.

# Panel Keys And Layout Items

Every edit of a migrated dashboard starts with finding the right panel, and the panel keys do not help: they are numbers. This part migrates the dashboard `Prometheus Overview`, reads how a key relates to the Grafana panel it came from, and reads the layout items that place the panels.

## Keys are positions

The migration names a panel by its position in the Grafana `panels` list, counted from zero. The seven top-level panels get the keys `0` to `6`. A panel inside a collapsed row gets a key built from the position of the row and the position inside the row, joined by an underscore. The key carries no meaning of its own, so it changes when someone adds a panel to the Grafana dashboard and migrates again.

Migrate the dashboard and save the result:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-overview | jq '.dashboard' > prometheus-overview.json
percli migrate -f prometheus-overview.json --online --project legacy --use-default-datasource -o json > overview.json
jq '.spec.panels | to_entries | map({key, title: .value.spec.display.name, plugin: .value.spec.plugin.kind})' overview.json
```

The list shows the keys in order with the display name and the plugin of each panel. The first three are `Targets up` as a `StatChart`, `Resident memory` as a `GaugeChart` and `Request rate` as a `TimeSeriesChart`. The panels for the heatmap and the state timeline are `Markdown` panels. The title is the only thing that joins a Grafana panel to its Perses panel, so every script in this module joins on the title.

## Layout items

A layout item places one panel. It has `x`, `y`, `width` and `height` on a grid that is 24 units wide, and a `content` with a `$ref` that points at the panel by key. Print the items of the first group with the title of the panel each one points at:

```sh
jq -r '.spec.layouts[0].spec.items[] | "\(.x),\(.y) \(.width)x\(.height) \(.content["$ref"])"' overview.json
```

Each line gives the position, the size and the reference, such as `#/spec/panels/0`. The migration keeps the order and the relative positions of the Grafana panels. It does not promise equal sizes, because the numbers are recalculated for the Perses grid.

To read the reference as a title, look the key up in the `panels` map:

```sh
jq -r '. as $d | .spec.layouts[].spec.items[] | .content["$ref"] | split("/")[-1] | . as $k | $d.spec.panels[$k].spec.display.name' overview.json
```

The command prints the titles in layout order: first the seven top-level panels, then the panel of the collapsed row. This is the list you check against the Grafana dashboard when you reorganise.

## Why the key matters for edits

A `jq` edit that targets `.spec.panels["3"]` works today and breaks as soon as the dashboard is migrated again. Select by title instead, as in `.spec.panels[] | select(.spec.display.name == "Top handlers")`. An edit written that way keeps working after a new migration, and it reads better in a review.

You can now map a key to a title and a layout item to a panel. Still open is how to reorganise one flat group into several named groups.

## Common pitfalls

> [!WARNING]
> - **Editing a panel by its key.** The key is a position and changes when the Grafana dashboard changes.
> - **Reading `width` as pixels.** The grid has 24 columns, and the height is in grid rows.
> - **Forgetting the underscore keys.** The panel from a collapsed row has a key with an underscore, and a script that expects numbers skips it.
> - **Changing a key in `panels` only.** Every `$ref` that points at it must change too.

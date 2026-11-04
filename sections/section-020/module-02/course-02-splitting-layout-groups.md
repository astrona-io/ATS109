# Splitting Layout Groups

The team that built the Grafana dashboard had its own way of grouping panels, and one open row in Grafana may already have been lost in the migration. This part splits the flat group `Panel Group 1` into named groups, sets which groups start closed, and checks that no panel was left out or used twice.

## What a group holds

A `Grid` is one entry of `spec.layouts`. Its `display.title` is the heading that the reader sees, `display.collapse.open` says whether the group starts open or closed, and `items` lists the panels it holds. A closed group still draws its heading, and the reader opens it with a click. The panels are not moved by closing a group; only the layout decides where a panel appears.

The migrated `Prometheus Overview` has two groups. The first holds seven items under `Panel Group 1`, and the second holds the one panel of the collapsed row `Internals`. In Grafana, the first three panels are the headline numbers and the next four are details. You can rebuild that grouping by splitting the first group by title.

## Build the new layout with jq

The expression below creates three groups. Panels are chosen by title, the titles come from the Grafana dashboard, and the group `Internals` is kept as it is. Run it on the migrated file from the earlier steps; if you do not have it, migrate the dashboard first with `percli migrate -f prometheus-overview.json --online --project legacy --use-default-datasource -o json > overview.json`.

<!-- astrona:playground:renew -->

```sh
jq '
  . as $d
  | def ref_title: .content["$ref"] | split("/")[-1] | . as $k | $d.spec.panels[$k].spec.display.name;
  ($d.spec.layouts[0].spec.items) as $flat
  | .metadata.name = "overview-grouped"
  | .spec.layouts = [
      {kind: "Grid", spec: {display: {title: "Summary", collapse: {open: true}},
        items: [$flat[] | select(ref_title | IN("Targets up", "Resident memory", "Request rate"))]}},
      {kind: "Grid", spec: {display: {title: "Details", collapse: {open: true}},
        items: [$flat[] | select(ref_title | IN("Top handlers", "Scrape targets", "Request duration", "Target state"))]}},
      $d.spec.layouts[1]
    ]' overview.json > overview-grouped.json
jq '.spec.layouts | map({title: .spec.display.title, items: (.spec.items | length), open: .spec.display.collapse.open})' overview-grouped.json
```

The summary prints three groups: `Summary` with three items, `Details` with four and `Internals` with one, closed. The seven items of the flat group are now split three and four, and each item moved with its position and size.

## Apply and check the references

Apply the new dashboard and check that every panel is used exactly once:

```sh
percli apply -f overview-grouped.json
jq -r '[.spec.layouts[].spec.items[].content["$ref"] | split("/")[-1]] | sort | join(" ")' overview-grouped.json
jq -r '.spec.panels | keys | sort | join(" ")' overview-grouped.json
```

The two lines list the same keys, which means that no panel is missing from the layout and none is shown twice. If a `select` had a typo in a title, the panel would be missing from every group, and the first line would be shorter than the second one.

Open the dashboard in the browser and read the headings. You may need to move the items so the first group starts at row zero; the positions are kept from the flat layout, so there can be a gap above `Details`. A gap does not make the dashboard invalid. If it bothers the readers, change the `y` of the items.

You can now split a flat group into named groups and prove that no panel was lost. Still open is the other half of the structure, the variables.

## Common pitfalls

> [!WARNING]
> - **Selecting items by position.** Select by title, so the split survives a new migration.
> - **Leaving a panel out of every group.** The dashboard is valid, but the panel is not drawn.
> - **Starting every group closed.** The reader then sees only headings.
> - **Forgetting to rename the dashboard.** Without a new `metadata.name`, the apply replaces the dashboard you started from.

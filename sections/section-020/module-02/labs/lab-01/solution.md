# Solution: Group Migrated Panels Into Rows

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

Start the Perses port-forward in a second terminal before you begin:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

## Step 1: Sign in and save the flat dashboard

```sh
percli login http://perses.localtest.me:8080
percli describe dashboard overview-flat --project legacy -ojson > overview-flat.json
```

## Step 2: Read the panel keys

The layout points at panels by key, and the keys are positions, not names. Print the key and the title of every panel:

```sh
jq -r '.spec.panels | to_entries[] | "\(.key)  \(.value.spec.display.name)"' overview-flat.json
```

The seven top-level panels have the keys `0` to `6`. The panel `Goroutines` was inside a collapsed Grafana row and has the key `7_0`.

## Step 3: Write the filter

The filter looks up the key of each title, takes the layout item of that key (so its position and size stay) and puts the items into a named group. It also removes the variable `filter`. Save this as `group.jq`:

```jq
[.spec.layouts[].spec.items[]] as $items
| (.spec.panels | to_entries | map({key: .key, name: .value.spec.display.name})) as $names
| def group($title; $open; $titles):
    {kind: "Grid", spec: {display: {title: $title, collapse: {open: $open}},
      items: [$titles[] as $t | ($names[] | select(.name == $t) | .key) as $k
              | $items[] | select(.content["$ref"] == "#/spec/panels/\($k)")]}};
  del(.metadata.createdAt, .metadata.updatedAt, .metadata.version)
  | .metadata.name = "overview-grouped"
  | .spec.variables |= map(select(.spec.name != "filter"))
  | .spec.layouts = [
      group("Summary"; true; ["Targets up", "Resident memory", "Request rate"]),
      group("Details"; true; ["Top handlers", "Scrape targets", "Request duration", "Target state"]),
      group("Internals"; false; ["Goroutines"])]
```

## Step 4: Build and apply the new dashboard

```sh
jq -f group.jq overview-flat.json > overview-grouped.json
percli lint -f overview-grouped.json --online
percli apply -f overview-grouped.json
```

The `lint` step asks the server to validate the file without storing it.

## Step 5: Check the result

```sh
percli describe dashboard overview-grouped --project legacy -ojson | jq '.spec.layouts | map({title: .spec.display.title, items: (.spec.items | length), open: .spec.display.collapse.open})'
```

The command prints three groups: `Summary` with 3 items, `Details` with 4 and `Internals` with 1, closed. Send the lab for grading with `astrona submit -c sections/section-020/module-02/labs/lab-01`.

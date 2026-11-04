# Reading The Grafana Dashboard JSON

A migration starts from a Grafana file, so every check you run afterwards starts with reading that file. The Grafana dashboard JSON model has many fields, and only some of them have a counterpart in Perses. This part walks through the model from the top down, names the job of each field, and says which ones a Perses dashboard keeps, renames or drops.

## The top level of a Grafana dashboard

The Grafana HTTP API returns a dashboard wrapped in an object with two fields: `dashboard` holds the model, and `meta` holds facts about the stored copy, such as the folder and who saved it. Only the `dashboard` field is the model. Fetch it from the `tester` pod and list its top-level fields.

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/http-requests | jq '.dashboard' > http-requests.json
jq 'keys' http-requests.json
```

The list holds `annotations`, `editable`, `links`, `panels`, `refresh`, `schemaVersion`, `tags`, `templating`, `time`, `timezone`, `title`, `uid` and `version`. Some fields identify the dashboard, some set how it opens, and some are lists of things on it:

| Field | What it holds |
| --- | --- |
| `uid` | The stable identifier used in URLs and in the API |
| `title` | The name people see |
| `tags` | Free labels used to search and group dashboards |
| `time` | The default time range, with `from` and `to` such as `now-6h` and `now` |
| `refresh` | How often the dashboard reloads, such as `30s` |
| `timezone` | How times are shown, such as `browser` |
| `templating.list` | The variables |
| `annotations.list` | Events drawn over the charts |
| `links` | Links to other dashboards or URLs |
| `panels` | A flat list of panels and rows |
| `schemaVersion` | The version of the model itself |
| `version` | How many times this dashboard was saved |
| `editable` | Whether people can change it in the Grafana interface |

Grafana raises `schemaVersion` whenever the model changes, and it upgrades older dashboards when it loads them. A Perses dashboard has no such field. The plugins that the Perses server runs decide whether a dashboard is valid.

## A panel in the model

Print the two panels with the fields that matter for a migration:

```sh
jq '.panels[] | {id, type, title, gridPos, datasource}' http-requests.json
```

Each panel has an `id` that is unique in the dashboard, a `type` that names the visualisation (`timeseries`, `stat`, `gauge`, `table` and so on), a `title`, and a `gridPos` with `x`, `y`, `w` and `h`. Grafana's grid is 24 units wide. The `datasource` field names the datasource by its type and its uid. This is the first difference with Perses: one Grafana object holds both what the panel shows and where it sits.

A panel has three more groups of fields, and they decide how it looks:

- `targets` is the list of queries. A Prometheus target has `expr` (the PromQL expression), `refId` (a letter that names the query), `legendFormat` (the series name), and optionally `interval` (the minimum step), `instant` and `range`.
- `fieldConfig` holds settings for the values. `fieldConfig.defaults` has the `unit`, the `thresholds`, the number of `decimals`, `mappings` and `color`. `fieldConfig.overrides` changes those settings for single fields.
- `options` holds settings that belong to the visualisation. For a time series it has the `legend` and the `tooltip`. For a stat it has `reduceOptions`, which says how a series becomes one number, and `colorMode`.

Print them for both panels to see the pattern:

```sh
jq '.panels[] | {title, expr: [.targets[].expr], legend: [.targets[].legendFormat], unit: .fieldConfig.defaults.unit, thresholds: .fieldConfig.defaults.thresholds.steps, options: (.options | keys)}' http-requests.json
```

The `Request rate` panel has the unit `reqps`, a legend `{{handler}}` and legend options. The `Targets up` panel has the unit `none`, two threshold steps (red from the base, green from `1`), and the reduce option `lastNotNull`. A Perses plugin needs the same facts, but it keeps each one inside the plugin `spec` that owns it.

## Variables, rows and the rest

The variables live in `templating.list`. Each entry has a `name`, a `type`, and settings that depend on the type. The playground dashboard has one `query` variable.

```sh
jq '.templating.list[] | {name, type, query: .query.query, includeAll, multi, allValue, sort, label}' http-requests.json
```

The variable `handler` runs `label_values(prometheus_http_requests_total, handler)` through the Prometheus datasource. It offers an All choice (`includeAll`) with the value `.*` (`allValue`), and it allows one choice at a time (`multi` is false). Other Grafana variable types are `custom`, `interval`, `textbox`, `constant`, `datasource` and `adhoc`.

A **row** is a panel of type `row`. It has a title and a `collapsed` flag. When the row is collapsed, the panels that belong to it are stored inside the row in a `panels` list. When the row is open, those panels are stored at the top level of `panels`, after the row. This detail matters for migration, and a later module comes back to it.

The model has two more lists. `annotations.list` holds annotation queries, which draw events on the charts. `links` holds dashboard links. Check whether this dashboard uses them:

```sh
jq '{annotations: (.annotations.list | length), links: (.links | length), rows: [.panels[] | select(.type == "row")] | length}' http-requests.json
```

All three counts are zero. A dashboard with annotations loses that part in a migration, because Perses v0.54.0 has no annotations in the dashboard specification.

## What a Perses dashboard keeps

Compare the model with the Perses fields you already know. These parts have a Perses counterpart: `uid`, `title`, `tags`, `time.from`, `refresh`, `templating.list`, `panels`, `gridPos`, `targets`, `fieldConfig.defaults.unit`, `fieldConfig.defaults.thresholds` and the reduce option. These parts have none: `id`, `version`, `schemaVersion`, `editable`, `timezone` and `annotations`. The folder, which is in `meta` and not in the model, becomes the Perses project.

You can now read a Grafana dashboard field by field and say which Perses field holds the same fact. The open question is how the Perses server decides what each of those fields may contain, and the next part builds on the variables and datasources you have already seen.

## Common pitfalls

> [!WARNING]
> - **Reading the API answer as the model.** The model is the `dashboard` field. The `meta` field belongs to Grafana's storage and has no use in a migration.
> - **Assuming open rows keep their panels.** An open row is empty in the file. Its panels sit at the top level.
> - **Forgetting that `refId` is only a label.** It names a query inside one panel. It has no meaning in Perses.
> - **Counting only `panels`.** A collapsed row holds panels one level deeper, so a count of `.panels` can be too low.

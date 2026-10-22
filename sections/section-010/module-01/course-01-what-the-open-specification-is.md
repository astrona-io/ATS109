# What The Open Specification Is

A dashboard file is only useful if more than one program can read it. If the format belongs to one tool, every dashboard you write is locked into that tool. This part explains what the Perses project means by an open specification, then reads a real Perses dashboard through the API and names every top-level field you will meet in the rest of the course.

## A specification anyone can implement

The Perses project publishes the dashboard data model as an **open specification**: a documented format that any tool may read and write, not only the Perses server. The project keeps three implementations of it in step. The Go types are used by the Perses server and `percli`. The CUE definitions are used to check dashboards and to write dashboards as code. The TypeScript types are used by the Perses web interface and the `@perses-dev` npm packages.

The project gives a simple test for compatibility. A tool is compatible with Perses when `percli`, the Perses command-line tool, accepts the dashboards it produces. Such a tool can then use the rest of the Perses tooling: the migration from Grafana, the linter in a build pipeline, and the libraries for dashboards as code.

The specification covers more than the dashboard. Every object the Perses server stores, such as a project or a datasource, is a **resource**: a JSON or YAML document with the same three top-level fields. The next section reads one.

## Read a dashboard through percli

The playground already holds one dashboard, `example`, in the project `specs`. A **project** is the Perses resource that groups dashboards, datasources, variables and other resources, and every dashboard belongs to exactly one project.

<!-- astrona:playground:renew -->

With the port-forward running in your second terminal, sign `percli` in to the Perses server, select the project, and list its dashboards:

```sh
percli login http://perses.localtest.me:8080
percli project specs
percli get dashboards
```

`percli login` stores the server address in `~/.perses/config.json` on your machine; this Perses has no authentication, so it asks for nothing else. `percli project specs` makes `specs` the project for the following commands. The list shows one dashboard, `example`, in the project `specs`, with its age.

Now print the whole dashboard as JSON and look at its top level:

```sh
percli describe dashboard example -ojson | jq 'keys'
percli describe dashboard example -ojson | jq '{kind, metadata: {name: .metadata.name, project: .metadata.project}, spec: (.spec | keys)}'
```

The first command shows three keys: `kind`, `metadata` and `spec`. The second shows that `kind` is `Dashboard`, that `metadata` names the dashboard `example` and its project `specs`, and which fields the `spec` holds: `display`, `duration`, `refreshInterval`, `variables`, `panels` and `layouts`. The server also adds fields such as `createdAt` and `version` to `metadata` when it stores the resource.

## The resource envelope and the dashboard spec

Every Perses resource has the same envelope. `kind` says what the resource is, `metadata` identifies it, and `spec` holds the content. For a dashboard, `metadata.name` is the identifier you use in the API and in `percli`, so it cannot contain spaces. The name people see on screen is `spec.display.name`, which can contain any characters.

The dashboard `spec` has a small number of fields, and each one has one job:

| Field | What it holds |
| --- | --- |
| `display` | `name` and `description` shown in the web interface |
| `duration` | The default time range when the dashboard opens, for example `1h` |
| `refreshInterval` | How often the dashboard reloads its data, for example `1m` (optional) |
| `variables` | A list of variables that queries and other variables can use |
| `panels` | A map from a panel key to a panel: what to show |
| `layouts` | A list of layouts that place the panels: where to show them |
| `datasources` | Optional datasources that only this dashboard can use |

The same dashboard is also served by the REST API, the HTTP interface `percli` itself calls. Read it from the `tester` pod, which is how the graders in this course read your work:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://perses.localtest.me:8080/api/v1/projects/specs/dashboards/example | jq '.spec.panels | keys'
```

The answer lists the two panel keys of the dashboard, `requests` and `targets`. The path follows the resource model: `/api/v1/projects/<project>/dashboards/<name>`. The address is the same inside the cluster as on your machine, because the cluster's DNS server sends `perses.localtest.me` to the Perses Service.

## The same dashboard in Grafana

Grafana stores its dashboards in its own format, the Grafana dashboard JSON model. The playground's Grafana holds a dashboard called `HTTP Requests`. Fetch it through the Grafana HTTP API from the `tester` pod, save it on your machine, and look at its top level:

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/http-requests | jq '.dashboard' > http-requests.json
jq '{uid, title, time, refresh, schemaVersion, panels: [.panels[] | {type, title, gridPos}]}' http-requests.json
```

The result shows the Grafana identifier `uid`, the `title`, a `time` range from `now-6h` to `now`, a `refresh` of `30s`, the `schemaVersion` of the model, and a list of two panels. Each Grafana panel carries its `type` and its own position in `gridPos`. That last point is the main difference you will meet again and again: Grafana mixes what a panel shows with where it sits, and Perses keeps the two apart.

You now know what the open specification is, what every Perses resource looks like at the top, and which fields a dashboard `spec` has. The open question is what goes inside a panel and how a layout finds it.

## Common pitfalls

> [!WARNING]
> - **Using the display name in commands.** `percli` and the API use `metadata.name`. The name with spaces on screen is `spec.display.name` and works in neither.
> - **Forgetting the project.** A dashboard name is only unique inside its project. Run `percli project <name>` first, or pass `--project`.
> - **Running `percli` without the port-forward.** `percli` runs on your machine and reaches Perses only while `kubectl -n perses port-forward svc/perses 8080:8080` is running.
> - **Treating Grafana's `uid` and Perses' `metadata.name` as unrelated.** A migration turns one into the other, so a tidy `uid` gives a tidy Perses name.

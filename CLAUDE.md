# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS109 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Open Specification & Grafana Migration** domain
  of the **Perses** training path (`ATP021`). It is 15% of the path. There is
  no official Perses certification exam; the path's domains and weights are
  Astrona's own, set in `ATP021/path.yaml`.
- **What the domain really tests:** reading and writing the Perses dashboard
  specification by hand, migrating Grafana dashboards with `percli migrate`,
  finishing what the migration could not translate, and proving that the
  migrated dashboard shows the same data. Every explanation should lead to a
  command the reader can run, and every fix should be proved with the Perses
  API: a dashboard that validates, a query that returns the same series as
  its Grafana panel.
- **The three topics:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | The Perses Open Specification | The dashboard specification |
  | 020 | Migrating Grafana Dashboards | `percli migrate` and finishing a migration |
  | 030 | Checking Query Parity | Proving a migrated dashboard shows the same data |

- **The versions:** **Perses v0.54.0** (server and `percli` from the same
  release archive) with the plugin archives bundled in that release
  (Prometheus 0.58.0, TimeSeriesChart 0.13.0, StatChart 0.13.0, GaugeChart
  0.13.0, Table 0.13.0, BarChart 0.13.0, PieChart 0.14.0, Markdown 0.12.0,
  StatusHistoryChart 0.13.0, HeatMapChart 0.5.0, StaticListVariable 0.9.0,
  DatasourceVariable 0.6.0, LogsTable 0.3.0), installed with the `perses` Helm
  chart **0.23.3** and Helm **3.22.1**. **Grafana 12.4.13** holds the legacy
  dashboards, **Prometheus v3.15.1** is the only data source. Perses is
  pre-1.0: names and fields can change between minor releases.
- **The main sources:** the Perses documentation
  (<https://perses.dev/perses/docs/migration/>,
  <https://perses.dev/perses/docs/api/dashboard/>,
  <https://perses.dev/perses/docs/concepts/open-specification/>), and the
  source of `perses/perses` at tag `v0.54.0`: `internal/api/plugin/migrate/`
  (migration engine), `internal/cli/cmd/migrate/migrate.go` (`percli migrate`
  flags), and the `schemas/migrate/migrate.cue` file inside each plugin
  archive. Where the documentation and the source disagree, the source wins
  and the page says what the program does.

### Status: built, not yet run

The first version of this repository was written from the Perses v0.54.0
documentation and source **without a live run**. No playground or lab has been
started, and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

Things to check first on a live run, most important first:

1. That `POST /api/v1/projects/<project>/dashboards` (and `percli apply`)
   rejects a dashboard whose plugin spec breaks the plugin schema (for
   example `calculation: "average"`), and that `POST /api/validate/dashboards`
   exists and answers `200` for a valid dashboard. The section 010 capstone
   and several graders depend on both.
2. That a Grafana `interval` variable migrates to `StaticListVariable` (its
   migration schema matches `type: "custom" | "interval"`), and that an
   `adhoc` variable becomes the `grafana migration not supported` placeholder.
3. That the datasource proxy accepts `POST .../api/v1/query` with form fields
   (graders run instant queries this way).
4. That Grafana 12.4.13 still provisions the classic dashboard JSON
   (`schemaVersion` 39) from files and serves it at `/api/dashboards/uid/<uid>`.

### Migration facts read from the v0.54.0 source

These are the facts the pages teach about `percli migrate`. Keep them in sync
with the source if the version changes.

- **Online and offline.** `--online` sends the Grafana JSON to `POST
  /api/migrate` on the Perses server, which runs the migration schemas of the
  plugins it has loaded. Without `--online`, `--plugin.path` must point at a
  plugin folder; the two flags are mutually exclusive. Other flags:
  `--input NAME=VALUE` (repeatable, replaces Grafana `${NAME}` inputs),
  `--format native|custom-resource|cr`, `--project`,
  `--use-default-datasource`, and the output flag `-o json|yaml`. The
  `cli.md` page still describes an older offline mode with three folders; do
  not teach it.
- **Names and time.** `metadata.name` becomes the Grafana `uid`;
  `spec.display.name` becomes the Grafana `title`; tags are kept;
  `spec.duration` is always `1h` (the Grafana time range and refresh are not
  migrated).
- **Panels.** Panels become a map keyed `"<index>"`, or `"<row index>_<index>"`
  for panels inside a collapsed row. A Grafana panel type is migrated when a
  loaded plugin declares it in `#grafanaType`: `timeseries` and `graph` →
  `TimeSeriesChart`; `stat` → `StatChart`; `gauge` → `GaugeChart`;
  `bargauge` → `BarChart`; `table` and `table-old` → `Table`; `piechart` →
  `PieChart`; `status-history` → `StatusHistoryChart`; `text` → `Markdown`;
  `logs` → `LogsTable`. Any other type (for example `heatmap`,
  `state-timeline`, `xychart`, `barchart`, `geomap`) becomes a `Markdown`
  panel with the text `**Migration from Grafana not supported !**`, and its
  queries are still migrated.
- **Layouts.** Top-level panels go to one `Grid` titled `Panel Group 1`. A
  Grafana row becomes its own `Grid` (title, `collapse.open: !collapsed`,
  `repeatVariable`) only with the panels stored inside it, which Grafana does
  only for **collapsed** rows. Panels under an open row sit at the top level
  in Grafana's JSON, so they land in `Panel Group 1` and the open row, now
  empty, is dropped.
- **Queries.** A target with `expr` becomes `PrometheusTimeSeriesQuery`:
  `expr` → `query`, `legendFormat` → `seriesNameFormat` (dropped when it is
  `__auto`), `interval` → `minStep`, and the target's `datasource.uid` →
  `datasource.name` with kind `PrometheusDatasource`. A target no plugin
  matches becomes a query with the text `migration_from_grafana_not_supported`.
  `--use-default-datasource` removes the datasource `name`, so the project's
  default datasource is used.
- **Variables.** `query` variables: `label_values(...)` →
  `PrometheusLabelValuesVariable`, `label_names()` →
  `PrometheusLabelNamesVariable`, `query_result(... by (label) ...)` →
  `PrometheusPromQLVariable` (other `query_result` forms get the label name
  `migration_from_grafana_not_supported`); `custom` and `interval` →
  `StaticListVariable`; `datasource` → `DatasourceVariable`; `textbox` and
  `constant` → `TextVariable` (constant sets `constant: true`). Any other
  type becomes a `StaticListVariable` with the values `grafana`,
  `migration`, `not`, `supported`. `includeAll`, `multi`, `allValue`, `sort`,
  `hide`, `label`, `description` and the current value are carried over.
- **Units and calculations** follow the shared mapping in the plugins'
  `common/migrate/mapping.cue`: for example `percentunit` →
  `percent-decimal`, `percent` → `percent`, `short` and `none` → `decimal`,
  `bytes` → `bytes`, `reqps` → `requests/sec`, `s` → `seconds`;
  `lastNotNull` → `last-number`, `mean`/`avg` → `mean`, `last`/`current` →
  `last`. A unit missing from the mapping (for example `kbytes`) is dropped,
  so the panel shows raw numbers. Threshold steps keep their values (Grafana's
  base step `null` becomes `0`), and named colours become hex codes
  (`green` → `#73bf69`, `orange` → `#ff9830`, `red` → `#f2495c`).
- **Built-in variables.** The Prometheus plugin 0.58.0 understands
  `$__interval`, `$__interval_ms`, `$__rate_interval`, `$__range`,
  `$__range_s` and `$__range_ms`, so queries that use them run unchanged.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Open specification | The published data model of a Perses dashboard (and its datasources), implemented in Go, CUE and TypeScript, that any tool can read and write |
| Grafana dashboard JSON model | Grafana's own dashboard format: `panels` (a list with `type`, `gridPos`, `targets`, `fieldConfig`, `options`), `templating.list`, `time`, `schemaVersion` |
| Panel (Perses) | An entry in the `spec.panels` map: a display name, a panel plugin (`kind` and `spec`) and a list of queries |
| Layout / Grid | `spec.layouts`: where panels are drawn; a `Grid` holds items with `x`, `y`, `width`, `height` and a `$ref` to a panel key |
| Plugin schema | The CUE definition a plugin ships for its own `spec`; the server checks every panel, query, variable and datasource against it |
| Migration schema | The `migrate.cue` file a plugin ships; it turns one Grafana panel type, query or variable into that plugin's Perses `spec` |
| `percli migrate` | The `percli` command that turns a Grafana dashboard JSON file into a Perses dashboard |
| Placeholder | What the migration writes when it cannot translate something: the Markdown panel `Migration from Grafana not supported !`, the query `migration_from_grafana_not_supported`, the variable values `grafana migration not supported` |
| Query parity | Two panels show the same data: the same expression at the same time returns the same series and values |
| Datasource proxy | The Perses endpoint `/proxy/projects/<project>/datasources/<name>/...` that forwards a request to the datasource |

### The example workloads

| Name | What it is |
| --- | --- |
| Perses (namespace `perses`, Helm release `perses`) | Perses v0.54.0, Service `perses` on port `8080`, authentication off, file database in an `emptyDir` |
| Prometheus (namespace `observability`) | `prom/prometheus:v3.15.1`, Service `prometheus` on port `9090`; it scrapes itself (job `prometheus`) |
| Grafana (namespace `observability`) | `grafana/grafana:12.4.13`, Service `grafana` on port `3000`, anonymous administrator (lab only), Prometheus datasource uid `prom-main`, dashboards provisioned from the ConfigMap `grafana-dashboards` into the folder `Legacy` |
| `tester` (namespace `observability`) | `nicolaka/netshoot:v0.13` with `curl` and `jq`; graders call the Perses and Grafana APIs from here |
| Perses projects | `specs` (section 010), `capstone` (010 capstone), `legacy` (020), `shared` (020 capstone), `parity` (030), `release` (030 capstone); each has the default datasource `prometheus` |

The Grafana dashboards were written for this course, not copied from
grafana.com (see "Generated files"). They use only metrics that Prometheus
exposes about itself:
`up`, `prometheus_http_requests_total`,
`prometheus_http_request_duration_seconds_bucket`,
`process_resident_memory_bytes`, `process_cpu_seconds_total`,
`process_open_fds`, `go_goroutines`, `prometheus_tsdb_head_series`,
`prometheus_tsdb_head_chunks`, `prometheus_tsdb_storage_blocks_bytes`,
`prometheus_tsdb_head_samples_appended_total`.

### Environment facts the text must respect

- **One Perses address everywhere: `http://perses.localtest.me:8080`**, as in
  ATS106: a CoreDNS `rewrite stop` block in the cluster and a port-forward on
  the reader's machine. Never the one-line `rewrite name` form.
- **Grafana is reached two ways.** The reader's browser uses
  `kubectl -n observability port-forward svc/grafana 3000:3000` and
  `http://localhost:3000`. Commands fetch a Grafana dashboard from the
  `tester` pod: `kubectl -n observability exec deploy/tester -- curl -s
  http://grafana.observability:3000/api/dashboards/uid/<uid> | jq .dashboard
  > <uid>.json` (the `jq` runs on the reader's machine).
- **`percli` runs on the reader's machine** and needs the Perses
  port-forward and `percli login http://perses.localtest.me:8080`.
- **Graders and `solution/apply.sh` never use a port-forward.** They call
  `POST /api/migrate`, the dashboard API and the datasource proxy from the
  `tester` pod, which is what `percli migrate --online` does.
- **Parity is checked with instant queries at one time.** Graders replace
  dashboard variables with fixed values (`$__rate_interval` and `$interval`
  → `5m`, `$handler` → `.*`, `$job` → `prometheus`), run the Grafana
  expression and the Perses expression through the same datasource proxy at
  the same Unix time, and compare the sorted series and values.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`), labs
(`config.yaml`, `README.md`, `prerequisites.md`, `question.md`,
`solution.md`, `bootstrap/01-install-perses.sh`, `bootstrap/02-seed-state.sh`,
`manifests/`, `solution/apply.sh`, `testing/wait-for-perses.sh`,
`validation/validate-*.sh`) and one capstone per section.

Each environment's `manifests/` holds `lab-start.yaml` and
`perses-values.yaml` (copied from ATS106), `grafana.yaml`,
`grafana-dashboards/*.json` (the Grafana dashboards), `perses/*.json` (Perses
dashboards the seed applies) and `files/*.json` (a file the task starts from,
stored by the seed in a ConfigMap in the namespace `perses`).

### Generated files

`config.yaml`, `README.md` and `prerequisites.md` of every environment,
`bootstrap/`, `testing/` and everything under `manifests/` were generated by a
script (`gen.py`, `dashboards.py`, `perses.py`) that is not in this
repository. Hand-written: every course page, `docs/overview.md`,
`question.md`, `solution.md`, `solution/apply.sh` and `validation/`. When you
change a shared piece (the install steps, the helpers block at the top of the
scripts, `grafana.yaml`), change it in every environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS109`, domain `Open Specification & Grafana
Migration`, weight `15`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `specification`, `migration`, `parity`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `dashboard-spec`, `panels`,
  `layouts`, `variables`, `datasource-ref`, `plugin-schema`, `validation`,
  `grafana-json`, `percli-migrate`, `migrate-api`, `migration-schema`,
  `placeholder`, `grafana-inputs`, `rows`, `custom-resource`,
  `query-parity`, `legend`, `units`, `thresholds`, `calculations`,
  `time-range`, `datasource-proxy`.
- `resources`: 1 to 4 pages on `perses.dev`. The only place outside links
  are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-010/module-01/playground
astrona destroy ats-109-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-109-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-109-playground-<section>-<module>`, `ats-109-lab-<section>-<module>`,
`ats-109-capstone-<section>`. Graders check **behaviour** (the dashboard
validates on the server, the queries return the same series as Grafana's, no
placeholder is left) and reject the plausible but wrong fix (deleting a
placeholder panel instead of replacing it, changing the Grafana dashboard to
match the Perses one, pointing every query at a datasource that only exists
because it was renamed to the old Grafana uid). A lab's `question.md` and
`solution.md` must match what its `validation/` scripts check.

### Where to find trusted sources

- **Specification:** <https://perses.dev/perses/docs/concepts/open-specification/>,
  <https://perses.dev/perses/docs/api/dashboard/>,
  <https://perses.dev/perses/docs/api/variable/>,
  <https://perses.dev/perses/docs/api/datasource/>
- **Migration:** <https://perses.dev/perses/docs/migration/>,
  <https://perses.dev/perses/docs/api/migrate/>
- **CLI:** <https://perses.dev/perses/docs/cli/>
- **Proxy:** <https://perses.dev/perses/docs/concepts/proxy/>
- **Source:** `perses/perses` at `v0.54.0` and the plugin archives in its
  release.

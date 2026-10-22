# ATS109 — Open Specification & Grafana Migration (Perses)

Course material for the **Open Specification & Grafana Migration** domain of
the Astrona Perses training path ([ATP021](https://github.com/astrona-io/ATP021)),
which is **15% of the path**. Written for **Perses v0.54.0** and
**Grafana 12.4.13**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Perses v0.54.0 documentation and source. None has been started on a
> cluster, and no lab has passed `astrona test` yet. See `CLAUDE.md` for what
> to check first.

The course opens with an Introduction in `sections/intro/`. Everything else
lives under `sections/`. Each section contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining the section into a single
  scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | The Perses Open Specification | 1 | 1 + capstone | The dashboard specification |
| [020](sections/section-020) | Migrating Grafana Dashboards | 1 | 1 + capstone | `percli migrate` and finishing a migration |
| [030](sections/section-030) | Checking Query Parity | 1 | 1 + capstone | Proving a migrated dashboard shows the same data |

The order follows a real migration project. You cannot judge what a migration
produced until you can read the Perses specification, so section 010 comes
first. Section 020 runs the migration and finishes what it cannot translate.
Section 030 proves that the result shows the same data as Grafana did.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Read And Write The Perses Dashboard Specification](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Migrate Grafana Dashboards With percli](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Check That A Migrated Dashboard Shows The Same Data](sections/section-030/module-01/course.md) | 2 | [lab-01](sections/section-030/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair A Hand-Written Dashboard | a layout reference to a missing panel, a calculation the schema refuses, a query on the old Grafana datasource name, a metric name typo |
| [020](sections/section-020/capstone/labs/lab-01) | Migrate A Shared Dashboard Export | a `${DS_PROMETHEUS}` input, an old `graph` panel, a collapsed row to keep, a custom resource to produce |
| [030](sections/section-030/capstone/labs/lab-01) | Prove Parity For A Migrated Dashboard | a wrong unit, wrong thresholds, a query on the wrong metric, a lost time range |

---

## The lab environment

Every playground and lab is a **kind** cluster with:

- **Perses v0.54.0** (Helm chart `perses` 0.23.3) in the namespace `perses`,
  authentication off, reached at `http://perses.localtest.me:8080` (a CoreDNS
  rewrite inside the cluster, a port-forward on the reader's machine);
- **Prometheus v3.15.1**, **Grafana 12.4.13** and a `tester` pod in the
  namespace `observability`. Grafana holds the legacy dashboards, written for
  this course, and its Prometheus datasource has the uid `prom-main`;
- **`percli` v0.54.0** installed on the reader's machine.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state of Perses** with independent checks, and
several of them reject the plausible but wrong fix: deleting a placeholder
panel instead of replacing it, leaving queries on the old Grafana datasource
name, or making the numbers match by changing the Grafana dashboard.

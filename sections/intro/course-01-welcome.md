# Welcome To The Course

This course trains you for the **Open Specification & Grafana Migration** part of the Astrona **Perses** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, `kubectl get` and `kubectl exec`. You can read JSON and pick a field out of it with `jq`, and you can read a PromQL query and say what it returns. You have used Grafana dashboards, or at least seen one. You do not need to know Perses yet. Each new idea is explained the first time it appears.

## What you can do at the end

Many teams that move to Perses already have hundreds of Grafana dashboards. This course does not ask you to remember words. It asks you to read a dashboard file, move a Grafana dashboard to Perses, and prove that nothing changed on the way. The course has three topics, and each one turns into a set of skills you will practise.

The first topic is **the Perses open specification**: the data model of a Perses dashboard. You will learn to:

- Read every part of a Perses dashboard: the resource envelope, panels, queries, layouts and variables.
- Write a Perses dashboard by hand that matches a small Grafana dashboard.
- Explain how plugins define and check their own part of the specification, and how a panel finds its datasource.

The second topic is **migrating Grafana dashboards**. You will learn to:

- Run `percli migrate` against a running Perses server and read what it produced.
- Say which Grafana panels, queries and variables translate, and what the migration writes when it cannot translate something.
- Finish a migration: replace every placeholder, point the queries at the right datasource, and apply the result.

The third topic is **query parity**: proving that a migrated dashboard shows the same data. You will learn to:

- Run the same query through Grafana's original expression and the Perses one at the same moment, and compare the results.
- Find the differences that are not in the query: legends, units, calculations, thresholds and the default time range.

Everything is written for **Perses v0.54.0** and **Grafana 12.4.13**.

## The words this course uses

The pages use Perses', Grafana's, Prometheus' and Kubernetes' own terms, because those are the words you meet in the product, the files and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

**Perses** is an open-source dashboard server and a dashboard specification, and a sandbox project of the Cloud Native Computing Foundation (CNCF). A **dashboard** is a page of **panels**, and each panel shows the result of one or more **queries**. A **datasource** is the connection to the system that answers the queries; in this course it is always Prometheus. A **specification** is the exact data model a file must follow.

The two dashboard formats you will compare every day look like this:

| | Grafana dashboard JSON | Perses dashboard |
| --- | --- | --- |
| Panels | A list; each panel carries its own position (`gridPos`) | A map of named panels; positions live in separate layouts |
| Queries | `targets` with `expr` | `queries` with a query plugin, for example `PrometheusTimeSeriesQuery` |
| Variables | `templating.list` | `variables` with a variable plugin |
| Panel types | `type`, for example `timeseries` | a panel plugin `kind`, for example `TimeSeriesChart` |

## The example setup in your playground

Every playground and lab runs the same small setup. Perses runs in the namespace `perses`. Prometheus, Grafana and a `tester` pod run in the namespace `observability`. Prometheus collects metrics about itself, such as how many HTTP requests it answered, and those are the only metrics the dashboards show.

Grafana holds the old dashboards you will read, migrate and compare. They were written for this course. Grafana's Prometheus datasource has the identifier (uid) `prom-main`, and you will see why that matters when you migrate. In Perses, each module uses its own project, for example `specs` or `legacy`, and each project has a datasource called `prometheus`. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections, in the order of a real migration project: first learn to read the target format, then migrate, then prove the result.

| Section | What it covers |
| --- | --- |
| 010 | The Perses Open Specification |
| 020 | Migrating Grafana Dashboards |
| 030 | Checking Query Parity |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.

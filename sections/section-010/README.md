# Section 010: The Perses Open Specification

A migration tool writes Perses dashboards for you, but you still have to read what it wrote, check it, and fix what it got wrong. That is only possible if you know the format by heart. This section teaches the Perses dashboard specification: the exact data model of a Perses dashboard, which the project publishes so that any tool can read and write it.

You will read a dashboard through the Perses API, write one by hand, and watch the Perses server refuse a dashboard that breaks the rules of one of its plugins. All along, a Grafana dashboard sits next to the Perses one, so you learn the two formats side by side.

**Topic covered:** The dashboard specification

## What you will learn

- What "open specification" means for Perses, and how a tool proves it is compatible.
- The resource envelope every Perses object shares: `kind`, `metadata` and `spec`.
- Panels as a map of named entries, each with a panel plugin and a list of queries.
- Layouts: `Grid` groups whose items point at panels with a JSON reference (`$ref`).
- List and text variables, and the variable plugins that fill a list.
- How a query finds its datasource, and the order of datasource scopes.
- How plugins check their own part of a dashboard with a CUE schema, and how to see the server refuse a value.
- How each part of a Grafana dashboard maps to a part of a Perses dashboard.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Read And Write The Perses Dashboard Specification

The module starts at its landing page, which also launches the playground. The playground holds the Perses project `specs` with the datasource `prometheus` and one example dashboard, and a Grafana dashboard called `HTTP Requests`.

1. What The Open Specification Is
2. Panels, Queries And Layouts
3. Variables, Datasources And Plugin Schemas, followed by the lab **Write A Perses Dashboard By Hand**
4. Summary

## Section capstone: Repair A Hand-Written Dashboard

The capstone is one graded scenario that uses the whole section. A colleague wrote a Perses dashboard file by hand to replace a Grafana dashboard. The server refuses it, and once it is in, some panels stay empty. Four independent faults hide in the file. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-109-capstone-010
```

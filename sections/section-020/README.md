# Section 020: Migrating Grafana Dashboards

Writing dashboards by hand works for one dashboard, not for the hundreds a team collects over the years. Perses ships a migration that turns a Grafana dashboard JSON file into a Perses dashboard. It is fast and it is honest: what it cannot translate, it marks with a placeholder instead of guessing.

This section runs that migration on real Grafana dashboards, reads what came out, and finishes the job: placeholders replaced, queries pointed at the right datasource, and the result applied to a project. You also learn the rules the migration follows, because they decide what you have to fix afterwards.

**Topic covered:** `percli migrate` and finishing a migration

## What you will learn

- How `percli migrate --online` and the `/api/migrate` endpoint turn a Grafana dashboard into a Perses dashboard, and where the translation rules live.
- What happens to the name, title, tags and time range of a dashboard.
- Which Grafana panel types, queries and variable types translate, and to what.
- The three placeholders the migration writes when it cannot translate something.
- Why panels under an open Grafana row lose their row, and collapsed rows keep it.
- How the Grafana datasource uid ends up in every query, and the two ways to fix it.
- How to replace placeholders, migrate into a project, and produce a Kubernetes custom resource.

## The learning path

Each module has a landing page, four short parts, a graded lab right after the part it tests, and a summary. Each module also has its own playground, and the landing page starts it for you.

### 1. Migrate Grafana Dashboards With percli

The module starts at its landing page, which also launches the playground. The playground holds two Grafana dashboards, `Prometheus Overview` and `Prometheus Storage`, and an empty Perses project `legacy` with the datasource `prometheus`.

1. How Migration Works
2. Translating Panels And Variables
3. Checking The Layout And Counts Of A Migrated Dashboard
4. Finishing A Migration, followed by the lab **Migrate Two Grafana Dashboards**
5. Summary

### 2. Read And Reshape A Migrated Dashboard

The module starts at its landing page, which also launches the playground. The playground holds a Grafana dashboard with collapsed and open rows and the Perses project `legacy`.

1. Panel Keys And Layout Items
2. Splitting Layout Groups
3. Variables After Migration
4. Cleaning Up Variables, followed by the lab **Group Migrated Panels Into Rows**
5. Summary

### 3. Migrate With Inputs, Projects And Output Formats

The module starts at its landing page, which also launches the playground. The playground holds a Grafana folder with several dashboards and the Perses project `shared`.

1. Grafana Inputs And The Input Flag
2. Projects And The Default Datasource
3. Output Formats And Custom Resources
4. Migrating A Whole Folder, followed by the lab **Migrate Every Dashboard In A Folder**
5. Summary

## Section capstone: Migrate A Shared Dashboard Export

The capstone is one graded scenario that uses the whole section. The platform team shared a Grafana dashboard exported "for sharing externally", so its datasource is an input instead of a real uid. It uses an old panel type, keeps half its panels in a collapsed row, and has to land in Perses both as a dashboard and as a Kubernetes custom resource. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-109-capstone-020
```

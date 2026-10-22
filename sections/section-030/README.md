# Section 030: Checking Query Parity

A migrated dashboard that opens without an error is not yet a correct dashboard. A rate window changed by one character, a legend that no longer names the series, a unit that turns 0.02 into "0.02 %" instead of "2 %": each one makes the Perses dashboard tell a different story from the Grafana dashboard people trusted. This section teaches you to prove that a migrated dashboard shows the same data, and to find the differences that are not in the data at all.

**Topic covered:** Proving a migrated dashboard shows the same data

## What you will learn

- What query parity means, and why a fair comparison fixes the time and the variable values.
- Running a Grafana expression through Grafana's query API, and a Perses expression through the Perses datasource proxy.
- Comparing the series and values of two instant queries with `jq`.
- How the legend, the unit, the calculation and the thresholds of a panel change what people see, even when the data is the same.
- How the Grafana units and reducers map to Perses units and calculations.
- A parity checklist to work through for every migrated panel.

## The learning path

The module has a landing page, two short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, and the landing page starts it for you.

### 1. Check That A Migrated Dashboard Shows The Same Data

The module starts at its landing page, which also launches the playground. The playground holds the Grafana dashboard `API Latency` and its migrated Perses version in the project `parity`.

1. Running The Same Query In Both Tools
2. What Changes The Picture Besides The Query, followed by the lab **Restore Query Parity After A Migration**
3. Summary

## Section capstone: Prove Parity For A Migrated Dashboard

The capstone is one graded scenario that uses the whole section. A release candidate of the migrated `API Latency` dashboard waits in the project `release`. Before it replaces the Grafana dashboard, you must check it panel by panel against Grafana: data, units, thresholds and time settings. Four independent differences are hidden in it. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS109.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-109-capstone-030
```

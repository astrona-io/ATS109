---
estimated_duration: 35m
---

# Prove Parity For A Migrated Dashboard

- **ID:** CAPSTONE
- **Slug:** ats-109-capstone-030
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Read `question.md` for the task; `solution.md` is the walkthrough.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-109-capstone-030
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation and starting state (generated) |
| `manifests/` | Workloads, Grafana dashboards and Perses resources (generated) |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/` | Waits for Perses and Grafana before the reference solution (generated) |
| `validation/` | Grading scripts, one per check |

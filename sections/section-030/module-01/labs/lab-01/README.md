---
estimated_duration: 25m
---

# Restore Query Parity After A Migration

- **ID:** LAB
- **Slug:** ats-109-lab-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Read `question.md` for the task; `solution.md` is the walkthrough.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-109-lab-030-01
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

# Migrate Grafana Dashboards With percli — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-109-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A sandbox with Perses v0.54.0, Prometheus and Grafana 12.4.13 holding the
legacy dashboards. Nothing to submit. `docs/overview.md` is the learner page.

## Run it

```sh
astrona run -c .
astrona destroy ats-109-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Installs everything and creates the starting resources (generated) |
| `manifests/` | Prometheus and tester, Perses Helm values, Grafana and its dashboards, Perses resources (generated) |
| `docs/overview.md` | What the environment contains and ideas to try |

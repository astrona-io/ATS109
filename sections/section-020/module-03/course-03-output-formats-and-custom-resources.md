# Output Formats And Custom Resources

The same migration can write a dashboard in more than one shape. The native shape is what the Perses API stores. The custom resource shape is a Kubernetes object that the Perses operator turns into a dashboard. This part writes both from one Grafana dashboard and reads the fields that differ.

## Two flags control the shape

The flag `--format` has the values `native`, `custom-resource` and the short form `cr`. The flag `-o` or `--output` chooses between `json` and `yaml`. They are independent: the format says which object is written, and the output says how it is printed. Without `--format`, the result is the native dashboard.

Write the native dashboard as YAML and read its first fields:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/prometheus-storage | jq '.dashboard' > prometheus-storage.json
percli migrate -f prometheus-storage.json --online --project legacy --use-default-datasource -o yaml > storage-native.yaml
head -8 storage-native.yaml
```

The head shows the three parts of the envelope: `kind: Dashboard`, a `metadata` block with the name `prometheus-storage` and the project `legacy`, and the start of the `spec`. This is the file `percli apply` takes.

## The custom resource

Write the same dashboard in the custom resource format:

```sh
percli migrate -f prometheus-storage.json --online --project legacy --use-default-datasource --format cr -o yaml > storage-cr.yaml
grep -nE '^(apiVersion|kind):|^  (name|namespace):' storage-cr.yaml
```

The lines show an `apiVersion` for the Perses operator, the kind `PersesDashboard`, and the name and namespace in the metadata. A custom resource is a Kubernetes object, so its namespace is where it lives in the cluster, and the project name is used for it. The `spec` below it holds the same panels, variables and layouts as the native dashboard, with the dashboard name in the metadata and not in the spec.

To see how close the two are, compare the `spec` of both with `jq` after you read them as JSON:

```sh
percli migrate -f prometheus-storage.json --online --project legacy --use-default-datasource --format cr -o json | jq '.spec.panels | length'
percli migrate -f prometheus-storage.json --online --project legacy --use-default-datasource -o json | jq '.spec.panels | length'
```

Both counts are the same number. Only the envelope differs.

## Which one to apply

Use `percli apply` with the native file when you talk to the Perses API directly, which is what the lab environment does. Use the custom resource when a GitOps tool, such as a controller that applies files from a repository with `kubectl`, manages the dashboards, because a Kubernetes object fits the existing review and rollout process. The cluster in this course has no Perses operator, so you read the custom resource but do not apply it with `kubectl`.

Do not edit the two shapes by hand in parallel. Keep one of them as the source, and generate the other from the same Grafana file when you need it.

You can now write the result of a migration in both shapes and tell them apart. Still open is how to repeat the work for every dashboard in a folder.

## Common pitfalls

> [!WARNING]
> - **Applying a custom resource with `percli apply`.** The command expects the native shape.
> - **Reading `-o` as the format.** `-o` picks JSON or YAML, and `--format` picks the object.
> - **Maintaining both shapes by hand.** They drift apart.
> - **Leaving out `--project` for the custom resource.** The namespace is then empty.

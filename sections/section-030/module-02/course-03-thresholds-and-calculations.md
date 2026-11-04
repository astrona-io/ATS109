# Thresholds And Calculations

Thresholds colour a value once it passes a limit. A calculation reduces a whole series to one number for a stat or gauge. Both change what the reader concludes, and both are written in the unit of the value. This part compares them between the two tools and shows how a wrong unit turns a safe value red.

## How thresholds are written

A threshold has steps. Each step has a colour and a value from which it applies. The first step has no value and is the base colour. In Grafana the steps are under `fieldConfig.defaults.thresholds.steps`, with `value: null` for the base. In Perses they are under `thresholds.steps` in the plugin settings, with the base step having no value and the others having a number. Perses also has `thresholds.mode`, with `absolute` and `percent`.

The value of a step is in the unit of the panel. If the panel unit is percent-decimal, then `0.05` means five percent. If the unit is percent, then `5` means five percent. Mixing the two moves the limit by a factor of one hundred.

## Compare the steps

Print the steps of each panel on both sides. Grafana first:

<!-- astrona:playground:renew -->

```sh
kubectl -n observability exec deploy/tester -- \
  curl -s http://grafana.observability:3000/api/dashboards/uid/api-latency \
  | jq -c '.dashboard.panels[] | {title, steps: [.fieldConfig.defaults.thresholds.steps[]? | [.value, .color]]}'
```

Then Perses:

```sh
percli describe dashboard api-latency --project parity -ojson \
  | jq -c '.spec.panels | to_entries[] | {title: .value.spec.display.name, steps: [.value.spec.plugin.spec.thresholds.steps[]? | [.value, .color]]}'
```

Take an error ratio panel as an example. The Grafana panel has the steps `[null, green]`, `[0.01, orange]` and `[0.05, red]` with the unit percentunit. A Perses panel can have the steps at `1` and `5` with the unit percent. The numbers look different, but the question that matters is whether both turn red at five percent. They do not agree on the unit, so a check of the numbers alone is not enough: write the limit in percent for both and compare that.

## Colours

A colour is a name or a hex code. Grafana uses names such as `green`, `orange` and `red` and maps them to its own palette. Perses takes the hex code as written. A migration copies the Grafana name, and the Perses palette can render it in another shade. When a team checks that the colours match, use the hex code on both sides, so the shade is not a choice of the tool.

## Calculations

A stat or gauge needs a calculation, because a series has many points and the panel shows one. The common ones are `last`, `mean`, `max`, `min` and `sum`. In Grafana, `reduceOptions.calcs` holds a list, such as `["lastNotNull"]`. In Perses, `calculation` holds a single name, such as `last-number`. The names differ: `lastNotNull` becomes `last-number` and `mean` stays `mean`.

Show how much the calculation matters. Compute the last value and the mean of the same series:

```sh
kubectl -n observability exec deploy/tester -- curl -s -X POST \
  http://perses.localtest.me:8080/proxy/projects/parity/datasources/prometheus/api/v1/query_range \
  --data-urlencode 'query=sum(rate(prometheus_http_requests_total[5m]))' \
  --data-urlencode "start=$(date -v-1H +%s 2>/dev/null || date -d '-1 hour' +%s)" \
  --data-urlencode "end=$(date +%s)" --data-urlencode 'step=60' \
  | jq '[.data.result[0].values[][1] | tonumber] | {last: .[-1], mean: (add / length)}'
```

The two numbers differ. A stat set to `last-number` shows the first and a stat set to `mean` shows the second, and the colour of the stat follows whichever is shown.

You can now compare steps in a single unit, and compare calculations by their effect on the number. Still open is the time window that the numbers cover.

## Common pitfalls

> [!WARNING]
> - **Comparing step numbers without comparing units.** Percent and percent-decimal differ by a factor of one hundred.
> - **Comparing colour names across tools.** Compare hex codes.
> - **Changing the calculation of a stat during a migration.** The shown value changes.
> - **Forgetting that the base step has no value.** A base step with a number is a different rule.

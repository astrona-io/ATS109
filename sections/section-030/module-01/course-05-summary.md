# Summary

A migrated dashboard is only finished when it shows what the Grafana dashboard showed. Query parity means that the same expression, with the same variable values, run at the same moment, returns the same series and values in both tools. Looking at two charts is not enough, because a one-minute rate and a five-minute rate can look alike on screen.

## What you learned

A fair comparison fixes three things: the time, given as a Unix timestamp to an instant query; every dashboard variable, such as `$handler`, set to the same value in both expressions; and built-in variables such as `$__rate_interval`, replaced by a fixed window. Grafana runs a panel's expression through `POST /api/ds/query`, with the datasource named by its uid and the time in milliseconds. Perses runs it through its datasource proxy at `/proxy/projects/<project>/datasources/<name>/api/v1/query`, which forwards the request to Prometheus. When both tools use the same Prometheus, sorting the series and values of the two answers and comparing them as text proves or disproves parity.

The data is only half of what a panel shows. The legend comes from `legendFormat` in Grafana and `seriesNameFormat` in Perses. The unit and the calculation follow a mapping: `percentunit` becomes `percent-decimal`, `short` becomes `decimal`, `reqps` becomes `requests/sec`, `lastNotNull` becomes `last-number`, and a unit outside the mapping, such as `kbytes`, is dropped. Thresholds keep their values, with Grafana's base step `null` becoming `0`, and they compare raw values, so a ratio needs fractions such as `0.05`. The migration always resets the time range to one hour and drops the refresh interval. The key facts to remember are these:

- `percent` prints a value as it is; `percent-decimal` multiplies a fraction by 100.
- `last` takes the final point even when it is empty; `last-number` skips empty points, like Grafana's `lastNotNull`.
- Prometheus takes Unix seconds; Grafana's query API takes milliseconds.
- For every panel, check the data, the datasource, the legend, the unit, the calculation, the thresholds and the time window.

<!-- astrona:playground:destroy -->

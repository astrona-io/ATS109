# Summary

A migrated dashboard is ready for release when it passes four checks in a fixed order. The server accepts it, no placeholder is left, every query reaches a datasource, and every panel returns the same data as its Grafana panel. The order runs from the cheapest check to the most expensive one, and each check catches a different kind of fault with a different fix.

The structural checks read only the dashboard JSON. A placeholder is a Markdown panel with the migration text, a query with the placeholder text, or a static list variable with the four placeholder values. A datasource fault is a name in a query that exists in no scope. A variable fault is a name used in a query that no variable defines. Each check prints panel or variable names, so a person knows what to fix.

The parity check runs the Grafana expression and the Perses expression through the same datasource proxy at the same Unix time. Fixed values replace the dashboard variables, the values are rounded, and the series are sorted. The clock is read once, because a counter changes from one second to the next.

One script joins the checks and prints a line for each panel. A line is `OK`, `PLACEHOLDER` or `MISMATCH`. The script keeps going after a failure and writes the names of the failing panels to a file, one per line.

A mismatch has a cause that two printed expressions show: a different metric with a similar name, or a different rate window. The fix goes into the Perses query, and the check runs again. Deleting the failing panel, editing Grafana to match, or choosing another time only hides the fault. The list of failing panels is stored in a ConfigMap so the next person can read it.

Key facts:

- Run the cheap structural checks before the data check.
- Match panels by title, not by position.
- Read the clock once for all queries.
- Grafana is the reference; fix the Perses side.

<!-- astrona:playground:destroy -->

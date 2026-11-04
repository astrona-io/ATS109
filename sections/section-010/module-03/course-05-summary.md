# Summary

A variable turns a fixed dashboard into one that a reader can steer. The `ListVariable` offers a list of values that a plugin fills, such as the values of a label in Prometheus or a fixed list. The `TextVariable` holds one value that the reader types, or a constant. A query uses a variable by name with a dollar sign, and Perses replaces the name with the chosen value before it sends the query.

A list can depend on another list. A matcher on the label values plugin may use the first variable, so the second list only offers values that exist for the first choice. The All choice needs a custom value, because a query written with an equality match cannot take a list, while a regular expression match with `.*` accepts every value.

A datasource can be defined in three places: inside the dashboard, in the project, and globally. A query that names a datasource looks it up in that order, and a query that names none uses the default datasource. A name that exists in no scope leaves the panel empty even though the dashboard is valid.

The server can check a dashboard before it is stored. The validation endpoint and `percli lint --online` run the plugin schemas against the file and report the path of the first field that breaks one. A valid dashboard can still show no data, so the proxy query remains the proof that a panel works.

Key facts:

- Variables are defined in `spec.variables` and used as `$name` in queries.
- `customAllValue` is what a query receives when the reader picks All.
- Datasource lookup runs dashboard, then project, then global.
- Validation checks structure and schemas, not whether a query returns data.

<!-- astrona:playground:destroy -->

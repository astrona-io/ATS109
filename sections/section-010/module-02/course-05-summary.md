# Summary

A panel has two halves. The queries decide which data the panel gets, and the panel plugin decides how that data is drawn. The `spec` of the plugin holds only the settings that plugin understands, and the Perses server refuses a setting that its schema does not know.

The time series chart groups its settings in four fields: the legend, the visual style, the vertical axis and the thresholds. The stat, gauge, bar and pie charts show one value for each series, so they need a calculation that reduces a series to one number and a format that prints it. The `-number` calculations skip empty points, which makes `last-number` the safe way to show the latest value.

A unit is a print format, and it must follow the scale of the query result. A fraction between 0 and 1 needs `percent-decimal`, and a value between 0 and 100 needs `percent`. Threshold steps use the same scale as the value, so a step list written for percentages colours nothing on a fraction. The first step carries the colour for normal values.

The table lists one row per series, the Markdown panel holds text and has no queries, and the pie chart shows parts of one total. A Markdown panel is also what a migration writes for a panel it cannot translate, so the text of the panel tells a note from a placeholder. The server cannot check that a plugin fits the question, so the reader chooses the plugin from the question the panel answers.

Key facts:

- Chart settings live in `plugin.spec`, never next to `plugin`.
- `calculation` and `format` are required to get a predictable stat, gauge, bar or pie chart.
- The unit goes in `yAxis.format.unit` on a time series and in `format.unit` on the other charts.
- Thresholds compare against the raw number after the calculation.

<!-- astrona:playground:destroy -->

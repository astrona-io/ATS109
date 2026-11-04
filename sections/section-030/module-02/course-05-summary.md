# Summary

Two panels with the same query can show different things. The reader sees the unit, the line names, the colours, the single value and the time window, and each of these is a setting that a migration can copy wrongly or not at all.

The unit decides how a number is written. A duration metric is in seconds, so a panel with milliseconds shows a value a thousand times too small and gives no error. Percent and percent-decimal differ by a factor of one hundred. The unit sits in a different place in each tool, so compare the unit of every panel by title.

The legend names the lines. A name comes from a format with placeholders for labels. If the format is missing, the legend lists long metric strings. A panel with no legend object takes the tool default, which can show a legend that Grafana had hidden.

Thresholds are steps with a colour and a value, and the value is in the unit of the panel. A step at 5 means five percent in one unit and five hundred percent in another. Compare the limits in one unit and compare colours as hex codes. A calculation reduces a series to one number, and the choice between the last value and the mean changes both the number and the colour.

The migration always writes a one hour duration and drops the refresh interval. A spike from earlier simply does not appear. The step spaces the points, and a step longer than the rate window skips data.

Key facts:

- Seconds shown as milliseconds is a fault, not a style.
- Threshold values are written in the unit of the panel.
- A migrated dashboard has a duration of `1h` and no refresh.
- A stat shows one number, picked by its calculation.

<!-- astrona:playground:destroy -->

# Summary

A migration keeps the data and the order of the panels, and drops much of the structure that people used to find their way around. The panel keys are positions in the Grafana list, so they carry no meaning and change when the Grafana dashboard changes. A script that edits a migrated dashboard therefore selects a panel by its title, which is the only thing that joins a Grafana panel to its Perses panel.

The layout is a list of `Grid` groups. Each group has a heading, a flag for starting open or closed, and a list of items that point at panels. A migration puts all top-level panels in one group and makes a separate group only for each collapsed row. Splitting the flat group into named groups is a change to the layout alone, and the proof is that every panel key is used exactly once.

Variables follow one rule for each Grafana type. Label queries become label plugins, custom and interval lists become static lists, a data source variable becomes a datasource variable, and text boxes become text variables. A type with no equivalent, such as an ad hoc filter, becomes a list of placeholder words. The settings for an All choice, multiple choice, sort order and the current value are carried over, but a missing custom All value leaves the query with a long list.

Cleaning up is a check and a small edit. List the names that the queries use, list the defined names, and remove a placeholder only when no query uses it. Built-in variables such as the rate interval need no definition. A change that removes a feature, such as an ad hoc filter, is worth a word with the team that uses the dashboard.

Key facts:

- A key is a position, so select panels by display name.
- Only a collapsed Grafana row becomes its own group.
- A placeholder variable lists the words `grafana`, `migration`, `not` and `supported`.
- A used but undefined variable is stored without an error and fails when the panel runs.

<!-- astrona:playground:destroy -->

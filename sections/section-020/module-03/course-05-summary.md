# Summary

A migration copies the datasource names from Grafana, and a name that does not exist in Perses leaves a panel empty while the dashboard stays valid. Three choices avoid this. The input flag replaces the placeholders of a shared export with a Perses datasource name, a name option writes that name into each query, and the default datasource option removes the name so that the project default is used.

A Grafana export that was made for sharing lists its inputs in a top-level field and writes each one as a dollar-and-braces reference. Migrated without help, the reference becomes the name of a datasource. Reading the list of inputs first, and giving every one a value, is the only safe way to migrate such a file.

The project flag writes the project into the metadata of the result. A file that carries its project can be applied from any shell, while a file without one depends on the project that the person selected. Choosing between a name and the default is a choice about change: a name keeps working when the project later gets a second datasource, and the default follows the project without touching the dashboard.

The result can be written as a native dashboard, which the Perses API stores, or as a custom resource, which a Kubernetes operator turns into a dashboard. The two differ only in the envelope. One of them is the source, and the other is generated from the same Grafana file.

A folder is migrated with a loop over the Grafana search results. The loop proves nothing by itself, so the check is a count of dashboards, a count of panels on both sides and a list of the datasource names. The folder is finished only when the placeholders left behind are replaced.

Key facts:

- An input is replaced with a value from the command line or the request, never by the server.
- Without `--project`, the project comes from the shell of the person who applies.
- The native and the custom resource shapes hold the same spec.
- A loop over a folder needs a check of counts and datasource names after it.

<!-- astrona:playground:destroy -->

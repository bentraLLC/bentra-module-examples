# JSON tools

Merge JSON objects and pick fields out of them. Bash and `jq` (both on every Bentra runner);
no dependencies and no connection.

| Action | Inputs | Outputs |
|---|---|---|
| `merge` | `base`, `overlay` (objects) | `result` (deep merge, overlay wins) |
| `pick` | `object`, `keys` | `result`, `missing` (requested keys not in the object) |

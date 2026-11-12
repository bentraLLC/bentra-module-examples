# Text tools

Turns names into URL- and resource-safe slugs. Node.js, using the `slugify` package.

| Action | Inputs | Outputs |
|---|---|---|
| `slugify` | `text`, `max_length` (default 63) | `slug` |

Dependencies are in `package.json` with a committed `package-lock.json`; the runner installs
them with `npm ci`. Entrypoints are CommonJS (`require`).

# SHA tool

Hashes text with SHA-256. Shows a **binary** module: any compiled language (Go, Rust, …)
works the same way.

| Action | Inputs | Outputs |
|---|---|---|
| `sha256` | `text` | `sha256` (hex), `bytes` |

The runner runs `bin/<os>-<arch>/<entrypoint>` for its own platform, so `runtime.platforms`
lists every binary in `bin/`. Rebuild and commit them with `make build` whenever `src/`
changes.

# Building Bentra modules

Instructions for coding agents writing [Bentra](https://bentralabs.com) modules. Copy this file
into your repository (as `AGENTS.md`, `CLAUDE.md` or your agent's equivalent) and keep it next
to your modules.

A **module** is a versioned package of **actions** that Bentra workflow steps call. It lives in
one folder of a Git repository (its **working directory**), is registered in an organization's
private registry, and is released as immutable versions that workflows pin exactly.

## Rules

1. **The working directory is the boundary.** Bentra lists, reads and packages only the module's
   folder and what is nested in it. Nothing outside exists for the module: no `../` paths, no
   shared code in a parent folder, no symlinks. Copy shared helpers into each module, or publish
   them as a package and list it as a dependency.
2. **One folder per module**, holding `module.yaml` (or `module.yml`, never both). Put modules
   under `bentra/modules/<name>/`; `<name>` should equal `metadata.name`.
3. **`module.yaml` is the only source of the module's details**: name, display name,
   description, category, icon, and its **version**.
4. **The version lives in module.yaml** (`version: 1.2.0`, strict semver: `MAJOR.MINOR.PATCH`
   or a pre-release like `1.3.0-rc.1`, no `v`). Bentra releases every version it sees on the
   tracked branch or tag that it hasn't released yet. **Bumping `version` and pushing is
   releasing**: confirm the new number with the user before you commit it. Changing files
   without bumping it releases nothing (Bentra shows a `version_not_bumped` warning).
5. **Keys are snake_case. Unknown keys are rejected**, except ones starting with `x-`.
   The exact schema, with descriptions and an example, is `bentra://schemas/module` (Bentra MCP
   server) or `GET /orgs/<org>/api/v1/schemas/module/`.
6. **Never put credentials in a module.** Declare the auth it accepts under `auth.methods`; the
   workflow step calling the module passes the values in `module.auth` (secrets from
   `${{ vars.NAME }}` or `${{ inputs.field }}`), and the action reads them from
   `$BENTRA_AUTH_FILE` at run time.
7. **Pin dependencies exactly** (`requests==2.32.5`, a committed `package-lock.json`).
8. **A released version never changes.** Removing an action, renaming an input or adding a
   required input is a breaking change: bump the major version.

## Layout

```
.github/
bentra/
  modules/
    <name>/                 # the working directory you register, e.g. bentra/modules/http-check
      module.yaml
      README.md             # any letter case; shown in Bentra's registry
      requirements.txt      # python: pinned. node: package.json + package-lock.json
      actions/
        <action>.py         # one entrypoint per action
      tests/
        <action>.json       # sample inputs for scripts/run-action.sh
  workflows/
    <workflow>/workflow.yml # workflows that call the modules (optional)
```

A repository can hold any number of modules; each is registered with its own working directory.
A repository whose root is a single module works too (working directory `""`).

## module.yaml

```yaml
apiVersion: bentra/v1
kind: Module
version: 1.0.0                      # bump to release; strict semver, no "v"
release_notes: First release        # optional, stored with the release
metadata:
  name: http-check                  # lowercase, digits, hyphens; what workflows reference
  display_name: HTTP check
  description: Check that URLs answer with the status you expect.
  category: monitoring              # infrastructure cloud data deployment security monitoring
                                    # notifications internal other
  icon: activity                    # optional Lucide icon name
runtime:
  language: python                  # python | node | bash | binary
  version: ">=3.11"                 # required for python and node
dependencies:
  file: requirements.txt            # optional
  env: [UV_INDEX_URL]               # optional: workflow variables the install and setup get
setup: |                            # optional: bash, run once when the environment is built
  uv pip install example-cli==1.2.3
auth:                               # optional; omit when no credentials are needed
  required: false                   # false: steps may call it without auth
  methods:                          # the calling step picks one with auth.type
    - type: token                   # token | basic | api_key | oauth2_client_credentials
      description: Bearer token with read access.
    - type: custom                  # your own fields
      name: signed
      fields:
        key_id: {type: string, required: true}
        private_key: {type: string, secret: true, required: true}
defaults:
  timeout_seconds: 120
actions:
  - name: check_url                 # snake_case, unique
    description: Request one URL and report its status.
    entrypoint: actions/check_url.py
    timeout_seconds: 60             # optional
    inputs:                         # JSON Schema, type: object
      type: object
      properties:
        url: {type: string}
        expected_status: {type: integer, default: 200}
      required: [url]
      additionalProperties: false
    outputs:                        # JSON Schema of what the action writes
      type: object
      properties:
        status: {type: integer}
        ok: {type: boolean}
      required: [status, ok]
```

Quote YAML strings that contain `: ` or start with a special character.

## The action contract

Each action call is one process, started in a scratch directory, with these environment
variables:

| Variable | What it is |
|---|---|
| `BENTRA_INPUT_FILE` | JSON object: the step's inputs, already checked against `inputs` |
| `BENTRA_OUTPUT_FILE` | Write **one JSON object** here (at most 1 MB), matching `outputs` |
| `BENTRA_AUTH_FILE` | `{"type": <method>, <field>: value}` from the step's `module.auth`. **Only set when the step passes auth**: handle it missing when `auth.required` is false. Built-in fields: token `token`; basic `username`, `password`; api_key `key`; oauth2_client_credentials `client_id`, `client_secret`, `token_url`, `scope` |
| `BENTRA_CONTEXT_FILE` | `{run_id, job_id, workflow_id, step: {id, name, index}, module: {name, version, action}}` |
| `BENTRA_STEP_OUTPUTS` | JSON object of earlier steps' outputs, keyed by step `id` |
| `BENTRA_MODULE_DIR` | The module's files (read only) |
| `BENTRA_TEMP_DIR`, `TMPDIR`, `HOME` | A scratch directory, removed after the call |

- **Exit 0 is success**; any other exit code fails the step. On failure you may write
  `{"error": {"code": "...", "message": "...", "details": {...}}}` to the output file.
- **stdout and stderr are the step's log.** Never print auth values; secret values and
  outputs marked `x-bentra-secret: true` are masked anyway.
- **The environment is an allowlist**: only `PATH`, locale, `TZ`, proxy and CA variables come
  through. Workflow variables and secrets reach an action only as inputs.
- Don't rely on anything surviving between calls; each call starts clean.

## Runtimes

| `language` | How the runner starts the entrypoint | Dependencies |
|---|---|---|
| `python` | `python <entrypoint>` in the module version's own environment. The runner installs `runtime.version` with uv when its image (Python 3.12 to 3.14) has no match | `dependencies.file: requirements.txt`, pinned, installed with `uv pip install -r` |
| `node` | `node <entrypoint>` (Node 22). **CommonJS only**: `.js`/`.cjs` with `require`; `import` can't see the installed packages | `dependencies.file: package.json` + committed `package-lock.json`; installed with `npm ci --omit=dev` |
| `bash` | `bash <entrypoint>`. Start with `set -euo pipefail`; use `jq` (installed) for JSON | none |
| `binary` | `bin/<os>-<arch>/<entrypoint>`, e.g. `bin/linux-amd64/sha-tool`. List each in `runtime.platforms` and commit the binaries | none (static binaries) |

## Minimal action (Python)

```python
import json, os, sys

inputs = json.load(open(os.environ["BENTRA_INPUT_FILE"]))
auth = {}
if os.environ.get("BENTRA_AUTH_FILE"):
    auth = json.load(open(os.environ["BENTRA_AUTH_FILE"]))

result = {"greeting": f"Hello, {inputs['name']}"}
print(result["greeting"])                      # the step log
with open(os.environ["BENTRA_OUTPUT_FILE"], "w") as out:
    json.dump(result, out)
sys.exit(0)
```

## Using a module in a workflow

```yaml
steps:
  - id: check                       # needed to read this step's outputs later
    name: Check the API
    module:
      name: http-check
      version: "2.0.0"              # exact and quoted
      action: check_url
      auth:                         # one of the module's auth methods
        type: token
        token: ${{ vars.MONITORING_TOKEN }}   # secrets: vars./inputs. only, never the value
      inputs:
        url: ${{ inputs.api_url }}  # form field; also steps.<id>.outputs.<key>, vars.<NAME>
  - name: Report
    run: jq '.check.status' "$BENTRA_STEP_OUTPUTS"
```

`${{ }}` expressions work only inside `module.inputs` and `module.auth` (auth: `inputs.` and
`vars.` only). A value that is exactly one expression
keeps its JSON type.

## Environment: `setup` and `dependencies.env`

The runner builds a module version's environment the first time a job uses it and reuses it
afterwards. Nothing is installed when a version is released.

- `setup` is a bash script (`bash -eo pipefail`) run once, after the dependency install, in
  the module's folder with the environment active. Use it for what a dependency file can't
  express: a command-line tool, an extra package. What it installs into the environment is on
  the action's `PATH`. Every runtime can have one. It does not run on every call, so never
  put per-call work in it.
- `dependencies.env` lists the names (capitals) of the calling workflow's variables and
  secrets that the install and `setup` receive, for a private package index. They get nothing
  else from the run, and actions never receive these.
- Pass credentials to installers through those environment variables only. A build that
  writes one into the environment's files is refused.
- To change dependencies or `setup`, bump `version`: a released version never changes.

`bentra/modules/yaml-lint` is the example.

## Checklist before releasing

- [ ] `module.yaml` validates against the schema; `metadata.name` matches the folder name.
- [ ] Every `entrypoint` exists inside the working directory; binaries for every platform.
- [ ] Dependencies are pinned (`requirements.txt` with `==`, committed `package-lock.json`).
- [ ] Each action reads only its env files, writes one JSON object matching `outputs`, and
      exits non-zero on failure.
- [ ] Optional auth is handled when `BENTRA_AUTH_FILE` is unset.
- [ ] Nothing secret in the repository or in logs.
- [ ] `scripts/run-action.sh <module dir> <action> <inputs.json>` succeeds for every action.
- [ ] `README.md` says what each action does, its inputs and outputs, and its auth.
- [ ] `version` is bumped (MAJOR for breaking changes) and the user agreed to the number.

## Registering and releasing (Bentra MCP tools)

1. `inspect_module_source` with the connector, repository, branch and working directory: shows
   the manifest, actions, README and `issues` (file, line, message, hint). Fix and repeat.
2. `register_module` with the same source. Registering releases the `version` in module.yaml.
3. To release again: bump `version`, push, then `refresh_module` (or wait for the push). Poll
   `list_module_publications` until the newest is `published` (or `failed` with `issues`).
   `validate_module` runs every release check without releasing.
4. `set_active_module_version` chooses the version new workflow steps use (omit `version` to
   follow the newest release). Workflows keep the exact version they pin.
5. Reference the module from `workflow.yml`, passing `module.auth` when it declares auth. Ask the
   user to add the secret variables in Bentra; never set their values yourself.

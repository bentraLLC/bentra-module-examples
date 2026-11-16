# yaml-lint

Checks YAML text with [yamllint](https://yamllint.readthedocs.io/) and reports each problem.

It shows two things a module can declare besides a dependency file:

- **`setup`**: a bash script the runner runs once, when it builds this version's
  environment. Here it installs the `yamllint` command into the environment, which puts it
  on the action's `PATH`. It does not run on every call.
- **`dependencies.env`**: the names of the calling workflow's variables that the install
  and the setup script receive. Nothing else from the run is passed to them, and the action
  never receives these. With `UV_INDEX_URL` set on the workflow, `uv pip install` uses that
  index; without it, the public one.

## Actions

| Action | Inputs | Outputs |
|---|---|---|
| `lint` | `content` (YAML text), `strict` (also fail on warnings) | `ok`, `problems` |

```yaml
- id: lint
  name: Lint the config
  module:
    name: yaml-lint
    version: "1.0.0"
    action: lint
    inputs:
      content: ${{ inputs.config }}
```

To change what is installed, edit `setup` and bump `version`: a released version never
changes, and a new version gets a new environment.

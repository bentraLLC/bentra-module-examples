# Bentra module examples

Complete, working [Bentra](https://bentralabs.com) modules for every runtime, laid out the way
Bentra expects, plus a workflow that chains them. Copy a folder to start your own module.

| Module | Runtime | Shows |
|---|---|---|
| [`http-check`](bentra/modules/http-check) | Python + `requests` | pinned dependencies, an optional connection with a secret, two actions sharing a helper, structured errors |
| [`json-tools`](bentra/modules/json-tools) | Bash + `jq` | no dependencies, no connection, object inputs and outputs |
| [`text-tools`](bentra/modules/text-tools) | Node.js + `slugify` | `package.json` + `package-lock.json`, CommonJS |
| [`sha-tool`](bentra/modules/sha-tool) | Go, prebuilt binary | `runtime.platforms`, `bin/<os>-<arch>/`, rebuilding with `make` |

[`bentra/workflows/module-demo`](bentra/workflows/module-demo/workflow.yml) calls all four and
passes outputs from one step to the next.

## Layout

```
bentra/
  modules/
    <name>/            # register this folder as the module's working directory
      module.yaml
      README.md
      actions/
      tests/           # sample inputs for scripts/run-action.sh
  workflows/
    module-demo/
      workflow.yml
scripts/run-action.sh  # run an action locally the way a Bentra runner does
AGENTS.md              # instructions for coding agents writing modules
```

Bentra reads only a module's working directory and what is inside it, so each module folder is
self-contained.

## Try an action locally

```bash
pip install pyyaml        # the harness reads module.yaml with it
scripts/run-action.sh bentra/modules/json-tools merge bentra/modules/json-tools/tests/merge.json
```

## Use them in Bentra

1. **Modules → Register module**: choose your connection, this repository, `main`, and a working
   directory such as `bentra/modules/http-check`.
2. Review the module, its actions and README, then register it and publish a version.
3. Reference it from a workflow step (see `bentra/workflows/module-demo/workflow.yml`).

## Building modules with an agent

Give your coding agent [`AGENTS.md`](AGENTS.md): the layout, the `module.yaml` rules, the action
contract and a checklist. With the Bentra MCP server connected, the agent can also inspect,
register, validate and publish modules for you.

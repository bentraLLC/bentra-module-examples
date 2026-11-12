#!/usr/bin/env bash
# Run one module action locally the way a Bentra runner does.
#
#   scripts/run-action.sh <module dir> <action> <inputs.json> [connection.json]
#   scripts/run-action.sh bentra/modules/json-tools merge bentra/modules/json-tools/tests/merge.json
#
# Needs: bash, jq, python3 with PyYAML (pip install pyyaml; or set PYTHON=<interpreter>), node + npm (node modules). Binary modules run
# only on a matching linux platform. Prints the action's log, then its outputs.
set -euo pipefail

module_dir=$(cd "$1" && pwd); action=$2; inputs=$(cd "$(dirname "$3")" && pwd)/$(basename "$3")
connection=${4:+$(cd "$(dirname "$4")" && pwd)/$(basename "$4")}
manifest="$module_dir/module.yaml"; [[ -f "$manifest" ]] || manifest="$module_dir/module.yml"

yaml() { "${PYTHON:-python3}" -c 'import json,sys,yaml; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))' "$manifest"; }
spec=$(yaml)
language=$(jq -r '.runtime.language' <<<"$spec")
entrypoint=$(jq -r --arg a "$action" '.actions[] | select(.name == $a) | .entrypoint' <<<"$spec")
[[ -n "$entrypoint" ]] || { echo "no action '$action' in $manifest" >&2; exit 2; }
deps=$(jq -r '.dependencies.file // empty' <<<"$spec")

scratch=$(mktemp -d); trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/tmp"
echo '{}' > "$scratch/steps.json"
jq -n --arg m "$(jq -r .metadata.name <<<"$spec")" --arg a "$action" \
  '{run_id: "local", job_id: "local", workflow_id: "local",
    step: {id: "local", name: "local", index: 0}, module: {name: $m, version: "0.0.0-local", action: $a}}' \
  > "$scratch/context.json"

runner=()
case "$language" in
  python)
    if [[ -n "$deps" ]]; then
      python3 -m venv "$scratch/env" && "$scratch/env/bin/pip" install -q -r "$module_dir/$deps"
      runner=("$scratch/env/bin/python")
    else runner=(python3); fi ;;
  node)
    if [[ -n "$deps" ]]; then
      cp "$module_dir/$deps" "$module_dir/package-lock.json" "$scratch/" \
        && (cd "$scratch" && npm ci --omit=dev --silent)
      export NODE_PATH="$scratch/node_modules"
    fi
    runner=(node) ;;
  bash) runner=(bash) ;;
  binary)
    os=$(uname -s | tr '[:upper:]' '[:lower:]'); arch=$(uname -m)
    case "$arch" in x86_64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; esac
    entrypoint="bin/$os-$arch/$entrypoint"
    [[ -x "$module_dir/$entrypoint" ]] || { echo "no binary for $os-$arch: $entrypoint" >&2; exit 2; } ;;
esac

env -i PATH="$PATH" HOME="$scratch" TMPDIR="$scratch/tmp" ${NODE_PATH:+NODE_PATH="$NODE_PATH"} \
  BENTRA_INPUT_FILE="$inputs" BENTRA_OUTPUT_FILE="$scratch/output.json" \
  BENTRA_CONTEXT_FILE="$scratch/context.json" BENTRA_STEP_OUTPUTS="$scratch/steps.json" \
  BENTRA_MODULE_DIR="$module_dir" BENTRA_TEMP_DIR="$scratch/tmp" \
  ${connection:+BENTRA_CONNECTION_FILE="$connection"} \
  "${runner[@]}" "$module_dir/$entrypoint" && status=0 || status=$?

echo "--- outputs (exit $status)"
cat "$scratch/output.json" 2>/dev/null || echo "(none written)"
echo
exit "$status"

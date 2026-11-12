#!/usr/bin/env bash
# pick: keep only .keys of .object; report keys that weren't there.
set -euo pipefail

jq '{
  result: (.object as $o | reduce .keys[] as $k ({}; if $o | has($k) then . + {($k): $o[$k]} else . end)),
  missing: [.keys[] as $k | select(.object | has($k) | not) | $k]
}' "$BENTRA_INPUT_FILE" > "$BENTRA_OUTPUT_FILE"

missing=$(jq -r '.missing | join(", ")' "$BENTRA_OUTPUT_FILE")
if [[ -n "$missing" ]]; then
  echo "not in the object: $missing" >&2
fi

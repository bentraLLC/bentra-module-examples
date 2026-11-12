#!/usr/bin/env bash
# merge: deep-merge .overlay into .base. Reads $BENTRA_INPUT_FILE, writes $BENTRA_OUTPUT_FILE.
set -euo pipefail

jq '{result: (.base * .overlay)}' "$BENTRA_INPUT_FILE" > "$BENTRA_OUTPUT_FILE"
echo "merged $(jq '.overlay | keys | length' "$BENTRA_INPUT_FILE") key(s) into base"

"""Lint YAML text with the yamllint command that the module's setup script installed."""
import json
import os
import subprocess
import sys

with open(os.environ["BENTRA_INPUT_FILE"]) as handle:
    inputs = json.load(handle)

command = ["yamllint", "--format", "parsable"]
if inputs.get("strict"):
    command.append("--strict")
result = subprocess.run([*command, "-"], input=inputs["content"], capture_output=True, text=True)
problems = [line for line in result.stdout.splitlines() if line.strip()]
for line in problems:
    print(line)
if result.stderr.strip():
    print(result.stderr.strip(), file=sys.stderr)

ok = result.returncode == 0
with open(os.environ["BENTRA_OUTPUT_FILE"], "w") as out:
    json.dump({"ok": ok, "problems": problems}, out)
raise SystemExit(0 if ok else 1)

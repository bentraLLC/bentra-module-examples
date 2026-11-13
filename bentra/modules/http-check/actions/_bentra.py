"""Helpers for the Bentra action contract: read inputs, auth and context, write outputs."""
import json
import os
import sys


def _load(variable: str) -> dict:
    path = os.environ.get(variable)
    if not path:
        return {}
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def inputs() -> dict:
    return _load("BENTRA_INPUT_FILE")


def auth() -> dict:
    """The step's auth, {"type": ..., <fields>}; {} when the step passes none."""
    return _load("BENTRA_AUTH_FILE")


def context() -> dict:
    return _load("BENTRA_CONTEXT_FILE")


def write_outputs(outputs: dict) -> None:
    with open(os.environ["BENTRA_OUTPUT_FILE"], "w", encoding="utf-8") as handle:
        json.dump(outputs, handle)


def fail(code: str, message: str, **details) -> None:
    """Record a structured error and stop the step."""
    with open(os.environ["BENTRA_OUTPUT_FILE"], "w", encoding="utf-8") as handle:
        json.dump({"error": {"code": code, "message": message, "details": details}}, handle)
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)

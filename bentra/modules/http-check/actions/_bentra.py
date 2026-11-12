"""Helpers for the Bentra action contract: read inputs, connection and context, write outputs."""
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


def connection() -> dict:
    """The step's connection fields; {} when the step names no connection."""
    return _load("BENTRA_CONNECTION_FILE")


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

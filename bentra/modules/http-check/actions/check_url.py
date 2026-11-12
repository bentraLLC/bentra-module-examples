"""check_url: request one URL and report its status."""
import time

import requests

import _bentra


def session() -> tuple[requests.Session, float]:
    conn = _bentra.connection()
    s = requests.Session()
    if conn.get("token"):
        s.headers["Authorization"] = f"Bearer {conn['token']}"
    return s, float(conn.get("timeout_seconds") or 30)


def check(s: requests.Session, url: str, timeout: float) -> tuple[int, int]:
    started = time.monotonic()
    try:
        response = s.get(url, timeout=timeout, allow_redirects=True)
    except requests.RequestException as exc:
        _bentra.fail("request_failed", f"{url} could not be reached: {exc.__class__.__name__}",
                     url=url)
    return response.status_code, int((time.monotonic() - started) * 1000)


def main() -> None:
    params = _bentra.inputs()
    expected = params.get("expected_status", 200)
    s, timeout = session()
    status, elapsed_ms = check(s, params["url"], timeout)
    ok = status == expected
    print(f"{params['url']} answered {status} in {elapsed_ms} ms (expected {expected})")
    _bentra.write_outputs({"status": status, "ok": ok, "elapsed_ms": elapsed_ms})
    if not ok:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

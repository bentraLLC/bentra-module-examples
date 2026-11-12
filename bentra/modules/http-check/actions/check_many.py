"""check_many: request several URLs; fail the step if any of them answers wrongly."""
import _bentra
from check_url import check, session


def main() -> None:
    params = _bentra.inputs()
    expected = params.get("expected_status", 200)
    s, timeout = session()
    failed = []
    for url in params["urls"]:
        status, elapsed_ms = check(s, url, timeout)
        print(f"{url}: {status} in {elapsed_ms} ms")
        if status != expected:
            failed.append(url)
    _bentra.write_outputs({"checked": len(params["urls"]), "failed": failed})
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

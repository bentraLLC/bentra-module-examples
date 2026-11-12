# HTTP check

Checks that URLs answer with the status you expect. Python, `requests`.

| Action | Inputs | Outputs |
|---|---|---|
| `check_url` | `url`, `expected_status` (default 200) | `status`, `ok`, `elapsed_ms` |
| `check_many` | `urls`, `expected_status` (default 200) | `checked`, `failed` |

The step fails when a URL answers with another status.

**Connection (optional):** `token` (secret, sent as a bearer token) and `timeout_seconds`.
Leave the connection out for public URLs.

```yaml
- id: check
  name: Check the API
  module:
    name: http-check
    version: "1.0.0"
    action: check_url
    inputs:
      url: https://example.com/health
```

# HTTP check

Checks that URLs answer with the status you expect. Python, `requests`.

| Action | Inputs | Outputs |
|---|---|---|
| `check_url` | `url`, `expected_status` (default 200), `timeout_seconds` (default 30) | `status`, `ok`, `elapsed_ms` |
| `check_many` | `urls`, `expected_status` (default 200), `timeout_seconds` (default 30) | `checked`, `failed` |

The step fails when a URL answers with another status.

**Auth (optional):** `type: token`, sent as a bearer token. Leave `auth` out for public URLs;
pass the token from a secret variable, never the value itself.

```yaml
- id: check
  name: Check the API
  module:
    name: http-check
    version: "2.0.0"
    action: check_url
    auth:                       # optional; for URLs that need a token
      type: token
      token: ${{ vars.HEALTH_TOKEN }}
    inputs:
      url: https://example.com/health
```

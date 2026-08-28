#!/usr/bin/env python3
"""
Thin authenticated client for the App Store Connect API.

Generates the ES256 JWT bearer token App Store Connect requires and makes
requests against https://api.appstoreconnect.apple.com. Credentials (Issuer
ID, Key ID) live in ~/.appstoreconnect/config.json; the private key itself
stays at ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 — never in this
repo, per Apple's own recommended layout (also what fastlane expects).

Requires: pip3 install --user pyjwt cryptography

Usage:
    python3 scripts/appstoreconnect.py get /v1/apps
    python3 scripts/appstoreconnect.py get "/v1/apps?filter[bundleId]=com.patrickhoughton.WordPuzzle"

What this does NOT do: create app records or in-app purchases. Apple's
in-app-purchase creation endpoints changed relatively recently and are not
exercised here — verify the exact request schema against Apple's current
OpenAPI spec (https://developer.apple.com/sample-code/app-store-connect/app-store-connect-openapi-specification.zip)
before scripting a create call, rather than trusting a hardcoded payload
that may drift from what Apple currently accepts.
"""

import json
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

import jwt

CONFIG_PATH = Path.home() / ".appstoreconnect" / "config.json"
BASE_URL = "https://api.appstoreconnect.apple.com"


def load_config():
    if not CONFIG_PATH.exists():
        sys.exit(
            f"Missing {CONFIG_PATH}. Create it with:\n"
            '  {"issuer_id": "...", "key_id": "..."}\n'
            "The private key must be at "
            "~/.appstoreconnect/private_keys/AuthKey_<key_id>.p8"
        )
    return json.loads(CONFIG_PATH.read_text())


def make_token(issuer_id: str, key_id: str) -> str:
    key_path = Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{key_id}.p8"
    if not key_path.exists():
        sys.exit(f"Private key not found at {key_path}")
    private_key = key_path.read_text()

    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 60 * 15,  # Apple caps this at 20 minutes
        "aud": "appstoreconnect-v1",
    }
    headers = {"kid": key_id}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def request(method: str, path: str, token: str, body: dict | None = None):
    url = path if path.startswith("http") else f"{BASE_URL}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method.upper())
    req.add_header("Authorization", f"Bearer {token}")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    method, path = sys.argv[1], sys.argv[2]
    body = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None

    config = load_config()
    token = make_token(config["issuer_id"], config["key_id"])
    status, response = request(method, path, token, body)

    print(f"HTTP {status}")
    print(json.dumps(response, indent=2))
    sys.exit(0 if 200 <= status < 300 else 1)


if __name__ == "__main__":
    main()

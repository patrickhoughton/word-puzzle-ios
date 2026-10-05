#!/usr/bin/env python3
"""
Upload App Store screenshots and the IAP App Review screenshot via the App Store
Connect API (reserve -> upload parts -> commit), using the JWT helpers in
scripts/appstoreconnect.py.

Payload shapes verified against Apple's OpenAPI spec v4.5 (2026-10-05):
  POST /v1/appScreenshotSets                    AppScreenshotSetCreateRequest
  POST /v1/appScreenshots                       AppScreenshotCreateRequest
  PATCH /v1/appScreenshots/{id}                 AppScreenshotUpdateRequest (uploaded, sourceFileChecksum)
  POST /v1/inAppPurchaseAppStoreReviewScreenshots  ...CreateRequest (relationship inAppPurchaseV2)
  PATCH /v1/inAppPurchaseAppStoreReviewScreenshots/{id}  ...UpdateRequest

Usage:
  python3 scripts/asc_upload_assets.py screenshots <versionLocalizationId> <displayType> <png>...
  python3 scripts/asc_upload_assets.py iap-review <iapId> <png>

Display types: 6.9" iPhone 1320x2868 -> APP_IPHONE_67; 13" iPad 2064x2752 -> APP_IPAD_PRO_3GEN_129.
Screenshots are created in argument order, which is the order App Store Connect shows.
Refuses to add to a screenshot set that already contains screenshots (no silent duplicates).
"""

import hashlib
import importlib.util
import sys
import time
import urllib.request
from pathlib import Path

_spec = importlib.util.spec_from_file_location("asc", Path(__file__).with_name("appstoreconnect.py"))
asc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(asc)


def token():
    cfg = asc.load_config()
    return asc.make_token(cfg["issuer_id"], cfg["key_id"])


def call(method, path, body=None):
    status, resp = asc.request(method, path, token(), body)
    if not 200 <= status < 300:
        sys.exit(f"FAILED {method} {path}: HTTP {status}\n{resp}")
    return resp


def put_parts(ops, data):
    for op in ops:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
        for h in op.get("requestHeaders") or []:
            req.add_header(h["name"], h["value"])
        with urllib.request.urlopen(req) as r:
            if not 200 <= r.status < 300:
                sys.exit(f"FAILED upload part offset {op['offset']}: HTTP {r.status}")


def upload(create_path, rtype, rel_name, rel_type, rel_id, png):
    data = Path(png).read_bytes()
    created = call("POST", create_path, {"data": {
        "type": rtype,
        "attributes": {"fileName": Path(png).name, "fileSize": len(data)},
        "relationships": {rel_name: {"data": {"type": rel_type, "id": rel_id}}},
    }})["data"]
    put_parts(created["attributes"]["uploadOperations"], data)
    call("PATCH", f"{create_path}/{created['id']}", {"data": {
        "type": rtype, "id": created["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()},
    }})
    # Wait for Apple's asset processing to finish (or fail) before moving on.
    for _ in range(30):
        state = call("GET", f"{create_path}/{created['id']}")["data"]["attributes"].get("assetDeliveryState") or {}
        if state.get("state") in ("COMPLETE", "FAILED"):
            break
        time.sleep(4)
    print(f"{Path(png).name}: id {created['id']} state {state.get('state')} errors {state.get('errors')}")
    if state.get("state") != "COMPLETE":
        sys.exit(f"Asset {png} did not reach COMPLETE")
    return created["id"]


def screenshots(loc_id, display_type, pngs):
    sets = call("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")["data"]
    existing = [s for s in sets if s["attributes"]["screenshotDisplayType"] == display_type]
    if existing:
        set_id = existing[0]["id"]
        shots = call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots")["data"]
        if shots:
            sys.exit(f"Set {set_id} ({display_type}) already has {len(shots)} screenshots; refusing to append")
    else:
        set_id = call("POST", "/v1/appScreenshotSets", {"data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {"appStoreVersionLocalization": {
                "data": {"type": "appStoreVersionLocalizations", "id": loc_id}}},
        }})["data"]["id"]
    print(f"set {set_id} ({display_type})")
    for png in pngs:
        upload("/v1/appScreenshots", "appScreenshots", "appScreenshotSet", "appScreenshotSets", set_id, png)


def iap_review(iap_id, png):
    upload("/v1/inAppPurchaseAppStoreReviewScreenshots", "inAppPurchaseAppStoreReviewScreenshots",
           "inAppPurchaseV2", "inAppPurchases", iap_id, png)


if __name__ == "__main__":
    if len(sys.argv) >= 5 and sys.argv[1] == "screenshots":
        screenshots(sys.argv[2], sys.argv[3], sys.argv[4:])
    elif len(sys.argv) == 4 and sys.argv[1] == "iap-review":
        iap_review(sys.argv[2], sys.argv[3])
    else:
        print(__doc__)
        sys.exit(1)

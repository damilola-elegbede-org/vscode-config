#!/usr/bin/env python3
"""Fail if any extension ID in the list is missing from the VS Code Marketplace."""
import json
import sys
import urllib.request

URL = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
ids = [l.strip().lower() for l in open(sys.argv[1]) if l.strip() and not l.startswith("#")]
body = {"filters": [{"criteria": [{"filterType": 7, "value": i} for i in ids], "pageSize": len(ids)}], "flags": 0}
req = urllib.request.Request(URL, json.dumps(body).encode(), {
    "Content-Type": "application/json", "Accept": "application/json;api-version=7.2-preview.1"})
found = {f'{e["publisher"]["publisherName"]}.{e["extensionName"]}'.lower()
         for e in json.load(urllib.request.urlopen(req, timeout=30))["results"][0]["extensions"]}
missing = sorted(set(ids) - found)
print(f"{len(ids) - len(missing)}/{len(ids)} extension IDs found on the Marketplace")
if missing:
    print("missing:", ", ".join(missing))
    sys.exit(1)

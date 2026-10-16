#!/usr/bin/env python3
"""Rewrites test/shard_weights.json from a `flutter test --reporter json` log.

    flutter test --reporter json > report.json
    tool/shard_weights_from_report.py report.json

The weight of a file is the sum of its tests' seconds, loading included.
"""
import collections
import json
import os
import sys

suites, started, seconds = {}, {}, collections.Counter()
for line in open(sys.argv[1]):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    kind = event.get("type")
    if kind == "suite":
        suites[event["suite"]["id"]] = event["suite"]["path"].split("/test/", 1)[-1]
    elif kind == "testStart":
        test = event["test"]
        started[test["id"]] = (event["time"], suites.get(test["suiteID"], ""))
    elif kind == "testDone" and event["testID"] in started:
        begin, path = started[event["testID"]]
        seconds[path] += event["time"] - begin
weights = {f: round(ms / 1000, 1) for f, ms in sorted(seconds.items())}
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "test", "shard_weights.json")
with open(out, "w") as handle:
    json.dump(weights, handle, indent=1)
    handle.write("\n")
print(f"{len(weights)} files")

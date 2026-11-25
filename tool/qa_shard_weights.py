#!/usr/bin/env python3
"""Refreshes test/shard_weights.json from `flutter test --reporter json` runs.

    tool/qa_shard_weights.py RUN.json [RUN2.json ...]  > test/shard_weights.json

Each file is the JSON reporter's output of any set of test files (the four
shards' files of a CI-like run, one after the other, work: pass them all).
The weight of a test file is its seconds, summed over its tests and its
set-up, and averaged over the runs that have it. Files no run has keep their
old weight from test/shard_weights.json. Prints the new table on stdout and,
on stderr, the balance of the four shards under it (tool/shard_tests.py).
QA's: run it after a big change in the suite's time.
"""
import collections
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def seconds(paths):
    runs = []
    for path in paths:
        names, suites, start = {}, {}, {}
        total = collections.defaultdict(float)
        with open(path) as handle:
            for line in handle:
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                kind = e.get("type")
                if kind == "suite":
                    suites[e["suite"]["id"]] = e["suite"]["path"]
                elif kind == "testStart":
                    t = e["test"]
                    names[t["id"]] = suites.get(t.get("suiteID"))
                    start[t["id"]] = e["time"]
                elif kind == "testDone":
                    suite = names.get(e["testID"])
                    if suite:
                        total[suite] += (e["time"] - start[e["testID"]]) / 1000
        runs.append(total)
    return runs


def main(paths):
    if not paths:
        sys.exit(__doc__)
    with open(os.path.join(ROOT, "test", "shard_weights.json")) as handle:
        weights = json.load(handle)
    by_file = collections.defaultdict(list)
    for run in seconds(paths):
        for suite, value in run.items():
            by_file[suite.split("/test/")[-1]].append(value)
    for name, values in by_file.items():
        weights[name] = round(sum(values) / len(values), 1)
    live = set()
    for base, _, files in os.walk(os.path.join(ROOT, "test")):
        for f in files:
            if f.endswith("_test.dart"):
                live.add(os.path.relpath(os.path.join(base, f), os.path.join(ROOT, "test")))
    weights = {k: v for k, v in sorted(weights.items()) if k in live}
    print(json.dumps(weights, indent=1, sort_keys=True))


if __name__ == "__main__":
    main(sys.argv[1:])

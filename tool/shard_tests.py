#!/usr/bin/env python3
"""Splits the test files across CI runners by how long each file takes.

    tool/shard_tests.py SHARD N     print the files of shard SHARD (0-based) of N
    tool/shard_tests.py --check N   check the N shards hold every file exactly once

Weights (seconds per file, from `flutter test --reporter json`) are in
test/shard_weights.json. A file without a weight counts as the median, so a
new test file needs no entry. Files go heaviest first to the lightest shard
(ties by name), the same on every runner, and each file lands in exactly one
shard: every call checks that before printing.
"""
import json
import os
import statistics
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TEST = os.path.join(ROOT, "test")


def test_files():
    found = []
    for base, _, names in os.walk(TEST):
        for name in names:
            if name.endswith("_test.dart"):
                found.append(os.path.relpath(os.path.join(base, name), TEST))
    return sorted(found)


def split(n):
    with open(os.path.join(TEST, "shard_weights.json")) as handle:
        weights = json.load(handle)
    files = test_files()
    known = [weights[f] for f in files if f in weights]
    median = statistics.median(known) if known else 1.0
    weight = {f: weights.get(f, median) for f in files}
    shards = [[] for _ in range(n)]
    load = [0.0] * n
    for f in sorted(files, key=lambda f: (-weight[f], f)):
        i = min(range(n), key=lambda k: (load[k], k))
        shards[i].append(f)
        load[i] += weight[f]
    placed = sorted(f for shard in shards for f in shard)
    if placed != files:
        dropped = sorted(set(files) - set(placed))
        doubled = sorted({f for f in placed if placed.count(f) > 1})
        sys.exit(f"shard split is not a partition: dropped {dropped}, doubled {doubled}")
    return shards, load


def main(argv):
    if len(argv) == 3 and argv[1] == "--check":
        n = int(argv[2])
        shards, load = split(n)
        count = sum(len(s) for s in shards)
        print(f"{count} test files in {n} shards, each in exactly one; "
              "expected seconds " + ", ".join(f"{x:.0f}" for x in load))
        return
    if len(argv) != 3:
        sys.exit(__doc__)
    shard, n = int(argv[1]), int(argv[2])
    if not 0 <= shard < n:
        sys.exit("shard must be in 0..N-1")
    shards, _ = split(n)
    for f in sorted(shards[shard]):
        print(os.path.join("test", f))


if __name__ == "__main__":
    main(sys.argv)

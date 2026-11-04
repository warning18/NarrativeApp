#!/usr/bin/env python3
"""Splits the test files across CI runners by how long each file takes.

    tool/shard_tests.py SHARD N     print the files of shard SHARD (0-based) of N
    tool/shard_tests.py --check N   check the N shards hold every file exactly once
    tool/shard_tests.py SHARD N --skip-gated
                                    the same, without the statistical simulator tests
    tool/shard_tests.py --gate      read the changed paths of a pull request on
                                    stdin; print `run` or `skip` for the gated tests

Weights (seconds per file, from `flutter test --reporter json`) are in
test/shard_weights.json. A file without a weight counts as the median, so a
new test file needs no entry. Files go heaviest first to the lightest shard
(ties by name), the same on every runner, and each file lands in exactly one
shard: every call checks that before printing.

The gated tests (tool/sim_gate.txt) are left out of the split altogether with
--skip-gated, so the remaining files are balanced again across the shards (the
partition check runs on that smaller set too). CI skips them only on a
pull request that changes none of the gate's trigger paths; an empty or
unreadable list of changed paths means `run`, and main always runs them.
"""
import json
import os
import statistics
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TEST = os.path.join(ROOT, "test")


def gate():
    """The gated file names and the trigger prefixes of tool/sim_gate.txt."""
    gated, triggers = [], []
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sim_gate.txt")) as handle:
        for line in handle:
            line = line.strip()
            if line.startswith("gated "):
                gated.append(line[len("gated "):].strip())
            elif line.startswith("trigger "):
                triggers.append(line[len("trigger "):].strip())
    return gated, triggers


def test_files():
    found = []
    for base, _, names in os.walk(TEST):
        for name in names:
            if name.endswith("_test.dart"):
                found.append(os.path.relpath(os.path.join(base, name), TEST))
    return sorted(found)


def split(n, skip=()):
    with open(os.path.join(TEST, "shard_weights.json")) as handle:
        weights = json.load(handle)
    files = [f for f in test_files() if f not in skip]
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
        split(n, skip=gate()[0])
        missing = [f for f in gate()[0] if f not in test_files()]
        if missing:
            sys.exit(f"tool/sim_gate.txt names test files that do not exist: {missing}")
        count = sum(len(s) for s in shards)
        print(f"{count} test files in {n} shards, each in exactly one; "
              "expected seconds " + ", ".join(f"{x:.0f}" for x in load))
        return
    if argv[1:] == ["--gate"]:
        _, triggers = gate()
        changed = [line.strip() for line in sys.stdin if line.strip()]
        hit = [p for p in changed if any(p.startswith(t) for t in triggers)]
        if not changed:
            print("run")
            print("no changed paths given: running the simulator tests", file=sys.stderr)
        elif hit:
            print("run")
            print(f"{len(hit)} changed path(s) can move the simulator tests, e.g. {hit[0]}", file=sys.stderr)
        else:
            print("skip")
            print(f"none of {len(changed)} changed path(s) can move the simulator tests", file=sys.stderr)
        return
    skip = "--skip-gated" in argv
    argv = [a for a in argv if a != "--skip-gated"]
    if len(argv) != 3:
        sys.exit(__doc__)
    shard, n = int(argv[1]), int(argv[2])
    if not 0 <= shard < n:
        sys.exit("shard must be in 0..N-1")
    shards, _ = split(n, skip=gate()[0] if skip else ())
    for f in sorted(shards[shard]):
        print(os.path.join("test", f))


if __name__ == "__main__":
    main(sys.argv)

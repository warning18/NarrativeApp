#!/usr/bin/env python3
"""Splits the test files across CI runners by how long each file takes.

    tool/shard_tests.py SHARD N     print the files of shard SHARD (0-based) of N
    tool/shard_tests.py --check N   check the N shards hold every file exactly once
    tool/shard_tests.py SHARD N --skip-gated
                                    the same, without any gated test file
    tool/shard_tests.py SHARD N --changed FILE
                                    the same, without the gated files of each
                                    group (tool/sim_gate.txt) that the changed
                                    paths listed in FILE (one a line) cannot move

Weights (seconds per file, from `flutter test --reporter json`) are in
test/shard_weights.json. A file without a weight counts as the median, so a
new test file needs no entry. Files go heaviest first to the lightest shard
(ties by name), the same on every runner, and each file lands in exactly one
shard: every call checks that before printing.

The gated tests (tool/sim_gate.txt, in groups) are left out of the split
altogether, so the remaining files are balanced again across the shards (the
partition check runs on that smaller set too). CI skips a group only on a
pull request whose changed paths touch none of the group's triggers (or only
paths under its `ignore` prefixes); an empty or unreadable list of changed
paths skips nothing, and main always runs everything. What is skipped is told
on stderr ("Simulator tests skipped: ...").
"""
import json
import os
import statistics
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TEST = os.path.join(ROOT, "test")


def groups():
    """tool/sim_gate.txt as {name: {gated, triggers, ignores}}."""
    found, current = {}, None
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sim_gate.txt")) as handle:
        for line in handle:
            line = line.strip()
            if line.startswith("group "):
                current = found.setdefault(
                    line[len("group "):].strip(), {"gated": [], "triggers": [], "ignores": []})
            elif current is not None and line.startswith("gated "):
                current["gated"].append(line[len("gated "):].strip())
            elif current is not None and line.startswith("trigger "):
                current["triggers"].append(line[len("trigger "):].strip())
            elif current is not None and line.startswith("ignore "):
                current["ignores"].append(line[len("ignore "):].strip())
    return found


def gate():
    """Every gated file name and every trigger prefix, over all groups."""
    gated, triggers = [], []
    for group in groups().values():
        gated += group["gated"]
        triggers += group["triggers"]
    return gated, triggers


MESSAGES = {
    "simulator": "Simulator tests skipped",
    "screens": "Screen smoke tests skipped",
}


def skipped_for(changed):
    """The gated files to leave out for the changed paths, and why (stderr)."""
    skip, notes = [], []
    if not changed:
        return skip, ["no changed paths given: nothing is skipped"]
    for name, group in groups().items():
        counts = [p for p in changed
                  if any(p.startswith(t) for t in group["triggers"])
                  and not any(p.startswith(i) for i in group["ignores"])]
        label = MESSAGES.get(name, f"{name} tests skipped")
        if counts:
            notes.append(f"{name} tests run: {len(counts)} changed path(s) can move them, e.g. {counts[0]}")
        else:
            skip += group["gated"]
            notes.append(f"{label}: none of {len(changed)} changed path(s) can move them (tool/sim_gate.txt)")
    return skip, notes


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
    skip = "--skip-gated" in argv
    argv = [a for a in argv if a != "--skip-gated"]
    skipped = gate()[0] if skip else []
    if "--changed" in argv:
        at = argv.index("--changed")
        if at + 1 >= len(argv):
            sys.exit(__doc__)
        try:
            with open(argv[at + 1]) as handle:
                changed = [line.strip() for line in handle if line.strip()]
        except OSError:
            changed = []
        argv = argv[:at] + argv[at + 2:]
        left_out, notes = skipped_for(changed)
        skipped = sorted(set(skipped) | set(left_out))
        for note in notes:
            print(note, file=sys.stderr)
    if len(argv) != 3:
        sys.exit(__doc__)
    shard, n = int(argv[1]), int(argv[2])
    if not 0 <= shard < n:
        sys.exit("shard must be in 0..N-1")
    shards, _ = split(n, skip=skipped)
    for f in sorted(shards[shard]):
        print(os.path.join("test", f))


if __name__ == "__main__":
    main(sys.argv)

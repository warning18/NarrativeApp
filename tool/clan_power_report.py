#!/usr/bin/env python3
"""Merges the runs test/qa_clan_power_50_test.dart wrote into one JSON file
(docs/qa/clan-power-50.json) and prints the tables of docs/qa/clan-power-50.md.

    CLAN_POWER_OUT=/tmp/cp flutter test test/qa_clan_power_50_test.dart
    tool/clan_power_report.py /tmp/cp docs/qa/clan-power-50.json > tables.md
"""
import collections
import glob
import json
import os
import statistics as st
import sys

MAIN = ["dominion", "vigil", "compact", "mire", "crows", "penitents"]
SOURCES = ["holding", "neglect", "gift", "quest", "story", "claim_war_fall"]
TIERS = [(75, "Ascendant"), (50, "Dominant"), (25, "Rising"), (0, "Minor")]


def tier(power):
    for floor, name in TIERS:
        if power >= floor:
            return name


def source(name):
    # The turn's own remainder (a fall, a claim's cost) and a fall at a step.
    return {"turn_other": "claim_war_fall", "fall": "claim_war_fall",
            "nemesis_broken": "claim_war_fall"}.get(name, name)


def merge(runs):
    out = []
    for r in runs:
        clans = {}
        for clan in runs[0]["chapters"][0]["start"]["power"]:
            rows = {"main": clan in MAIN, "power_start": [], "power_end": [],
                    "holds_start": [], "holds_end": [], "places_end": [],
                    "fallen_end": [], "delta": []}
            for c in r["chapters"]:
                rows["power_start"].append(c["start"]["power"][clan])
                rows["power_end"].append(c["end"]["power"][clan])
                rows["holds_start"].append(len(c["start"]["places"][clan]))
                rows["holds_end"].append(len(c["end"]["places"][clan]))
                rows["places_end"].append(c["end"]["places"][clan])
                rows["fallen_end"].append(clan in c["end"]["fallen"])
                by = collections.Counter()
                if c["turn"]:
                    for k, v in c["turn"]["delta"].get(clan, {}).items():
                        by[k] += v
                for e in c["events"]:
                    for k, v in e["delta"].get(clan, {}).items():
                        by[k] += v
                rows["delta"].append(dict(sorted(by.items())))
            clans[clan] = rows
        territory = []
        events = []
        for c in r["chapters"]:
            if c["turn"]:
                for t in c["turn"]["changes"]:
                    territory.append({"chapter": c["chapter"], **t})
            for e in c["events"]:
                for place, move in e["places"].items():
                    frm, to = move.split("->")
                    territory.append({"chapter": c["chapter"], "place": place,
                                      "from": frm, "to": to, "cause": "event"})
                events.append({"chapter": c["chapter"], "step": e["step"],
                               "choice": e["choice"], "delta": e["delta"]})
        out.append({k: r[k] for k in ("run", "seed", "strategy", "race",
                                      "profession", "patron", "sworn",
                                      "nemeses", "finalNemesis", "endedHow",
                                      "furthestChapter")}
                   | {"clans": clans, "territory": territory,
                      "events": events})
    return out


def r2(ys):
    n = len(ys)
    xs = list(range(n))
    mx, my = st.mean(xs), st.mean(ys)
    sxx = sum((x - mx) ** 2 for x in xs)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    syy = sum((y - my) ** 2 for y in ys)
    if syy == 0:
        return 1.0, 0.0
    return (sxy * sxy) / (sxx * syy), sxy / sxx


def main(argv):
    folder, target = argv[1], argv[2]
    runs = [json.load(open(f)) for f in sorted(glob.glob(f"{folder}/run_*.json"))]
    merged = merge(runs)
    meta = {
        "what": "Clan power over 50 simulated playthroughs (QA, docs/qa/clan-power-50.md)",
        "chapters": "index 0..7 = chapters 1..8. power_start: after the chapter's"
                    " turn (and the offers taken on arrival); power_end: just"
                    " before the next chapter's turn (the end of the run for 8)."
                    " Chapter 1: the state when the run starts.",
        "delta": "per chapter, power moved by source: holding (+1 a place held"
                 " at the turn), neglect (-5, a main clan not helped), gift (a"
                 " clan's gift taken), quest (a quest handed in for the clan),"
                 " story (a story choice or event's own power), turn_other (the"
                 " rest of the turn), fall (a clan left with no place: power to"
                 " 0), nemesis_broken. The sum of a chapter's delta is"
                 " power_end - the previous power_end (checked on every row).",
        "runs": len(merged),
    }
    with open(target, "w") as handle:
        json.dump({"meta": meta, "runs": merged}, handle, separators=(",", ":"))
        handle.write("\n")

    n = len(merged)
    chapters = 8

    def series(clan, key):
        return [[run["clans"][clan][key][c] for run in merged] for c in range(chapters)]

    print("### Power by chapter (mean, min to max over the runs; start of the chapter)\n")
    print("| Clan | start | " + " | ".join(f"ch {c}" for c in range(1, 9)) + " |")
    print("|---|---|" + "---|" * 8)
    for clan in MAIN:
        cells = []
        for c in range(chapters):
            v = series(clan, "power_start")[c]
            cells.append(f"{st.mean(v):.0f} ({min(v)} to {max(v)})")
        print(f"| {clan} | {runs[0]['chapters'][0]['start']['power'][clan]} | " + " | ".join(cells) + " |")
    print("\n### Power at the end of a chapter (mean)\n")
    print("| Clan | " + " | ".join(f"ch {c}" for c in range(1, 9)) + " |")
    print("|---|" + "---|" * 8)
    for clan in MAIN:
        print(f"| {clan} | " + " | ".join(f"{st.mean(v):.0f}" for v in series(clan, "power_end")) + " |")

    print("\n### Places held (mean) at the start of a chapter\n")
    print("| Clan | " + " | ".join(f"ch {c}" for c in range(1, 9)) + " |")
    print("|---|" + "---|" * 8)
    for clan in MAIN:
        print(f"| {clan} | " + " | ".join(f"{st.mean(v):.1f}" for v in series(clan, "holds_start")) + " |")

    print("\n### Runs that saw a clan change tier, take or lose a place, or fall\n")
    print("| Clan | tier up | tier down | any tier change | took a place | lost a place | fell |")
    print("|---|---|---|---|---|---|---|")
    for clan in MAIN:
        up = down = anyc = took = lost = fell = 0
        for run in merged:
            c = run["clans"][clan]
            line = [c["power_start"][0]] + [x for pair in zip(c["power_start"], c["power_end"]) for x in pair]
            tiers = [tier(x) for x in line]
            order = [t for _, t in reversed(TIERS)]
            idx = [order.index(t) for t in tiers]
            u = any(b > a for a, b in zip(idx, idx[1:]))
            d = any(b < a for a, b in zip(idx, idx[1:]))
            up += u
            down += d
            anyc += u or d
            took += any(t["to"] == clan for t in run["territory"])
            lost += any(t["from"] == clan for t in run["territory"])
            fell += any(c["fallen_end"])
        print(f"| {clan} | {up} | {down} | {anyc} | {took} | {lost} | {fell} |")

    print("\n### What moved the power: mean points a run, by source\n")
    print("| Clan | holding | neglect | gift | quest | story | fall / claim / war | net |")
    print("|---|---|---|---|---|---|---|---|")
    total = collections.Counter()
    for clan in MAIN:
        by = collections.Counter()
        for run in merged:
            for d in run["clans"][clan]["delta"]:
                for k, v in d.items():
                    by[source(k)] += v
        for k, v in by.items():
            total[k] += abs(v)
        net = sum(by.values())
        print(f"| {clan} | " + " | ".join(f"{by[s] / n:+.1f}" for s in SOURCES) + f" | {net / n:+.1f} |")
    print("\n### Share of all the points moved (absolute, main clans)\n")
    grand = sum(total.values())
    for s in SOURCES:
        print(f"- {s}: {100 * total[s] / grand:.0f}%")

    print("\n### Is it linear?\n")
    print("| Clan | mean curve R² | mean slope a chapter | runs with R² over 0.9 | runs with a step of 8+ in a chapter | steps of 8+, all chapters |")
    print("|---|---|---|---|---|---|")
    for clan in MAIN:
        mean_curve = [st.mean(v) for v in series(clan, "power_start")]
        r_mean, slope = r2(mean_curve)
        high = 0
        jumpy = 0
        jumps = 0
        for run in merged:
            c = run["clans"][clan]
            ends = c["power_end"]
            r_run, _ = r2(c["power_start"])
            high += r_run > 0.9
            steps = [abs(b - a) for a, b in zip([c["power_start"][0]] + ends[:-1], ends)]
            js = sum(s >= 8 for s in steps)
            jumpy += js > 0
            jumps += js
        print(f"| {clan} | {r_mean:.2f} | {slope:+.1f} | {high} of {n} | {jumpy} of {n} | {jumps} of {n * chapters} |")

    print("\n### One chapter's net change of a main clan (all runs, clans and chapters)\n")
    nets = []
    for run in merged:
        for clan in MAIN:
            c = run["clans"][clan]
            prev = [c["power_start"][0]] + c["power_end"][:-1]
            nets += [b - a for a, b in zip(prev, c["power_end"])]
    nets.sort()
    q = lambda p: nets[int(p * (len(nets) - 1))]
    print(f"- {len(nets)} clan-chapters; mean {st.mean(nets):+.2f}, median {st.median(nets):+.0f}, "
          f"10th/90th percentile {q(.1):+d}/{q(.9):+d}, min {nets[0]:+d}, max {nets[-1]:+d}")
    print(f"- |change| 5 or less: {100 * sum(abs(x) <= 5 for x in nets) / len(nets):.0f}%; "
          f"8 or more: {100 * sum(abs(x) >= 8 for x in nets) / len(nets):.0f}%")

    print("\n### By the clan the run backs (patron), the patron's power at the start of each chapter (mean)\n")
    print("| Patron | runs | " + " | ".join(f"ch {c}" for c in range(1, 9)) + " |")
    print("|---|---|" + "---|" * 8)
    for clan in MAIN:
        mine = [run for run in merged if run["patron"] == clan]
        if not mine:
            continue
        print(f"| {clan} | {len(mine)} | " + " | ".join(
            f"{st.mean(run['clans'][clan]['power_start'][c] for run in mine):.0f}"
            for c in range(chapters)) + " |")
    print("\nNemesis (a clan that was the nemesis at some chapter's turn): " + ", ".join(
        f"{clan} {sum(clan in run['nemeses'] for run in merged)}" for clan in MAIN))

    print("\n### Dramatic runs (largest single-chapter swings, main clans)\n")
    swings = []
    for run in merged:
        for clan in MAIN:
            c = run["clans"][clan]
            prev = [c["power_start"][0]] + c["power_end"][:-1]
            for i, (a, b) in enumerate(zip(prev, c["power_end"])):
                swings.append((b - a, run["run"], clan, i + 1, run["patron"], dict(c["delta"][i])))
    for d, r, clan, ch, patron, why in sorted(swings, key=lambda s: -abs(s[0]))[:8]:
        print(f"- run {r} ({patron}): {clan} {d:+d} in chapter {ch}: {why}")
    falls = collections.Counter()
    for run in merged:
        for clan in MAIN:
            c = run["clans"][clan]
            if any(c["fallen_end"]):
                falls[(run["run"], clan)] = c["fallen_end"].index(True) + 1
    print("\nFalls (run, clan: chapter): " + ", ".join(f"{r} {c}: {ch}" for (r, c), ch in sorted(falls.items())))


if __name__ == "__main__":
    main(sys.argv)

#!/usr/bin/env python3
"""Sets the typical player beside the naive and the competent one
(docs/simulation/typical-player.md), from typical-player-runs_test.dart.txt.

    python3 typical_summary.py NAIVE.json TYPICAL.json COMPETENT.json \
        TYPICAL-BUILDS.json OUT_DIR

Writes OUT_DIR/typical-summary.json (per chapter and policy: encounters,
won on the first try, won within 3 tries, deaths; the bosses' loss rates;
the deadliest fights) and OUT_DIR/typical-player-builds.json (per fight of
the builds file and per profession, the median-level typical run's build on
arrival, as a PlayerSession save: the median by level, ties by seed; the
politics' histories left out). Uses story_summary.py's terms.
"""
import json
import os
import statistics
import sys
from collections import defaultdict

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                'difficulty-review-1.914'))
from story_summary import BOSSES, CHAPTERS, ch_key, summarise  # noqa: E402


def per_chapter(runs):
    s = summarise(runs)
    out = {}
    for c in CHAPTERS:
        enc = sum(r['byChapter'].get(ch_key(c), {}).get('fights', 0)
                  for r in runs)
        first = sum(r['byChapter'].get(ch_key(c), {}).get('firstTry', 0)
                    for r in runs)
        won = sum(r['byChapter'].get(ch_key(c), {}).get('won', 0)
                  for r in runs)
        ch = s['chapters'][c]
        out[c] = {
            'runsReached': ch['runsReached'],
            'encounters': enc,
            'firstTryPct': round(100.0 * first / enc, 1) if enc else None,
            'within3Pct': round(100.0 * won / enc, 1) if enc else None,
            'deaths': ch['deaths'],
            'medianArrivalLevel': ch['medianArrivalLevel'],
        }
    bosses = {}
    for b, target in BOSSES.items():
        f = l = 0
        for r in runs:
            for es in r['enemiesByChapter'].values():
                if b in es:
                    f += es[b]['fought']
                    l += es[b]['lost']
        bosses[b] = {'target': target, 'fought': f, 'lost': l,
                     'lossPct': round(100.0 * l / f, 1) if f else None}
    return {
        'encounterWinPct': s['encounterWinPct'],
        'runsWithNoDeath': s['runsWithNoDeath'],
        'endings': s['endings'],
        'medianFinalLevel': s['medianFinalLevel'],
        'chapters': out,
        'bosses': bosses,
        'deadliestFights': s['deadliestFights'],
    }


def pick_builds(runs, builds):
    by_seed = {r['seed']: r for r in runs}
    groups = defaultdict(lambda: defaultdict(list))
    for b in builds:
        r = by_seed[b['seed']]
        groups[b['node']][r['profession']].append(b)
    out = {}
    for node in sorted(groups, key=int):
        per = {}
        for prof, items in sorted(groups[node].items()):
            items.sort(key=lambda b: (b['save']['level'], b['seed']))
            pick = items[(len(items) - 1) // 2]
            r = by_seed[pick['seed']]
            levels = [b['save']['level'] for b in items]
            save = dict(pick['save'])
            # The politics' histories (log, news) weigh 90% of a save and
            # no fight reads them.
            save['politics'] = {k: v for k, v in save['politics'].items()
                                if k not in ('log', 'news', 'relationsLog')}
            per[prof] = {
                'seed': pick['seed'],
                'race': r['race'],
                'goal': r['goal'],
                'chapter': pick['chapter'],
                'enemies': pick['enemies'],
                'runsArriving': len(items),
                'levelRange': [min(levels), max(levels)],
                'medianLevel': statistics.median(levels),
                'save': save,
            }
        common = max(per, key=lambda p: (per[p]['runsArriving'], p))
        out[node] = {'mostCommonProfession': common, 'byProfession': per}
    return out


def main():
    naive, typical, competent = (json.load(open(p)) for p in sys.argv[1:4])
    builds = json.load(open(sys.argv[4]))
    out = sys.argv[5]
    summary = {p: per_chapter(r) for p, r in
               (('naive', naive), ('typical', typical),
                ('competent', competent))}
    json.dump(summary, open(f'{out}/typical-summary.json', 'w'), indent=1)
    json.dump(pick_builds(typical, builds),
              open(f'{out}/typical-player-builds.json', 'w'), indent=1)


if __name__ == '__main__':
    main()

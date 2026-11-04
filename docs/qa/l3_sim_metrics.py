#!/usr/bin/env python3
"""QA: the L3's simulator figures from the runs' JSON files (SIM_OUT of
test/sim_playthroughs_test.dart), and a comparison of two sets.

    python3 docs/qa/l3_sim_metrics.py OLD.json[,OLD2.json] NEW.json[,NEW2.json]

Prints attempt win, encounter win, level and gold at the end, the endings, the
per-profession and per-chapter encounter win, the bosses against the curve's
targets (test/boss_balance_test.dart) and the enemies lost most.
"""
import collections, json, sys

BOSSES = {'aurel_vane': (1, 75), 'void_stalker': (3, 65),
          'hollow_court_inquisitor': (4, 55), 'bone_warden': (4, 55), 'void_archon': (5, 50),
          'white_admiral': (6, 45), 'claimant_vane': (7, 40), 'claimant_tallis': (7, 40),
          'claimant_morrow': (7, 40), 'tear_herald': (8, 35), 'void_sovereign': (8, 35)}


def load(arg):
    runs = []
    for f in arg.split(','):
        runs += json.load(open(f))
    return runs


def metrics(runs):
    n = len(runs)
    won = sum(r['won'] for r in runs); lost = sum(r['lost'] for r in runs)
    fought = collections.Counter(); lostc = collections.Counter()
    bychap = collections.defaultdict(lambda: [0, 0]); bypro = collections.defaultdict(lambda: [0, 0])
    for r in runs:
        for chap, enemies in r['enemiesByChapter'].items():
            c = int(chap.split()[-1])
            for e, v in enemies.items():
                fought[e] += v['fought']; lostc[e] += v['lost']
                bychap[c][0] += v['fought']; bychap[c][1] += v['lost']
                bypro[r['profession']][0] += v['fought']; bypro[r['profession']][1] += v['lost']
    enc = sum(fought.values())
    out = dict(
        n=n, attempt=100 * won / max(1, won + lost), encounter=100 * (1 - sum(lostc.values()) / max(1, enc)),
        level=sum(r['level'] for r in runs) / n, gold=sum(r['gold'] for r in runs) / n,
        endings=dict(collections.Counter(r['endedHow'] for r in runs)),
        pro={p: 100 * (1 - l / max(1, f)) for p, (f, l) in bypro.items() if not p.startswith('champion')},
        chap={c: 100 * (1 - l / max(1, f)) for c, (f, l) in sorted(bychap.items())},
        boss={b: (100 * (1 - lostc[b] / fought[b]) if fought[b] else None, fought[b]) for b in BOSSES},
        lostmost=sorted(((100 * lostc[e] / fought[e], e, fought[e]) for e in fought if fought[e] >= 40 and not e.startswith('champion')), reverse=True)[:6],
    )
    return out


def fmt(m):
    return (f"n={m['n']} attempt {m['attempt']:.1f}% encounter {m['encounter']:.1f}% level {m['level']:.1f} gold {m['gold']:.0f} "
            f"endings {m['endings']}")


if __name__ == '__main__':
    old, new = metrics(load(sys.argv[1])), metrics(load(sys.argv[2]))
    print('OLD', fmt(old)); print('NEW', fmt(new))
    print('profession (encounter win) old / new:')
    for p in sorted(new['pro']):
        print(f"  {p:9} {old['pro'].get(p, 0):5.1f} / {new['pro'][p]:5.1f}")
    spread = lambda m: max(m['pro'].values()) - min(m['pro'].values())
    print(f"  spread {spread(old):.1f} / {spread(new):.1f}")
    print('chapter (encounter win) old / new:', ' '.join(f"{c}:{old['chap'].get(c, 0):.0f}/{new['chap'][c]:.0f}" for c in new['chap']))
    print('bosses (encounter win, target) old / new:')
    for b, (ch, t) in BOSSES.items():
        o, nw = old['boss'][b], new['boss'][b]
        print(f"  {b:24} ch{ch} target {t}: " + (f"{o[0]:.0f}" if o[0] is not None else '-') + ' / ' + (f"{nw[0]:.0f} (n={nw[1]})" if nw[0] is not None else '-'))
    print('enemies lost most (new):', ', '.join(f"{e} {p:.0f}% (n={f})" for p, e, f in new['lostmost']))
    print('enemies lost most (old):', ', '.join(f"{e} {p:.0f}%" for p, e, f in old['lostmost']))

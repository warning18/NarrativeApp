#!/usr/bin/env python3
"""Formats the story runs of story_runs_test.dart.txt (see its header).

    python3 story_summary.py NAIVE.json COMPETENT.json OUT_DIR [RUNS11.json RUNS23.json]

Writes OUT_DIR/story-runs-1.914.csv (one row per run and policy, per-chapter
columns) and OUT_DIR/story-summary.json. The optional last two files are the
800-run check (test/sim_playthroughs_test.dart, SIM_GOALS=random,favorGood,
favorEvil,maximizeGold SIM_RUNS=400 SIM_SEED=11 / 23) for the comparison
figures.

Terms:
- attempt: one try at a fight; an encounter is one fight scene, retried up
  to 3 times (the chapter-1 fights with a defeat branch, scenes 105, 110,
  120 and 400, are fought once and the story goes on after a loss).
- failed attempts = attempts - encounters won.
- a death: an encounter lost after its 3 tries (with permadeath on, the run
  ends there). Story losses (the defeat branches) are counted apart.
- "would die in chapter c": the chapter of a run's first death.
"""
import csv
import json
import statistics
import sys
from collections import Counter, defaultdict

STORY_LOSS_NODES = {'105', '110', '120', '400'}
CHAPTERS = list(range(1, 9))
# The chapter bosses and their targets (boss_balance_test, share won).
BOSSES = {'aurel_vane': 75, 'void_stalker': 65, 'hollow_court_inquisitor': 55,
          'bone_warden': 55, 'void_archon': 50, 'white_admiral': 45,
          'claimant_vane': 40, 'claimant_tallis': 40, 'claimant_morrow': 40,
          'tear_herald': 35, 'void_sovereign': 35}


def ch_key(c):
    return f'Chapter {c}'


def per_run(r):
    """Per-chapter facts of one run."""
    out = {}
    deaths_by_ch = defaultdict(list)
    story_losses = defaultdict(list)
    for f in r['fights']:
        if f['won']:
            continue
        fid = f"{f['node']}:{f['enemy']}"
        (story_losses if f['node'] in STORY_LOSS_NODES else deaths_by_ch)[
            f['chapter']].append(fid)
    for c in CHAPTERS:
        b = r['byChapter'].get(ch_key(c), {'attempts': 0, 'won': 0,
                                           'fights': 0, 'firstTry': 0})
        a = r['arrivals'].get(str(c))
        out[c] = {
            'reached': a is not None or ch_key(c) in r['byChapter'],
            'attempts': b['attempts'],
            'won': b['won'],
            'encounters': b['fights'],
            'failed': b['attempts'] - b['won'],
            'deaths': deaths_by_ch[c],
            'storyLosses': story_losses[c],
            'arrLevel': a['level'] if a else None,
            'arrGold': a['gold'] if a else None,
        }
    finished = r['endedHow'] == 'ending'
    for c in CHAPTERS:
        nxt = out.get(c + 1)
        out[c]['finished'] = out[c]['reached'] and (
            (nxt is not None and nxt['reached']) or (c == 8 and finished))
    first_death = next((c for c in CHAPTERS if out[c]['deaths']), None)
    return out, first_death


def pct(n, d):
    return None if d == 0 else round(100.0 * n / d, 1)


def summarise(runs):
    facts = [per_run(r) for r in runs]
    n = len(runs)
    chapters = {}
    for c in CHAPTERS:
        rows = [f[0][c] for f in facts]
        reached = [x for x in rows if x['reached']]
        att = sum(x['attempts'] for x in rows)
        won = sum(x['won'] for x in rows)
        enc = sum(x['encounters'] for x in rows)
        deaths = Counter(d for x in rows for d in x['deaths'])
        story = Counter(d for x in rows for d in x['storyLosses'])
        fought = Counter()
        for r in runs:
            for f in r['fights']:
                if f['chapter'] == c:
                    fought[f"{f['node']}:{f['enemy']}"] += 1
        by_enemy = Counter()
        by_enemy_fought = Counter()
        for r in runs:
            for e, v in r['enemiesByChapter'].get(ch_key(c), {}).items():
                by_enemy[e] += v['lost']
                by_enemy_fought[e] += v['fought']
        lv = [x['arrLevel'] for x in rows if x['arrLevel'] is not None]
        gd = [x['arrGold'] for x in rows if x['arrGold'] is not None]
        first_deaths = sum(1 for f in facts if f[1] == c)
        alive_in = sum(1 for f in facts if f[1] is None or f[1] >= c)
        chapters[c] = {
            'runsReached': len(reached),
            'runsFinished': sum(1 for x in rows if x['finished']),
            'attempts': att,
            'won': won,
            'failedAttempts': att - won,
            'attemptWinPct': pct(won, att),
            'encounters': enc,
            'encounterWinPct': pct(won, enc),
            'deaths': sum(deaths.values()),
            'storyLosses': sum(story.values()),
            'runsWithADeath': sum(1 for x in rows if x['deaths']),
            'permadeath': {'aliveOnArrival': alive_in,
                           'firstDeathHere': first_deaths},
            'medianArrivalLevel': statistics.median(lv) if lv else None,
            'medianArrivalGold': statistics.median(gd) if gd else None,
            'topFightsByDeaths': [
                {'fight': k, 'deaths': v, 'fought': fought[k]}
                for k, v in deaths.most_common(6)],
            'storyLossesByFight': [
                {'fight': k, 'lost': v, 'fought': fought[k]}
                for k, v in story.most_common(6)],
            'enemiesByLosses': [
                {'enemy': k, 'lost': v, 'fought': by_enemy_fought[k]}
                for k, v in by_enemy.most_common(8) if v],
            'fightsNeverLost': sorted(
                k for k, v in fought.items()
                if deaths[k] == 0 and story[k] == 0 and v >= 10),
        }
    allf = Counter()
    alld = Counter()
    for r in runs:
        for f in r['fights']:
            fid = f"ch{f['chapter']} {f['node']}:{f['enemy']}"
            allf[fid] += 1
            if not f['won'] and f['node'] not in STORY_LOSS_NODES:
                alld[fid] += 1
    deadliest = [{'fight': k, 'deaths': v, 'fought': allf[k],
                  'lossPct': pct(v, allf[k])} for k, v in alld.most_common(10)]

    def group(key):
        g = defaultdict(list)
        for r, f in zip(runs, facts):
            g[r[key]].append((r, f))
        res = {}
        for k, items in sorted(g.items()):
            att = sum(x['attempts'] for _, f in items for x in f[0].values())
            won = sum(x['won'] for _, f in items for x in f[0].values())
            enc = sum(x['encounters'] for _, f in items for x in f[0].values())
            de = sum(len(x['deaths']) for _, f in items for x in f[0].values())
            survive = sum(1 for _, f in items if f[1] is None)
            fd = Counter(f[1] for _, f in items if f[1] is not None)
            res[k] = {
                'runs': len(items),
                'attemptWinPct': pct(won, att),
                'encounterWinPct': pct(won, enc),
                'deathsPerRun': round(de / len(items), 2),
                'runsWithNoDeath': survive,
                'firstDeathChapter': dict(sorted(fd.items())),
                'medianFinalLevel': statistics.median(r['level'] for r, _ in items),
                'medianFinalGold': statistics.median(r['gold'] for r, _ in items),
            }
        return res

    att = sum(c['attempts'] for c in chapters.values())
    won = sum(c['won'] for c in chapters.values())
    enc = sum(c['encounters'] for c in chapters.values())
    return {
        'runs': n,
        'endings': dict(Counter(r['endedHow'] for r in runs)),
        'furthestChapter': dict(Counter(r['chapter'] for r in runs)),
        'attemptWinPct': pct(won, att),
        'encounterWinPct': pct(won, enc),
        'attempts': att, 'won': won, 'encounters': enc,
        'runsWithNoDeath': sum(1 for f in facts if f[1] is None),
        'medianFinalLevel': statistics.median(r['level'] for r in runs),
        'medianFinalGold': statistics.median(r['gold'] for r in runs),
        'chapters': chapters,
        'deadliestFights': deadliest,
        'byRace': group('race'),
        'byProfession': group('profession'),
        'byGoal': group('goal'),
    }


def check800(paths):
    runs = []
    for p in paths:
        runs += json.load(open(p))
    ch = {}
    for c in CHAPTERS:
        a = sum(r['byChapter'].get(ch_key(c), {}).get('attempts', 0) for r in runs)
        w = sum(r['byChapter'].get(ch_key(c), {}).get('won', 0) for r in runs)
        e = sum(r['byChapter'].get(ch_key(c), {}).get('fights', 0) for r in runs)
        lv = [r['arrivals'][str(c)]['level'] for r in runs if str(c) in r['arrivals']]
        gd = [r['arrivals'][str(c)]['gold'] for r in runs if str(c) in r['arrivals']]
        ch[c] = {'attempts': a, 'won': w, 'encounters': e,
                 'attemptWinPct': pct(w, a), 'encounterWinPct': pct(w, e),
                 'failedAttempts': a - w,
                 'medianArrivalLevel': statistics.median(lv) if lv else None,
                 'medianArrivalGold': statistics.median(gd) if gd else None}
    prof = defaultdict(lambda: [0, 0, 0])
    race = defaultdict(lambda: [0, 0, 0])
    for r in runs:
        for b in r['byChapter'].values():
            for g in (prof[r['profession']], race[r['race']]):
                g[0] += b['attempts']; g[1] += b['won']; g[2] += b['fights']
    lost = Counter(); fought = Counter()
    for r in runs:
        for c, es in r['enemiesByChapter'].items():
            for e, v in es.items():
                lost[f'{c} {e}'] += v['lost']; fought[f'{c} {e}'] += v['fought']
    bosses = {}
    for b, t in BOSSES.items():
        f = l = 0
        for r in runs:
            for es in r['enemiesByChapter'].values():
                if b in es:
                    f += es[b]['fought']; l += es[b]['lost']
        bosses[b] = {'target': t, 'fought': f, 'lost': l,
                     'encounterWinPct': pct(f - l, f)}
    return {
        'runs': len(runs),
        'bosses': bosses,
        'method': 'test/sim_playthroughs_test.dart, naive player, goals random,'
                  'favorGood,favorEvil,maximizeGold, seeds 11 and 23, 400 each,'
                  ' professions rotated, race drawn; measured on v1.914 (3309315f)',
        'endings': dict(Counter(r['endedHow'] for r in runs)),
        'chapters': ch,
        'byProfession': {k: {'runs': sum(1 for r in runs if r['profession'] == k),
                             'attemptWinPct': pct(v[1], v[0]),
                             'encounterWinPct': pct(v[1], v[2])}
                         for k, v in sorted(prof.items())},
        'byRace': {k: {'runs': sum(1 for r in runs if r['race'] == k),
                       'attemptWinPct': pct(v[1], v[0]),
                       'encounterWinPct': pct(v[1], v[2])}
                   for k, v in sorted(race.items())},
        'enemiesByLosses': [{'enemy': k, 'lost': v, 'fought': fought[k]}
                            for k, v in lost.most_common(10)],
    }


def write_csv(path, policies):
    cols = ['policy', 'seed', 'goal', 'race', 'profession', 'chapter_reached',
            'finished', 'first_death_chapter', 'final_level', 'final_gold']
    per = ['arr_level', 'arr_gold', 'attempts', 'won', 'failed', 'encounters',
           'deaths', 'story_losses', 'lost_to']
    for c in CHAPTERS:
        cols += [f'c{c}_{p}' for p in per]
    with open(path, 'w', newline='') as fh:
        w = csv.writer(fh)
        w.writerow(cols)
        for runs in policies:
            for r in runs:
                f, fd = per_run(r)
                row = [r['policy'], r['seed'], r['goal'], r['race'],
                       r['profession'], r['chapter'],
                       int(r['endedHow'] == 'ending'), fd or '',
                       r['level'], r['gold']]
                for c in CHAPTERS:
                    x = f[c]
                    row += [x['arrLevel'] if x['arrLevel'] is not None else '',
                            x['arrGold'] if x['arrGold'] is not None else '',
                            x['attempts'], x['won'], x['failed'],
                            x['encounters'], len(x['deaths']),
                            len(x['storyLosses']),
                            ';'.join(x['deaths'] + [s + '(story)' for s in x['storyLosses']])]
                w.writerow(row)


def main():
    naive = json.load(open(sys.argv[1]))
    comp = json.load(open(sys.argv[2]))
    out = sys.argv[3]
    write_csv(f'{out}/story-runs-1.914.csv', [naive, comp])
    summary = {
        'version': '1.914.0 (origin/main 3309315f)',
        'plan': 'seeds 1..100, one simulatePlaythroughs call per seed; the 25 '
                'race x profession pairs x 4 goals (random, favorGood, '
                'favorEvil, maximizeGold), see story_runs_test.dart.txt',
        'notes': 'Lost fights do not stop a run: after 3 failed tries the walk '
                 'moves on. "deaths" = encounters lost after 3 tries (the run '
                 'would end there with permadeath). Story losses = the '
                 'chapter-1 defeat branches (scenes 105, 110, 120, 400), fought '
                 'once. Fight ids are scene:enemy (the first enemy of a pack).',
        'naive': summarise(naive),
        'competent': summarise(comp),
    }
    if len(sys.argv) > 5:
        summary['check800_naive_v1914'] = check800(sys.argv[4:6])
    json.dump(summary, open(f'{out}/story-summary.json', 'w'), indent=1)


if __name__ == '__main__':
    main()

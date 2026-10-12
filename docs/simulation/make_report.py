#!/usr/bin/env python3
"""Builds the tables of the simulation reports from the simulator's JSON.

The runs come from the headless harness (see docs/simulation/README in the
reports): `test/sim_playthroughs_test.dart` (SIM_RUNS, SIM_SEED, SIM_OUT) for
the 100-run batches, and `test/sim_coverage_test.dart` for the coverage
batches. This script only formats numbers; it changes no game data.

    python3 docs/simulation/make_report.py tables runs100.json     # report-100-runs.md
    python3 docs/simulation/make_report.py csv runs100.json        # runs-100.csv
    python3 docs/simulation/make_report.py explore-csv coverage.json  # runs-explore-100.csv
    python3 docs/simulation/make_report.py branches coverage.json  # report-branches.md
    python3 docs/simulation/make_report.py quests six.json thorough.json random.json  # report-quests.md

and prints the tables to stdout.
"""
import collections
import json
import statistics as st
import sys

import os

ROOT = os.environ.get('REPO') or __file__.rsplit('/docs/', 1)[0]


def load(path):
    with open(path) as f:
        return json.load(f)


def pct(a, b):
    return '–' if not b else f'{round(100 * a / b)}%'


def attempts(r):
    return r['won'] + r['lost']


def group_table(runs, key, order=None):
    """One row per value of `key`: the columns of the first report."""
    groups = collections.defaultdict(list)
    for r in runs:
        groups[r[key]].append(r)
    names = order or sorted(groups)
    lines = [
        '| group | runs | level | gold | alignment | scenes | attempts/run | attempt win | spell casts | quests seen | shops | offers | skills |',
        '|---|---|---|---|---|---|---|---|---|---|---|---|---|',
    ]
    for name in names:
        rs = groups[name]
        n = len(rs)
        mean = lambda f: sum(f(x) for x in rs) / n
        lines.append(
            f"| {name} | {n} | {mean(lambda x: x['level']):.1f} | {mean(lambda x: x['gold']):.0f} "
            f"| {mean(lambda x: x['alignment']):.0f} | {mean(lambda x: x['steps']):.0f} "
            f"| {mean(attempts):.0f} | {pct(sum(x['won'] for x in rs), sum(attempts(x) for x in rs))} "
            f"| {mean(lambda x: x['casts']):.0f} | {mean(lambda x: x['quests']):.1f} "
            f"| {mean(lambda x: x['shops']):.1f} | {mean(lambda x: x['offers']):.0f} "
            f"| {mean(lambda x: x['skills']):.1f} |")
    return '\n'.join(lines)


def chapter_rows(runs):
    by = collections.defaultdict(lambda: {'att': 0, 'won': 0, 'fights': 0})
    for r in runs:
        for k, v in r['byChapter'].items():
            by[k]['att'] += v['attempts']
            by[k]['won'] += v['won']
            by[k]['fights'] += v['fights']
    return by


def chapter_table(runs):
    n = len(runs)
    by = chapter_rows(runs)
    lines = [
        '| chapter | runs | encounters | attempts | attempts/run | encounter win | attempt win | failed attempts/run |',
        '|---|---|---|---|---|---|---|---|',
    ]
    for k in sorted(by):
        v = by[k]
        # `won` counts attempts won; an encounter is won when one attempt is.
        enc_lost = None
        lines.append(
            f"| {k} | {n} | {v['fights']} | {v['att']} | {v['att'] / n:.1f} "
            f"| {pct(v['won'], v['fights'])} | {pct(v['won'], v['att'])} "
            f"| {(v['att'] - v['won']) / n:.1f} |")
    return '\n'.join(lines)


def chapter_by(runs, key, names):
    cols = [f'Chapter {i}' for i in range(1, 9)]
    lines = [f'| {key} | ' + ' | '.join(f'C{i}' for i in range(1, 9)) + ' |',
             '|---|' + '---|' * 8]
    for name in names:
        rs = [r for r in runs if r[key] == name]
        cells = []
        for c in cols:
            a = sum(r['byChapter'].get(c, {}).get('attempts', 0) for r in rs)
            w = sum(r['byChapter'].get(c, {}).get('won', 0) for r in rs)
            cells.append(f'{pct(w, a)} / {a / len(rs):.0f}')
        lines.append(f'| {name} | ' + ' | '.join(cells) + ' |')
    return '\n'.join(lines)


def chapter_by_profession(runs, names):
    cols = [f'Chapter {i}' for i in range(1, 9)]
    lines = ['| profession | ' + ' | '.join(f'C{i}' for i in range(1, 9)) + ' |',
             '|---|' + '---|' * 8]
    for name in names:
        rs = [r for r in runs if r['profession'] == name]
        cells = []
        for c in cols:
            a = sum(r['byChapter'].get(c, {}).get('attempts', 0) for r in rs)
            w = sum(r['byChapter'].get(c, {}).get('won', 0) for r in rs)
            cells.append(pct(w, a))
        lines.append(f'| {name} | ' + ' | '.join(cells) + ' |')
    return '\n'.join(lines)


def enemy_table(runs, enemies):
    met = collections.Counter()
    lost = collections.Counter()
    first = {}
    for r in runs:
        for e, n in r['enemies'].items():
            met[e] += n
        for e, n in r['enemiesLost'].items():
            lost[e] += n
    rows = []
    for e in met:
        d = enemies.get(e, {})
        rows.append((lost[e] / met[e], e, d.get('minChapter', '?'),
                     d.get('maxHealth', '?'), d.get('damage', '?'), met[e], lost[e]))
    rows.sort(key=lambda x: (-x[0], x[1]))
    lines = ['| enemy | first chapter | HP | damage | encounters | lost | loss rate |',
             '|---|---|---|---|---|---|---|']
    for rate, e, ch, hp, dmg, m, l in rows:
        lines.append(f'| {e} | {ch} | {hp} | {dmg} | {m} | {l} | {round(100 * rate)}% |')
    return '\n'.join(lines)


def percentile(xs, p):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(round(p * (len(xs) - 1))))]


def distributions(runs):
    measures = [
        ('level', 'level'), ('gold', 'gold'), ('alignment', 'alignment'),
        ('steps', 'steps'), ('unique', 'unique'), ('encounters', 'encounters'),
        ('won', 'won'), ('lost', 'lost'), ('casts', 'casts'),
        ('potions', 'potions'), ('quests', 'quests'), ('shops', 'shops'),
        ('flags', 'flags'), ('signs', 'signs'), ('offers', 'offers'),
        ('skills', 'skills'),
    ]
    lines = ['| measure | min | p10 | median | p90 | max | mean |',
             '|---|---|---|---|---|---|---|']
    for label, key in measures:
        xs = [r[key] for r in runs]
        lines.append(
            f'| {label} | {min(xs)} | {percentile(xs, .1)} | {percentile(xs, .5)} '
            f'| {percentile(xs, .9)} | {max(xs)} | {st.mean(xs):.1f} |')
    return '\n'.join(lines)


def headline(runs):
    won = sum(r['won'] for r in runs)
    att = sum(attempts(r) for r in runs)
    enc = sum(r['encounters'] for r in runs)
    # encounter won = at least one attempt won within it
    by = chapter_rows(runs)
    enc_won = sum(v['won'] for v in by.values())
    return {
        'runs': len(runs),
        'ended': sum(r['endedHow'] == 'ending' for r in runs),
        'ch8': sum(r['chapter'] == 8 for r in runs),
        'attempts': att,
        'encounters': enc,
        'attempt_win': 100 * won / att,
        'encounter_win': 100 * enc_won / max(1, sum(v['fights'] for v in by.values())),
        'level': st.mean(r['level'] for r in runs),
        'gold': st.mean(r['gold'] for r in runs),
    }


def profession_win(runs):
    d = collections.defaultdict(lambda: [0, 0])
    for r in runs:
        d[r['profession']][0] += r['won']
        d[r['profession']][1] += attempts(r)
    return {k: 100 * v[0] / v[1] for k, v in d.items()}


def level_buckets(runs):
    out = collections.defaultdict(lambda: [0, 0])
    for r in runs:
        b = '5 or less' if r['level'] <= 5 else '6 to 8' if r['level'] <= 8 else '9 to 11' if r['level'] <= 11 else '12 or more'
        out[b][0] += r['won']
        out[b][1] += attempts(r)
    return {k: 100 * v[0] / v[1] for k, v in out.items()}


# ---- branch coverage report (report-branches.md) ---------------------------

def unreached_table(cov, story):
    """The scenes no batch reached, with where they are reached from and why
    the way in stays shut for the simulated character."""
    seen = set()
    flags = set()
    for k in ('random', 'explore', 'exploreBothSides'):
        seen |= set(cov[k]['nodes'])
        flags |= set(cov[k]['flags'])
    unreached = [n for n in cov['universe']['nodes'] if n not in seen]
    incoming = collections.defaultdict(list)
    for nid, node in story.items():
        for i, c in enumerate(node.get('choices', [])):
            for kind, key in (('next', 'next_id'), ('fail', 'failNextId'),
                              ('lose', 'loseNextId')):
                to = c.get(key)
                if to:
                    incoming[to].append((nid, i, kind, c))
    rows = []
    for n in unreached:
        ins = incoming.get(n, [])
        reached = [f for f, _, _, _ in ins if f not in unreached]
        only_unreached = [f for f, _, _, _ in ins if f in unreached]
        if reached:
            src = ', '.join(sorted(set(reached)))
        else:
            src = '(only from other unreached scenes: ' + ', '.join(sorted(set(only_unreached))) + ')'
        why = []
        if not reached:
            why.append('downstream of the above')
        for f, i, kind, c in ins:
            if f in unreached:
                continue
            bits = [f'{f}#{i}: {kind}']
            need = c.get('showIfFlags') or []
            if need:
                bits.append('needs ' + ', '.join(need) + (' (no run set it)' if any(x not in flags for x in need) else ''))
            gate = c.get('politicsIf')
            if gate:
                text = json.dumps(gate, ensure_ascii=False)
                bits.append('clan/politics gate ' + (text if len(text) <= 90 else text[:90]))
            why.append('; '.join(bits))
        place = story.get(n, {}).get('location', '?')
        rows.append((n, place, src, ' / '.join(why)))
    lines = ['| scene | place | reached only from | what blocks it |', '|---|---|---|---|']
    for n, place, src, why in rows:
        lines.append(f'| {n} | {place} | {src} | {why} |')
    return '\n'.join(lines), unreached


def coverage_tables(cov):
    uni = cov['universe']
    lines = ['| batch | runs | scenes | ways on | quests offered | shops opened | enemies met |',
             '|---|---|---|---|---|---|---|']
    names = {'random': 'random', 'explore': 'explore',
             'exploreBothSides': 'explore, both sides of checks'}
    for key in ('random', 'explore', 'exploreBothSides'):
        for p in cov[key]['curve']:
            if p['runs'] in (10, 30, 100):
                lines.append(
                    f"| {names[key]} | {p['runs']} | {p['nodes']} ({round(100 * p['nodes'] / len(uni['nodes']))}%) "
                    f"| {p['choices']} ({round(100 * p['choices'] / len(uni['choices']))}%) "
                    f"| {p['quests']} | {p['shops']} | {p['enemies']} |")
    nodes = set()
    choices = set()
    for key in ('random', 'explore', 'exploreBothSides'):
        nodes |= set(cov[key]['nodes'])
        choices |= set(cov[key]['choices'])
    summary = (f"All three batches together (300 runs): **{len(nodes)}/{len(uni['nodes'])} scenes "
               f"({round(100 * len(nodes) / len(uni['nodes']))}%)** and {len(choices)}/{len(uni['choices'])} "
               f"ways on ({round(100 * len(choices) / len(uni['choices']))}%).")
    curve = ['| runs | scenes | ways on | quests | enemies |', '|---|---|---|---|---|']
    for p in cov['explore']['curve']:
        curve.append(f"| {p['runs']} | {p['nodes']} | {p['choices']} | {p['quests']} | {p['enemies']} |")
    return '\n'.join(lines), summary, '\n'.join(curve)


# ---- quest report (report-quests.md) ---------------------------------------

def quest_goal_table(runs, quests, goals):
    lines = ['| goal | runs | quests taken | quests done | quest gold | quest XP | level | attempt win |',
             '|---|---|---|---|---|---|---|---|']
    for g in goals:
        rs = [r for r in runs if r['strategy'] == g]
        n = len(rs)
        taken = sum(len(r['questRecords']) for r in rs) / n
        done = sum(sum(1 for q in r['questRecords'] if q['to'] is not None) for r in rs) / n
        gold = sum(sum(q['gold'] for q in r['questRecords'] if q['to'] is not None) for r in rs) / n
        xp = sum(sum(q['xp'] for q in r['questRecords'] if q['to'] is not None) for r in rs) / n
        lines.append(
            f"| {g} | {n} | {taken:.1f} | {done:.1f} | {gold:.0f} | {xp:.0f} "
            f"| {st.mean(r['level'] for r in rs):.1f} "
            f"| {pct(sum(r['won'] for r in rs), sum(attempts(r) for r in rs))} |")
    return '\n'.join(lines)


def quest_table(thorough, rand, quests):
    def stats(runs):
        taken = collections.Counter()
        done = collections.Counter()
        span = collections.defaultdict(list)
        stuck = collections.defaultdict(collections.Counter)
        for r in runs:
            for q in r['questRecords']:
                taken[q['id']] += 1
                if q['to'] is not None:
                    done[q['id']] += 1
                    span[q['id']].append(q['to'] - q['from'])
            for qid, objs in r['questsStuck'].items():
                for o in objs:
                    stuck[qid][o] += 1
        return taken, done, span, stuck
    tt, td, ts, tstuck = stats(thorough)
    rt, rd, rs_, _ = stats(rand)
    n_t, n_r = len(thorough), len(rand)
    lines = ['| chapter | quest | kind | difficulty | taken (thorough) | done (thorough) | taken (random) | done (random) | scenes to finish | pays | what stayed undone |',
             '|---|---|---|---|---|---|---|---|---|---|---|']
    order = sorted(quests.items(), key=lambda kv: (kv[1].get('chapter', 0), kv[1].get('questName', kv[0])))
    for qid, q in order:
        sp = ts.get(qid)
        stuck = tstuck.get(qid)
        top = ''
        if stuck:
            top = stuck.most_common(1)[0][0][:70]
        lines.append(
            f"| {q.get('chapter', 0)} | {q.get('questName', qid)} (`{qid}`) | {q.get('category', 'Main')} "
            f"| {q.get('difficulty', '')} | {pct(tt[qid], n_t)} | {pct(td[qid], n_t)} "
            f"| {pct(rt[qid], n_r)} | {pct(rd[qid], n_r)} "
            f"| {int(st.median(sp)) if sp else '–'} | {q.get('rewardGold', 0)}g {q.get('rewardXP', 0)}xp | {top} |")
    taken = sum(len(r['questRecords']) for r in thorough) / n_t
    done = sum(sum(1 for q in r['questRecords'] if q['to'] is not None) for r in thorough) / n_t
    return '\n'.join(lines), taken, done


def runs_csv(runs):
    cols = ['run', 'goal', 'race', 'profession', 'level', 'gold', 'alignment', 'ended',
            'furthest_chapter', 'scenes', 'distinct_scenes', 'encounters', 'attempts_won',
            'attempts_lost', 'spell_casts', 'potions', 'shops', 'quests', 'flags', 'signs',
            'offers', 'skills'] + [f'C{i}_attempts' for i in range(1, 9)] + [f'C{i}_won' for i in range(1, 9)]
    out = [','.join(cols)]
    for i, r in enumerate(runs, 1):
        row = [i, r['strategy'], r['race'], r['profession'], r['level'], r['gold'], r['alignment'],
               r['endedHow'], r['chapter'], r['steps'], r['unique'], r['encounters'], r['won'],
               r['lost'], r['casts'], r['potions'], r['shops'], r['quests'], r['flags'], r['signs'],
               r['offers'], r['skills']]
        row += [r['byChapter'].get(f'Chapter {c}', {}).get('attempts', 0) for c in range(1, 9)]
        row += [r['byChapter'].get(f'Chapter {c}', {}).get('won', 0) for c in range(1, 9)]
        out.append(','.join(str(x) for x in row))
    return '\r\n'.join(out) + '\r\n'


def explore_csv(cov):
    cols = ['run', 'profession', 'race', 'level', 'gold', 'alignment', 'scenes_seen', 'new_scenes',
            'new_ways_on', 'new_quests', 'checks', 'checks_failed', 'attempts_won',
            'attempts_lost', 'quests', 'ended']
    out = [','.join(cols)]
    for i, r in enumerate(cov['explore']['perRun'], 1):
        row = [i, r['profession'], r['race'], r['level'], r['gold'], r['alignment'], r['nodes'],
               r['newNodes'], r['newChoices'], r['newQuests'], r['checks'], r['checksFailed'],
               r['won'], r['lost'], r['quests'], r['endedHow']]
        out.append(','.join(str(x) for x in row))
    return '\r\n'.join(out) + '\r\n'


def main_tables(path):
    runs = load(path)
    enemies = load(f'{ROOT}/assets/gamedata/enemies.json')
    goals = ['random', 'favorGood', 'favorEvil', 'maximizeGold']
    professions = sorted({r['profession'] for r in runs})
    print('## 2. By goal\n')
    print(group_table(runs, 'strategy', goals))
    print('\n## 3. By profession\n')
    print(group_table(runs, 'profession'))
    print('\n## 4. By race\n')
    print(group_table(runs, 'race'))
    print('\n## 5. By chapter\n')
    print(chapter_table(runs))
    print('\nChapter by goal (attempt win / attempts per run):\n')
    print(chapter_by(runs, 'strategy', goals))
    print('\nChapter by profession (attempt win):\n')
    print(chapter_by_profession(runs, professions))
    print('\n## 6. Every enemy met (encounter loss = all 3 attempts failed)\n')
    print(enemy_table(runs, enemies))
    print('\n## 7. Distributions across the runs\n')
    print(distributions(runs))


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'tables':
        main_tables(sys.argv[2])
    elif cmd == 'csv':
        sys.stdout.write(runs_csv(load(sys.argv[2])))
    elif cmd == 'explore-csv':
        sys.stdout.write(explore_csv(load(sys.argv[2])))
    elif cmd == 'branches':
        cov = load(sys.argv[2])
        story = load(f'{ROOT}/assets/Cleaned_Narrative_DAG.json')
        cover, summary, curve = coverage_tables(cov)
        table, unreached = unreached_table(cov, story)
        print(cover); print(); print(summary); print(); print(curve); print()
        print(f'## What no run reached ({len(unreached)} scenes)\n'); print(table)
    elif cmd == 'quests':
        quests = load(f'{ROOT}/assets/gamedata/quests.json')
        six, thorough, rand = load(sys.argv[2]), load(sys.argv[3]), load(sys.argv[4])
        goals = ['random', 'favorGood', 'favorEvil', 'maximizeGold', 'explore', 'completionist']
        print(quest_goal_table(six, quests, goals)); print()
        table, taken, done = quest_table(thorough, rand, quests)
        print(table); print(); print(f'The thorough player takes {taken:.1f} quests a run and hands in {done:.1f}.')

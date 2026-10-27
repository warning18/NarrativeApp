// QA: the story graph cannot block the player at a fight or a test (see
// docs/qa/blocking-nodes.md, and docs/qa/blocking_nodes.py for the full
// analysis, which also lists the details). The graph is read as data, no
// run: a choice is open when its showIfFlags are set and its hideIfFlags are
// not; a lost fight goes to loseNextId (else it is retried), a failed check
// to failNextId (else on to next_id); a place's hub always offers the way
// back to the camp (camp_state.dart's canReturnToCampFrom).
//   - every flag a choice or a node waits for is set by something (a choice,
//     a quest, a zone, a coast event, the companions, the Host);
//   - every node can be entered, whatever order the player took things in
//     (a may-set / must-set dataflow over the flag gates);
//   - every fight's defeat branch and every check's failure branch meets the
//     way the win or the success takes again, and no skill challenge lacks
//     its failure branch;
//   - a choice that costs gold has a free way beside it, and so has a node
//     that waits for gold or for an alignment;
//   - every node can reach an ending.
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef Json = Map<String, dynamic>;

Json _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync()) as Json;

List<String> _strings(Object? v) =>
    v is List ? [for (final x in v) x.toString()] : const [];

void _collect(Object? o, String key, Set<String> into) {
  if (o is Map) {
    for (final e in o.entries) {
      if (e.key == key) {
        final v = e.value;
        if (v is String && v.isNotEmpty) into.add(v);
        if (v is List) into.addAll(v.whereType<String>());
      }
      _collect(e.value, key, into);
    }
  } else if (o is List) {
    for (final v in o) {
      _collect(v, key, into);
    }
  }
}

void main() {
  final graph =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Json;
  final nodes = {for (final e in graph.entries) e.key: e.value as Json};
  const ends = {'END', 'EXIT'};

  List<Json> choicesOf(String n) =>
      [for (final c in nodes[n]!['choices'] as List) c as Json];
  bool fight(Json c) =>
      c['triggerEnemyId'] != null ||
      (c['triggerEnemyIds'] as List?)?.isNotEmpty == true ||
      c['shipBattleId'] != null;
  bool check(Json c) => c['checkAbility'] != null;
  Json settlement(String n) => (nodes[n]!['settlement'] as Json?) ?? const {};

  final camps = [
    for (final n in nodes.keys)
      if (settlement(n)['kind'] == 'camp') n,
  ];
  final errands = [
    for (final e in nodes.entries)
      if (e.value['campErrand'] != null && e.value['campErrand'] != false)
        e.key,
  ];
  final places = [
    for (final n in nodes.keys)
      if (settlement(n).isNotEmpty &&
          settlement(n)['kind'] != 'camp' &&
          settlement(n)['chapter'] != null)
        n,
  ];

  // (choice or null, target, flags added): the ways out of a node.
  List<(Json?, String, List<String>)> edgesFrom(String n, {bool camp = true}) {
    final out = <(Json?, String, List<String>)>[];
    for (final c in choicesOf(n)) {
      final flags = _strings(c['flagsToAdd']);
      final next = c['next_id']?.toString() ?? '';
      if (c['returnToCamp'] == true && camp) {
        for (final k in camps) {
          out.add((c, k, flags));
        }
      }
      if (next.isNotEmpty) out.add((c, next, flags));
      if (check(c)) {
        final f = c['failNextId']?.toString() ?? '';
        out.add((c, f.isNotEmpty ? f : next, const []));
      }
      final lose = c['loseNextId']?.toString() ?? '';
      if (fight(c) && lose.isNotEmpty) out.add((c, lose, const []));
    }
    if (camp) {
      final s = settlement(n);
      if (places.contains(n)) {
        for (final k in camps) {
          out.add((null, k, const []));
        }
      }
      if (s['kind'] == 'camp') {
        for (final e in errands) {
          out.add((null, e, const []));
        }
        final chapter = (s['chapter'] as num?)?.toInt() ?? 0;
        for (final p in places) {
          if ((settlement(p)['chapter'] as num).toInt() <= chapter) {
            out.add((null, p, const []));
            final a = settlement(p)['arrivalNodeId']?.toString();
            if (a != null && nodes.containsKey(a)) out.add((null, a, const []));
          }
        }
      }
    }
    return [
      for (final e in out)
        if (!ends.contains(e.$2) && nodes.containsKey(e.$2)) e,
    ];
  }

  // The flags the game itself sets (companions, the Host, discovery), and
  // every table that can set one.
  bool gameFlag(String f) =>
      f.startsWith('ally_') ||
      f.startsWith('devoted_') ||
      f.startsWith('host_') ||
      f.startsWith('found_');

  final inGraph = <String>{
    for (final n in nodes.keys)
      for (final c in choicesOf(n)) ..._strings(c['flagsToAdd']),
  };
  final outside = <String>{};
  _collect(_table('quests'), 'flagToAdd', outside);
  _collect(_table('zones'), 'rewardFlag', outside);
  _collect(_table('politics_events'), 'flags', outside);
  _collect(_table('detour_scenes'), 'flag', outside);
  final setters = {...inGraph, ...outside};
  // A flag only a game system sets (an expedition cleared, the Host, a
  // companion) is taken as obtainable wherever it is waited for.
  bool external(String f) => gameFlag(f) || !inGraph.contains(f);

  group('the story graph does not block', () {
    test('every flag something waits for is set by something', () {
      final missing = <String>{};
      for (final n in nodes.keys) {
        final flags = [
          ..._strings(nodes[n]!['reqFlags']),
          for (final c in choicesOf(n)) ...[
            ..._strings(c['showIfFlags']),
            ..._strings(c['hideIfFlags']),
          ],
        ];
        for (final f in flags) {
          if (!setters.contains(f) && !gameFlag(f)) missing.add('$f ($n)');
        }
      }
      expect(missing, isEmpty);
    });

    test('every node can be entered under the flag gates', () {
      final may = <String, Set<String>>{'0': {}};
      final must = <String, Set<String>>{'0': {}};
      bool open(Json? c, Set<String> m, Set<String> s) {
        if (c == null) return true;
        for (final f in _strings(c['showIfFlags'])) {
          if (!external(f) && !m.contains(f)) return false;
        }
        for (final f in _strings(c['hideIfFlags'])) {
          if (!external(f) && s.contains(f)) return false;
        }
        return true;
      }

      var changed = true;
      while (changed) {
        changed = false;
        for (final n in may.keys.toList()) {
          for (final (c, t, fl) in edgesFrom(n)) {
            if (!open(c, may[n]!, must[n]!)) continue;
            final reqs = _strings(nodes[t]!['reqFlags']);
            if (reqs
                .any((f) => !gameFlag(f) && !{...may[n]!, ...fl}.contains(f))) {
              continue;
            }
            final newMay = {...may[n]!, ...fl};
            final newMust = {...must[n]!, ...fl};
            if (!may.containsKey(t)) {
              may[t] = newMay;
              must[t] = newMust;
              changed = true;
            } else {
              if (!may[t]!.containsAll(newMay)) {
                may[t]!.addAll(newMay);
                changed = true;
              }
              final keep = must[t]!.intersection(newMust);
              if (keep.length != must[t]!.length) {
                must[t] = keep;
                changed = true;
              }
            }
          }
        }
      }
      expect([
        for (final n in nodes.keys)
          if (!may.containsKey(n)) n
      ], isEmpty);
    });

    test('a defeat or a failure meets the way the win or success takes', () {
      Map<String, int> dists(String from) {
        final d = {from: 0};
        final q = Queue<String>()..add(from);
        while (q.isNotEmpty) {
          final x = q.removeFirst();
          for (final (_, t, _) in edgesFrom(x, camp: false)) {
            if (!d.containsKey(t)) {
              d[t] = d[x]! + 1;
              q.add(t);
            }
          }
        }
        return d;
      }

      final cache = <String, Map<String, int>>{};
      Map<String, int> of(String n) => cache.putIfAbsent(n, () => dists(n));
      final apart = <String>[], noFail = <String>[];
      for (final n in nodes.keys) {
        for (final c in choicesOf(n)) {
          if (c['challengeSuccessesNeeded'] != null &&
              (c['failNextId']?.toString() ?? '').isEmpty) {
            noFail.add(n);
          }
          for (final key in ['failNextId', 'loseNextId']) {
            final f = c[key]?.toString() ?? '';
            final ok = c['next_id']?.toString() ?? '';
            if (f.isEmpty || ends.contains(f) || !nodes.containsKey(f)) {
              continue;
            }
            if (!nodes.containsKey(ok)) continue;
            final df = of(f), ds = of(ok);
            if (!df.keys.any(ds.containsKey)) {
              apart.add('$n $key -> $f');
            }
          }
        }
      }
      expect(noFail, isEmpty,
          reason: 'skill challenges with no failure branch');
      expect(apart, isEmpty, reason: 'branches that never meet the main way');
    });

    test('a cost has a free way beside it; a gate has a free way round', () {
      final bad = <String>[];
      bool gated(String t) =>
          nodes[t]!.containsKey('reqGold') ||
          nodes[t]!.containsKey('reqAlignmentScore') ||
          nodes[t]!.containsKey('reqAlignmentMax');
      for (final n in nodes.keys) {
        final cs = choicesOf(n);
        if (cs.any((c) => c['pays'] == true) &&
            cs.every((c) => c['pays'] == true)) {
          bad.add('$n: every way costs gold');
        }
      }
      for (final n in nodes.keys) {
        final cs = choicesOf(n);
        final leadsToGate = cs.any((c) =>
            nodes.containsKey(c['next_id']) && gated(c['next_id'].toString()));
        if (!leadsToGate) continue;
        final free = cs.any((c) =>
            nodes.containsKey(c['next_id']) &&
            !gated(c['next_id'].toString()) &&
            c['pays'] != true);
        if (!free) bad.add('$n: only gated ways on');
      }
      expect(bad, isEmpty);
    });

    test('every node can reach an ending', () {
      final rev = <String, Set<String>>{};
      final good = <String>{};
      for (final n in nodes.keys) {
        for (final c in choicesOf(n)) {
          if (ends.contains(c['next_id']) || c['isEnding'] == true) good.add(n);
        }
        for (final (_, t, _) in edgesFrom(n)) {
          rev.putIfAbsent(t, () => {}).add(n);
        }
      }
      final q = Queue<String>.from(good);
      while (q.isNotEmpty) {
        for (final p in rev[q.removeFirst()] ?? const <String>{}) {
          if (good.add(p)) q.add(p);
        }
      }
      expect([
        for (final n in nodes.keys)
          if (!good.contains(n)) n
      ], isEmpty);
    });
  });
}

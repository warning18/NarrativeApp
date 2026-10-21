// QA: the clans' power over fifty simulated playthroughs (the measurement
// behind docs/qa/clan-power-50.md). Not a guard: it only runs when
// CLAN_POWER_OUT names a folder, and writes one JSON file a run there
// (CLAN_POWER_FROM and CLAN_POWER_TO pick the runs, 0 to 50 by default;
// tool/clan_power_report.py merges the files into docs/qa/).
//
// The simulator keeps only a run's final politics, so each run is replayed
// from its seed with `maxSteps` cut at the chapters' turns (a run is
// deterministic, so a shorter replay is a prefix of the longer one) and at
// every step where a clan's power moved, found by bisection. A chapter's
// turn is split into its holdings, its neglect and what the rest of the
// turn did, by running the game's own `territoryTurn` on the state before
// it; what moved power between two turns is told by what the step was (a
// quest handed in, an offer taken, a clan fallen, else the story's own).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _lastChapter = 8;

/// What a clan's power change [d] at one step was made of: quests handed in
/// ([quests] at most, [questPower] each), clan gifts taken ([offers] at
/// most, 2 or 4 each), and what is left, the story's own `power`.
Map<String, int> _split(int d, int quests, int offers) {
  var best = (5 * 0 + 0, 0, 0, 0);
  var bestMiss = d.abs() + 1;
  for (var a = 0; a <= quests; a++) {
    for (var c4 = 0; c4 <= offers; c4++) {
      for (var c2 = 0; c2 + c4 <= offers; c2++) {
        final made = questPower * a + legendaryGiftPower * c4 + giftPower * c2;
        final miss = (d - made).abs();
        // The nearest, then the one that explains the most.
        if (miss < bestMiss ||
            (miss == bestMiss && made.abs() > best.$1.abs())) {
          bestMiss = miss;
          best = (made, a, c4, c2);
        }
      }
    }
  }
  final (made, a, c4, c2) = best;
  return {
    if (a > 0) 'quest': questPower * a,
    if (c4 + c2 > 0) 'gift': legendaryGiftPower * c4 + giftPower * c2,
    if (d - made != 0) 'story': d - made,
  };
}

/// One snapshot of a replay: the run cut at [k] steps.
class _Snap {
  _Snap(this.k, this.run);
  final int k;
  final SimRunSummary run;
  PoliticsState get politics => run.politics;
  int get chapter => run.furthestChapter ?? 0;
  int get quests =>
      run.questRecords.where((q) => q.completedAtStep != null).length;
  int get offers => run.offers;
}

void main() {
  final out = Platform.environment['CLAN_POWER_OUT'];
  test('clan power over fifty playthroughs', () {
    if (out == null || out.isEmpty) return;
    final from =
        int.tryParse(Platform.environment['CLAN_POWER_FROM'] ?? '') ?? 0;
    final to = int.tryParse(Platform.environment['CLAN_POWER_TO'] ?? '') ?? 50;
    Directory(out).createSync(recursive: true);

    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final tables = {
      for (final name in [
        'enemies', 'dice', 'skills', 'items', 'shops', 'races', //
        'professions', 'spells', 'item_sets', 'zones', 'skill_trees',
        'factions', 'signs', 'subclans', 'relations', 'titles', 'geography',
        'biomes', 'quests', 'npcs', 'land_routes', 'land_events', 'houses',
        'expedition_steps', 'training_paths', 'specialisations',
        'spec_variants',
      ])
        name: _table(name),
    };
    final data = ClanData.fromTables(
      factions: tables['factions']!,
      subclans: tables['subclans']!,
      relations: tables['relations']!,
      titles: tables['titles']!,
    );
    final geography = Geography.parse(
        geography: tables['geography']!, biomes: tables['biomes']!);
    final gameConfig = _table('game_config');
    final professions = tables['professions']!.keys.toList()..sort();
    final races = tables['races']!.keys.toList()..sort();
    final clans = [
      for (final id in data.factions.keys)
        if (hasPower(id, data)) id,
    ];

    for (var r = from; r < to; r++) {
      final strategy = SimStrategy.values[r % SimStrategy.values.length];
      final raceId = races[(r + r ~/ 5) % races.length];
      final professionId = professions[r % professions.length];
      final seed = 7000 + r;
      final cache = <int, _Snap>{};
      _Snap at(int k) => cache.putIfAbsent(
            k,
            () => _Snap(
                k,
                simulatePlaythroughs(story,
                        tables: tables,
                        gameConfig: gameConfig,
                        plan: [
                          (
                            strategy: strategy,
                            raceId: raceId,
                            professionId: professionId
                          )
                        ],
                        seed: seed,
                        maxSteps: k)
                    .first),
          );

      final full = at(1500);
      final total = full.run.steps;
      final top = at(total);

      // The chapters' turns: the smallest cut at which the run has reached
      // each chapter.
      final arrival = <int, int>{};
      void arrivals(int lo, int hi, int loCh, int hiCh) {
        if (loCh >= hiCh) return;
        if (hi - lo <= 1) {
          for (var n = loCh + 1; n <= hiCh; n++) {
            arrival[n] = hi;
          }
          return;
        }
        final mid = (lo + hi) ~/ 2;
        final midCh = at(mid).chapter;
        arrivals(lo, mid, loCh, midCh);
        arrivals(mid, hi, midCh, hiCh);
      }

      arrivals(0, total, at(0).chapter, top.chapter);
      final reached = arrival.keys.where((n) => n >= 2).toList()..sort();

      String sig(PoliticsState p) => jsonEncode([
            [for (final id in clans) powerOf(p, id, data)],
            p.fallen,
            p.control.entries.map((e) => '${e.key}:${e.value}').toList()
              ..sort(),
          ]);

      // Every step in (lo, hi] where power or places moved, one by one.
      final events = <Map<String, dynamic>>[];
      void changes(int lo, int hi, int chapter) {
        final a = at(lo), b = at(hi);
        if (sig(a.politics) == sig(b.politics)) return;
        if (hi - lo <= 1) {
          final dq = b.quests - a.quests, dof = b.offers - a.offers;
          final fell = [
            for (final id in b.politics.fallen)
              if (!a.politics.fallen.contains(id)) id,
          ];
          final newChoices =
              b.run.choicesTaken.skip(a.run.choicesTaken.length).toList();
          events.add({
            'step': hi,
            'chapter': chapter,
            'choice': newChoices.isEmpty ? '' : newChoices.last,
            'delta': {
              for (final id in clans)
                if (powerOf(b.politics, id, data) !=
                    powerOf(a.politics, id, data))
                  id: fell.contains(id)
                      ? {
                          'fall': powerOf(b.politics, id, data) -
                              powerOf(a.politics, id, data)
                        }
                      : (powerOf(b.politics, id, data) -
                                      powerOf(a.politics, id, data) <
                                  0 &&
                              a.politics.nemesis == id &&
                              b.politics.nemesis.isEmpty
                          ? {
                              'nemesis_broken': powerOf(b.politics, id, data) -
                                  powerOf(a.politics, id, data)
                            }
                          : _split(
                              powerOf(b.politics, id, data) -
                                  powerOf(a.politics, id, data),
                              dq,
                              dof)),
            },
            'places': {
              for (final e in holdings(geography, b.politics).entries)
                if (holdings(geography, a.politics)[e.key] != e.value)
                  e.key: '${holdings(geography, a.politics)[e.key] ?? ''}'
                      '->${e.value}',
            },
          });
          return;
        }
        final mid = (lo + hi) ~/ 2;
        changes(lo, mid, chapter);
        changes(mid, hi, chapter);
      }

      // The turns, split by the game's own rules.
      final turns = <int, Map<String, dynamic>>{};
      for (final n in reached) {
        final j = arrival[n]!;
        final before = at(j - 1).politics;
        final after = at(j).politics;
        var s = applyLoyaltyDrift(before, data: data, chapter: n).state;
        final held = holdings(geography, s);
        final holding = <String, int>{}, neglect = <String, int>{};
        for (final id in clans) {
          if (s.fallen.contains(id)) continue;
          final places = held.values.where((h) => h == id).length;
          var value = powerOf(s, id, data) + holdingPower * places;
          holding[id] = holdingPower * places;
          if (isMainClan(id, data) && !s.helped.contains(id)) {
            final floor = (data.faction(id)!.startPower - neglectFloor)
                .clamp(0, maxPower);
            if (value > floor) {
              final lower =
                  (value - neglectPower) < floor ? floor : value - neglectPower;
              neglect[id] = lower - value;
            }
          }
        }
        final turn =
            territoryTurn(s, data: data, geography: geography, chapter: n);
        s = updateNemesis(turn.state, data, chapter: n);
        final delta = <String, Map<String, int>>{};
        final dq = at(j).quests - at(j - 1).quests;
        final dof = at(j).offers - at(j - 1).offers;
        for (final id in clans) {
          final was = powerOf(before, id, data);
          final h = holding[id] ?? 0, g = neglect[id] ?? 0;
          final turned = powerOf(s, id, data) - was;
          final other = turned - h - g;
          final extra = powerOf(after, id, data) - powerOf(s, id, data);
          final m = <String, int>{
            if (h != 0) 'holding': h,
            if (g != 0) 'neglect': g,
            if (other != 0)
              (after.fallen.contains(id) && !before.fallen.contains(id)
                  ? 'fall'
                  : 'turn_other'): other,
            if (extra != 0) ..._split(extra, dq, dof),
          };
          if (m.isNotEmpty) delta[id] = m;
        }
        turns[n] = {
          'step': j,
          'delta': delta,
          'changes': [
            for (final c in turn.changes)
              {
                'place': c.placeId,
                'from': c.from,
                'to': c.to,
                'cause': c.cause
              },
          ],
        };
      }

      // Between a chapter's arrival and the next one's.
      final spanStart = <int, int>{
        1: 0,
        for (final n in reached) n: arrival[n]!,
      };
      for (var n = 1; n <= _lastChapter; n++) {
        final lo = spanStart[n];
        if (lo == null) continue;
        final hi = n < _lastChapter && arrival.containsKey(n + 1)
            ? arrival[n + 1]! - 1
            : total;
        if (hi > lo) changes(lo, hi, n);
      }

      // Snapshots: the start of a chapter is after its turn, the end just
      // before the next one's.
      Map<String, dynamic> state(PoliticsState p) => {
            'power': {for (final id in clans) id: powerOf(p, id, data)},
            'places': {
              for (final id in clans) id: placesOf(id, geography, p),
            },
            'fallen': p.fallen,
            'nemesis': p.nemesis,
            'standing': {
              for (final e in p.standings.entries) e.key: e.value.round()
            },
          };
      final chapters = <Map<String, dynamic>>[];
      for (var n = 1; n <= _lastChapter; n++) {
        final startK = spanStart[n];
        if (startK == null) break;
        final endK = n < _lastChapter && arrival.containsKey(n + 1)
            ? arrival[n + 1]! - 1
            : total;
        final startSnap = at(startK == 0 ? 0 : startK);
        final endSnap = at(endK);
        chapters.add({
          'chapter': n,
          'startStep': startK,
          'endStep': endK,
          'before_turn': n >= 2 ? state(at(startK - 1).politics) : null,
          'start': state(startSnap.politics),
          'end': state(endSnap.politics),
          'turn': turns[n],
          'events': [
            for (final e in events)
              if (e['chapter'] == n) e,
          ],
        });
      }

      File('$out/run_${r.toString().padLeft(2, '0')}.json').writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert({
          'run': r,
          'seed': seed,
          'strategy': strategy.name,
          'race': raceId,
          'profession': professionId,
          'endedHow': full.run.endedHow,
          'furthestChapter': full.run.furthestChapter,
          'patron': full.run.patron,
          'sworn': full.run.politics.swornFactionId,
          'nemeses': full.run.nemeses.toList()..sort(),
          'finalNemesis': full.run.politics.nemesis,
          'territory': [
            for (final c in full.run.territory)
              {
                'place': c.placeId,
                'from': c.from,
                'to': c.to,
                'cause': c.cause
              },
          ],
          'chapters': chapters,
        }),
      );
      // ignore: avoid_print
      print('run $r done: ${cache.length} replays, chapters '
          '${chapters.length}, events ${events.length}');
    }
  }, timeout: const Timeout(Duration(hours: 2)));
}

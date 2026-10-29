// The professions' cores (profession_cores.dart): Fury, the Watchfire, the
// Ash Well, Flurry and the Trail; and, in the simulator, what each does to
// its profession's fights (docs/simulation/profession-cores.md has the
// full batch).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/profession_cores.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';
import 'support/sim_world.dart';

void main() {
  test('each profession has its core', () {
    expect(coreOfProfession('warrior'), ProfessionCore.fury);
    expect(coreOfProfession('cleric'), ProfessionCore.watchfire);
    expect(coreOfProfession('mage'), ProfessionCore.ashWell);
    expect(coreOfProfession('rogue'), ProfessionCore.flurry);
    expect(coreOfProfession('ranger'), ProfessionCore.trail);
    expect(coreOfProfession('bard'), ProfessionCore.none);
  });

  test('the Watchfire takes what heals past full, up to half', () {
    expect(
        watchfireAfterHeal(
            fire: 0, healing: 30, currentHealth: 90, maxHealth: 100),
        20);
    expect(
        watchfireAfterHeal(
            fire: 45, healing: 30, currentHealth: 100, maxHealth: 100),
        50);
    expect(
        watchfireAfterHeal(
            fire: 5, healing: 10, currentHealth: 50, maxHealth: 100),
        5);
    expect(watchfireBurn(20), 40);
  });

  test('the Ash Well: dearer spells cost one less, never under one', () {
    expect(ashWellSpellCost(3), 2);
    expect(ashWellSpellCost(1), 1);
    expect(ashWellHeal(5, 200), 20);
    expect(ashWellHeal(0, 200), 0);
  });

  test('a Flurry is two strikes at 55%', () {
    expect(flurryDamage(20, 20), 22);
    expect(flurryDamage(30, 0), 17);
  });

  test(
      'the Trail deals five of six faces a run, none twice, and shows the '
      'next', () {
    final deck = TrailDeck(6, Random(3));
    for (var run = 0; run < 20; run++) {
      final seen = <int>{};
      for (var i = 0; i < trailDrawsPerRun; i++) {
        final next = deck.peek();
        final drawn = deck.draw();
        expect(drawn, next);
        expect(seen.add(drawn), isTrue, reason: 'run $run: $drawn twice');
      }
      expect(seen, hasLength(5));
    }
  });

  test('in the simulator, each core against its profession without it', () {
    Map<String, dynamic> table(String name) =>
        jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
            as Map<String, dynamic>;
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final tables = simTables();
    final professions = tables['professions']!.keys.toList()..sort();
    final runs = int.tryParse(Platform.environment['CORES_RUNS'] ?? '') ??
        professions.length * 2;
    Map<String, ({double win, double rounds})> measure(Set<String> off) {
      final summaries = simulatePlaythroughs(story,
          tables: tables,
          gameConfig: table('game_config'),
          plan: [
            for (var i = 0; i < runs; i++)
              (
                strategy: SimStrategy.random,
                raceId: null,
                professionId: professions[i % professions.length],
              ),
          ],
          seed: 11,
          clashOff: off);
      final won = <String, int>{}, fights = <String, int>{};
      final rounds = <String, int>{};
      for (final r in summaries) {
        final p = r.professionId;
        won[p] = (won[p] ?? 0) + r.fightsWon;
        fights[p] = (fights[p] ?? 0) + r.fightsWon + r.fightsLost;
        rounds[p] = (rounds[p] ?? 0) + r.roundsFought;
      }
      return {
        for (final p in fights.keys)
          p: (win: 100 * won[p]! / fights[p]!, rounds: rounds[p]! / fights[p]!),
      };
    }

    final without = measure(const {'cores'});
    final withCores = measure(const {});
    for (final p in professions) {
      // ignore: avoid_print
      print('$p: ${without[p]!.win.toStringAsFixed(1)}% '
          '${without[p]!.rounds.toStringAsFixed(1)}r -> '
          '${withCores[p]!.win.toStringAsFixed(1)}% '
          '${withCores[p]!.rounds.toStringAsFixed(1)}r');
    }
    // Every core plays: its profession's fights change.
    for (final p in professions) {
      expect(withCores[p]!.win == without[p]!.win, isFalse, reason: p);
    }
  });
}

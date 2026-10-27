// Regression coverage for the three late-game "wall" bosses (Inquisition
// High Warden / Ch3, Hollow Court Zealot / Ch4, Void Manifestation / Ch5).
// A prior tuning pass found these effectively unwinnable for a solo,
// unassisted character at the level a normal playthrough actually reaches
// them (avg 249 retry attempts needed for Void Manifestation, hitting a
// 300-attempt cap regularly — see the session notes this test package's
// history references). This locks in win rates that keep them a genuine
// challenge without re-introducing that wall, and confirms a player who
// grinds a few more levels is meaningfully rewarded for it (the whole
// point of "leave the player a way to improve before being blocked").
//
// Combat here is a simplified stand-in for FightScreen's real loop (single
// die roll per round, a small keep/reroll heuristic, no potions/skills/
// allies) — deliberately pessimistic, so a passing win rate here is a
// floor a real, better-equipped player will clear more easily.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';

Future<Map<String, dynamic>> _loadJson(String path) async {
  final raw = await rootBundle.loadString(path);
  return json.decode(raw) as Map<String, dynamic>;
}

bool _shouldReroll(DiceFaceResult face, int hp, int maxHealth) {
  if (face.type == 'Empty') return true;
  final hpFrac = hp / maxHealth;
  if (hpFrac < 0.4) return face.type == 'Attack';
  if (face.type == 'Defend') return true;
  return false;
}

/// Fraction of [trials] a level-[level] "balanced fighter" (starter die,
/// starter skills only, no allies/potions/items) wins against [enemy] in
/// a single attempt. Deterministic (fixed seeds) so this never flakes.
double _winRate(
  Map<String, dynamic> enemy,
  Map<String, dynamic> skills,
  List<Map<String, dynamic>> faces,
  int level, {
  int trials = 500,
}) {
  var wins = 0;
  // The fighter's numbers on the fight's small scale (stat-scale.md: a
  // fifth of the 120 health + 20, 13 damage + 3, 3 armor + 2 a level; its
  // armor rounded up, as the game's own armor reaches a whole point).
  final maxHealth = 24 + 4 * (level - 1);
  final baseDamage = ((13 + 3 * (level - 1)) / 5).round();
  final baseArmor = ((3 + 2 * (level - 1)) / 5).ceil();
  final enemyMaxHealth =
      scaledMaxHealth((enemy['maxHealth'] as num).toInt(), level);
  final enemyDamage = scaledDamage((enemy['damage'] as num).toInt(), level);

  for (var t = 0; t < trials; t++) {
    final rand = Random(t * 13 + level);
    var hp = maxHealth;
    var enemyHealth = enemyMaxHealth;
    var won = false;
    for (var round = 0; round < 80; round++) {
      var face = rollDie(faces, rand);
      var rolls = 1;
      while (rolls < 3 && _shouldReroll(face, hp, maxHealth)) {
        face = rollDie(faces, rand);
        rolls++;
      }
      if (face.faceName == 'Profession Technique') {
        face = face.withLinkedSkillID('warrior_shield_bash');
      } else if (face.faceName == 'Heritage Technique') {
        face = face.withLinkedSkillID('human_resolve');
      }
      final result = resolvePlayerFace(face, skills, baseDamage);
      enemyHealth = max(0, enemyHealth - result.damageDealt);
      hp = min(maxHealth, hp + result.healingDone);
      final block = result.blockAmount;
      if (enemyHealth <= 0) {
        won = true;
        break;
      }
      final move = resolveEnemyMove(
        enemy: {...enemy, 'damage': enemyDamage},
        skills: skills,
        enemyCurrentHealth: enemyHealth,
        enemyMaxHealth: enemyMaxHealth,
        random: rand,
      );
      final dmgTaken = max(0, move.damage - block - baseArmor);
      hp = max(0, hp - dmgTaken);
      if (hp <= 0) {
        won = false;
        break;
      }
    }
    if (won) wins++;
  }
  return wins / trials;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> enemies;
  late Map<String, dynamic> skills;
  late List<Map<String, dynamic>> starterFaces;

  setUpAll(() async {
    enemies = await _loadJson('assets/gamedata/enemies.json');
    skills = await _loadJson('assets/gamedata/skills.json');
    final dice = await _loadJson('assets/gamedata/dice.json');
    starterFaces =
        ((dice['starter_die'] as Map<String, dynamic>)['faces'] as List)
            .cast<Map<String, dynamic>>();
  });

  group('late-game boss win rates stay winnable', () {
    // (enemyId, the level a normal playthrough typically reaches it at,
    // minimum and maximum acceptable single-attempt win rate).
    const cases = [
      ('inquisition_high_warden', 3, 0.20, 0.65),
      ('hollow_court_zealot', 4, 0.15, 0.60),
      ('void_manifestation', 4, 0.15, 0.55),
    ];

    for (final (enemyId, level, minRate, maxRate) in cases) {
      test(
          '$enemyId at level $level lands between '
          '${(minRate * 100).round()}% and ${(maxRate * 100).round()}% win rate',
          () {
        final enemy = enemies[enemyId] as Map<String, dynamic>;
        final rate = _winRate(enemy, skills, starterFaces, level);
        expect(
          rate,
          allOf(greaterThanOrEqualTo(minRate), lessThanOrEqualTo(maxRate)),
          reason: 'win rate was ${(rate * 100).toStringAsFixed(1)}% -- either '
              'a regression toward the old unwinnable stats, or an '
              'over-correction that makes the fight trivial',
        );
      });
    }

    test(
        'void_manifestation win rate rises with player level '
        '(grinding is a real way past the climax)', () {
      final enemy = enemies['void_manifestation'] as Map<String, dynamic>;
      final rateAtFour = _winRate(enemy, skills, starterFaces, 4);
      final rateAtSeven = _winRate(enemy, skills, starterFaces, 7);
      expect(rateAtSeven, greaterThan(rateAtFour + 0.15));
    });
  });

  // The boss curve (v1.280.0, the user's design): each chapter's bosses won
  // about this share of the time where the story puts them -- after the
  // chapter's own fights, at the level a run has by then -- easier early,
  // harder late, about half on average. Measured with the playthrough
  // simulator (encounter win: an encounter is lost after 3 failed
  // attempts); docs/simulation/ has the 800-run figures. Seeded, so the
  // numbers are fixed for given data; the tolerance is for data changes
  // elsewhere moving them a little. 400 runs (about 20 s): with 200, a new
  // loot roll anywhere shifted the seeded stream enough to move a boss met
  // only 64 times by 12 points (v1.281.0).
  group('the boss curve', () {
    const targets = {
      'aurel_vane': (1, 0.75),
      'void_stalker': (3, 0.65),
      'hollow_court_inquisitor': (4, 0.55),
      'bone_warden': (4, 0.55),
      'void_archon': (5, 0.50),
      'white_admiral': (6, 0.45),
      'claimant_vane': (7, 0.40),
      'claimant_tallis': (7, 0.40),
      'claimant_morrow': (7, 0.40),
      'tear_herald': (8, 0.35),
      'void_sovereign': (8, 0.35),
    };
    late Map<String, (int, int)> tally;

    /// The encounters each profession wins within three tries, in percent
    /// (the same 400 runs: the guard on the professions' spread, QA).
    late Map<String, double> professionWin;

    setUpAll(() {
      Map<String, dynamic> table(String name) =>
          jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
              as Map<String, dynamic>;
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
          'expedition_steps', 'training_paths', 'politics_events',
        ])
          name: table(name),
      };
      final professions = tables['professions']!.keys.toList()..sort();
      const goals = [
        SimStrategy.random,
        SimStrategy.favorGood,
        SimStrategy.favorEvil,
        SimStrategy.maximizeGold,
      ];
      final runs = simulatePlaythroughs(story,
          tables: tables,
          gameConfig: table('game_config'),
          plan: [
            for (var i = 0; i < 400; i++)
              (
                strategy: goals[i % goals.length],
                raceId: null,
                professionId:
                    professions[(i ~/ goals.length) % professions.length],
              ),
          ],
          seed: 7);
      tally = {};
      for (final run in runs) {
        for (final MapEntry(key: boss, value: (chapter, _))
            in targets.entries) {
          final met = run.enemiesByChapter['Chapter $chapter']?[boss];
          if (met == null) continue;
          final (fought, lost) = tally[boss] ?? (0, 0);
          tally[boss] = (fought + met.fought, lost + met.lost);
        }
      }
      final fought = <String, int>{};
      final lost = <String, int>{};
      for (final run in runs) {
        for (final chapter in run.enemiesByChapter.values) {
          for (final enemy in chapter.values) {
            fought[run.professionId] =
                (fought[run.professionId] ?? 0) + enemy.fought;
            lost[run.professionId] = (lost[run.professionId] ?? 0) + enemy.lost;
          }
        }
      }
      professionWin = {
        for (final p in professions)
          p: 100 * (1 - (lost[p] ?? 0) / (fought[p] ?? 1)),
      };
    });

    for (final MapEntry(key: boss, value: (chapter, target))
        in targets.entries) {
      test(
          '$boss (chapter $chapter) is won about ${(target * 100).round()}% '
          'of the time', () {
        final (fought, lost) = tally[boss] ?? (0, 0);
        expect(fought, greaterThanOrEqualTo(40), reason: 'too few met');
        final rate = (fought - lost) / fought;
        expect(rate, closeTo(target, _band(target, fought)),
            reason: 'won ${(rate * 100).toStringAsFixed(1)}% of $fought');
      });
    }

    // The three claimants are met one per run (whichever claim the run
    // backed), so each is met only about 50 to 80 times in the 400 runs:
    // their own bands are wide (see _band). Together they are met in every
    // run that gets that far, and held to the plain 12 points.
    test('the claimants together are won about 40% of the time', () {
      var fought = 0, lost = 0;
      for (final boss in const [
        'claimant_vane',
        'claimant_tallis',
        'claimant_morrow',
      ]) {
        final (f, l) = tally[boss] ?? (0, 0);
        fought += f;
        lost += l;
      }
      expect(fought, greaterThanOrEqualTo(300), reason: 'too few met');
      final rate = (fought - lost) / fought;
      expect(rate, closeTo(0.40, 0.12),
          reason: 'won ${(rate * 100).toStringAsFixed(1)}% of $fought');
    });

    test(
        'the bosses are won about half the time on average, early ones '
        'more often than late ones', () {
      double rate(String boss) {
        final (fought, lost) = tally[boss]!;
        return (fought - lost) / fought;
      }

      final rates = [for (final boss in targets.keys) rate(boss)];
      final mean = rates.reduce((a, b) => a + b) / rates.length;
      expect(mean, inInclusiveRange(0.42, 0.58));
      expect(rate('aurel_vane'), greaterThan(rate('void_archon')));
      expect(rate('void_archon'), greaterThan(rate('tear_herald')));
    });

    // The five professions win about as often as each other (the L3 on
    // v1.489 found the warrior at 73% and the mage at 60%; v1.497 and v1.499
    // closed it). No profession more than 8 points from the others (Core's
    // numbers sit within about 5; 8 stays quiet at the 0.1 to 1 point
    // noise), none under 60%. Core tunes this: the profession paths in
    // training_paths.json, bonusMaxHealth and the base numbers in
    // professions.json.
    test('the five professions win within 8 points of each other', () {
      final summary = [
        for (final e in professionWin.entries)
          '${e.key} ${e.value.toStringAsFixed(1)}%',
      ].join(', ');
      debugPrint('encounter win by profession: $summary');
      final spread =
          professionWin.values.reduce(max) - professionWin.values.reduce(min);
      expect(spread, lessThanOrEqualTo(8),
          reason: 'the professions are $spread points apart ($summary)');
      for (final e in professionWin.entries) {
        expect(e.value, greaterThanOrEqualTo(60),
            reason: '${e.key} wins ${e.value.toStringAsFixed(1)}% ($summary)');
      }
    });
  });
}

/// The band a boss's win rate is held to around [target], met [fought]
/// times in the seeded runs: 12 points, or three standard errors of a rate
/// measured on that few meetings when that is wider. A boss met 60 times
/// moves by 6 points for one standard error when another part of the story
/// shifts the seeded stream (Narrative's Wharf fold moved Morrow from 46%
/// to 54% with the game unchanged at Morrow; over three seeds it averages
/// 47% before and 46% after), so 12 points was a two-sigma band there.
double _band(double target, int fought) =>
    max(0.12, 3 * sqrt(target * (1 - target) / fought));

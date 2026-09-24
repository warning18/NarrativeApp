// Unit coverage for boss phases (lib/combat/combat_engine.dart's BossPhase
// helpers) plus a data check that every phase authored in enemies.json
// references real skills and reads cleanly in both languages.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _loadGamedata(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $name under ${Directory.current.path}');
}

void main() {
  final twoPhases = <String, dynamic>{
    'enemyName': 'Boss',
    'damage': 20,
    'skillMoves': [
      {'skillID': 'fireball', 'condition': 'Chance', 'chance': 30}
    ],
    'phases': [
      {
        'healthThreshold': 25,
        'name': 'Cornered',
        'nameFr': 'Acculé',
        'message': 'It comes back harder.',
        'messageFr': 'Il revient plus fort.',
        'damageMultiplier': 1.2,
        'healPercent': 15,
        'cleanse': true,
      },
      {
        'healthThreshold': 50,
        'name': 'Smoke',
        'message': 'It stops pretending to have a shape.',
        'damageMultiplier': 1.15,
        'addMoves': [
          {'skillID': 'void_blast', 'condition': 'Chance', 'chance': 45}
        ],
      },
    ],
  };

  group('parseBossPhases', () {
    test('orders phases from the highest threshold down', () {
      final phases = parseBossPhases(twoPhases);
      expect(phases.map((p) => p.healthThresholdPercent), [50, 25]);
      expect(phases.first.addMoves.single['skillID'], 'void_blast');
      expect(phases.last.cleanse, isTrue);
      expect(phases.last.healPercent, 15);
    });

    test('an ordinary enemy has none', () {
      expect(parseBossPhases({'enemyName': 'Rat'}), isEmpty);
      expect(parseBossPhases({'phases': 'nonsense'}), isEmpty);
    });

    test('names and messages fall back to English', () {
      final phases = parseBossPhases(twoPhases);
      expect(phases.last.nameFor(AppLanguage.fr), 'Acculé');
      expect(phases.first.nameFor(AppLanguage.fr), 'Smoke');
      expect(phases.last.messageFor(AppLanguage.fr), 'Il revient plus fort.');
      expect(phases.first.messageFor(AppLanguage.fr),
          'It stops pretending to have a shape.');
    });
  });

  group('bossPhaseIndexFor', () {
    final phases = parseBossPhases(twoPhases);

    test('counts the thresholds the health has fallen to', () {
      expect(bossPhaseIndexFor(phases, 100, 100), 0);
      expect(bossPhaseIndexFor(phases, 51, 100), 0);
      expect(bossPhaseIndexFor(phases, 50, 100), 1);
      expect(bossPhaseIndexFor(phases, 26, 100), 1);
      expect(bossPhaseIndexFor(phases, 25, 100), 2);
      expect(bossPhaseIndexFor(phases, 1, 100), 2);
    });

    test('a dead or phaseless enemy is never in a phase', () {
      expect(bossPhaseIndexFor(phases, 0, 100), 0);
      expect(bossPhaseIndexFor(const [], 10, 100), 0);
      expect(bossPhaseIndexFor(phases, 10, 0), 0);
    });
  });

  group('enemyDataInPhase', () {
    final phases = parseBossPhases(twoPhases);

    test('appends the phase moves without touching the source record', () {
      final inPhase = enemyDataInPhase(twoPhases, phases.first);
      final moves = (inPhase['skillMoves'] as List).cast<Map>();
      expect(moves.map((m) => m['skillID']), ['fireball', 'void_blast']);
      expect((twoPhases['skillMoves'] as List).length, 1);
    });

    test('replaceMoves swaps the whole list', () {
      const phase = BossPhase(
        healthThresholdPercent: 30,
        name: 'x',
        addMoves: [
          {'skillID': 'shadow_step', 'condition': 'Always'}
        ],
        replaceMoves: true,
      );
      final moves = (enemyDataInPhase(twoPhases, phase)['skillMoves'] as List)
          .cast<Map>();
      expect(moves.single['skillID'], 'shadow_step');
    });

    test('a phase without moves leaves the record as it is', () {
      expect(identical(enemyDataInPhase(twoPhases, phases.last), twoPhases),
          isTrue);
    });
  });

  group('healthAfterPhaseHeal', () {
    test('heals a share of max health, never past it', () {
      const phase =
          BossPhase(healthThresholdPercent: 25, name: 'x', healPercent: 15);
      expect(healthAfterPhaseHeal(phase, 20, 200), 50);
      expect(healthAfterPhaseHeal(phase, 195, 200), 200);
      const none = BossPhase(healthThresholdPercent: 25, name: 'x');
      expect(healthAfterPhaseHeal(none, 20, 200), 20);
    });
  });

  group('enemies.json phases', () {
    final enemies = _loadGamedata('enemies.json');
    final skills = _loadGamedata('skills.json');
    final zones = _loadGamedata('zones.json');

    test('every phase move names a real skill and every text is bilingual', () {
      var phased = 0;
      for (final entry in enemies.entries) {
        final phases = parseBossPhases(entry.value as Map<String, dynamic>);
        if (phases.isEmpty) continue;
        phased++;
        var lastThreshold = 101;
        for (final phase in phases) {
          expect(phase.healthThresholdPercent, inInclusiveRange(1, 99),
              reason: '${entry.key}: threshold');
          expect(phase.healthThresholdPercent, lessThan(lastThreshold),
              reason: '${entry.key}: thresholds must be distinct');
          lastThreshold = phase.healthThresholdPercent;
          expect(phase.name, isNotEmpty, reason: '${entry.key}: name');
          expect(phase.nameFr, isNotEmpty, reason: '${entry.key}: nameFr');
          expect(phase.message, isNotEmpty, reason: '${entry.key}: message');
          expect(phase.messageFr, isNotEmpty,
              reason: '${entry.key}: messageFr');
          expect(phase.damageMultiplier, inInclusiveRange(1.0, 1.3),
              reason: '${entry.key}: a phase enrage stays modest');
          for (final move in phase.addMoves) {
            expect(skills.containsKey(move['skillID']), isTrue,
                reason: '${entry.key}: unknown skill ${move['skillID']}');
          }
        }
      }
      expect(phased, greaterThanOrEqualTo(14));
    });

    test('every zone boss and solo-only unique has at least one phase', () {
      final bossIds = <String>{
        ...soloOnlyEnemyIds,
        for (final zone in zones.values)
          (zone as Map<String, dynamic>)['bossEnemyId']?.toString() ?? '',
      }..remove('');
      for (final id in bossIds) {
        expect(enemies.containsKey(id), isTrue, reason: id);
        expect(parseBossPhases(enemies[id] as Map<String, dynamic>), isNotEmpty,
            reason: '$id has no phases');
        expect(isBossEnemy(id, enemies[id] as Map<String, dynamic>), isTrue);
      }
    });
  });
}

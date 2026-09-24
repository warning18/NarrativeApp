import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/zone_gating.dart';

Map<String, dynamic> _loadGamedata(String name) {
  final candidates = ['assets/gamedata/$name', '../assets/gamedata/$name'];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $name under ${Directory.current.path}');
}

void main() {
  group('requiredFlagsOf / meetsRequiredFlags', () {
    test('a missing or empty field means no requirement', () {
      expect(requiredFlagsOf(const {}), isEmpty);
      expect(requiredFlagsOf(const {'requiredFlags': []}), isEmpty);
      expect(
          requiredFlagsOf(const {
            'requiredFlags': ['']
          }),
          isEmpty);
      expect(meetsRequiredFlags(const {}, const []), isTrue);
    });

    test('every listed flag must be present', () {
      const zone = {
        'requiredFlags': ['a', 'b']
      };
      expect(meetsRequiredFlags(zone, const ['a']), isFalse);
      expect(meetsRequiredFlags(zone, const ['b', 'a', 'c']), isTrue);
    });
  });

  group('zoneTier / zoneIsMain', () {
    test('tier defaults to 1 and never drops below it', () {
      expect(zoneTier(const {}), 1);
      expect(zoneTier(const {'tier': 0}), 1);
      expect(zoneTier(const {'tier': 3}), 3);
      expect(zoneIsMain(const {}), isFalse);
      expect(zoneIsMain(const {'isMainZone': true}), isTrue);
    });
  });

  group('lockRequirementName', () {
    const zones = {
      'z_a': {'zoneName': 'Zone A', 'rewardFlag': 'a_cleared'},
      'z_b': {'zoneName': 'Zone B', 'rewardFlag': 'b_cleared'},
    };

    test('names the zone whose rewardFlag is the first missing flag', () {
      const record = {
        'requiredFlags': ['a_cleared', 'b_cleared']
      };
      expect(lockRequirementName(record, const [], zones), 'Zone A');
      expect(lockRequirementName(record, const ['a_cleared'], zones), 'Zone B');
    });

    test('falls back to the flag id, and is null when nothing is missing', () {
      const record = {
        'requiredFlags': ['story_flag']
      };
      expect(lockRequirementName(record, const [], zones), 'story_flag');
      expect(lockRequirementName(record, const ['story_flag'], zones), isNull);
    });
  });

  group('zones.json / houses.json gating data', () {
    final zones = _loadGamedata('zones.json');
    final houses = _loadGamedata('houses.json');
    final enemies = _loadGamedata('enemies.json');
    final rewardFlags = <String>{
      for (final zone in zones.values)
        if ((zone['rewardFlag']?.toString() ?? '').isNotEmpty)
          zone['rewardFlag'].toString(),
    };

    test('every zone boss is a real, non-hunter enemy with narration', () {
      for (final entry in zones.entries) {
        final zone = entry.value as Map<String, dynamic>;
        final bossId = zone['bossEnemyId']?.toString() ?? '';
        expect(bossId, isNotEmpty, reason: '${entry.key} has no boss');
        final boss = enemies[bossId] as Map<String, dynamic>?;
        expect(boss, isNotNull, reason: '${entry.key} boss $bossId missing');
        expect((boss!['hunterAlignment']?.toString() ?? ''), isEmpty,
            reason: '${entry.key} boss is an alignment hunter');
        expect(zone['bossFlavorText']?.toString() ?? '', isNotEmpty,
            reason: '${entry.key} has no boss narration');
        expect(zone['bossFlavorTextFr']?.toString() ?? '', isNotEmpty,
            reason: '${entry.key} has no FR boss narration');
        expect(zoneTier(zone), greaterThanOrEqualTo(1));
        expect(zoneRecommendedLevel(zone), greaterThanOrEqualTo(1));
      }
    });

    test('within a chapter, a higher tier never advises a lower level', () {
      final byChapter = <int, List<Map<String, dynamic>>>{};
      for (final zone in zones.values) {
        byChapter
            .putIfAbsent((zone['chapter'] as num).toInt(), () => [])
            .add(zone as Map<String, dynamic>);
      }
      for (final chapterZones in byChapter.values) {
        for (final a in chapterZones) {
          for (final b in chapterZones) {
            if (zoneTier(a) < zoneTier(b)) {
              expect(zoneRecommendedLevel(a),
                  lessThanOrEqualTo(zoneRecommendedLevel(b)));
            }
          }
        }
      }
    });

    test(
        'every zone/house requirement is another zone\'s rewardFlag, never '
        'its own, and no zone is gated on a later chapter', () {
      for (final entry in zones.entries) {
        final zone = entry.value as Map<String, dynamic>;
        for (final flag in requiredFlagsOf(zone)) {
          expect(rewardFlags, contains(flag),
              reason: '${entry.key} requires unknown flag $flag');
          expect(flag, isNot(zone['rewardFlag']?.toString()),
              reason: '${entry.key} requires its own reward');
          final source = zones.values
                  .firstWhere((z) => z['rewardFlag']?.toString() == flag)
              as Map<String, dynamic>;
          expect((source['chapter'] as num).toInt(),
              lessThanOrEqualTo((zone['chapter'] as num).toInt()),
              reason: '${entry.key} is gated on a later chapter\'s zone');
        }
      }
      for (final entry in houses.entries) {
        for (final flag
            in requiredFlagsOf(entry.value as Map<String, dynamic>)) {
          expect(rewardFlags, contains(flag),
              reason: 'house ${entry.key} requires unknown flag $flag');
        }
      }
    });

    test('every story-launched zone exists and is a main zone', () {
      final dag = _loadGamedata('../Cleaned_Narrative_DAG.json');
      var launches = 0;
      for (final entry in dag.entries) {
        final node = entry.value as Map<String, dynamic>;
        for (final choice in (node['choices'] as List? ?? const [])) {
          final zoneId =
              (choice as Map<String, dynamic>)['launchZoneId']?.toString();
          if (zoneId == null || zoneId.isEmpty) continue;
          launches++;
          expect(zones, contains(zoneId),
              reason: 'node ${entry.key} launches unknown zone $zoneId');
          expect(zoneIsMain(zones[zoneId] as Map<String, dynamic>), isTrue,
              reason: 'node ${entry.key} launches a non-main zone');
        }
      }
      expect(launches, greaterThanOrEqualTo(3));
    });

    test('each chapter has exactly one ungated entry zone per chapter 3+', () {
      final byChapter = <int, List<String>>{};
      for (final entry in zones.entries) {
        final zone = entry.value as Map<String, dynamic>;
        if (requiredFlagsOf(zone).isEmpty) {
          byChapter
              .putIfAbsent((zone['chapter'] as num).toInt(), () => [])
              .add(entry.key);
        }
      }
      for (final chapter in byChapter.keys) {
        expect(byChapter[chapter], isNotEmpty,
            reason: 'chapter $chapter has no ungated zone to start from');
      }
    });
  });
}

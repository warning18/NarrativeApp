// An expedition's written road (expedition_steps.dart): a zone with steps
// walks them and is as long as they are; each step plays as a node whose
// numbers are Core's (the chapter's DC, a rest's heal, a discovery's
// material, the notes' gold, days, load and hurt); a zone without keeps its
// count. And, once Narrative's expedition_steps.json exists, every zone,
// foe, ability and step kind in it is real.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/ability_check.dart';
import 'package:narrative_data_app/data/expedition_kinds.dart';
import 'package:narrative_data_app/data/expedition_steps.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final steps = writtenStepsFrom({
    'z_test': {
      'steps': [
        {
          'id': 'sheds',
          'type': 'check',
          'text': 'Which shed is not for fish?',
          'text_fr': 'Quel hangar n’est pas pour le poisson ?',
          'choices': [
            {
              'id': 'look',
              'text': 'Look closer',
              'check': 'perception',
              'hard': true,
              'fight': 'harbor_rat',
              'success': {'note': 'Past them.', 'note_fr': 'Passés.'},
              'fail': {'note': 'Seen.', 'healthPct': -10, 'days': 1},
            },
            {
              'id': 'leave',
              'text': 'Leave it',
              'outcome': {'gold': 5}
            },
          ],
        },
        {
          'id': 'locker',
          'type': 'discovery',
          'text': 'A tarred locker.',
          'place': 'The net-loft',
          'material': 'material_timber',
          'choices': [
            {'id': 'open', 'text': 'Open it'},
          ],
        },
        {
          'id': 'brazier',
          'type': 'rest',
          'text': 'The smokehouse brazier.',
          'choices': [
            {'id': 'rest', 'text': 'Warm up'},
            {'id': 'on', 'text': 'Keep going'},
          ],
        },
      ],
    },
    'z_empty': {'steps': []},
  });

  test('a zone with steps is as long as they are; one without keeps its count',
      () {
    expect(steps.keys, ['z_test']);
    expect(expeditionCountOf({'expeditionCount': 4}, steps['z_test']!), 3);
    expect(expeditionCountOf({'expeditionCount': 4}), 4);
    expect(expeditionCountOf({}), 3);
    final zones = zonesWithWrittenCounts({
      'z_test': {'expeditionCount': 6},
      'z_other': {'expeditionCount': 4},
    }, steps);
    expect((zones['z_test'] as Map)['expeditionCount'], 3);
    expect((zones['z_other'] as Map)['expeditionCount'], 4);
    expect(deliveryDeadlineOf({'expeditionCount': 4}, count: 9), 11);
    // A zone's own deadline keeps its spare days over the written road:
    // Fever Bark's 6 days for 4 stages is 10 for 8 written ones.
    expect(
        deliveryDeadlineOf({'expeditionCount': 4, 'deadlineDays': 6}, count: 8),
        10);
  });

  test('the file may wrap its zones with a version', () {
    final wrapped = writtenStepsFrom({
      'version': 1,
      'zones': {
        'z_a': {
          'steps': [
            {'id': 'one', 'text': 'One.'},
          ],
        },
      },
    });
    expect(wrapped.keys, ['z_a']);
    expect(wrapped['z_a']!.single.type, 'event');
  });

  test('a check step: the chapter\'s DC, harder when hard; a sneak past foes',
      () {
    final built = buildWrittenStep(steps['z_test']![0],
        zoneId: 'z_test',
        chapter: 3,
        random: Random(1),
        enemies: const {'harbor_rat': {}});
    final look = built.node.choices[0];
    expect(look.checkAbility, 'perception');
    expect(look.checkDC, SubNodeEngine.detourCheckDc(3) + writtenHardDc);
    expect(look.triggerEnemyIds, ['harbor_rat']);
    expect(look.avoidFightOnSuccess, isTrue);
    expect(built.node.choices[1].goldMod, 5);
    expect(built.node.descriptionFr, contains('hangar'));

    final failed = built.outcomeFor(0).resolve(failed: true, fought: false);
    expect(failed.hurt, 10);
    expect(failed.days, 1);
    expect(
        built
            .outcomeFor(0)
            .notesFor(failed: false, checked: true, french: true),
        'Passés.');
    expect(
        built
            .outcomeFor(0)
            .notesFor(failed: true, checked: true, french: false),
        'Seen.');
  });

  test('a foe the file does not know is left out', () {
    final built = buildWrittenStep(steps['z_test']![0],
        zoneId: 'z_test',
        chapter: 2,
        random: Random(1),
        enemies: const {'someone_else': {}});
    expect(built.node.choices[0].triggerEnemyIds, isEmpty);
  });

  test('a discovery turns up one of the zone\'s materials; a rest heals', () {
    final discovery = buildWrittenStep(steps['z_test']![1],
        zoneId: 'z_test',
        chapter: 2,
        random: Random(1),
        rewardMaterials: const {'material_timber': 3, 'material_cut_stone': 1});
    expect(discovery.node.choices[0].grantMaterials, {'material_timber': 1});
    expect(discovery.node.description, startsWith('The net-loft. '));
    // A hint the zone doesn't give: one of its own instead.
    final other = buildWrittenStep(steps['z_test']![1],
        zoneId: 'z_test',
        chapter: 2,
        random: Random(1),
        rewardMaterials: const {'material_cut_stone': 2});
    expect(other.node.choices[0].grantMaterials, {'material_cut_stone': 1});

    final rest = buildWrittenStep(steps['z_test']![2],
        zoneId: 'z_test', chapter: 4, random: Random(1));
    expect(rest.node.choices[0].healAmount, SubNodeEngine.restHealFor(4));
    expect(rest.node.choices[1].healAmount, 0);
  });

  test(
      'expedition_steps.json, once written, names real zones, foes and '
      'abilities', () {
    final file = File('assets/gamedata/expedition_steps.json');
    if (!file.existsSync()) return;
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final zones = _json('assets/gamedata/zones.json');
    final enemies = _json('assets/gamedata/enemies.json');
    final written = writtenStepsFrom(raw);
    for (final MapEntry(key: zoneId, value: list) in written.entries) {
      expect(zones.containsKey(zoneId), isTrue, reason: zoneId);
      final ids = <String>{};
      for (final step in list) {
        final where = '$zoneId.${step.id}';
        expect(step.id, isNotEmpty, reason: zoneId);
        expect(ids.add(step.id), isTrue, reason: 'duplicate $where');
        expect(step.text, isNotEmpty, reason: where);
        expect(step.textFr, isNotEmpty, reason: where);
        if (step.place.isNotEmpty) {
          expect(step.placeFr, isNotEmpty, reason: where);
        }
        for (final choice in step.choices) {
          expect(choice.text, isNotEmpty, reason: where);
          expect(choice.textFr, isNotEmpty, reason: '$where.${choice.id}');
          if (choice.check != null) {
            expect(abilityScoreKeys, contains(choice.check), reason: where);
          }
          for (final foe in choice.fight) {
            expect(enemies.containsKey(foe), isTrue, reason: '$where: $foe');
          }
        }
      }
    }
    // Every step's type is one the engine plays.
    final zoneRecords = raw['zones'] is Map ? raw['zones'] as Map : raw;
    for (final list in zoneRecords.values) {
      final steps = list is Map ? list['steps'] : list;
      if (steps is! List) continue;
      for (final step in steps) {
        final type = (step as Map)['type'];
        if (type != null) expect(writtenStepTypes, contains(type));
      }
    }
  });
}

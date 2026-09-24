// v1.128: a fight, a stall or a job met between two scenes says what it is
// and why it happens. Covers the encounter-text helpers, the detour
// builder's use of them, the mood gate on detours, the detour's origin in
// the play state, the hunter's reason, and the data every random enemy
// needs for all of that.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/alignment_events.dart';
import 'package:narrative_data_app/data/encounter_text.dart';
import 'package:narrative_data_app/data/map_themes.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';

Map<String, dynamic> _loadJson(String path) {
  for (final p in [path, '../$path']) {
    final file = File(p);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('missing $path');
}

void main() {
  final rats = {
    'rat': {
      'enemyName': 'Harbor Rat',
      'description': 'A quay rat.',
      'description_fr': 'Un rat des quais.',
      'encounterText': ['Rat line one.', 'Rat line two.'],
      'encounterText_fr': ['Rat un.', 'Rat deux.'],
      'packText': 'Rats hold the wall.',
      'packText_fr': 'Les rats tiennent le mur.',
    },
    'bandit': {'enemyName': 'Street Bandit'},
  };

  group('encounter text helpers', () {
    test('the roster counts duplicates in first-seen order', () {
      expect(enemyRoster(['bandit', 'rat', 'bandit'], rats),
          'Street Bandit ×2, Harbor Rat');
      expect(enemyRoster(['ghost'], rats), 'ghost');
      final label = fightLabelFor(['rat'], rats);
      expect(label.en, 'Fight: Harbor Rat');
      expect(label.fr, 'Combattre : Harbor Rat');
    });

    test('a solo fight draws its encounter line, wrapped by index', () {
      final line = encounterLineFor(ids: ['rat'], enemies: rats, index: 3);
      expect(line?.en, 'Rat line two.');
      expect(line?.fr, 'Rat deux.');
    });

    test('a pack led by an enemy with a pack line uses it', () {
      final line =
          encounterLineFor(ids: ['rat', 'bandit'], enemies: rats, index: 0);
      expect(line?.en, 'Rats hold the wall.');
      expect(line?.fr, 'Les rats tiennent le mur.');
    });

    test('an enemy with no lines leaves the caller its fallback', () {
      expect(
          encounterLineFor(ids: ['bandit'], enemies: rats, index: 0), isNull);
      expect(encounterLineFor(ids: const [], enemies: rats, index: 0), isNull);
    });

    test('descriptions fall back to English and skip empty records', () {
      expect(enemyDescriptionFor(rats['rat'], true), 'Un rat des quais.');
      expect(enemyDescriptionFor({'description': 'Only English.'}, true),
          'Only English.');
      expect(enemyDescriptionFor(rats['bandit'], false), isNull);
      expect(enemyDescriptionFor(null, false), isNull);
    });
  });

  group('detour nodes say what they are', () {
    final flavor = flavorFor(MapTheme.ashenStreets);

    test('a fight uses the drawn enemy\'s own line and names it', () {
      for (var seed = 0; seed < 60; seed++) {
        final node = SubNodeEngine.buildNode(
          random: Random(seed),
          flavor: flavor,
          shopPool: const [],
          enemyPool: const ['rat'],
          packPool: const ['rat'],
          maxPackSize: 2,
          enemies: rats,
        );
        final choice = node.choices.single;
        if (!choice.triggersCombat) continue;
        final pack = choice.allTriggerEnemyIds.length > 1;
        expect(
            node.description,
            pack
                ? 'Rats hold the wall.'
                : anyOf('Rat line one.', 'Rat line two.'));
        expect(
            choice.text, pack ? 'Fight: Harbor Rat ×2' : 'Fight: Harbor Rat');
        expect(choice.textFr, startsWith('Combattre : Harbor Rat'));
      }
    });

    test('without records the themed line and plain label remain', () {
      for (var seed = 0; seed < 60; seed++) {
        final node = SubNodeEngine.buildNode(
          random: Random(seed),
          flavor: flavor,
          shopPool: const [],
          enemyPool: const ['rat'],
        );
        final choice = node.choices.single;
        if (!choice.triggersCombat) continue;
        expect(flavor.enemy, contains(node.description));
        expect(choice.text, 'Fight');
      }
    });

    test('a stall and a job are named, and the job says what it asks', () {
      final quests = {
        'q_x': {
          'questName': 'The Missing Net',
          'objectives': [
            {'description': 'Find the net-mender\'s son'}
          ],
        },
      };
      final job = SubNodeEngine.buildNode(
        random: Random(1),
        flavor: flavor,
        shopPool: const [],
        enemyPool: const [],
        questId: 'q_x',
        quests: quests,
      );
      expect(job.choices.single.text, 'Take the job: The Missing Net');
      expect(job.contextNoteFor(false), "The job: Find the net-mender's son");
      expect(
          job.contextNoteFor(true), "Le travail : Find the net-mender's son");

      final shops = {
        's_x': {'shopName': 'Widow\'s Table'}
      };
      for (var seed = 0; seed < 40; seed++) {
        final node = SubNodeEngine.buildNode(
          random: Random(seed),
          flavor: flavor,
          shopPool: const ['s_x'],
          enemyPool: const [],
          shops: shops,
        );
        final choice = node.choices.single;
        if ((choice.unlockShopId ?? '').isEmpty) continue;
        expect(choice.text, "Take a look: Widow's Table");
        expect(choice.textFr, "Jeter un œil : Widow's Table");
      }
    });
  });

  group('detours wait for a scene at rest', () {
    test('no detour interrupts a crisis running from scene to scene', () {
      for (final from in SubNodeEngine.tenseMoods) {
        for (final to in SubNodeEngine.tenseMoods) {
          expect(SubNodeEngine.detourAllowedBetween(from, to), isFalse);
        }
        // A crisis starting or ending at the transition leaves a road.
        expect(SubNodeEngine.detourAllowedBetween(from, 'neutral'), isTrue);
        expect(SubNodeEngine.detourAllowedBetween('grim', from), isTrue);
      }
      expect(SubNodeEngine.detourAllowedBetween(null, null), isTrue);
    });

    test('the story\'s mid-crisis transitions take no detour', () {
      final story = _loadJson('assets/Cleaned_Narrative_DAG.json');
      String? mood(String id) =>
          ((story[id] as Map<String, dynamic>?)?['context_taxonomy']
              as Map<String, dynamic>?)?['mood'] as String?;
      // The hovel raid into the unfurling, the run for the docks, the
      // roof coming down on the Court.
      expect(SubNodeEngine.detourAllowedBetween(mood('400'), mood('450')),
          isFalse);
      expect(SubNodeEngine.detourAllowedBetween(mood('450'), mood('891')),
          isFalse);
      expect(SubNodeEngine.detourAllowedBetween(mood('5005'), mood('6001')),
          isFalse);
      // Leaving the market at rest for the hovel still passes a road.
      expect(
          SubNodeEngine.detourAllowedBetween(mood('151'), mood('300')), isTrue);
    });
  });

  group('alignment events give their reason', () {
    test('a hunter says who sent it and why', () {
      final enemies = {
        'angel': {'hunterAlignment': 'Evil', 'hunterTier': 1},
        'imp': {'hunterAlignment': 'Good', 'hunterTier': 1},
      };
      final angel = buildHunterAmbushNode(
          enemies: enemies, side: 'Evil', chapter: 1, random: Random(1))!;
      expect(angel.contextNoteFor(false), contains('Choir'));
      expect(angel.contextNoteFor(true), contains('Chœur'));
      final imp = buildHunterAmbushNode(
          enemies: enemies, side: 'Good', chapter: 1, random: Random(1))!;
      expect(imp.contextNoteFor(false), contains('Pit'));
    });

    test('a temptation says what the answer does', () {
      final node = buildTemptationNode(
          activeQuestIds: const [],
          completedQuestIds: const [],
          random: Random(2))!;
      expect(node.contextNoteFor(false), contains('alignment'));
    });
  });

  group('enemy data carries its narration', () {
    final enemies = _loadJson('assets/gamedata/enemies.json');

    test('every enemy says who it is, in both languages', () {
      for (final entry in enemies.entries) {
        final e = entry.value as Map<String, dynamic>;
        expect((e['description'] as String?)?.isNotEmpty, isTrue,
            reason: entry.key);
        expect((e['description_fr'] as String?)?.isNotEmpty, isTrue,
            reason: entry.key);
      }
    });

    test('every enemy a detour or a zone can draw has its own lines', () {
      final drawable = SubNodeEngine.filterEnemyPool(
          enemies: enemies, unlockedEnemyIds: const [], chapter: 99);
      expect(drawable, isNotEmpty);
      for (final id in drawable) {
        final e = enemies[id] as Map<String, dynamic>;
        final en = (e['encounterText'] as List?) ?? const [];
        final fr = (e['encounterText_fr'] as List?) ?? const [];
        expect(en.length, greaterThanOrEqualTo(2), reason: id);
        expect(fr.length, en.length, reason: id);
        final line = encounterLineFor(ids: [id], enemies: enemies, index: 0);
        expect(line, isNotNull, reason: id);
      }
    });

    test('every enemy that can lead a pack has a pack line', () {
      for (final entry in enemies.entries) {
        final e = entry.value as Map<String, dynamic>;
        if (e['packEligible'] != true) continue;
        expect((e['packText'] as String?)?.isNotEmpty, isTrue,
            reason: entry.key);
        expect((e['packText_fr'] as String?)?.isNotEmpty, isTrue,
            reason: entry.key);
      }
    });
  });

  group('story fights are announced', () {
    final story = _loadJson('assets/Cleaned_Narrative_DAG.json');

    test('Kelda\'s gate sets up the boarding party before its fight', () {
      final node = story['2015_kelda'] as Map<String, dynamic>;
      expect(node['description'], contains('boarding party'));
      expect(node['description_fr'], contains("l'équipe d'abordage"));
      final choice = (node['choices'] as List).single as Map<String, dynamic>;
      expect(choice['triggerEnemyId'], 'inquisition_soldier');
      expect(choice['text'], 'Hold the gate beside her');
    });
  });
}

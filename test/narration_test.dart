// Coverage for the narration layer: a story node's flag callbacks, hub
// progress lines, persona variants and show-if flags; the name tokens and
// speaker labels; the companions' voices; the fight aftermath pools; the
// excursion pools' size and parity; and the authored story data behind
// all of it (every callback flag is one the game can set, every persona
// key names a real race or profession, every token has its French twin).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_aftermath.dart';
import 'package:narrative_data_app/data/ally_acknowledgments.dart';
import 'package:narrative_data_app/data/map_themes.dart';
import 'package:narrative_data_app/data/narration_tokens.dart';
import 'package:narrative_data_app/data/sub_node_engine.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _loadJson(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $relative under ${Directory.current.path}');
}

void main() {
  group('StoryChoice.showIfFlags', () {
    test('hides the choice until every flag is held', () {
      const choice = StoryChoice(
        text: 'Later',
        nextId: '1',
        showIfFlags: ['a', 'b'],
        hideIfFlags: ['done'],
      );
      expect(choice.isHiddenFor(const []), isTrue);
      expect(choice.isHiddenFor(const ['a']), isTrue);
      expect(choice.isHiddenFor(const ['a', 'b']), isFalse);
      expect(choice.isHiddenFor(const ['a', 'b', 'done']), isTrue);
    });

    test('round-trips through JSON and stays out of it when empty', () {
      const choice =
          StoryChoice(text: 'Later', nextId: '1', showIfFlags: ['a']);
      final restored = StoryChoice.fromJson(choice.toJson());
      expect(restored.showIfFlags, ['a']);
      expect(
          const StoryChoice(text: 'Go', nextId: '1')
              .toJson()
              .containsKey('showIfFlags'),
          isFalse);
    });
  });

  group('StoryNode narration fields', () {
    final node = StoryNode.fromJson('hub', {
      'description': 'The hub.',
      'flag_callbacks': [
        {'flag': 'saved', 'en': 'You saved it.', 'fr': 'Vous l\'avez sauvé.'},
        {
          'flag': 'took',
          'en': 'You took it.',
          'unlessFlags': ['returned'],
        },
        {'flag': '', 'en': 'ignored'},
        'nonsense',
      ],
      'persona_variants': {
        'race:orc': {'en': 'An orc.', 'fr': 'Un orc.'},
        'profession:mage': {'en': 'A {profession}.'},
        'race:bad': 'nonsense',
      },
      'hub_progress': {
        'prefix': 'hub_x_',
        'lines': [
          {'after': 4, 'en': 'Much changed.', 'fr': 'Beaucoup a changé.'},
          {'after': 2, 'en': 'Some changed.'},
        ],
      },
      'choices': [],
    });

    test('callbacks show for held flags, in authored order, unless vetoed', () {
      expect(node.flagCallbacks, hasLength(2));
      expect(node.callbacksFor(const [], false), isEmpty);
      expect(node.callbacksFor(const ['took', 'saved'], false),
          ['You saved it.', 'You took it.']);
      expect(node.callbacksFor(const ['saved'], true), ['Vous l\'avez sauvé.']);
      expect(node.callbacksFor(const ['took', 'returned'], false), isEmpty);
      expect(node.callbacksFor(const ['took'], true), ['You took it.'],
          reason: 'no French falls back to English');
    });

    test('persona lines come race first, then profession', () {
      expect(
          node.personaLinesFor(
              raceId: 'orc', professionId: 'mage', french: false),
          ['An orc.', 'A {profession}.']);
      expect(
          node.personaLinesFor(
              raceId: 'orc', professionId: 'mage', french: true),
          ['Un orc.', 'A {profession}.']);
      expect(
          node.personaLinesFor(
              raceId: 'elf', professionId: 'rogue', french: false),
          isEmpty);
      expect(node.personaVariants.containsKey('race:bad'), isFalse);
    });

    test('hub progress picks the highest threshold reached', () {
      expect(node.hubProgress!.lines.map((l) => l.after), [2, 4],
          reason: 'sorted ascending');
      expect(node.hubProgressLineFor(const ['hub_x_a'], false), isNull);
      expect(node.hubProgressLineFor(const ['hub_x_a', 'hub_x_b'], false),
          'Some changed.');
      expect(
          node.hubProgressLineFor(
              const ['hub_x_a', 'hub_x_b', 'hub_x_c', 'hub_x_d', 'other'],
              true),
          'Beaucoup a changé.');
    });

    test('round-trips through toJson', () {
      final restored = StoryNode.fromJson('hub', node.toJson());
      expect(restored.flagCallbacks.map((c) => c.flag), ['saved', 'took']);
      expect(restored.flagCallbacks[1].unlessFlags, ['returned']);
      expect(restored.personaVariants.keys, ['race:orc', 'profession:mage']);
      expect(restored.hubProgress!.prefix, 'hub_x_');
      expect(restored.hubProgress!.lines.length, 2);
      final plain =
          StoryNode.fromJson('p', {'description': 'x', 'choices': []});
      expect(plain.toJson().containsKey('flag_callbacks'), isFalse);
      expect(plain.toJson().containsKey('persona_variants'), isFalse);
      expect(plain.toJson().containsKey('hub_progress'), isFalse);
    });
  });

  group('narration tokens', () {
    test('fills name, race, profession and companion in both languages', () {
      const text = '{name}, a {race} {profession}, walked with {companion}.';
      expect(
          personalizeNarration(text,
              name: 'Ash',
              raceId: 'elf',
              professionId: 'ranger',
              companionName: 'Kelda',
              french: false),
          'Ash, a elf ranger, walked with Kelda.');
      expect(
          personalizeNarration(text,
              name: 'Ash',
              raceId: 'dwarf',
              professionId: 'cleric',
              companionName: 'Kelda',
              french: true),
          'Ash, a nain clerc, walked with Kelda.');
    });

    test('falls back for an unnamed character and an empty party', () {
      expect(
          personalizeNarration('{name} and {companion}',
              name: '  ',
              raceId: 'human',
              professionId: 'warrior',
              french: false),
          'stranger and no one');
      expect(
          personalizeNarration('{name}',
              name: '', raceId: '', professionId: '', french: true),
          "l'étranger");
    });

    test('text without tokens is returned as is', () {
      const text = 'No tokens here.';
      expect(
          identical(
              personalizeNarration(text,
                  name: 'x', raceId: 'x', professionId: 'x', french: false),
              text),
          isTrue);
    });

    test('speaker labels: none for the Narrator, translated for the cast', () {
      expect(speakerLabelFor(null, french: false), isNull);
      expect(speakerLabelFor('', french: false), isNull);
      expect(speakerLabelFor('Narrator', french: true), isNull);
      expect(speakerLabelFor('Archivist', french: false), 'The Archivist');
      expect(speakerLabelFor('Archivist', french: true), "L'Archiviste");
      expect(speakerLabelFor('The Sovereign', french: true), 'Le Souverain');
      expect(speakerLabelFor('Somebody Else', french: true), 'Somebody Else');
    });
  });

  group('companion acknowledgments', () {
    test('nothing for a character walking alone', () {
      expect(
          allyAcknowledgmentFor('2015', activeAllyIds: const [], french: false),
          isNull);
      expect(
          withAllyAcknowledgment('2015', 'x',
              activeAllyIds: const [], french: false),
          'x');
    });

    test('a companion with their own line speaks, else the party default', () {
      final kelda = allyAcknowledgmentFor('2015',
          activeAllyIds: const ['kelda'], french: false)!;
      expect(kelda, contains('Kelda'));
      final grosh = allyAcknowledgmentFor('2015',
          activeAllyIds: const ['grosh'], french: false)!;
      expect(grosh, isNot(contains('Grosh')));
      expect(grosh, isNot(kelda));
      // The first active ally with a voice speaks.
      expect(
          allyAcknowledgmentFor('2015',
              activeAllyIds: const ['grosh', 'sable'], french: false),
          contains('Sable'));
      expect(
          withAllyAcknowledgment('2015', 'Body.',
              activeAllyIds: const ['kelda'], french: true),
          startsWith('Body. Kelda'));
    });

    test('every acknowledged node has matching English and French voices', () {
      const companions = [
        'kelda',
        'sable',
        'maren',
        'liora',
        'vess',
        'grosh',
        'tobin',
        'malrik',
      ];
      expect(acknowledgedNodeIds.length, greaterThanOrEqualTo(16));
      for (final nodeId in acknowledgedNodeIds) {
        for (final ally in companions) {
          final en = allyAcknowledgmentFor(nodeId,
              activeAllyIds: [ally], french: false);
          final fr = allyAcknowledgmentFor(nodeId,
              activeAllyIds: [ally], french: true);
          expect(en, isNotNull, reason: '$nodeId has no English default');
          expect(fr, isNotNull, reason: '$nodeId has no French default');
          expect(en!.startsWith(' '), isTrue,
              reason: '$nodeId/$ally: appended lines start with a space');
          expect(fr!.startsWith(' '), isTrue,
              reason: '$nodeId/$ally: appended lines start with a space');
        }
      }
    });
  });

  group('fight aftermath', () {
    const names = ['Harbor Rat'];
    test('every pool has the same number of lines in both languages', () {
      for (final pool in aftermathPoolsForTest) {
        expect(pool.en, isNotEmpty);
        expect(pool.en.length, pool.fr.length);
      }
    });

    test('routes each outcome to its own pool and names the enemy', () {
      String line(FightOutcome o, {bool french = false}) =>
          aftermathLineFor(o, french: french, seed: 0);
      final lost = line(const FightOutcome(won: false, enemyNames: names));
      final boss = line(const FightOutcome(
          won: true, enemyNames: names, isBoss: true, phasesCrossed: 2));
      final elite =
          line(const FightOutcome(won: true, enemyNames: names, isElite: true));
      final hunt =
          line(const FightOutcome(won: true, enemyNames: names, isHunt: true));
      final ally = line(const FightOutcome(
          won: true, enemyNames: names, knockedOutAllyName: 'Kelda'));
      final flawless = line(const FightOutcome(
          won: true, enemyNames: names, flawless: true, rounds: 2));
      final plain = line(const FightOutcome(won: true, enemyNames: names));
      final all = {lost, boss, elite, hunt, ally, flawless, plain};
      expect(all, hasLength(7), reason: 'seven distinct pools');
      for (final l in [lost, boss, elite, hunt, flawless, plain]) {
        expect(l, contains('Harbor Rat'));
      }
      expect(ally, contains('Kelda'));
      expect(ally, isNot(contains('{ally}')));
      expect(
          line(const FightOutcome(won: true, enemyNames: names), french: true),
          isNot(plain));
    });

    test('a long flawless fight reads as a plain win', () {
      final long = aftermathLineFor(
          const FightOutcome(
              won: true, enemyNames: names, flawless: true, rounds: 9),
          french: false,
          seed: 0);
      final plain = aftermathLineFor(
          const FightOutcome(won: true, enemyNames: names),
          french: false,
          seed: 0);
      expect(long, plain);
    });

    test('the seed varies the line and an empty name has a fallback', () {
      final lines = {
        for (var seed = 0; seed < 8; seed++)
          aftermathLineFor(const FightOutcome(won: true, enemyNames: names),
              french: false, seed: seed),
      };
      expect(lines.length, greaterThan(1));
      expect(
          deathNarrationFor('', french: false, seed: 1), contains('the enemy'));
      expect(deathNarrationFor('Void Archon', french: true, seed: 2),
          contains('Void Archon'));
    });
  });

  group('excursion and hunt pools', () {
    test('every theme has at least 12 lines per kind, EN and FR in step', () {
      for (final theme in MapTheme.values) {
        final f = flavorFor(theme);
        final pairs = {
          'shop': (f.shop, f.shopFr),
          'enemy': (f.enemy, f.enemyFr),
          'quest': (f.quest, f.questFr),
          'treasure': (f.treasure, f.treasureFr),
          'rest': (f.rest, f.restFr),
          'generic': (f.generic, f.genericFr),
        };
        for (final entry in pairs.entries) {
          final (en, fr) = entry.value;
          expect(en.length, greaterThanOrEqualTo(12),
              reason: '${theme.name}.${entry.key}');
          expect(fr.length, en.length,
              reason: '${theme.name}.${entry.key} FR parity');
          expect(en.toSet().length, en.length,
              reason: '${theme.name}.${entry.key} has a duplicate');
        }
      }
    });

    test('the hunt has eight trails and eight quarries in both languages', () {
      final sizes = SubNodeEngine.huntPoolSizes;
      expect(sizes.trail, greaterThanOrEqualTo(8));
      expect(sizes.trailFr, sizes.trail);
      expect(sizes.quarry, greaterThanOrEqualTo(8));
      expect(sizes.quarryFr, sizes.quarry);
    });
  });

  group('authored narration data', () {
    final dag = _loadJson('assets/Cleaned_Narrative_DAG.json');
    final zones = _loadJson('assets/gamedata/zones.json');
    final races = _loadJson('assets/gamedata/races.json');
    final professions = _loadJson('assets/gamedata/professions.json');
    final settable = <String>{
      for (final node in dag.values)
        for (final choice in (node as Map)['choices'] as List)
          ...((choice as Map)['flagsToAdd'] as List? ?? const [])
              .map((f) => f.toString()),
      for (final zone in zones.values)
        if ((zone as Map)['rewardFlag'] != null) zone['rewardFlag'].toString(),
    };
    final nodes = {
      for (final entry in dag.entries)
        entry.key:
            StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
    };

    test('every callback and show-if flag is one the game can set', () {
      var callbacks = 0;
      var showIfs = 0;
      for (final node in nodes.values) {
        for (final callback in node.flagCallbacks) {
          callbacks++;
          expect(settable, contains(callback.flag),
              reason: '${node.id} calls back on ${callback.flag}');
          expect(callback.line.fr, isNotEmpty,
              reason: '${node.id}/${callback.flag} has no French');
        }
        for (final choice in node.choices) {
          for (final flag in choice.showIfFlags) {
            showIfs++;
            expect(settable, contains(flag),
                reason: '${node.id} waits on $flag');
          }
        }
      }
      expect(callbacks, greaterThanOrEqualTo(25));
      expect(showIfs, greaterThanOrEqualTo(8));
    });

    test('hub progress lines count flags the hub actually sets', () {
      var hubs = 0;
      for (final node in nodes.values) {
        final progress = node.hubProgress;
        if (progress == null) continue;
        hubs++;
        final setHere = settable.where((f) => f.startsWith(progress.prefix));
        expect(setHere.length, greaterThanOrEqualTo(progress.lines.last.after),
            reason: '${node.id}: ${progress.prefix} has too few activities');
        for (final line in progress.lines) {
          expect(line.line.fr, isNotEmpty);
        }
      }
      expect(hubs, 4);
    });

    test('persona keys name real races and professions, with French', () {
      var variants = 0;
      for (final node in nodes.values) {
        for (final entry in node.personaVariants.entries) {
          variants++;
          final parts = entry.key.split(':');
          expect(parts, hasLength(2), reason: '${node.id}: ${entry.key}');
          final table = parts[0] == 'race' ? races : professions;
          expect(table.keys, contains(parts[1]),
              reason: '${node.id}: ${entry.key}');
          expect(entry.value.fr, isNotEmpty,
              reason: '${node.id}: ${entry.key} has no French');
        }
      }
      expect(variants, greaterThanOrEqualTo(20));
    });

    test('name tokens appear in both languages of the same node', () {
      final tokens = RegExp(r'\{(name|race|profession|companion)\}');
      var tokenNodes = 0;
      for (final node in nodes.values) {
        final en = tokens.allMatches(node.description).map((m) => m[0]).toSet();
        final fr = tokens
            .allMatches(node.descriptionFr ?? '')
            .map((m) => m[0])
            .toSet();
        expect(fr, en, reason: '${node.id} tokens differ between languages');
        if (en.isNotEmpty) tokenNodes++;
        for (final variant in node.personaVariants.values) {
          expect(tokens.allMatches(variant.fr ?? '').map((m) => m[0]).toSet(),
              tokens.allMatches(variant.en).map((m) => m[0]).toSet(),
              reason: '${node.id} persona tokens differ');
        }
      }
      expect(tokenNodes, greaterThanOrEqualTo(3));
    });

    test('hub return lines are varied', () {
      for (final hub in ['2015', '3005', '5010', '6010']) {
        final texts = <String>{};
        var count = 0;
        for (final node in nodes.values) {
          if (node.id == hub) continue;
          for (final choice in node.choices) {
            if (choice.nextId == hub) {
              count++;
              texts.add(choice.text);
            }
          }
        }
        expect(texts.length, greaterThanOrEqualTo(6),
            reason: 'hub $hub: $count returns share ${texts.length} texts');
      }
    });

    test('second beats wait on their first visit and retire themselves', () {
      for (final hub in ['5010', '6010']) {
        final beats =
            nodes[hub]!.choices.where((c) => c.showIfFlags.isNotEmpty).toList();
        expect(beats.length, greaterThanOrEqualTo(4), reason: 'hub $hub');
        for (final beat in beats) {
          expect(beat.hideIfFlags, isNotEmpty, reason: beat.text);
          final target = nodes[beat.nextId]!;
          expect(target.choices.every((c) => c.nextId == hub), isTrue,
              reason: '${target.id} should return to $hub');
          expect(
              target.choices
                  .any((c) => c.flagsToAdd.contains(beat.hideIfFlags.first)),
              isTrue,
              reason: '${target.id} must set ${beat.hideIfFlags.first}');
        }
      }
    });

    test('the finale confronts the Sovereign before the crossing', () {
      final confront = nodes['7002_confront']!;
      expect(confront.speaker, 'The Sovereign');
      expect(confront.choices, hasLength(3));
      for (final choice in confront.choices) {
        expect(choice.launchZoneId, 'z_beyond_the_tear');
        expect(choice.nextId, '7003');
      }
      expect(confront.choices.map((c) => c.alignmentMod).toSet(),
          containsAll([2, 0, -2]));
      final sail = nodes['7002']!.choices.firstWhere(
          (c) => c.nextId == '7002_confront',
          orElse: () => fail('7002 no longer leads to the confrontation'));
      expect(sail.launchesZone, isFalse);
      expect(nodes['7002_crew']!.choices.single.nextId, '7002');
    });

    test('the main zones carry a midpoint beat in both languages', () {
      var count = 0;
      for (final entry in zones.entries) {
        final zone = entry.value as Map;
        final en = zone['midpointFlavorText']?.toString() ?? '';
        final fr = zone['midpointFlavorTextFr']?.toString() ?? '';
        if (en.isEmpty) {
          expect(fr, isEmpty, reason: entry.key);
          continue;
        }
        count++;
        expect(fr, isNotEmpty, reason: '${entry.key} midpoint has no French');
        expect(
            (zone['expeditionCount'] as num).toInt(), greaterThanOrEqualTo(3),
            reason: '${entry.key}: a midpoint needs three events');
      }
      expect(count, greaterThanOrEqualTo(4));
    });
  });
}

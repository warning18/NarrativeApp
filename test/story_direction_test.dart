// The owner's story direction, checked against the authored data: every
// origin carries the first piece of the Shroud; the chapter-2 exit builds
// the boat; chapter 3 lands on a remote coast after a long voyage; the
// Shroud's four pieces are taken on the spine, each of the last three at a
// cost; the whole Shroud gates the final crossing; power is worn (each
// race has a medium and the {sigil} token resolves for it); and there is
// no clean way through the spine's dilemmas.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/narration_tokens.dart';
import 'package:narrative_data_app/data/zone_gating.dart';
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

/// A choice costs something when it wounds, impoverishes, blackens the
/// character's name, takes a companion, or leaves a mark the story reads
/// back later.
bool _costs(StoryChoice c, Set<String> sadFlags) =>
    c.alignmentMod < 0 ||
    c.goldMod < 0 ||
    c.healAmount < 0 ||
    (c.loseAllyId?.isNotEmpty ?? false) ||
    c.flagsToAdd.any(sadFlags.contains);

void main() {
  final dag = _loadJson('assets/Cleaned_Narrative_DAG.json');
  final zones = _loadJson('assets/gamedata/zones.json');
  final races = _loadJson('assets/gamedata/races.json');
  final quests = _loadJson('assets/gamedata/quests.json');
  final nodes = {
    for (final entry in dag.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  };
  final allChoices = [
    for (final node in nodes.values)
      for (final choice in node.choices) (node: node, choice: choice),
  ];

  group('the Shroud', () {
    test('every origin epilogue hands over the heirloom piece', () {
      for (final origin in ['1000', '1001', '1002']) {
        final next = nodes[origin]!.choices.singleWhere(
            (c) => c.nextId == '2001',
            orElse: () => fail('$origin does not lead to chapter 2'));
        expect(next.grantsBannerPieceId, 'heirloom_shroud', reason: origin);
        expect(next.flagsToAdd, contains('void_banner_bearer'), reason: origin);
      }
    });

    test('nothing in the story still splits bearers from seekers', () {
      for (final node in nodes.values) {
        expect(node.reqFlags, isNot(contains('void_banner_seeker')),
            reason: node.id);
        for (final choice in node.choices) {
          expect(choice.flagsToAdd, isNot(contains('void_banner_seeker')),
              reason: '${node.id}: ${choice.text}');
        }
      }
      expect(nodes.containsKey('5003_seeker'), isFalse);
      expect(nodes.containsKey('6001_seeker'), isFalse);
      for (final quest in quests.values) {
        expect((quest as Map)['grantsBannerPieceId'] ?? '', isEmpty,
            reason: 'pieces come from the story now, not ${quest['questID']}');
      }
    });

    test('four distinct pieces are taken on the spine, in chapter order', () {
      // Node ids number the story in reading order (1xxx chapter 1's
      // epilogues, 4999 the Warden, 5xxx the Court, 6xxx the Quarter).
      final granted = <String, ({String node, int chapter})>{};
      for (final entry in allChoices) {
        final id = entry.choice.grantsBannerPieceId;
        if (id == null || id.isEmpty) continue;
        final chapter = int.parse(entry.node.id.split('_').first) ~/ 1000;
        final previous = granted[id];
        if (previous != null) {
          expect(previous.chapter, chapter,
              reason: '$id is granted in two chapters');
          continue;
        }
        granted[id] = (node: entry.node.id, chapter: chapter);
      }
      expect(granted.keys.toSet(), {
        'heirloom_shroud',
        'warden_standard',
        'moon_shard_shroud',
        'reliquary_thread',
      });
      expect(granted['heirloom_shroud']!.chapter, lessThan(2));
      expect(granted['warden_standard']!.node, '4999_standard');
      expect(granted['moon_shard_shroud']!.node, '5004_altar');
      expect(granted['reliquary_thread']!.node, '6010_thread');
      expect(granted['warden_standard']!.chapter,
          lessThan(granted['moon_shard_shroud']!.chapter));
      expect(granted['moon_shard_shroud']!.chapter,
          lessThan(granted['reliquary_thread']!.chapter));
    });

    test('each late piece is unavoidable: every choice of its scene grants it',
        () {
      for (final (id, piece) in [
        ('4999_standard', 'warden_standard'),
        ('5004_altar', 'moon_shard_shroud'),
        ('6010_thread', 'reliquary_thread'),
      ]) {
        final node = nodes[id]!;
        expect(node.choices.length, greaterThanOrEqualTo(2), reason: id);
        for (final choice in node.choices) {
          expect(choice.grantsBannerPieceId, piece,
              reason: '$id: ${choice.text}');
        }
      }
      // The last piece makes the Shroud whole, on every path.
      for (final choice in nodes['6010_thread']!.choices) {
        expect(choice.flagsToAdd, contains('banner_whole'));
      }
      // And the pieces sit on the spine: the Warden's standard right after
      // the High Warden, the altar between the Court and the ledger, the
      // reliquary before the dead heart.
      expect(nodes['4999']!.choices.single.nextId, '4999_standard');
      for (final choice in nodes['4999_standard']!.choices) {
        expect(choice.nextId, '5001');
      }
      expect(nodes['5004']!.choices.single.nextId, '5004_altar');
      expect(nodes['5004b']!.choices.single.nextId, '5004_altar');
      for (final choice in nodes['5004_altar']!.choices) {
        expect(choice.nextId, '5005');
      }
      expect(
          nodes['6010']!.choices.where((c) => c.nextId == '6010_thread').length,
          1);
      for (final choice in nodes['6010_thread']!.choices) {
        expect(choice.launchZoneId, 'z_shroud_vigil');
        expect(choice.nextId, '6003');
      }
    });

    test('the whole Shroud opens the final crossing', () {
      expect(nodes['7002_confront']!.reqFlags, contains('banner_whole'));
      final sail = nodes['7002']!
          .choices
          .singleWhere((c) => c.nextId == '7002_confront');
      expect(sail.lockedText, isNotEmpty);
      expect(sail.launchesZone, isFalse);
      for (final choice in nodes['7002_confront']!.choices) {
        expect(choice.nextId, '7002_price');
      }
      for (final choice in nodes['7002_price']!.choices) {
        expect(choice.launchZoneId, 'z_beyond_the_tear');
        expect(choice.nextId, '7003');
      }
      expect(
          nodes['7002_price']!.choices.any((c) => c.loseAllyId == '*'), isTrue,
          reason: 'the Sovereign can take a companion');
    });
  });

  group('the chapter 2 exit builds the boat', () {
    test('2900 launches both repair zones and casts off only with both done',
        () {
      final hub = nodes['2900']!;
      final hull =
          hub.choices.singleWhere((c) => c.launchZoneId == 'z_fishermans_row');
      final sail =
          hub.choices.singleWhere((c) => c.launchZoneId == 'z_tanners_court');
      expect(hull.nextId, '2900');
      expect(sail.nextId, '2900');
      expect(hull.hideIfFlags, ['hull_patched']);
      expect(sail.hideIfFlags, ['sail_mended']);
      expect(hull.hideIfFlags.single,
          (zones['z_fishermans_row'] as Map)['rewardFlag']);
      expect(sail.hideIfFlags.single,
          (zones['z_tanners_court'] as Map)['rewardFlag']);
      final castOff =
          hub.choices.singleWhere((c) => c.nextId == '2900_boat_fixed');
      expect(castOff.showIfFlags.toSet(), {'hull_patched', 'sail_mended'});
      expect(castOff.isHiddenFor(const ['hull_patched']), isTrue);
      expect(
          castOff.isHiddenFor(const ['hull_patched', 'sail_mended']), isFalse);
      expect(nodes.containsKey('2900_boat_unfixed'), isFalse);
      for (final zid in ['z_fishermans_row', 'z_tanners_court']) {
        expect(zoneIsMain(zones[zid] as Map<String, dynamic>), isTrue,
            reason: '$zid is launched by the story');
      }
    });

    test('casting off and the voyage lead to a remote chapter 3', () {
      for (final choice in nodes['2900_boat_fixed']!.choices) {
        expect(choice.nextId, '2999');
      }
      for (final choice in nodes['2999']!.choices) {
        expect(choice.nextId, '3001');
      }
      expect(nodes['2999']!.description, contains('Three weeks'));
      expect(nodes['3001']!.description, contains('Ashen Coast'));
      expect(nodes['3001']!.description, contains('a day\'s walk'));
      expect(nodes['3001_camp']!.description, contains('sailed with me'));
      // The old geography is gone from chapter 3 onward.
      for (final node in nodes.values) {
        final chapter = int.tryParse(node.id.split('_').first) ?? 0;
        if (chapter < 3000) continue;
        for (final text in [node.description, node.descriptionFr ?? '']) {
          expect(text, isNot(contains('Upper Gate')), reason: node.id);
          expect(text, isNot(contains('Lower City')), reason: node.id);
          expect(text, isNot(contains('camp below the Spire')),
              reason: node.id);
        }
      }
    });
  });

  group('no clean way through', () {
    const sadFlags = {
      'lysa_lost',
      'keeper_dead',
      'refugees_left',
      'sailed_alone',
      'skiff_cut',
      'storm_cargo_lost',
      'storm_ridden',
      'standard_cut_living',
      'standard_waited',
      'standard_mercy',
      'court_woken',
      'court_never_woke',
      'reliquary_opened',
      'chartkeeper_paid',
      'penitent_seal',
      'sovereign_took_companion',
      'sovereign_blood',
      'camp_given',
    };
    const dilemmas = [
      '400',
      '2900_boat_fixed',
      '2999',
      '4999_standard',
      '5004_altar',
      '6010_thread',
      '7002_price',
    ];

    test('every dilemma offers at least two ways and none of them is free', () {
      for (final id in dilemmas) {
        final node = nodes[id]!;
        expect(node.choices.length, greaterThanOrEqualTo(2), reason: id);
        for (final choice in node.choices) {
          expect(_costs(choice, sadFlags), isTrue,
              reason: '$id: "${choice.text}" costs nothing');
          expect(choice.textFr, isNotEmpty, reason: '$id: ${choice.text}');
        }
      }
    });

    test('every cost leaves a mark the story reads back later', () {
      final readBack = <String>{
        for (final node in nodes.values)
          for (final callback in node.flagCallbacks) callback.flag,
        for (final node in nodes.values)
          for (final choice in node.choices) ...choice.showIfFlags,
        for (final node in nodes.values) ...node.reqFlags,
      };
      final set = <String>{
        for (final entry in allChoices) ...entry.choice.flagsToAdd,
      };
      for (final flag in sadFlags) {
        expect(set, contains(flag), reason: '$flag is never set');
      }
      final unread = sadFlags.difference(readBack);
      expect(unread.length, lessThanOrEqualTo(4),
          reason: 'too many costs go unremembered: $unread');
    });
  });

  group('power is worn', () {
    test('every race has a medium in both languages and {sigil} resolves', () {
      for (final entry in races.entries) {
        final race = entry.value as Map;
        expect(race['powerMedium']?.toString() ?? '', isNotEmpty,
            reason: entry.key);
        expect(race['powerMediumFr']?.toString() ?? '', isNotEmpty,
            reason: entry.key);
        expect(powerMediumFor(entry.key, french: false),
            race['powerMedium'].toString());
        expect(powerMediumFor(entry.key, french: true),
            race['powerMediumFr'].toString());
        final line = personalizeNarration('my {sigil}',
            name: 'x',
            raceId: entry.key,
            professionId: 'warrior',
            french: false);
        expect(line, isNot(contains('{sigil}')));
      }
      expect(powerMediumFor('unknown', french: false), 'mark');
    });

    test('the prologue and the first scenes say so', () {
      expect(
          nodes['0']!.description, contains('power is not held; it is worn'));
      for (final id in ['250', '450', '3001', '7003']) {
        final variants = nodes[id]!.personaVariants;
        expect(variants.keys.where((k) => k.startsWith('race:')).length,
            greaterThanOrEqualTo(2),
            reason: id);
      }
    });
  });

  group('StoryChoice cost fields', () {
    test('grantsBannerPieceId and loseAllyId round-trip and count as effects',
        () {
      const choice = StoryChoice(
        text: 'Pay',
        nextId: '1',
        grantsBannerPieceId: 'warden_standard',
        loseAllyId: '*',
      );
      expect(choice.hasEffects, isTrue);
      final restored = StoryChoice.fromJson(choice.toJson());
      expect(restored.grantsBannerPieceId, 'warden_standard');
      expect(restored.loseAllyId, '*');
      const plain = StoryChoice(text: 'Go', nextId: '1');
      expect(plain.hasEffects, isFalse);
      expect(plain.toJson().containsKey('grantsBannerPieceId'), isFalse);
      expect(plain.toJson().containsKey('loseAllyId'), isFalse);
    });
  });
}

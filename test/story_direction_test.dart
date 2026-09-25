// The owner's story direction, checked against the authored data: every
// origin carries the first piece of the Shroud; the chapter-2 exit builds
// the boat; chapter 3 lands on a remote coast after a long voyage; the
// Shroud is cut into six, a piece at the end of each open chapter (3 to
// 6), each at a cost, and the last taken from the Sovereign; five pieces
// open the final crossing; power is worn (each race has a medium and the
// {sigil} token resolves for it); and there is no clean way through the
// spine's dilemmas.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart'
    show soloOnlyEnemyIds;
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
  StoryChoice choiceIn(String nodeId, String target) =>
      nodes[nodeId]!.choices.singleWhere((c) => c.nextId == target,
          orElse: () => fail('$nodeId does not lead to $target'));

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

    test(
        'six distinct pieces: the heirloom, one per open chapter, and the '
        'Sovereign\'s', () {
      // Node ids number the story in reading order (1xxx chapter 1's
      // epilogues, 4999 the Warden, 5xxx the Court, 6xxx the Quarter, 7xxx
      // the Hollow Shore and the crossing).
      final granted = <String, ({String node, int band})>{};
      for (final entry in allChoices) {
        final id = entry.choice.grantsBannerPieceId;
        if (id == null || id.isEmpty) continue;
        final band = int.parse(entry.node.id.split('_').first) ~/ 1000;
        final previous = granted[id];
        if (previous != null) {
          expect(previous.band, band, reason: '$id is granted in two chapters');
          continue;
        }
        granted[id] = (node: entry.node.id, band: band);
      }
      expect(granted.keys.toSet(), {
        'heirloom_shroud',
        'warden_standard',
        'moon_shard_shroud',
        'reliquary_thread',
        'white_fleet_sail',
        'sovereign_mantle',
      });
      expect(granted['heirloom_shroud']!.band, lessThan(2));
      expect(granted['warden_standard']!.node, '4999_standard');
      expect(granted['moon_shard_shroud']!.node, '5004_altar');
      expect(granted['reliquary_thread']!.node, '6010_thread');
      expect(granted['white_fleet_sail']!.node, '7300');
      expect(granted['sovereign_mantle']!.node, '7003');
      final order = [
        'warden_standard',
        'moon_shard_shroud',
        'reliquary_thread',
        'white_fleet_sail',
      ];
      for (var i = 1; i < order.length; i++) {
        expect(granted[order[i - 1]]!.band, lessThan(granted[order[i]]!.band),
            reason: '${order[i - 1]} before ${order[i]}');
      }
    });

    test('each late piece is unavoidable: every choice of its scene grants it',
        () {
      for (final (id, piece) in [
        ('4999_standard', 'warden_standard'),
        ('5004_altar', 'moon_shard_shroud'),
        ('6010_thread', 'reliquary_thread'),
        ('7300', 'white_fleet_sail'),
        ('7003', 'sovereign_mantle'),
      ]) {
        final node = nodes[id]!;
        expect(node.choices.length, greaterThanOrEqualTo(2), reason: id);
        for (final choice in node.choices) {
          expect(choice.grantsBannerPieceId, piece,
              reason: '$id: ${choice.text}');
        }
      }
      // The fifth opens the crossing; the sixth, taken from the Sovereign,
      // makes the Shroud whole, on every path.
      for (final choice in nodes['7300']!.choices) {
        expect(choice.flagsToAdd, contains('banner_five'));
      }
      for (final choice in nodes['7003']!.choices) {
        expect(choice.flagsToAdd, contains('banner_whole'));
      }
      for (final node in nodes.values) {
        if (node.id == '7003') continue;
        for (final choice in node.choices) {
          expect(choice.flagsToAdd, isNot(contains('banner_whole')),
              reason: '${node.id} makes the Shroud whole too early');
        }
      }
      // Each piece ends its chapter's main quest, set out on from the camp,
      // and the story comes back to the next chapter's camp with it.
      expect(nodes['4999']!.choices.single.nextId, '4999_standard');
      for (final choice in nodes['4999_standard']!.choices) {
        expect(choice.nextId, '4999_camp');
      }
      final court = nodes['4999_camp']!.choices.single;
      expect(court.mainQuest, isTrue);
      expect(court.launchZoneId, 'z_drowned_stair');
      expect(court.nextId, '5003');
      expect(nodes['5004']!.choices.single.nextId, '5004_altar');
      expect(nodes['5004b']!.choices.single.nextId, '5004_altar');
      for (final choice in nodes['5004_altar']!.choices) {
        expect(choice.nextId, '5005');
      }
      expect(nodes['6010']!.choices.where((c) => c.nextId == '6010_thread'),
          isEmpty,
          reason: 'the Quarter is a place; the thread is the main quest');
      final thread = nodes['6002_camp']!.choices.single;
      expect(thread.mainQuest, isTrue);
      expect(thread.nextId, '6010_thread');
      expect(thread.travelPlaceId, '6010');
      for (final choice in nodes['6010_thread']!.choices) {
        expect(choice.launchZoneId, 'z_shroud_vigil');
        expect(choice.nextId, '6003');
      }
      final fleet = nodes['7001']!.choices.single;
      expect(fleet.mainQuest, isTrue);
      expect(fleet.launchZoneId, 'z_white_fleet_grave');
      expect(fleet.nextId, '7300');
      for (final choice in nodes['7300']!.choices) {
        expect(choice.nextId, '7400');
      }
    });

    test('five pieces open the final crossing; the Sovereign wears the sixth',
        () {
      expect(nodes['7002_confront']!.reqFlags, ['banner_five']);
      expect(nodes['7002']!.choices.where((c) => c.nextId == '7002_confront'),
          isEmpty,
          reason: 'the crossing sets out from the camp');
      final sail = nodes['7400']!.choices.single;
      expect(sail.nextId, '7002_confront');
      expect(sail.mainQuest, isTrue);
      expect(sail.travelPlaceId, '7002');
      expect(sail.showIfFlags, ['banner_five']);
      expect(sail.lockedText ?? '', isEmpty);
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

    test('the whole Banner turns time back in every ending, for New Game+', () {
      for (final id in ['7005', '7005_seeker', '7005_dawn', '7005_crown']) {
        final node = nodes[id]!;
        expect(node.description, contains('[EPILOGUE]'), reason: id);
        expect(node.descriptionFr, contains('[ÉPILOGUE]'), reason: id);
        expect(node.description, contains('the night before the invasion'),
            reason: id);
        expect(node.choices.single.isEnding, isTrue, reason: id);
      }
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
      '7300',
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

  group('the Inquisition\'s pact', () {
    test('an Evil character can sell the crew out on the Hollow Shore', () {
      final pact = nodes['7002_pact']!;
      expect(pact.reqAlignmentMax, -15);
      expect(pact.speaker, 'Legate');
      final offer = nodes['7002']!.choices.singleWhere(
          (c) => c.nextId == '7002_pact',
          orElse: () => fail('7002 no longer offers the pact'));
      expect(offer.lockedText, isNotEmpty);
      expect(offer.hideIfFlags.toSet(), {'inquisition_pact', 'pact_refused'});
      final take = pact.choices.singleWhere((c) => c.nextId == '7002_betrayal');
      expect(take.triggerEnemyId, '@first_ally');
      expect(take.flagsToAdd, contains('inquisition_pact'));
      expect(take.alignmentMod, lessThan(0));
      final refuse = pact.choices.singleWhere((c) => c.nextId == '7002');
      expect(refuse.flagsToAdd, contains('pact_refused'));
      expect(nodes['7002_betrayal']!.flagCallbacks.map((c) => c.flag).toSet(),
          {'companion_turned', 'legate_fought'});
      final legate = nodes['7002_price']!
          .choices
          .singleWhere((c) => c.flagsToAdd.contains('legate_given'));
      expect(legate.showIfFlags, ['inquisition_pact']);
      expect(legate.launchZoneId, 'z_beyond_the_tear');
    });

    test(
        'every companion has a turned self, and the story\'s duels are '
        'never random draws', () {
      final enemies = _loadJson('assets/gamedata/enemies.json');
      final companions = _loadJson('assets/gamedata/companions.json');
      for (final id in companions.keys) {
        final turned = enemies['${id}_turned'] as Map<String, dynamic>?;
        expect(turned, isNotNull, reason: id);
        expect(turned!['minChapter'], 6);
        expect(turned['packEligible'], isFalse);
        expect((turned['phases'] as List), isNotEmpty);
        expect(soloOnlyEnemyIds, contains('${id}_turned'));
      }
      expect(enemies.containsKey('inquisition_legate'), isTrue);
      expect(enemies.containsKey('masked_penitent'), isTrue);
      expect(soloOnlyEnemyIds, contains('inquisition_legate'));
      expect(soloOnlyEnemyIds, contains('masked_penitent'));
    });
  });

  group('Lysa\'s fate', () {
    test('a survivor is remembered; an abandoned Lysa is found by alignment',
        () {
      expect(choiceIn('3005', '3005_lysa').showIfFlags, ['lysa_survived']);
      expect(choiceIn('6010', '6010_lysa').showIfFlags, ['lysa_survived']);
      final dead = choiceIn('6010', '6010_lysa_dead');
      final masked = choiceIn('6010', '6010_masked');
      expect(dead.showIfFlags, ['lysa_lost']);
      expect(masked.showIfFlags, ['lysa_lost']);
      expect(nodes['6010_lysa_dead']!.reqAlignmentScore, 5);
      expect(nodes['6010_masked']!.reqAlignmentMax, 4);
      // One retires the other: Lysa is found once.
      expect(dead.hideIfFlags.toSet(), masked.hideIfFlags.toSet());
      final fight = nodes['6010_masked']!.choices.single;
      expect(fight.triggerEnemyId, 'masked_penitent');
      expect(fight.flagsToAdd, contains('lysa_fallen'));
      expect(fight.alignmentMod, lessThan(0));
      expect(nodes['6010_masked_after']!.description, contains('Lysa'),
          reason: 'the mask comes off after the fight, not before');
      expect(nodes['6010_masked']!.description, isNot(contains('Lysa')));
      expect(nodes['6010_lysa_dead']!.choices.single.flagsToAdd,
          contains('lysa_found_dead'));
      for (final flag in ['lysa_fallen', 'lysa_found_dead']) {
        final readBack = nodes.values
            .expand((n) => n.flagCallbacks)
            .where((c) => c.flag == flag)
            .length;
        expect(readBack, greaterThanOrEqualTo(3), reason: flag);
      }
    });

    test('the Quarter\'s gate settles her fate before the hub opens', () {
      // The first trip to the Reliquary Quarter goes through its gate, and a
      // character who lost Lysa cannot pass it without taking one of the two
      // fate scenes (each open to one side of the alignment line, so exactly
      // one is ever available).
      expect(nodes['6010']!.settlement!.arrivalNodeId, '6010_gate');
      for (final choice in nodes['6002']!.choices) {
        expect(choice.nextId, '6002_camp', reason: choice.text);
      }
      final gate = nodes['6010_gate']!;
      final through = gate.choices.singleWhere((c) => c.nextId == '6010');
      expect(through.hideIfFlags, contains('lysa_lost'));
      expect(through.showIfFlags, isEmpty);
      for (final target in ['6010_lysa_dead', '6010_masked']) {
        final choice = gate.choices.singleWhere((c) => c.nextId == target);
        expect(choice.showIfFlags, ['lysa_lost'], reason: target);
        expect(choice.lockedText, isNotEmpty, reason: target);
        expect(choice.hideIfFlags.toSet(),
            {'hub_6010_lysa_dead', 'hub_6010_masked'},
            reason: target);
      }
      // Both fate scenes come back to the hub proper.
      expect(nodes['6010_lysa_dead']!.choices.single.nextId, '6010');
      for (final choice in nodes['6010_masked_after']!.choices) {
        expect(choice.nextId, '6010', reason: choice.text);
      }
      // The gate reads both origins back, in both languages.
      for (final flag in ['lysa_lost', 'lysa_survived']) {
        final callback = gate.flagCallbacks.singleWhere((c) => c.flag == flag);
        expect(callback.line.en, isNotEmpty, reason: flag);
        expect(callback.line.fr, isNotEmpty, reason: flag);
      }
      expect(
          gate.choices.any((c) => c.launchesZone || c.triggersCombat), isFalse);
    });
  });

  group('the 1.118 regressions stay fixed', () {
    test(
        'Vane\'s tunnel leads to the berths and the harbor\'s end knows '
        'its own state', () {
      expect(nodes['2030']!.description, contains('old berths'));
      expect(nodes['2030']!.description, isNot(contains('checkpoint')));
      final hub = nodes['2900']!;
      expect(hub.description, isNot(contains('would need a hull')));
      final needs =
          hub.flagCallbacks.where((c) => c.flag == 'void_banner_bearer').single;
      expect(needs.unlessFlags.toSet(), {'hull_patched', 'sail_mended'});
      final both = hub.flagCallbacks
          .where((c) => c.flag == 'hull_patched' && c.andFlags.isNotEmpty)
          .single;
      expect(both.andFlags, ['sail_mended']);
      expect(
          hub.callbacksFor(const ['void_banner_bearer'], false), hasLength(1));
      expect(
          hub.callbacksFor(
              const ['void_banner_bearer', 'hull_patched', 'sail_mended'],
              false),
          hasLength(1));
      expect(
          hub.callbacksFor(
              const ['void_banner_bearer', 'hull_patched'], false).single,
          contains('sail was still'));
      for (final cb in hub.flagCallbacks) {
        expect(cb.line.en, isNot(contains('Gate')), reason: cb.flag);
      }
      expect(nodes['3002']!.description,
          isNot(contains('a second set of doors sealed')));
      expect(nodes['3002']!.description, contains("Spire's outer gate"));
    });

    test(
        'the wanderer sails on with the whole Shroud and the camp callback '
        'yields to the price', () {
      for (final epilogue in nodes['7005_seeker']!.alignmentEpilogues.values) {
        expect(epilogue.en, isNot(contains('The Banner is out there')));
        expect(epilogue.en.toLowerCase(), contains('shroud'));
      }
      expect(nodes['7004']!.description, isNot(contains('expecting me')));
      final camp = nodes['7004']!
          .flagCallbacks
          .firstWhere((c) => c.flag == 'camp_founded');
      expect(camp.unlessFlags, ['camp_given']);
      expect(
          nodes['7004']!.callbacksFor(const ['camp_founded', 'camp_given'],
              false).any((line) => line.contains('expecting me')),
          isFalse);
    });

    test('Lysa sails with you and is never left on the wharf', () {
      for (final id in ['2001', '2015', '2900_boat_fixed', '3001_camp']) {
        expect(nodes[id]!.flagCallbacks.any((c) => c.flag == 'lysa_survived'),
            isTrue,
            reason: id);
      }
      final camp = nodes['3001_camp']!;
      final alone = camp.callbacksFor(const ['sailed_alone'], false);
      expect(alone.single, contains('brought no one,'));
      final aloneWithLysa =
          camp.callbacksFor(const ['sailed_alone', 'lysa_survived'], false);
      expect(aloneWithLysa.any((l) => l.contains('no one but Lysa')), isTrue);
      expect(aloneWithLysa.any((l) => l.contains('brought no one,')), isFalse);
      expect(
          nodes['6010_lysa']!.description, isNot(contains('over the water')));
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

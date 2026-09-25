// From chapter 3 the camp is the party's base: the story comes back to it
// between arcs, towns are places visited away from it, and what is built
// there is read back by the story.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/settlements.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _loadJson(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $relative');
}

void main() {
  final dag = _loadJson('assets/Cleaned_Narrative_DAG.json');
  final story = StoryData({
    for (final entry in dag.entries)
      entry.key:
          StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
  });
  final houses = _loadJson('assets/gamedata/houses.json');
  final shops = _loadJson('assets/gamedata/shops.json');

  test('the camp has one name, and every open chapter stands at it', () {
    final camps =
        story.nodes.values.where((n) => n.settlement?.isCamp ?? false);
    expect(camps.map((n) => n.id).toSet(),
        {'3001_camp', '4999_camp', '6002_camp', '7001', '7400'});
    for (final camp in camps) {
      expect(camp.settlement!.nameFor(false), 'The Cove Camp');
      expect(camp.settlement!.nameFor(true), 'Le camp de la crique');
      expect(camp.settlement!.chapter, isNotNull, reason: camp.id);
    }
    // After the Spire, every road goes home before the Court.
    for (final choice in story.nodeFor('4999_standard')!.choices) {
      expect(choice.nextId, '4999_camp');
    }
    // The Court's stair is the fourth chapter's main quest, from the camp.
    final court = story.nodeFor('4999_camp')!.choices.single;
    expect(court.mainQuest, isTrue);
    expect(court.nextId, '5003');
    // After the ledger, the party sails home; the Quarter's thread is the
    // fifth chapter's main quest.
    expect(story.nodeFor('6002')!.choices.map((c) => c.nextId).toSet(),
        {'6002_camp'});
    final thread = story.nodeFor('6002_camp')!.choices.single;
    expect(thread.mainQuest, isTrue);
    expect(thread.nextId, '6010_thread');
    expect(thread.travelPlaceId, '6010');
  });

  test('the late hubs are places away from the camp', () {
    for (final id in ['3005', '5010', '6010', '7100', '7002']) {
      final place = story.nodeFor(id)!.settlement;
      expect(place, isNotNull, reason: id);
      expect(place!.isCamp, isFalse, reason: id);
      expect(place.chapter, isNotNull, reason: id);
      expect(place.portId, isNull,
          reason: '$id: its zones are launched by the story itself');
    }
  });

  test('coming into the Reliquary Quarter through its gate is arriving', () {
    // The gate is one of the Quarter's own scenes by name, but the first
    // visit through it is still an arrival; a later return is not.
    expect(isSettlementArrival('6010', '6010_gate', history: ['6002']), isTrue);
    expect(
        isSettlementArrival('6010', '6010_lysa_dead',
            history: ['6002', '6010_gate']),
        isTrue);
    expect(
        isSettlementArrival('6010', '6010_hounds',
            history: ['6010_gate', '6010']),
        isFalse);
    expect(
        isSettlementArrival('4999_camp', '4999_standard', history: []), isTrue);
  });

  test('the Vault moved from the Quarter to a house at the camp', () {
    expect(story.nodeFor('3005')!.choices.map((c) => c.unlockShopId),
        isNot(contains('smugglers_vault')));
    expect(story.nodeFor('3005_vault'), isNull);
    final cellar = houses['smugglers_cellar'] as Map<String, dynamic>;
    expect(cellar['unlocksShopId'], 'smugglers_vault');
    expect(shops['smugglers_vault'], isA<Map<String, dynamic>>());
    expect((shops['smugglers_vault'] as Map)['detourEligible'], isFalse);
  });

  test('every camp house is read back by the story', () {
    final read = <String>{
      for (final node in story.nodes.values)
        for (final callback in node.flagCallbacks) callback.flag,
    };
    for (final houseId in houses.keys) {
      expect(read, contains(houseFlag(houseId)), reason: houseId);
    }
  });

  test('once the camp stands, it never burns quietly in the endings', () {
    // Every ending that mentions the camp's fires gates them on the camp
    // not having been given to the Sovereign.
    for (final id in ['7004', '7005', '7005_seeker', '7005_dawn']) {
      for (final callback in story.nodeFor(id)!.flagCallbacks) {
        if (callback.flag != 'camp_founded') continue;
        expect(callback.unlessFlags, contains('camp_given'), reason: id);
      }
    }
    expect(
        story
            .nodeFor('7004')!
            .flagCallbacks
            .where((c) => c.flag == 'camp_founded')
            .length,
        1);
  });
}

// Scene or map (choice_flow.dart, docs/proposals/scene-vs-map-flow.md): a
// scene's stop is its building, else its district, else its location; the
// map is handed over only for a plain way to another stop, a choice done
// here is carried there, and an errand comes back to its town hub in one
// tap. Checked on the story itself, chapters 1 and 2.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/scene_flow.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final geography =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final plans = cityPlanRecordsFrom(_table('city_plans'));
  final stops = StoryStops.of(
    story: story,
    geography: geography,
    cityPlans: plans,
    ports: _table('ports'),
  );
  ChoiceFlow flow(String nodeId, String startsWith, {String? nextId}) {
    final node = story.nodeFor(nodeId)!;
    final choice =
        node.choices.firstWhere((c) => c.text.startsWith(startsWith));
    return stops.flowOf(node, choice, nextId: nextId);
  }

  test('a stop is the building, else the district, else the location', () {
    expect(stops.stopOf('100'), 'blind_beggar');
    expect(stops.stopOf('300'), 'alster_family_house');
    expect(stops.stopOf('250'), 'alster_lower_town');
    expect(stops.stopOf('260'), 'alster_stone_bridge');
    expect(stops.stopOf('965'), 'lark_wreck');
    // The camp keeps the whole camp.
    expect(stops.stopOf('3001_camp'), 'cove_camp');
    expect(stops.stopOf('no_such_scene'), '');
  });

  test('the prologue happens nowhere', () {
    expect(stops.stopOf('0'), '');
    expect(StoryStops.isPrologue(story.nodeFor('0')!), isTrue);
    expect(flow('0', 'Choose who you are'), const FlowStay());
  });

  test('a village hub and its scenes stand in the hub district', () {
    // White Wells: the hub's lot is at the Pool, and so is the rest.
    expect(stops.stopOf('1200'), 'white_wells_pool');
    expect(stops.stopOf('1210'), 'white_wells_pool');
    expect(stops.stopOf('5100'), 'wracks_end_hull_houses');
    for (final id in story.nodes.keys) {
      if (story.nodeFor(id)!.location == 'rimewell') {
        expect(stops.stopOf(id), 'rimewell_bell_square', reason: id);
      }
    }
  });

  test('the Blind Beggar: one building, one lot, choices stay inside', () {
    const beggar = ['100', '105', '106', '110', '115', '120', '125'];
    final alster = plans['alster']!;
    for (final id in beggar) {
      expect(stops.stopOf(id), 'blind_beggar', reason: id);
      expect(alster.anchors[id], alster.anchors['100'], reason: id);
    }
    expect(alster.nameOf(alster.anchors['100']!, french: false),
        'The Blind Beggar');
    // So is the family house.
    for (final id in ['300', '400', '400_lost', '450', '470']) {
      expect(alster.anchors[id], alster.anchors['300'], reason: id);
    }
    // A pick at the tables stays in the scene...
    for (final c in story.nodeFor('100')!.choices) {
      expect(stops.flowOf(story.nodeFor('100')!, c), const FlowStay());
    }
    // ...and leaving by the door is a map move to the Lower Town.
    final out =
        story.nodeFor('106')!.choices.firstWhere((c) => c.nextId == '250');
    expect(stops.flowOf(story.nodeFor('106')!, out),
        const FlowMap('alster_lower_town'));
  });

  test('the walk home from Weaver’s Alley is a map move', () {
    expect(
        flow('270', 'Leave them both'), const FlowMap('alster_family_house'));
    // Inside the house, the scenes follow one another.
    expect(flow('300', 'Watch from across the street'), const FlowStay());
    // Kneeling at the house: done here, then carried to the Black Hold's
    // cells (a building of it since v1.470).
    expect(flow('400', 'Kneel'), const FlowTripThenArrive('black_hold_cells'));
    // The toll fight: fought at the bridge, carried home.
    expect(flow('260', 'Refuse and fight'),
        const FlowTripThenArrive('alster_family_house'));
    expect(flow('260', 'Pay the toll'), const FlowStay());
  });

  test('a roll that moves the party is carried; a failure nearby stays', () {
    final wade = story
        .nodeFor('840')!
        .choices
        .firstWhere((c) => c.text.startsWith('Wade straight'));
    expect(stops.flowOf(story.nodeFor('840')!, wade),
        const FlowTripThenArrive('alster_family_house'));
    expect(stops.flowOf(story.nodeFor('840')!, wade, nextId: wade.failNextId),
        const FlowStay());
    // Up to the battlements: a plain way out of the Black Hold.
    expect(flow('823', 'Up, to the battlements'),
        const FlowMap('alster_family_house'));
  });

  test('Smugglers’ Wharf: errands go by the map, come back in one tap', () {
    expect(flow('2015', 'Visit the Arcane Bazaar'),
        const FlowMap('saltmouth_lantern_alleys'));
    expect(flow('2015_bazaar', 'Return to the stalls'),
        const FlowReturnToHub('saltmouth_wharf', '2015'));
    expect(flow('2015_sable', 'Promise to win it back'),
        const FlowReturnToHub('saltmouth_wharf', '2015'));
    // A fight from the hub to the yard is carried there.
    expect(flow('2011', 'Continue through the Docks'),
        const FlowTripThenArrive('saltmouth_yard'));
    // A plain walk from the wharf to the yard is a map move (no read-through).
    expect(flow('2040_paid', 'Walk to the yards'),
        const FlowMap('saltmouth_yard'));
    expect(stops.changesStop('2040_paid', '2900'), isTrue);
    expect(
        passThroughChoiceOf(story.nodeFor('2015_bazaar')!, const [],
            travels: stops.changesStop),
        isNull,
        reason: 'the way back is a stop, not read through');
  });

  test('the endings stay', () {
    for (final id in ['7005', '7005_seeker', '7005_dawn', '7005_crown']) {
      final node = story.nodeFor(id)!;
      for (final c in node.choices.where((c) => c.isEnding)) {
        expect(stops.flowOf(node, c), const FlowStay(), reason: id);
      }
    }
  });

  test('main-story scenes: not a hub, not an errand, not the camp', () {
    expect(stops.isMainStoryScene('100'), isTrue);
    expect(stops.isMainStoryScene('400'), isTrue);
    expect(stops.isMainStoryScene('2999'), isTrue);
    expect(stops.isHub('2015'), isTrue);
    expect(stops.isMainStoryScene('2015'), isFalse);
    expect(stops.hubsOfErrand('2015_bazaar'), {'2015'});
    expect(stops.isMainStoryScene('2015_bazaar'), isFalse);
    expect(stops.isMainStoryScene('3001_camp'), isFalse);
    // The doc's count: 25 hubs, 121 main-story scenes (three page turns of chapter 1 among them).
    expect(story.nodes.keys.where(stops.isHub).length, 25);
    expect(story.nodes.keys.where(stops.isMainStoryScene).length, 121);
  });

  test('the services of a port town', () {
    final wharf = stops.servicesAt('saltmouth');
    bool has(PlaceServiceKind kind, String id) =>
        wharf.any((s) => s.kind == kind && s.id == id);
    expect(has(PlaceServiceKind.port, 'port_smugglers_wharf'), isTrue);
    expect(has(PlaceServiceKind.shop, 'arcane_bazaar'), isTrue);
    expect(has(PlaceServiceKind.shop, 'black_market_docks'), isTrue);
    final bazaar = wharf.firstWhere((s) => s.id == 'arcane_bazaar');
    expect(bazaar.nodeId, '2015');
    expect(story.nodeFor('2015')!.choices[bazaar.choiceIndex!].unlockShopId,
        'arcane_bazaar');
    // The district alone holds the hub's own services.
    expect(stops.servicesAt('saltmouth_wharf').map((s) => s.id),
        contains('port_smugglers_wharf'));
    // The trainer is on the High Quay.
    expect(
        stops
            .servicesAt('alster_high_quay')
            .where((s) => s.kind == PlaceServiceKind.trainer)
            .map((s) => s.id),
        ['890_trainer']);
    expect(
        stops.servicesAt('lark_wreck').where((s) =>
            s.kind == PlaceServiceKind.shop || s.kind == PlaceServiceKind.port),
        isEmpty);
  });

  test('the whole story: same-stop choices stay, no district walk read through',
      () {
    final counts = <String, int>{};
    var readThroughMoves = 0;
    for (final node in story.nodes.values) {
      for (final c in node.choices) {
        final f = stops.flowOf(node, c);
        counts.update(f.runtimeType.toString(), (n) => n + 1,
            ifAbsent: () => 1);
      }
      final way =
          passThroughChoiceOf(node, const [], travels: stops.changesStop);
      if (way != null && stops.stopOf(node.id) != stops.stopOf(way.nextId)) {
        readThroughMoves++;
      }
    }
    // On the story (v1.439): 725 stay, 104 map, 87 carried, 145 returns.
    expect(readThroughMoves, 0);
    expect(counts['FlowStay'], greaterThan(600));
    expect(counts['FlowReturnToHub'], greaterThan(20));
  });
}

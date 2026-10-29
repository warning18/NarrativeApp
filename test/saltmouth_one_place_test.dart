// Saltmouth is one place on the world chart (v1.536), as Alster is since
// v1.534: its six districts (the Landward Gate, Tern Row, Smugglers' Wharf,
// the ship-breaker's yard, the Lantern Alleys, Card Row) are town places
// walked on its own plan (city_plans.json), not world landmarks joined by
// roads. The world's roads reach it at its edge. A move to another district
// shows the whole town, a move within the district the district.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/world_leg_path.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final geo = Geography.parse(
    geography: _json('assets/gamedata/geography.json'),
    biomes: _json('assets/gamedata/biomes.json'),
  );
  final raw = _json('assets/Cleaned_Narrative_DAG.json');
  final story = StoryData({
    for (final e in raw.entries)
      if (e.value is Map<String, dynamic>)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });

  /// Chapter 2's scenes that happen in Saltmouth.
  final saltmouthScenes = [
    for (final id in story.nodes.keys)
      if (geo.locationOfNode(story.nodeFor(id))?.id == 'saltmouth') id,
  ];
  const districts = [
    'saltmouth_landward_gate', 'saltmouth_tern_row', 'saltmouth_wharf', //
    'saltmouth_yard', 'saltmouth_lantern_alleys', 'saltmouth_card_row',
  ];
  const gone = ['upper', 'tern', 'wharf', 'berths', 'alleys', 'cards'];

  test('Saltmouth is one world node, with roads from its edge', () {
    expect(saltmouthScenes,
        containsAll(['2005', '2010', '2015_ternrow', '2900', '2015_cards']));
    // Every scene in Saltmouth stands on the one landmark.
    final landmarks = {
      for (final id in saltmouthScenes) landmarkOfScene(id)?.id,
    };
    expect(landmarks, {'saltmouth'});
    expect(geo.placeOfLandmark('saltmouth')!.id, 'saltmouth');
    expect(geo.placeOfLandmark('saltmouth')!.level, GeoLevel.location);
    // No other landmark lies in Saltmouth, and the old six are gone.
    for (final landmark in worldMapLandmarks) {
      if (landmark.id == 'saltmouth') continue;
      expect(geo.locationOf(geo.placeOfLandmark(landmark.id)?.id)?.id,
          isNot('saltmouth'),
          reason: landmark.id);
    }
    for (final id in gone) {
      expect(landmarkById(id), isNull, reason: id);
    }
    // Two roads, both from its edge: in from the White Wells, out to sea
    // from the yard. No road inside it.
    expect({for (final r in roadsAt('saltmouth')) r.id},
        {'wells_saltmouth', 'saltmouth_storm'});
    for (final road in worldRoads) {
      expect(gone, isNot(contains(road.a)), reason: road.id);
      expect(gone, isNot(contains(road.b)), reason: road.id);
    }
    final route = roadRoute('wells', 'storm')!;
    expect(route.places, ['wells', 'saltmouth', 'storm']);
    // The roads keep their stops.
    expect([for (final s in roadBetween('wells', 'saltmouth')!.stops) s.id],
        ['caravan_ford', 'salt_marker']);
    expect([for (final s in roadBetween('saltmouth', 'storm')!.stops) s.id],
        ['last_light']);
    // On every chart, Saltmouth is one spot.
    for (final shape in MapShape.values) {
      expect(chartOf(shape).places.containsKey('saltmouth'), isTrue,
          reason: shape.name);
      for (final id in gone) {
        expect(chartOf(shape).places.containsKey(id), isFalse,
            reason: '${shape.name}: $id');
      }
    }
  });

  test('its districts are town places', () {
    expect([for (final d in districtsOfCity(geo, 'saltmouth')) d.id],
        containsAll(districts));
    for (final child in districtsOfCity(geo, 'saltmouth')) {
      expect(child.landmarks, isEmpty, reason: child.id);
    }
    expect(
        districtOfPlace(geo, 'saltmouth_tide_cellar')!.id, 'saltmouth_wharf');
    for (final id in saltmouthScenes) {
      final place = geo.placeOfNode(story.nodeFor(id))!;
      expect(place.level, anyOf(GeoLevel.district, GeoLevel.building),
          reason: id);
    }
  });

  test('a move between its districts is a town walk, not a world road', () {
    // The gate to the wharf, the wharf to Tern Row, the alleys to Card Row,
    // the wharf to the yard.
    for (final (from, to) in [
      ('2005', '2010'),
      ('2015', '2015_ternrow'),
      ('2015_bazaar', '2015_cards'),
      ('2015', '2900'),
    ]) {
      expect(geo.travelsBetween(story, from, to), isFalse, reason: '$from>$to');
      expect(worldLegPathForScenes(chartOf(MapShape.story), from, to), isNull,
          reason: '$from>$to');
    }
    for (var i = 0; i < districts.length; i++) {
      for (var j = 0; j < districts.length; j++) {
        if (i == j) continue;
        expect(
            townMoveView(geo, districts[i], districts[j]), JourneyTownView.town,
            reason: '${districts[i]}>${districts[j]}');
      }
    }
    // Into and out of Saltmouth is a journey along the world's roads.
    expect(geo.travelsBetween(story, '1200', '2001'), isTrue);
    expect(townMoveView(geo, 'saltmouth_yard', 'white_wells'), isNull);
  });

  test('a move inside one district stays on the district', () {
    expect(townMoveView(geo, 'saltmouth_wharf', 'saltmouth_tide_cellar'),
        JourneyTownView.district);
    expect(
        townMoveView(
            geo, 'saltmouth_landward_gate', 'saltmouth_landward_warehouse'),
        JourneyTownView.district);
    expect(townMoveView(geo, 'saltmouth_yard', 'saltmouth_yard'),
        JourneyTownView.district);
  });

  testWidgets('the level tabs follow a move in Saltmouth, with no world road',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester);
    final play = container.read(storyPlayProvider.notifier);

    Future<void> moveTo(String nodeId) async {
      play.jumpTo(nodeId);
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 2));
      // What arriving opens over the game (a scene read full screen, a
      // place's card) is closed, back to the map.
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(milliseconds: 500));
        final back = find.byKey(const ValueKey('journey_continue'));
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 500));
        }
      }
      await tester.pump(const Duration(seconds: 1));
    }

    play.jumpTo('2015');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    await moveTo('2015');
    expect(container.read(currentCityProvider), 'saltmouth');

    final townRows = find.textContaining('THE DISTRICTS');
    // The wharf to Tern Row: another district, the whole town.
    await moveTo('2015_ternrow');
    expect(container.read(partyDistrictProvider), 'saltmouth_tern_row');
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(townRows, findsOneWidget);
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(find.byKey(const ValueKey('journey_transit')), findsNothing);

    // The District tab shows the district, not the world chart.
    await tester.tap(find.byKey(const Key('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(townRows, findsNothing);
    expect(find.byType(JourneyWorldMap), findsNothing);

    // Back to the wharf (another district again), then a move within it,
    // to the dockside: the district.
    await moveTo('2015');
    expect(townRows, findsOneWidget);
    await moveTo('2015_dockside');
    expect(container.read(partyDistrictProvider), 'saltmouth_wharf');
    expect(townRows, findsNothing);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(find.byKey(const ValueKey('journey_transit')), findsNothing);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}

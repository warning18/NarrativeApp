// Alster, the starting town, is one place on the world chart (v1.534), as
// every later town is: its districts and buildings are town places walked
// on its own plan (city_plans.json), not world landmarks joined by roads.
// A move to another district shows the whole town, a move within the
// district the district; the level tabs follow the move.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/world_leg_path.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/data/world_roads.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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

  /// Chapter 1's scenes that happen in Alster.
  final alsterScenes = [
    for (final id in story.nodes.keys)
      if (geo.locationOfNode(story.nodeFor(id))?.id == 'alster') id,
  ];

  test('Alster is one world node, where the roads start', () {
    expect(alsterScenes, containsAll(['100', '250', '260', '270', '300']));
    // Every scene in Alster stands on the one landmark.
    final landmarks = {
      for (final id in alsterScenes) landmarkOfScene(id)?.id,
    };
    expect(landmarks, {'alster'});
    expect(geo.placeOfLandmark('alster')!.id, 'alster');
    expect(geo.placeOfLandmark('alster')!.level, GeoLevel.location);
    // No other landmark lies in Alster.
    for (final landmark in worldMapLandmarks) {
      if (landmark.id == 'alster') continue;
      expect(geo.locationOf(geo.placeOfLandmark(landmark.id)?.id)?.id,
          isNot('alster'),
          reason: landmark.id);
    }
    // One road out of Alster, by sea from the High Quay: no road inside it.
    expect([for (final r in roadsAt('alster')) r.id], ['alster_crash']);
    expect(roadRoute('alster', 'wells')!.places.first, 'alster');
    // On every chart, Alster is one spot.
    for (final shape in MapShape.values) {
      expect(chartOf(shape).places.containsKey('alster'), isTrue,
          reason: shape.name);
      for (final gone in ['beggar', 'alley', 'hovel', 'bridge', 'docks']) {
        expect(chartOf(shape).places.containsKey(gone), isFalse,
            reason: '${shape.name}: $gone');
      }
    }
  });

  test('its locations are town places: districts and buildings', () {
    for (final child in districtsOfCity(geo, 'alster')) {
      expect(child.landmarks, isEmpty, reason: child.id);
    }
    for (final id in ['blind_beggar', 'alster_family_house']) {
      expect(geo.place(id)!.level, GeoLevel.building, reason: id);
      expect(geo.place(id)!.landmarks, isEmpty, reason: id);
      expect(districtOfPlace(geo, id)!.id, 'alster_lower_town');
    }
    for (final id in alsterScenes) {
      final place = geo.placeOfNode(story.nodeFor(id))!;
      expect(place.level, anyOf(GeoLevel.district, GeoLevel.building),
          reason: id);
    }
  });

  test('a move between its districts is a town walk, not a world road', () {
    // The Lower Town to the Stone Bridge, the bridge to the family house.
    for (final (from, to) in [('250', '260'), ('261', '300'), ('270', '300')]) {
      expect(geo.travelsBetween(story, from, to), isFalse, reason: '$from>$to');
      expect(worldLegPathForScenes(chartOf(MapShape.story), from, to), isNull,
          reason: '$from>$to');
    }
    expect(townMoveView(geo, 'alster_lower_town', 'alster_stone_bridge'),
        JourneyTownView.town);
    expect(townMoveView(geo, 'alster_family_house', 'alster_high_quay'),
        JourneyTownView.town);
    // Out of Alster is a journey along the world's roads.
    expect(geo.travelsBetween(story, '960', '965'), isTrue);
    expect(townMoveView(geo, 'alster_high_quay', 'lark_wreck'), isNull);
  });

  test('a move inside one district stays on the district', () {
    expect(townMoveView(geo, 'alster_lower_town', 'alster_family_house'),
        JourneyTownView.district);
    expect(townMoveView(geo, 'blind_beggar', 'alster_lower_town'),
        JourneyTownView.district);
    // As in Saltmouth.
    expect(townMoveView(geo, 'saltmouth_wharf', 'saltmouth_tide_cellar'),
        JourneyTownView.district);
    expect(townMoveView(geo, 'saltmouth_wharf', 'saltmouth_tern_row'),
        JourneyTownView.town);
    // A first placing decides nothing.
    expect(townMoveView(geo, null, 'alster_lower_town'), isNull);
  });

  testWidgets('the level tabs follow a move in Alster, with no world road',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);

    Future<void> moveTo(String nodeId) async {
      play.jumpTo(nodeId);
      await _settle(tester);
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

    play.jumpTo('250');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);
    await moveTo('250');
    expect(container.read(currentCityProvider), 'alster');

    final townRows = find.textContaining('THE DISTRICTS');
    // The Lower Town to the Stone Bridge: another district, the whole town.
    await moveTo('260');
    expect(container.read(partyDistrictProvider), 'alster_stone_bridge');
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(townRows, findsOneWidget);
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(find.byKey(const ValueKey('journey_transit')), findsNothing);

    // The District tab shows the district, not the world chart.
    await tester.tap(find.byKey(const Key('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(townRows, findsNothing);
    expect(find.byType(JourneyWorldMap), findsNothing);

    // Back to the Lower Town (another district again), then a move within
    // it: the district.
    await moveTo('270');
    expect(townRows, findsOneWidget);
    await moveTo('250');
    expect(container.read(partyDistrictProvider), 'alster_lower_town');
    expect(townRows, findsNothing);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(find.byKey(const ValueKey('journey_transit')), findsNothing);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}

// Scenes played at a building's doorstep (v1.542): a building's `doorstep`
// in geography.json lists the scenes whose location is the building but
// which happen in the street before its door (the family house watched from
// across the street). The Journey opens them on the district's streets with
// the party at the building's door and their ways in the street round it,
// not in the building's room; every other scene of the building keeps its
// room.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/gamedata/field_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The scenes tagged, by building.
const _tagged = {
  'alster_family_house': ['300', '400', '400_lost', '450'],
  'blind_beggar': ['125'],
  'saltmouth_landward_warehouse': ['2015_informant_trap'],
};

void main() {
  final geoJson = _json('assets/gamedata/geography.json');
  final geo = Geography.parse(
    geography: geoJson,
    biomes: _json('assets/gamedata/biomes.json'),
  );
  final raw = _json('assets/Cleaned_Narrative_DAG.json');
  final story = StoryData({
    for (final e in raw.entries)
      if (e.value is Map<String, dynamic>)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final records = cityPlanRecordsFrom(_json('assets/gamedata/city_plans.json'));

  test('the doorstep list round-trips through the loader and the schema', () {
    final place = GeoPlace.fromJson(
        'house',
        jsonDecode(jsonEncode({
          'level': 'building',
          'parent': 'x',
          'kind': 'house',
          'doorstep': ['300', ' ', '400'],
        })) as Map)!;
    expect(place.doorstep, ['300', '400']);
    // Only a building has a doorstep.
    final district = GeoPlace.fromJson('d', {
      'level': 'district',
      'doorstep': ['300'],
    })!;
    expect(district.doorstep, isEmpty);
    // The file's own lists, as written.
    for (final MapEntry(:key, :value) in _tagged.entries) {
      expect(geoJson[key]['doorstep'], value, reason: key);
      expect(geo.place(key)!.doorstep, value, reason: key);
    }
    // The database editor knows the field.
    final field =
        geographySchema.fields.where((f) => f.key == 'doorstep').single;
    expect(field.type, FieldType.stringList);
  });

  test('every doorstep scene exists and is located at its building', () {
    for (final place in geo.places.values) {
      if (place.doorstep.isNotEmpty) expect(place.isBuilding, isTrue);
      for (final id in place.doorstep) {
        final node = story.nodeFor(id);
        expect(node, isNotNull, reason: id);
        expect(geo.placeOfNode(node)?.id, place.id, reason: id);
      }
    }
  });

  test('a tagged scene plays at the doorstep, an untagged one in its room', () {
    for (final MapEntry(:key, :value) in _tagged.entries) {
      for (final id in value) {
        final node = story.nodeFor(id);
        expect(geo.doorstepOfNode(node)?.id, key, reason: id);
        expect(geo.roomOfNode(node), isNull, reason: id);
      }
    }
    // Inside: the ruins' trapdoor, the Beggar's tables, the cells.
    for (final (id, building) in [
      ('470', 'alster_family_house'),
      ('100', 'blind_beggar'),
      ('120', 'blind_beggar'),
      ('800', 'black_hold_cells'),
    ]) {
      final node = story.nodeFor(id);
      expect(geo.roomOfNode(node)?.id, building, reason: id);
      expect(geo.doorstepOfNode(node), isNull, reason: id);
    }
    // A district's scene has neither.
    expect(geo.roomOfNode(story.nodeFor('250')), isNull);
    expect(geo.doorstepOfNode(story.nodeFor('250')), isNull);
  });

  test('the doorstep stands on the district plan, the ways round it', () {
    final alster = records['alster']!;
    final door = sceneDoorstep(geo, alster, story.nodeFor('300'),
        waysHere: const [0, 1, 2])!;
    // The family house on Alster's plan, in the Lower Town.
    expect(door.buildingId, 'alster_b005');
    expect(door.districtId, 'alster_lower_town');
    final house = alster.building('alster_b005')!;
    expect((door.at - house.centre).distance, lessThan(80));
    expect(door.at, alster.doorstepOf('alster_b005'));
    // Three spots in the street round the door, apart from it and each
    // other.
    expect(door.spotOfWay.keys, [0, 1, 2]);
    final spots = door.spotOfWay.values.toList();
    for (var i = 0; i < spots.length; i++) {
      expect((spots[i] - door.at).distance, greaterThanOrEqualTo(22));
      expect((spots[i] - door.at).distance, lessThan(200));
      for (var j = i + 1; j < spots.length; j++) {
        expect((spots[i] - spots[j]).distance, greaterThanOrEqualTo(22));
      }
    }
    // The same every time.
    expect(
        sceneDoorstep(geo, alster, story.nodeFor('300'),
                waysHere: const [0, 1, 2])!
            .spotOfWay,
        door.spotOfWay);
    // The Blind Beggar's alley, and Saltmouth's warehouse.
    expect(sceneDoorstep(geo, alster, story.nodeFor('125'))!.buildingId,
        'alster_b000');
    expect(
        sceneDoorstep(geo, records['saltmouth']!,
                story.nodeFor('2015_informant_trap'))!
            .buildingId,
        'saltmouth_b006');
    // A scene inside has none.
    expect(sceneDoorstep(geo, alster, story.nodeFor('470')), isNull);
    expect(sceneDoorstep(geo, alster, story.nodeFor('100')), isNull);
  });

  testWidgets('the Journey opens the family house scene on the street',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
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
    play.jumpTo('300');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 1));

    // The district's streets, not the house's room, and no way back in.
    expect(find.byKey(const ValueKey('journey_room')), findsNothing);
    expect(find.byKey(const Key('journey_go_inside')), findsNothing);
    // The district view is the building's street (v1.544): its front, the
    // street before it, and the three ways as pins on the stones.
    expect(find.byKey(const ValueKey('journey_street_scene')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsNothing);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('street_pin_$i')), findsOneWidget);
    }
    // The Town tab still shows the town's plan with the party at the door.
    await tester.tap(find.byKey(const Key('journey_tab_town')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('journey_street_scene')), findsNothing);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    final chart = tester
        .widget<CityChartView>(find.byKey(const ValueKey('journey_city_chart')))
        .chart;
    final alster = await tester.runAsync(() async => cityPlanRecordsFrom(
        _json('assets/gamedata/city_plans.json'))['alster']!);
    // The party at the house's door; the three ways in the street round it.
    expect(chart.here, alster!.doorstepOf('alster_b005'));
    expect(chart.ways, hasLength(3));
    for (final w in chart.ways) {
      expect(w.at, isNotNull, reason: w.name);
      expect(w.at, isNot(chart.here), reason: w.name);
    }
    expect({for (final w in chart.ways) w.at}, hasLength(3));
    expect(
        chart.buildings.firstWhere((b) => b.key == 'alster_b005').story, true);

    // Inside the ruins (470), the room again.
    play.jumpTo('470');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('journey_room')), findsOneWidget);
  });
}

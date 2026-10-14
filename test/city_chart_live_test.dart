// The city chart on the story's own city (Core's record, the scene's ways):
// from the hub of Smugglers' Wharf it opens on the whole city, shows the
// party's district, hands a way's choice back, and walks the party.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/city_chart_screen.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  testWidgets(
      'the hub of the wharf opens on the city; a way goes back as its '
      'choice; walking moves the party', (tester) async {
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(storyDataProvider.future);
      await container.read(cityPlanRecordsProvider.future);
      await container
          .read(gameDbProvider(geographySchema).notifier)
          .whenLoaded();
      await container.read(gameDbProvider(biomesSchema).notifier).whenLoaded();
    });
    container.read(storyPlayProvider.notifier).jumpTo('2015');
    expect(container.read(currentCityProvider), 'saltmouth');
    final here = container.read(partyDistrictProvider);
    expect(here, isNotNull);

    StoryChoice? picked;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await Navigator.of(context)
                .push<StoryChoice>(
                    MaterialPageRoute(builder: (_) => const CityChartScreen())),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    Future<void> settle() async {
      for (var k = 0; k < 6; k++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await tester.tap(find.text('open'));
    await settle();
    expect(find.byKey(const Key('city_chart')), findsOneWidget);
    expect(find.text('Saltmouth'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Tap the Landward Gate's label: it is found (the hub stands in the
    // wharf, the gate's scenes are in the story) or fogged; either way a
    // card comes up, and the party is not asked to walk into fog.
    final record = container.read(cityPlanRecordsProvider).value!['saltmouth']!;
    final topLeft = tester.getTopLeft(find.byKey(const Key('city_chart')));
    final size = tester.getSize(find.byKey(const Key('city_chart')));
    final scale = size.width / 1000 < size.height / 1000
        ? size.width / 1000
        : size.height / 1000;
    final origin = Offset(
        (size.width - 1000 * scale) / 2, (size.height - 1000 * scale) / 2);
    Offset at(Offset plan) => topLeft + origin + plan * scale;

    final wharf = 'saltmouth_wharf';
    expect(record.districts.containsKey(wharf), isTrue);
    await tester.tapAt(at(record.districts[wharf]!.label));
    await settle();
    expect(find.byKey(const Key('city_chart_district_card')), findsOneWidget);

    // A way of the hub, pinned on its building: tapped, its card offers Go,
    // and Go hands the choice back to the Journey.
    final chart =
        tester.widget<CityChartView>(find.byType(CityChartView)).chart;
    final wharfWays = chart.waysIn(wharf);
    expect(wharfWays, isNotEmpty, reason: 'the hub has ways on the wharf');
    final box = chart.districtById(wharf)!.box;
    final zoom = size.width / box.width < size.height / box.height
        ? size.width / box.width
        : size.height / box.height;
    final building = chart.buildingOf(wharfWays.first)!;
    final pin = topLeft +
        Offset(size.width / 2, size.height * 0.42) +
        (building.at - box.center) * zoom +
        const Offset(0, -16);
    await tester.tapAt(pin);
    await settle();
    expect(find.byKey(const Key('city_chart_way_card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('city_chart_go')));
    await settle();
    expect(picked, isNotNull);
    expect(find.byKey(const Key('city_chart')), findsNothing,
        reason: 'the page closed on the pick');
    return;
  });

  testWidgets('a district found can be walked to for free; one in fog cannot',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(storyDataProvider.future);
      await container.read(cityPlanRecordsProvider.future);
      await container
          .read(gameDbProvider(geographySchema).notifier)
          .whenLoaded();
      await container.read(gameDbProvider(biomesSchema).notifier).whenLoaded();
      await container.read(playerSessionProvider.notifier).applyChoiceEffects(
          flagsToAdd: [districtFoundFlag('saltmouth_tern_row')],
          goldIsProfit: false);
    });
    container.read(storyPlayProvider.notifier).jumpTo('2015');
    final record = container.read(cityPlanRecordsProvider).value!['saltmouth']!;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CityChartScreen()),
    ));
    for (var k = 0; k < 6; k++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final topLeft = tester.getTopLeft(find.byKey(const Key('city_chart')));
    final size = tester.getSize(find.byKey(const Key('city_chart')));
    final scale = size.width / 1000 < size.height / 1000
        ? size.width / 1000
        : size.height / 1000;
    final origin = Offset(
        (size.width - 1000 * scale) / 2, (size.height - 1000 * scale) / 2);
    Offset at(String id) =>
        topLeft + origin + record.districts[id]!.label * scale;

    // Fog first: the Card Row has not been found.
    expect(container.read(foundDistrictsProvider),
        isNot(contains('saltmouth_card_row')));
    await tester.tapAt(at('saltmouth_card_row'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('city_chart_fog_card')), findsOneWidget);
    expect(find.byKey(const Key('city_chart_walk')), findsNothing);

    // Tern Row was found by a flag: walking there moves the party.
    await tester.tapAt(at('saltmouth_tern_row'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));
    final walk = find.byKey(const Key('city_chart_walk'));
    expect(walk, findsOneWidget);
    await tester.tap(walk);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(partyDistrictProvider), 'saltmouth_tern_row');
  });
}

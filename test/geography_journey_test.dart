// The world's places on the Journey tab (v1.197), on a 360 px phone: the
// breadcrumb over the place's map opens This land, the place's land is
// painted under it in each of the three looks, and a hazard on the road
// costs health pushed through (the companions' too, never the last) or a
// day and its ration waited out. On a fixture world laid over the real
// story's landmark of scene 2005 (the ship's arrival in Saltmouth).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/road_events.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/screens/story_player_screen.dart'
    show takeStoryChoice;

import 'geography_test.dart' show biomeJson;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A sheet opening or closing, over a map that never stops moving.
Future<void> _sheet(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Saltmouth's headland round the real landmark of scene 2005. The
/// story's own `location`s name places this world does not have, so the
/// scene's place is its landmark's (see Geography.placeOfNode).
Geography _world() => Geography.parse(geography: {
      'old': {
        'level': 'continent',
        'parent': '',
        'name': 'The Old Continent',
        'name_fr': 'l’Ancien Continent',
      },
      'salt_coast': {
        'level': 'country',
        'parent': 'old',
        'ruler': '',
        'name': 'The Salt Coast',
        'name_fr': 'la Côte de Sel',
      },
      'headland': {
        'level': 'zone',
        'parent': 'salt_coast',
        'biome': 'arid_coast',
        'name': 'Saltmouth Headland',
        'name_fr': 'le Cap de Saltmouth',
      },
      'saltmouth': {
        'level': 'location',
        'parent': 'headland',
        'kind': 'city',
        'name': 'Saltmouth',
      },
      'smugglers_wharf': {
        'level': 'district',
        'parent': 'saltmouth',
        'name': 'Smugglers’ Wharf',
        'name_fr': 'le Quai des Contrebandiers',
        'landmark': landmarkOfScene('2005')!.id,
      },
    }, biomes: {
      'arid_coast': biomeJson('Arid coast', 'salt_flats',
          hazards: ['salt_gale', 'flood']),
    });

void main() {
  testWidgets('where the party stands, its land, and a hazard on the road',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [geographyProvider.overrideWithValue(_world())],
      child: const MyApp(),
    ));
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
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'maxHealth': 200,
          'currentHealth': 150,
          'day': 10,
          'watch': 1,
          'provisions': 5,
          'recruitedAllies': [
            {'companionId': 'kelda', 'currentHealth': 1 << 30},
          ],
          'activeAllyIds': ['kelda'],
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('2001');
    await _settle(tester);
    play.jumpTo('2005');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);
    expect(find.byType(JourneyScreen), findsOneWidget);

    // 1. Over the wharf's map, where it lies; the place itself in view.
    final crumbs = find.byKey(const ValueKey('journey_crumbs'));
    expect(crumbs, findsOneWidget);
    final wharf = find.byKey(const ValueKey('geo_crumb_smugglers_wharf'));
    expect(find.descendant(of: wharf, matching: find.text('Smugglers’ Wharf')),
        findsOneWidget);
    expect(tester.getRect(wharf).right, lessThanOrEqualTo(360));
    // Its land is painted under the place.
    expect(find.byKey(const ValueKey('journey_biome')), findsOneWidget);
    // A crumb opens This land.
    await tester.tap(wharf);
    await _sheet(tester);
    final sheet = find.byKey(const ValueKey('this_land_sheet'));
    expect(sheet, findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('THIS LAND')),
        findsOneWidget);
    expect(
        find.descendant(of: sheet, matching: find.text('Saltmouth Headland')),
        findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Arid coast')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(180, 20));
    await _sheet(tester);
    expect(sheet, findsNothing);

    // 2. The three looks, and French: the map keeps its land and its
    // breadcrumb at 360 px.
    for (final look in MapLook.values) {
      await tester.runAsync(
          () => container.read(mapLookProvider.notifier).choose(look));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('journey_biome')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: look.name);
    }
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        find.descendant(
            of: crumbs, matching: find.text('le Quai des Contrebandiers')),
        findsOneWidget);
    await tester.tap(wharf);
    await _sheet(tester);
    expect(find.descendant(of: sheet, matching: find.text('CETTE CONTRÉE')),
        findsOneWidget);
    expect(
        find.descendant(of: sheet, matching: find.text('Le Cap de Saltmouth')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(180, 20));
    await _sheet(tester);
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.pump(const Duration(milliseconds: 300));

    // 3. A hazard on the road: the map shows its scene's two ways, the
    // breadcrumb gives way to the detour.
    final hazard = _world().biomes['arid_coast']!.hazards.first;
    PlayerSession session() => container.read(playerSessionProvider);
    play.startExcursion(
        roadEventChain(RoadEventKind.hazard,
            chapter: 2, enemyPool: const [], seed: 4, hazard: hazard),
        '2010',
        origin: 'Disembark');
    await _settle(tester);
    expect(crumbs, findsNothing);
    expect(find.text(hazard.push), findsOneWidget);
    expect(find.text(hazard.wait), findsOneWidget);

    // Pushed through: the character and Kelda each lose 20 (chapter 2),
    // never the last point.
    final wound = hazardWoundFor(2);
    final pushIndex = container
        .read(storyPlayProvider)
        .activeExcursionNode!
        .choices
        .indexWhere(isHazardPush);
    await tester.tap(find.byKey(ValueKey('journey_step_$pushIndex')));
    await tester.pump();
    expect(find.text('−$wound HP'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await _settle(tester);
    expect(session().currentHealth, 150 - wound);
    final kelda =
        session().recruitedAllies.firstWhere((a) => a.companionId == 'kelda');
    expect(kelda.currentHealth, lessThan(AllyState.fullHealthSentinel));
    expect(kelda.currentHealth, greaterThan(1));
    expect(container.read(storyPlayProvider).isInExcursion, isFalse);

    // Waited out: a day on the road and its ration, and no wound.
    final keldaBefore = kelda.currentHealth;
    final before = session();
    play.startExcursion(
        roadEventChain(RoadEventKind.hazard,
            chapter: 2, enemyPool: const [], seed: 5, hazard: hazard),
        '2015',
        origin: 'The market');
    await _settle(tester);
    final waitChoice = container
        .read(storyPlayProvider)
        .activeExcursionNode!
        .choices
        .firstWhere(isHazardWait);
    final journey = tester.element(find.byType(JourneyScreen));
    final taking = takeStoryChoice(journey, journey as WidgetRef, waitChoice);
    await _settle(tester);
    await tester.runAsync(() => taking);
    await _settle(tester);
    expect(session().day, before.day + 1);
    expect(session().watch, before.watch);
    expect(session().provisions, before.provisions - 1);
    expect(session().currentHealth, before.currentHealth);
    expect(
        session()
            .recruitedAllies
            .firstWhere((a) => a.companionId == 'kelda')
            .currentHealth,
        keldaBefore);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}

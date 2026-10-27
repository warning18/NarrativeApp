// A free walk between a town's districts (board 15) when the party's own
// district has no way of the scene in it: at Saltmouth's Landward Gate after
// the informant is dealt with (2021), the only way leads to the wharf, so the
// District view offers a walk to each district bordering the gate (Tern Row,
// the Lantern Alleys) on the town's plan. The walk costs nothing: no ration,
// no time, the story stays at its scene. The Town view's rows open a
// district not explored yet by walking into it (and so finding it). A scene
// played at a building's doorstep keeps its street only while the party
// stands in that building's district.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final records = cityPlanRecordsFrom(
      jsonDecode(File('assets/gamedata/city_plans.json').readAsStringSync())
          as Map<String, dynamic>);

  test('the districts a party can walk into from its own', () {
    final salt = records['saltmouth']!;
    expect(salt.neighboursOf('saltmouth_landward_gate'),
        ['saltmouth_lantern_alleys', 'saltmouth_tern_row']);
    expect(salt.neighboursOf('saltmouth_tern_row'),
        containsAll(['saltmouth_landward_gate', 'saltmouth_wharf']));
    expect(salt.neighboursOf('nowhere'), isEmpty);
    // A locked district (wave 18) is no way to walk; when every neighbour
    // is locked, the nearest open district is, so the party is never stuck.
    const locked = {'saltmouth_lantern_alleys', 'saltmouth_tern_row'};
    final fromGate = salt.walkableFrom('saltmouth_landward_gate', locked);
    expect(fromGate, hasLength(1));
    expect(fromGate.single, isNot(isIn(locked)));
    expect(fromGate.single, isNot('saltmouth_landward_gate'));
    expect(salt.walkableFrom('saltmouth_landward_gate', const {}),
        salt.neighboursOf('saltmouth_landward_gate'));
    expect(salt.walkableFrom('saltmouth_wharf', locked),
        isNot(contains('saltmouth_tern_row')));
    // Every district of every plan has a neighbour, the links go both ways,
    // and the whole town is reached from any district.
    for (final record in records.values) {
      final ids = record.districts.keys.toList();
      if (ids.length < 2) continue;
      for (final a in ids) {
        expect(record.neighboursOf(a), isNotEmpty, reason: a);
        for (final b in record.neighboursOf(a)) {
          expect(record.neighboursOf(b), contains(a), reason: '$a>$b');
        }
      }
      final reached = {ids.first};
      for (var grew = true; grew;) {
        grew = false;
        for (final a in reached.toList()) {
          for (final b in record.neighboursOf(a)) {
            grew = reached.add(b) || grew;
          }
        }
      }
      expect(reached, ids.toSet(), reason: record.cityId);
    }
  });

  /// The game in play mode on the Journey at scene [nodeId], back on its
  /// map, and a jump to another scene (one app per test: the game's data
  /// loads once).
  Future<(ProviderContainer, Future<void> Function(String))> open(
      WidgetTester tester, String nodeId) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(400, 1000);
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
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          // The two quests that open the alleys and Tern Row (wave 18):
          // done, so both are open to walk into.
          'completedQuestIds': ['q_ch2_informants_tip', 'q_ch2_terns_toll'],
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);

    Future<void> backToMap() async {
      await tester.pump(const Duration(seconds: 2));
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

    Future<void> moveTo(String id) async {
      play.jumpTo(id);
      await _settle(tester);
      await backToMap();
    }

    play.jumpTo(nodeId);
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);
    await backToMap();
    return (container, moveTo);
  }

  testWidgets('a district with no way offers a free walk to its neighbours',
      (tester) async {
    final (container, moveTo) = await open(tester, '2021');
    expect(container.read(partyDistrictProvider), 'saltmouth_landward_gate');
    expect(container.read(partyDistrictWaysProvider), isEmpty);

    await tester.tap(find.byKey(const Key('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('0 WAYS HERE'), findsOneWidget);
    final toTern =
        find.byKey(const ValueKey('journey_city_walk_saltmouth_tern_row'));
    expect(toTern, findsOneWidget);
    expect(
        find.byKey(
            const ValueKey('journey_city_walk_saltmouth_lantern_alleys')),
        findsOneWidget);
    expect(find.text('Walk to Tern Row'), findsOneWidget);
    // Not across the town: the wharf does not border the gate.
    expect(find.byKey(const ValueKey('journey_city_walk_saltmouth_wharf')),
        findsNothing);

    // The walk: the party is in Tern Row, the story where it was, nothing
    // spent.
    final session = container.read(playerSessionProvider);
    final day = (session.day, session.watch);
    final rations = session.provisions;
    await tester.ensureVisible(toTern);
    await tester.tap(toTern);
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(partyDistrictProvider), 'saltmouth_tern_row');
    expect(container.read(storyPlayProvider).currentNodeId, '2021');
    expect(
        container.read(foundDistrictsProvider), contains('saltmouth_tern_row'));
    final after = container.read(playerSessionProvider);
    expect((after.day, after.watch), day);
    expect(after.provisions, rations);
    // Tern Row has no way either: on to its neighbours, the wharf among them.
    expect(find.byKey(const ValueKey('journey_city_walk_saltmouth_wharf')),
        findsOneWidget);

    // The Town view: a district not explored yet opens on a tap, walked
    // into and found.
    await tester.tap(find.byKey(const Key('journey_tab_town')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(foundDistrictsProvider),
        isNot(contains('saltmouth_card_row')));
    final cardRow =
        find.byKey(const ValueKey('journey_city_district_saltmouth_card_row'));
    await tester.ensureVisible(cardRow);
    await tester.tap(cardRow);
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(partyDistrictProvider), 'saltmouth_card_row');
    expect(
        container.read(foundDistrictsProvider), contains('saltmouth_card_row'));
    expect(container.read(storyPlayProvider).currentNodeId, '2021');
    expect(find.textContaining('THE DISTRICTS'), findsNothing);

    // Walking off a scene played at a building's doorstep leaves its
    // street: the informant's trap is played at the warehouse's door, at the
    // gate, and its ways all lead to the wharf.
    await moveTo('2015_informant_trap');
    expect(container.read(partyDistrictProvider), 'saltmouth_landward_gate');
    await tester.tap(find.byKey(const Key('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(StreetViewScene), findsOneWidget);
    final toAlleys = find
        .byKey(const ValueKey('journey_city_walk_saltmouth_lantern_alleys'));
    await tester.ensureVisible(toAlleys);
    await tester.tap(toAlleys);
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(partyDistrictProvider), 'saltmouth_lantern_alleys');
    expect(
        container.read(storyPlayProvider).currentNodeId, '2015_informant_trap');
    // The alleys are drawn on the town's plan, not the warehouse's street.
    expect(find.byType(StreetViewScene), findsNothing);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}

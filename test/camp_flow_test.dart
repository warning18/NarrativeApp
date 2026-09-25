// The camp is open only while the story stands at it: it takes the Story
// tab's place, lets the party go only once its own shore is cleared, and
// gives way to the ship when the party sails out or the story moves on.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_state.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/harbor_screen.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

StoryNode _node(Map<String, dynamic> settlement) => StoryNode.fromJson('n',
    {'id': 'n', 'description': '', 'choices': [], 'settlement': settlement});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ports = _data('ports');
  final zones = _data('zones');
  final houses = _data('houses');
  final companions = _data('companions');

  group('where the party stands', () {
    const camp = {'kind': 'camp', 'name': 'The Cove Camp'};
    const town = {'kind': 'town', 'name': 'The Ashen Quarter'};

    test('at the camp is a camp scene, not a detour from it', () {
      expect(storyAtCamp(_node(camp), inExcursion: false), isTrue);
      expect(storyAtCamp(_node(camp), inExcursion: true), isFalse);
      expect(storyAtCamp(_node(town), inExcursion: false), isFalse);
      expect(storyAtCamp(null, inExcursion: false), isFalse);
    });

    test('the camp, the ship sailed out, the story away, or no camp yet', () {
      CampPresence presence(int chapter, bool atCamp, String port) =>
          campPresenceFor(
              chapter: chapter,
              atCampScene: atCamp,
              ports: ports,
              savedPortId: port);
      expect(presence(2, false, ''), CampPresence.notYet);
      expect(presence(3, false, ''), CampPresence.away);
      expect(presence(3, true, ''), CampPresence.atCamp);
      expect(presence(3, true, 'port_ashen_landing'), CampPresence.atCamp);
      expect(presence(3, true, 'port_smugglers_wharf'), CampPresence.sailedOut);
      expect(presence(4, false, 'port_drowned_stair'), CampPresence.away);
    });

    test('leaving asks for the camp shore\'s expeditions of the chapter', () {
      List<String> blockers(int chapter, List<String> done) => campExitBlockers(
          ports: ports, zones: zones, chapter: chapter, completedZoneIds: done);
      expect(blockers(3, const []), ['z_cinder_row', 'z_scaffold_yards']);
      expect(blockers(3, const ['z_cinder_row']), ['z_scaffold_yards']);
      expect(blockers(3, const ['z_cinder_row', 'z_scaffold_yards']), isEmpty);
      // Another port's zones are never asked for.
      expect(blockers(5, const ['z_cinder_row', 'z_scaffold_yards']), isEmpty);
    });
  });

  group('the camp\'s works', () {
    test('Kelda\'s hall waits for Kelda; the rest are for everyone', () {
      final hall = houses['keldas_hall'] as Map<String, dynamic>;
      expect(hall['requiredAllyId'], 'kelda');
      expect(houseDiscovered(hall, const []), isFalse);
      expect(houseDiscovered(hall, const ['kelda']), isTrue);
      expect(
          houseDiscovered(
              houses['barracks_annex'] as Map<String, dynamic>, const []),
          isTrue);
      // Every house tied to an ally names a real companion.
      for (final entry in houses.entries) {
        final allyId =
            (entry.value as Map<String, dynamic>)['requiredAllyId'] ?? '';
        if (allyId == '') continue;
        expect(companions.containsKey(allyId), isTrue, reason: entry.key);
      }
    });

    test('the harbor is a house of its own, in both languages', () {
      final harbor = houses[harborHouseId] as Map<String, dynamic>;
      expect(harbor['buildCost'], greaterThan(0));
      expect(harbor['houseName_fr'], isNotEmpty);
      expect(harbor['description_fr'], isNotEmpty);
    });
  });

  testWidgets(
      'the camp takes the story\'s place until the party leaves, '
      'and not before its shore is cleared', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'characterName': 'Maren',
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 600,
          'enemyKillCounts': <String, dynamic>{},
          // The Eel is out at the wharf when the story comes home.
          'currentPortId': 'port_smugglers_wharf',
        })));
    container.read(storyPlayProvider.notifier).jumpTo('3001');
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    expect(_tab('Story'), findsOneWidget);

    // Coming into the camp: the Story tab closes, the camp opens with its
    // scene, and the Eel is back in the cove.
    container.read(storyPlayProvider.notifier).jumpTo('3001_camp');
    await _settle(tester);
    expect(_tab('Story'), findsNothing);
    expect(find.byKey(const Key('camp_leave')), findsOneWidget);
    expect(find.text('Back at the fire'), findsOneWidget);
    expect(find.text('Read it all'), findsOneWidget);
    expect(container.read(playerSessionProvider).currentPortId,
        'port_ashen_landing');
    // Kelda's hall is not on offer before Kelda joins.
    expect(find.text("Kelda's Hall"), findsNothing);

    // The shore first.
    await tester.tap(find.byKey(const Key('camp_leave')));
    await _settle(tester);
    expect(find.text('Not yet'), findsOneWidget);
    expect(find.text('Cinder Row'), findsWidgets);
    await tester.tap(find.text('Close'));
    await _settle(tester);

    // The harbor, once built, is one tap away.
    await tester.runAsync(() => notifier.buildHouse(harborHouseId, 250));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('camp_harbor')));
    await _settle(tester);
    expect(find.byType(HarborScreen), findsOneWidget);
    expect(find.text('Shipwright'), findsOneWidget);
    await tester.pageBack();
    await _settle(tester);

    // Sailed out to another port, the camp gives way to the ship until she
    // sails back; the story stays closed meanwhile.
    await tester.runAsync(() => notifier.arriveAtPort('port_smugglers_wharf'));
    await _settle(tester);
    expect(find.byKey(const Key('camp_leave')), findsNothing);
    expect(find.textContaining("Ashore at Smugglers' Wharf"), findsOneWidget);
    expect(find.byKey(const Key('ship_sail_home')), findsOneWidget);
    expect(_tab('Ship'), findsOneWidget);
    expect(_tab('Story'), findsNothing);
    await tester.runAsync(() => notifier.arriveAtPort('port_ashen_landing'));
    await _settle(tester);
    expect(find.byKey(const Key('camp_leave')), findsOneWidget);

    // Shore cleared: the camp's own way on, then the story again.
    await tester.runAsync(() => notifier.loadSession(container
        .read(playerSessionProvider)
        .copyWith(
            completedZoneIds: const ['z_cinder_row', 'z_scaffold_yards'])));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('camp_leave')));
    await _settle(tester);
    expect(find.text('Leave the camp'), findsOneWidget);
    await tester.tap(find.byKey(const Key('leave_choice_3005')));
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, isNot('3001_camp'));
    expect(_tab('Story'), findsOneWidget);
    // Away from the camp, its tab is the ship.
    expect(_tab('Ship'), findsOneWidget);
    expect(
        container.read(playerSessionProvider).flags, contains('camp_founded'));
    await tester.pump(const Duration(seconds: 5));
  });
}

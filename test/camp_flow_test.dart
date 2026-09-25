// From chapter 3 the camp is the party's base: the story stands there
// between trips, the Story tab gives way to it, expeditions find the
// chapter's places, the party walks or sails to them and back, and the
// chapter's main quest opens at the camp once enough of it is done.
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
import 'package:narrative_data_app/screens/voyage_screen.dart';

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

/// Lets a notice (a few seconds on screen, over everything) go.
Future<void> _waitOutNotices(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await _settle(tester);
}

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

StoryNode _node(Map<String, dynamic> settlement) => StoryNode.fromJson('n',
    {'id': 'n', 'description': '', 'choices': [], 'settlement': settlement});

Map<String, dynamic> _story() =>
    json.decode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ports = _data('ports');
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

    test('from a place once the camp stands, the party can go back to it', () {
      const place = {
        'kind': 'town',
        'name': 'The Ashen Quarter',
        'chapter': 3,
      };
      const flags = ['camp_founded'];
      expect(
          canReturnToCampFrom(_node(place), inExcursion: false, flags: flags),
          isTrue);
      expect(
          canReturnToCampFrom(_node(place),
              inExcursion: false, flags: const []),
          isFalse);
      expect(canReturnToCampFrom(_node(place), inExcursion: true, flags: flags),
          isFalse);
      expect(canReturnToCampFrom(_node(camp), inExcursion: false, flags: flags),
          isFalse);
      // A town of the straight road (no chapter of its own) is the story's.
      expect(canReturnToCampFrom(_node(town), inExcursion: false, flags: flags),
          isFalse);
      // The party is at the camp when the story is.
      expect(partyAtCamp(_node(camp), inExcursion: false), isTrue);
      expect(partyAtCamp(_node(place), inExcursion: false), isFalse);
    });

    test('a town is a walk from the camp, or a voyage to its landing', () {
      final story = _story();
      final nodes = (story['nodes'] ?? story) as Map<String, dynamic>;
      String? landing(String id) => landingPortIdFor(
          StoryNode.fromJson(id, nodes[id] as Map<String, dynamic>).settlement,
          ports);
      expect(landing('3005'), isNull);
      expect(landing('5010'), 'port_drowned_stair');
      expect(landing('6010'), 'port_black_reliquary');
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
      'the camp is the base: a place found, walked to and back, '
      'and the main quest once the chapter is explored', (tester) async {
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
    final play = container.read(storyPlayProvider.notifier);
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'characterName': 'Maren',
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 600,
          'enemyKillCounts': <String, dynamic>{},
          // The Eel is out at the wharf when the story comes home.
          'currentPortId': 'port_smugglers_wharf',
          'flags': ['camp_founded'],
        })));
    play.jumpTo('3001');
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    expect(_tab('Story'), findsOneWidget);

    // Coming into the camp: the Story tab closes, the camp opens with its
    // scene and its chapter, and the Eel is back in the cove.
    play.jumpTo('3001_camp');
    await _settle(tester);
    expect(_tab('Story'), findsNothing);
    expect(find.text('Back at the fire'), findsOneWidget);
    expect(find.byKey(const Key('chapter_card')), findsOneWidget);
    expect(find.text('Explored: 0 of 8'), findsOneWidget);
    expect(find.text('Visit The Ashen Quarter first.'), findsOneWidget);
    expect(find.textContaining('No place found yet'), findsOneWidget);
    FilledButton mainQuest() => tester.widget<FilledButton>(
        find.byKey(const Key('main_quest_3002'), skipOffstage: false));
    expect(mainQuest().onPressed, isNull);
    expect(container.read(playerSessionProvider).currentPortId,
        'port_ashen_landing');
    // Kelda's hall is not on offer before Kelda joins.
    expect(find.text("Kelda's Hall"), findsNothing);

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
    expect(find.byKey(const Key('chapter_card')), findsNothing);
    expect(find.textContaining("Ashore at Smugglers' Wharf"), findsOneWidget);
    expect(find.byKey(const Key('ship_sail_home')), findsOneWidget);
    expect(_tab('Ship'), findsOneWidget);
    expect(_tab('Story'), findsNothing);
    await tester.runAsync(() => notifier.arriveAtPort('port_ashen_landing'));
    await _settle(tester);
    expect(find.byKey(const Key('chapter_card')), findsOneWidget);

    // An expedition has found the Ashen Quarter: it is on the camp's list,
    // a walk away.
    await tester.runAsync(() => notifier
            .loadSession(container.read(playerSessionProvider).copyWith(flags: [
          ...container.read(playerSessionProvider).flags,
          placeFoundFlag('3005'),
        ])));
    await _settle(tester);
    expect(find.byKey(const Key('place_3005')), findsOneWidget);
    expect(find.textContaining('No place found yet'), findsNothing);
    // Grosh is in the Quarter: the camp says someone there might join.
    expect(find.byKey(const Key('companion_hint_3005')), findsOneWidget);
    expect(
        find.text('Word at the fire: someone in The Ashen Quarter '
            'might join you.'),
        findsOneWidget);
    expect(find.byKey(const Key('place_companion_3005')), findsOneWidget);

    // Going there: the road may hold something first; the story plays it,
    // then arrives.
    await tester.tap(find.byKey(const Key('go_3005')));
    await _settle(tester);
    if (container.read(storyPlayProvider).isInExcursion) {
      play.jumpTo('3005');
      await _settle(tester);
    }
    expect(container.read(storyPlayProvider).currentNodeId, '3005');
    expect(_tab('Story'), findsOneWidget);
    await _waitOutNotices(tester);
    if (find.text('Go in', skipOffstage: false).evaluate().isNotEmpty) {
      await tester.tap(find.text('Go in', skipOffstage: false));
      await _settle(tester);
    }
    // In the town, the camp is a walk back; no other place is known yet.
    expect(find.byKey(const Key('town_back_to_camp')), findsOneWidget);
    expect(find.byKey(const Key('place_travel_on')), findsNothing);
    expect(_tab('Ship'), findsNothing);
    await tester.tap(_tab('Camp'));
    await _settle(tester);
    expect(find.byKey(const Key('camp_return')), findsOneWidget);

    // Back to the camp: the story stands there again, and the Quarter has
    // been visited.
    await tester.tap(find.byKey(const Key('camp_return')));
    await _settle(tester);
    if (container.read(storyPlayProvider).isInExcursion) {
      play.jumpTo('3001_camp');
      await _settle(tester);
    }
    expect(container.read(storyPlayProvider).currentNodeId, '3001_camp');
    await _waitOutNotices(tester);
    expect(_tab('Story'), findsNothing);
    expect(find.text('Visit The Ashen Quarter first.'), findsNothing);

    // Explored enough (the shore's two expeditions, six things done in
    // the town), the main quest opens.
    await tester.runAsync(() => notifier.loadSession(container
            .read(playerSessionProvider)
            .copyWith(completedZoneIds: const [
          'z_cinder_row',
          'z_scaffold_yards'
        ], flags: [
          ...container.read(playerSessionProvider).flags,
          'hub_3005_oath',
          'hub_3005_wisp',
          'hub_3005_acolyte',
          'hub_3005_relic',
          'hub_3005_golem',
          'hub_3005_stalker',
        ])));
    await _settle(tester);
    expect(find.text('Explored: 8 of 8'), findsOneWidget);
    expect(mainQuest().onPressed, isNotNull);
    await tester.ensureVisible(find.byKey(const Key('main_quest_3002')));
    await tester.tap(find.byKey(const Key('main_quest_3002')));
    await _settle(tester);
    if (container.read(storyPlayProvider).isInExcursion) {
      play.jumpTo('3002');
      await _settle(tester);
    }
    expect(container.read(storyPlayProvider).currentNodeId, '3002');
    expect(_tab('Story'), findsOneWidget);
    await _waitOutNotices(tester);

    // A chapter later, the Drowned Cloister is across the water: going
    // there is a voyage.
    await tester.runAsync(() => notifier
            .loadSession(container.read(playerSessionProvider).copyWith(flags: [
          ...container.read(playerSessionProvider).flags,
          placeFoundFlag('5010'),
        ])));
    play.jumpTo('4999_camp');
    await _settle(tester);
    await _waitOutNotices(tester);
    expect(find.byKey(const Key('place_5010')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('go_5010')));
    await tester.tap(find.byKey(const Key('go_5010')));
    await _settle(tester);
    expect(find.byType(VoyageScreen), findsOneWidget);
    expect(container.read(playerSessionProvider).currentPortId,
        'port_ashen_landing');
    await tester.pump(const Duration(seconds: 5));
  });
}

// The Journey's first steps in a new game (v1.565, the user's chapter 1
// feedback): the party's first step out of the Blind Beggar lands on the
// Journey's map, not the proclamation's page (250), and the Journey's tour
// starts there, once, before any "New:" card; a way taken on a town's
// District view walks the party's mark to its pin before its scene opens
// (a tap skips the walk); and a page whose cards hold every move the map
// would offer (the Weaver's Alley, 270) has no "Back to the map".
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/chapter_grid_layout.dart';
import 'package:narrative_data_app/data/choice_shape.dart';
import 'package:narrative_data_app/data/feature_unlocks.dart';
import 'package:narrative_data_app/data/first_journey.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/scene_lock.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/tutorial_provider.dart';
import 'package:narrative_data_app/tutorial/guide_tour.dart';
import 'package:narrative_data_app/tutorial/tutorial_topics.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final _story = () {
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  return StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
}();

final _geography =
    Geography.parse(geography: _table('geography'), biomes: _table('biomes'));

GeoPlace? _placeOf(String id) => _geography.placeOfNode(_story.nodeFor(id));

/// [node]'s ways as its page weighs them, read off the data as the Journey
/// lays them out: in a place up close (not inside a building's room, not on
/// the road), a way acted out here is a card; any other is a pin. Every
/// way counts as takeable (the flags of a run are not known here).
List<ExitWay> _exitWays(StoryNode node) {
  final place = _geography.placeOfNode(node);
  final room =
      place != null && place.isBuilding && !place.doorstep.contains(node.id);
  final cardsOn = place != null && !room;
  return [
    for (final c in node.choices)
      () {
        final shape =
            choiceShape(node, c, story: _story, geography: _geography);
        return (
          card: cardsOn && shape.here,
          takeable: true,
          to: shape.to?.id,
        );
      }(),
  ];
}

bool _hidden(String id) {
  final node = _story.nodeFor(id)!;
  return pageExitHidden(
    ways: _exitWays(node),
    hub: isHubScene(node),
    ending: isStoryEnding(node),
    editMode: false,
  );
}

/// The scenes of chapters 1 to 3 whose page has no "Back to the map",
/// checked on the data (v1.565). A change here is a change the user sees:
/// update it on purpose.
const _hiddenInChapters1to3 = <String>[
  '125',
  '260',
  '261',
  '270',
  '300',
  '400',
  '400_lost',
  '450',
  '840',
  '850',
  '855',
  '891',
  '895',
  '896_failed',
  '897_failed',
  '898_failed',
  '960',
  '965',
  '1100',
  '1120',
  '1125',
  '1130',
  '1140',
  '1140_spotted',
  '1200',
  '1210',
  '2000',
  '2001',
  '2010',
  '2011',
  '2015_house_drowned_debt',
  '2015_house_salt_ledger',
  '2015_dockside',
  '2015_smuggler',
  '2015_rats',
  '2015_informant_caught',
  '2015_kelda',
  '2030',
  '2040',
  '2050',
  '2070',
  '2900',
  '2900_boat_fixed',
  '2999',
  '3001',
  '3005_house_tribunal',
  '3005_clan_vigil_1',
  '3005_clan_vigil_1_breach',
  '3005_clan_compact_1',
  '3005_oath',
  '3005_relic',
  '3005_maren',
  '3010',
  '2010_crane',
  '2015_informant_trap',
  '2015_informant_exposed',
  '2015_ternrow',
  '2015_ternrow_fight',
  '2015_ternrow_talked',
  '2010_liora',
  '3005_grosh',
  '3005_wall',
  '3005_wall_fight',
  '3005_wall_argued',
  '2015_cards',
  '2015_cards_lost',
  '2015_bandits',
  '3005_lysa',
  '3100_house_cantors',
  '3100_house_emberwives',
  '3100_tithe',
  '3100_kiln',
  '3100_kiln_failed',
  '3100_bread',
  '3100_new_moon',
  '3200_house_road_exorcists',
  '3200_clan_penitents_1',
  '3200_circle',
  '3200_brew',
  '3200_brew_failed',
  '3200_smith_later',
  '3200_springs',
  '2015_sable_caught',
  '850_fed_failed',
  '2011_roof_fall',
  '2015_drawer',
  '3005_envoys',
  '2015_scaffold_clerk_fight',
  '2015_route_sold',
  '2015_survivor',
  '2015_child_tongue',
  '2015_dominion_blades',
  '3005_glass_fire_fight',
  '3005_black_thread',
  '3005_shrine_break',
  '3005_spire_takings',
  '3005_tribunal_gold',
  '3005_lysa_price',
  '890_trainer',
  '2015_crow_offer',
  '2015_alleys_door',
  '2015_ternrow_door',
];

Future<void> _settle(WidgetTester tester, {int rounds = 3}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 60 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The Journey reading scene [id] as its page.
Finder _page(String id) => find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key! as ValueKey<String>).value.startsWith('journey_reading_${id}_'));

final _cityChart = find.byKey(const ValueKey('journey_city_chart'));
final _backToMap = find.byKey(const ValueKey('journey_continue'));
final _cornerMap = find.byKey(const ValueKey('journey_reading_exit'));

Future<ProviderContainer> _continueSave(
  WidgetTester tester, {
  required String node,
  required List<String> history,
  required List<String> flags,
  bool animate = false,
  bool tours = false,
  List<String> seenTours = const [],
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (!animate) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  SharedPreferences.setMockInitialValues({
    'tutorial_enabled': tours,
    'tutorial_seen_topics': seenTours,
    'player_session': json.encode({
      'raceId': 'human',
      'professionId': 'warrior',
      'gold': 80,
      'flags': flags,
    }),
    'autosave_story_node': node,
    'autosave_story_history': json.encode(history),
    'autosave_story_visited': json.encode([...history, node]),
  });
  await tester.pumpWidget(ProviderScope(
      overrides: [tutorialAutoShowProvider.overrideWithValue(tours)],
      child: const MyApp()));
  await _settle(tester, rounds: 6);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await tester.tap(find.byKey(const Key('menu_continue')));
  await _settle(tester, rounds: 6);
  await tester.pump(const Duration(seconds: 3));
  expect(container.read(storyPlayProvider).currentNodeId, node);
  if (find.text('Journey').evaluate().isNotEmpty &&
      find.byKey(const Key('journey_level_tabs')).evaluate().isEmpty) {
    await tester.tap(find.text('Journey').last);
    await _settle(tester);
  }
  return container;
}

/// Takes "Out the back, into the streets" from the Bouncer's aftermath
/// (106): a spot in the Blind Beggar's room (called, not tapped: the
/// room's spots may lie over each other).
Future<void> _outTheBack(
    WidgetTester tester, ProviderContainer container) async {
  final step = find.byWidgetPredicate((w) =>
      w is Semantics &&
      (w.properties.label ?? '').contains('Out the back') &&
      w.child is GestureDetector);
  expect(step, findsOneWidget);
  void tapStep() =>
      (tester.widget<Semantics>(step).child! as GestureDetector).onTap!();
  tapStep();
  await tester.pump();
  tapStep();
  await tester.pump();
  await _pumpUntil(
      tester, () => container.read(storyPlayProvider).currentNodeId == '250');
  await _settle(tester);
  await tester.pump(const Duration(seconds: 2));
  expect(container.read(storyPlayProvider).currentNodeId, '250');
}

/// Closes the "Previously…" recap a save picked back up opens over the
/// map, when it is up.
Future<void> _closeRecap(WidgetTester tester) async {
  await _pumpUntil(
      tester, () => find.byType(AlertDialog).evaluate().isNotEmpty);
  final go = find.descendant(
      of: find.byType(AlertDialog), matching: find.text('Go on'));
  if (go.evaluate().isEmpty) return;
  await tester.tap(go);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(AlertDialog), findsNothing);
}

Future<void> _done(WidgetTester tester) async {
  final error = tester.takeException();
  expect(error, isNull,
      reason: error is FlutterError ? error.toStringDeep() : '$error');
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  setUp(() => rootBundle.clear());

  group('firstStepOutside', () {
    const ladder = [featureLadderFlag];
    test('out of the Blind Beggar onto the streets, once, in a new game', () {
      // Every way out of the Beggar ends at the proclamation (250), in the
      // Lower Town: from its room (106, 110, 115, 120) or its doorstep (125).
      for (final from in ['106', '110', '115', '120', '125']) {
        expect(
            _story.nodeFor(from)!.choices.map((c) => c.nextId), contains('250'),
            reason: from);
        expect(
            firstStepOutside(
                flags: ladder,
                from: _placeOf(from),
                to: _placeOf('250'),
                chapter: chapterOfNode('250')),
            isTrue,
            reason: from);
      }
      // Once: the flag set, never again.
      expect(
          firstStepOutside(
              flags: const [featureLadderFlag, journeyFirstShownFlag],
              from: _placeOf('110'),
              to: _placeOf('250'),
              chapter: 1),
          isFalse);
      // A game off the ladder (a save from before it) is left alone.
      expect(
          firstStepOutside(
              flags: const [],
              from: _placeOf('110'),
              to: _placeOf('250'),
              chapter: 1),
          isFalse);
      // Dragged out to the Beggar's doorstep (125) is still at a building:
      // its page tells what happened; the streets come with 250.
      expect(
          firstStepOutside(
              flags: ladder,
              from: _placeOf('110'),
              to: _placeOf('125'),
              chapter: 1),
          isFalse);
      // Past chapter 1, never.
      expect(
          firstStepOutside(
              flags: ladder,
              from: _placeOf('110'),
              to: _placeOf('250'),
              chapter: 2),
          isFalse);
    });

    test('the Journey tour waits for it in a new game', () {
      expect(journeyTourDue(const [featureLadderFlag], chapter: 1), isFalse);
      expect(
          journeyTourDue(const [featureLadderFlag, journeyFirstShownFlag],
              chapter: 1),
          isTrue);
      expect(journeyTourDue(const [], chapter: 1), isTrue);
      expect(journeyTourDue(const [featureLadderFlag], chapter: 2), isTrue);
    });

    test('the walk to a pin: 0.6 s next door to 1.2 s across the town', () {
      expect(cityWalkDuration(0), Duration.zero);
      expect(cityWalkDuration(1), const Duration(milliseconds: 601));
      expect(cityWalkDuration(100), const Duration(milliseconds: 720));
      expect(cityWalkDuration(250), const Duration(milliseconds: 900));
      expect(cityWalkDuration(500), const Duration(milliseconds: 1200));
      expect(cityWalkDuration(1400), const Duration(milliseconds: 1200));
    });
  });

  group('pageExitHidden', () {
    test('cards that hold every move hide the way back to the map', () {
      // Every way a card.
      expect(
          pageExitHidden(ways: const [
            (card: true, takeable: true, to: 'a'),
            (card: true, takeable: true, to: null),
          ], hub: false, ending: false, editMode: false),
          isTrue);
      // A pin to where a card leads too.
      expect(
          pageExitHidden(ways: const [
            (card: true, takeable: true, to: 'house'),
            (card: false, takeable: true, to: 'house'),
          ], hub: false, ending: false, editMode: false),
          isTrue);
      // A pin that can't be taken yet offers no move.
      expect(
          pageExitHidden(ways: const [
            (card: true, takeable: true, to: 'house'),
            (card: false, takeable: false, to: 'bridge'),
          ], hub: false, ending: false, editMode: false),
          isTrue);
    });

    test('another move on the map keeps it', () {
      // A pin elsewhere.
      expect(
          pageExitHidden(ways: const [
            (card: true, takeable: true, to: 'alley'),
            (card: false, takeable: true, to: 'bridge'),
          ], hub: false, ending: false, editMode: false),
          isFalse);
      // A pin the world doesn't place.
      expect(
          pageExitHidden(ways: const [
            (card: true, takeable: true, to: 'house'),
            (card: false, takeable: true, to: null),
          ], hub: false, ending: false, editMode: false),
          isFalse);
      // No card: the page is read, the ways are on the map.
      expect(
          pageExitHidden(ways: const [
            (card: false, takeable: true, to: 'house'),
          ], hub: false, ending: false, editMode: false),
          isFalse);
      expect(
          pageExitHidden(ways: const [
            (card: true, takeable: false, to: 'house'),
            (card: false, takeable: true, to: 'house'),
          ], hub: false, ending: false, editMode: false),
          isFalse);
      // A hub, an ending, Edit Mode.
      const all = [(card: true, takeable: true, to: 'a')];
      expect(
          pageExitHidden(ways: all, hub: true, ending: false, editMode: false),
          isFalse);
      expect(
          pageExitHidden(ways: all, hub: false, ending: true, editMode: false),
          isFalse);
      expect(
          pageExitHidden(ways: all, hub: false, ending: false, editMode: true),
          isFalse);
    });

    test('on the data: the Weaver\'s Alley has none, the proclamation keeps it',
        () {
      final alley = _exitWays(_story.nodeFor('270')!);
      // "Cut it free" and "Strip the handler's gear" are cards; "Leave them
      // both" a pin on the map; all three end at the family house.
      expect(alley.map((w) => w.card), [true, true, false]);
      expect(alley.map((w) => w.to).toSet(), {'alster_family_house'});
      expect(_hidden('270'), isTrue);
      // 250: the Weaver's Alley a card, the Stone Bridge a pin elsewhere.
      expect(_hidden('250'), isFalse);
      // The Beggar's room: its ways are spots, no cards.
      expect(_hidden('110'), isFalse);
    });

    test('the scenes of chapters 1 to 3 with no way back to the map', () {
      final hidden = [
        for (final id in _story.nodes.keys)
          if (chapterOfNode(id) >= 1 && chapterOfNode(id) <= 3 && _hidden(id))
            id,
      ];
      expect(hidden, _hiddenInChapters1to3);
    });
  });

  testWidgets(
      'a new game\'s first step out of the Beggar lands on the Journey, '
      'once; the page the next time, with its way back to the map',
      (tester) async {
    final container = await _continueSave(tester,
        node: '106',
        history: const ['0', '100', '105'],
        flags: const [featureLadderFlag, 'casino_tables']);
    expect(_page('106'), findsNothing);
    await _outTheBack(tester, container);
    // The proclamation: the Lower Town's chart, not its page.
    expect(_page('250'), findsNothing);
    expect(_cityChart, findsOneWidget);
    expect(container.read(playerSessionProvider).flags,
        contains(journeyFirstShownFlag));
    await _done(tester);
  });

  testWidgets(
      'once had, the proclamation opens on its page, its way back to the map '
      'kept (the Stone Bridge is a move the page has not)', (tester) async {
    final container = await _continueSave(tester, node: '106', history: const [
      '0',
      '100',
      '105'
    ], flags: const [
      featureLadderFlag,
      journeyFirstShownFlag,
      'casino_tables'
    ]);
    await _outTheBack(tester, container);
    expect(_page('250'), findsOneWidget);
    expect(_backToMap, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(_backToMap).onPressed, isNotNull);
    expect(_cornerMap, findsOneWidget);
    await _done(tester);
  });

  testWidgets(
      'the Journey tour waits for the first step outside, starts there '
      'once, and the "New:" card waits behind it', (tester) async {
    final container = await _continueSave(tester,
        node: '106',
        history: const ['0', '100', '105'],
        flags: const [featureLadderFlag, 'casino_tables'],
        tours: true,
        seenTours: [
          for (final t in TutorialTopic.values)
            if (t != TutorialTopic.journey) t.name,
        ]);
    // The Beggar's room on the map: no tour yet.
    await _closeRecap(tester);
    await _settle(tester, rounds: 20);
    expect(find.byType(GuideTour), findsNothing);
    // A feature opens on the way out (the Quests list), its card waiting.
    final session = container.read(playerSessionProvider);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(session
            .copyWith(flags: [...session.flags, GameFeature.quests.flag])));
    await tester.pump();
    final card = find.byKey(const ValueKey('unlock_card_quests'));
    await _outTheBack(tester, container);
    expect(_cityChart, findsOneWidget);
    await _pumpUntil(
        tester, () => find.byType(GuideTour).evaluate().isNotEmpty);
    // The tour, alone: the card is not over it.
    expect(find.byType(GuideTour), findsOneWidget);
    expect(card, findsNothing);
    expect(container.read(tutorialProvider).hasSeen(TutorialTopic.journey),
        isTrue);
    await tester.tap(find.byKey(const Key('tutorial_skip')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(GuideTour), findsNothing);
    // Then the card.
    await _pumpUntil(tester, () => card.evaluate().isNotEmpty);
    expect(card, findsOneWidget);
    // Seen: not again.
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(GuideTour), findsNothing);
    await _done(tester);
  });

  testWidgets(
      'a way taken on the District view walks the party to its pin first '
      '(a tap skips it); the Weaver\'s Alley\'s page has no way back to the '
      'map, "Leave them both" a road card on it', (tester) async {
    final container = await _continueSave(tester,
        node: '250',
        history: const ['0', '100', '105', '106'],
        flags: const [featureLadderFlag, journeyFirstShownFlag],
        animate: true);
    await _closeRecap(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_cityChart, findsOneWidget);
    Offset? partyAt() =>
        tester.widget<CityChartView>(find.byType(CityChartView)).partyAt;
    expect(partyAt(), isNull);
    // The Weaver's Alley, the one way in the Lower Town: its row, then Go.
    final row = find.byKey(const ValueKey('journey_city_row_1'));
    expect(row, findsOneWidget);
    await tester.tap(row);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    final go = find.byKey(const ValueKey('journey_go'));
    await tester.ensureVisible(go);
    await tester.pump();
    await tester.tap(go);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    // The mark walks; the scene waits for it.
    final skip = find.byKey(const ValueKey('journey_city_walk_skip'));
    expect(skip, findsOneWidget);
    final early = partyAt();
    expect(early, isNotNull);
    await tester.pump(const Duration(milliseconds: 250));
    final later = partyAt();
    expect(later, isNotNull);
    expect(later, isNot(early));
    expect(container.read(storyPlayProvider).currentNodeId, '250');
    // A tap lands it: the scene opens.
    await tester.tap(skip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Well before the walk's own end (0.6 s at the least, 0.35 s gone).
    expect(container.read(storyPlayProvider).currentNodeId, '270');
    await _pumpUntil(
        tester, () => container.read(storyPlayProvider).currentNodeId == '270');
    expect(container.read(storyPlayProvider).currentNodeId, '270');
    await _pumpUntil(tester, () => _page('270').evaluate().isNotEmpty);
    expect(_page('270'), findsOneWidget);
    expect(skip, findsNothing);
    // Its words shown at once (Continue), then no way back to the map.
    if (_backToMap.evaluate().isNotEmpty) {
      await tester.tap(_backToMap);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(_page('270'), findsOneWidget);
    expect(_backToMap, findsNothing);
    expect(_cornerMap, findsNothing);
    // Every way a card: "Leave them both", a pin on the map to the same
    // house, too.
    for (final i in [0, 1, 2]) {
      expect(find.byKey(ValueKey('journey_choice_card_$i')), findsOneWidget,
          reason: '$i');
    }
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('journey_choice_card_2')),
            matching: find.textContaining('Leave them both')),
        findsOneWidget);
    await _done(tester);
  });
}

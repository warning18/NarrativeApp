// The scene lock (v1.553, scene_lock.dart), narrowed: a scene the story
// brought the party to holds the Journey on its page until a way is taken
// only when no takeable way has a place on the map (a pin, a way on the
// city chart, a spot in a room, a road or a World move). Its ways are cards
// there, the map's tabs and buttons wait, greyed ("Choose first"). A way
// the map draws stays on the map: a scene with one never locks, and its
// on-the-spot choices stay cards under the scene, as before v1.553. The
// House's Bouncer aftermath (106, in the gambling hall's room) is the
// user's case: every way a spot in the room, no lock.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/choice_shape.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/scene_lock.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

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

final _cityPlans = _table('city_plans').keys.toSet();

/// [id]'s ways as the lock weighs them, every one takeable, placed on the
/// map as the Journey's fallback reads them (mapDrawsEveryWay).
List<LockWay> _ways(String id, {bool takeable = true}) {
  final node = _story.nodeFor(id)!;
  final all = mapDrawsEveryWay(node,
      history: const [], world: _geography, cityPlans: _cityPlans);
  return [
    for (final c in node.choices)
      () {
        final here =
            choiceShape(node, c, story: _story, geography: _geography).here;
        return (here: here, takeable: takeable, mapped: all || !here);
      }(),
  ];
}

bool _locks(String id, {bool takeable = true, bool editMode = false}) {
  final node = _story.nodeFor(id)!;
  return sceneLocked(
    ways: _ways(id, takeable: takeable),
    hub: isHubScene(node),
    ending: isStoryEnding(node),
    editMode: editMode,
  );
}

Future<void> _settle(WidgetTester tester, {int rounds = 3}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _setUp(WidgetTester tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // No walks or beats to wait for.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The Journey reading scene [id] as its page.
Finder _page(String id) => find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key! as ValueKey<String>).value.startsWith('journey_reading_${id}_'));

Finder _card(int i) => find.byKey(ValueKey('journey_choice_card_$i'));

/// Scrolls the page's cards to card [i] (the list builds what it shows).
Future<void> _seeCard(WidgetTester tester, int i) =>
    tester.scrollUntilVisible(_card(i), 60,
        scrollable: find.descendant(
            of: find.byKey(const ValueKey('journey_choice_cards')),
            matching: find.byType(Scrollable)));

final _chooseFirst = find.byKey(const ValueKey('journey_choose_first'));

/// The page holds the party: its tabs, its corner map button and its way
/// back to the map are greyed, and say "Choose first".
void _expectLocked(WidgetTester tester) {
  expect(_chooseFirst, findsOneWidget);
  expect(
      find.text(trFor(AppLanguage.en, 'journey_choose_first')), findsOneWidget);
  for (final tab in ['district', 'town', 'world']) {
    final ink = tester.widget<InkWell>(find.byKey(Key('journey_tab_$tab')));
    expect(ink.onTap, isNull, reason: tab);
  }
  final corner = tester
      .widget<IconButton>(find.byKey(const ValueKey('journey_reading_exit')));
  expect(corner.onPressed, isNull);
  final exit = find.byKey(const ValueKey('journey_continue'));
  expect(find.descendant(of: exit, matching: find.text('Back to the map')),
      findsOneWidget);
  expect(tester.widget<ButtonStyleButton>(exit).onPressed, isNull);
}

/// Taps card [i] twice: picked, then taken.
Future<void> _take(WidgetTester tester, int i) async {
  await _seeCard(tester, i);
  await tester.tap(_card(i));
  await tester.pump();
  if (_card(i).evaluate().isNotEmpty) {
    await tester.tap(_card(i));
    await tester.pump();
  }
}

void main() {
  setUp(rootBundle.clear);

  group('sceneLocked', () {
    test('the Bouncer\'s aftermath does not lock: its ways are room spots', () {
      final hits = [
        for (final e in _story.nodes.entries)
          if (e.value.description.contains('on my knees in the sawdust')) e.key,
      ];
      expect(hits, ['106']);
      final node = _story.nodeFor('106')!;
      expect(
          node.choices.map((c) => c.text),
          containsAll(
              ['Work the next table', 'Out the back, into the streets']));
      // Inside the Blind Beggar: the room's plan draws every way.
      expect(
          mapDrawsEveryWay(node,
              history: const ['0', '100', '105'],
              world: _geography,
              cityPlans: _cityPlans),
          isTrue);
      expect(_locks('106'), isFalse);
    });

    // Chapter 1's opening chain and a few others: v1.553 locked every one
    // with a way acted out here; now only the wreck, whose ways are all
    // acted out on the deck with no city chart or room to draw them.
    const expected = {
      '0': false, // v1.553: locked
      '100': false, // v1.553: locked
      '105': false, // v1.553: locked
      '106': false, // v1.553: locked
      '110': false, // v1.553: locked
      '115': false, // v1.553: locked
      '120': false, // v1.553: locked
      '125': false, // v1.553: locked
      '250': false, // v1.553: locked
      '260': false, // v1.553: locked
      '270': false, // v1.553: locked
      '300': false, // v1.553: locked
      '400': false, // v1.553: locked
      '960': false, // v1.553: locked
      '965': true, // v1.553: locked
      '1200': false, // v1.553: locked
      '2015_dockside': false, // v1.553: locked
    };
    for (final e in expected.entries) {
      test('scene ${e.key} ${e.value ? 'locks' : 'does not lock'}', () {
        expect(_locks(e.key), e.value);
      });
    }

    test('a way on the map keeps a scene unlocked: mixed scenes do not lock',
        () {
      // 250: the bridge, its one way on (the alley is parked, v1.620), is a
      // road on Alster's city chart.
      final ways = _ways('250');
      expect(ways, hasLength(1));
      expect(ways[0].here, isFalse);
      expect(ways.every((w) => w.mapped), isTrue);
      expect(_locks('250'), isFalse);
      // A pure choice beside a way on the map: no lock.
      expect(
          sceneLocked(ways: const [
            (here: true, takeable: true, mapped: false),
            (here: false, takeable: true, mapped: true),
          ], hub: false, ending: false, editMode: false),
          isFalse);
      // A choice acted out here that the city chart or a room draws: no
      // lock either.
      expect(
          sceneLocked(ways: const [
            (here: true, takeable: true, mapped: true),
          ], hub: false, ending: false, editMode: false),
          isFalse);
    });

    test('only pure choices: the scene locks', () {
      expect(
          sceneLocked(ways: const [
            (here: true, takeable: true, mapped: false),
            (here: true, takeable: true, mapped: false),
          ], hub: false, ending: false, editMode: false),
          isTrue);
      // A way on the map that can't be taken yet doesn't free the party.
      expect(
          sceneLocked(ways: const [
            (here: true, takeable: true, mapped: false),
            (here: false, takeable: false, mapped: true),
          ], hub: false, ending: false, editMode: false),
          isTrue);
    });

    test('a city whose plans still load draws every way: nothing locks', () {
      final node = _story.nodeFor('250')!;
      expect(
          mapDrawsEveryWay(node,
              history: const [], world: _geography, cityPlans: null),
          isTrue);
      expect(
          mapDrawsEveryWay(node,
              history: const [], world: _geography, cityPlans: const {}),
          isFalse);
    });

    test('a hub does not lock', () {
      final camp = _story.nodeFor('4999_camp')!;
      expect(isHubScene(camp), isTrue);
      expect(_locks('4999_camp'), isFalse);
      // Even with a pure choice.
      expect(
          sceneLocked(
              ways: const [(here: true, takeable: true, mapped: false)],
              hub: true,
              ending: false,
              editMode: false),
          isFalse);
    });

    test('an ending does not lock', () {
      expect(isStoryEnding(_story.nodeFor('7005')!), isTrue);
      expect(_locks('7005'), isFalse);
      expect(
          sceneLocked(
              ways: const [(here: true, takeable: true, mapped: false)],
              hub: false,
              ending: true,
              editMode: false),
          isFalse);
      expect(
          sceneLocked(
              ways: const [], hub: false, ending: false, editMode: false),
          isFalse);
    });

    test('a scene with no takeable way does not lock', () {
      expect(_locks('965', takeable: false), isFalse);
      expect(
          sceneLocked(ways: const [
            (here: true, takeable: false, mapped: false),
          ], hub: false, ending: false, editMode: false),
          isFalse);
    });

    test('Edit Mode does not lock', () {
      expect(_locks('965', editMode: true), isFalse);
    });
  });

  testWidgets(
      'a save on the Bouncer\'s aftermath opens on the map, its ways spots '
      'in the room; the next table opens with its way back to the map',
      (tester) async {
    await _setUp(tester);
    SharedPreferences.setMockInitialValues({
      'tutorial_enabled': false,
      'player_session': json.encode({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 80,
        // The gambling hall's tables are open ("Work the next table").
        'flags': ['casino_tables'],
      }),
      'autosave_story_node': '106',
      'autosave_story_history': json.encode(['0', '100', '105']),
      'autosave_story_visited': json.encode(['0', '100', '105', '106']),
    });
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester, rounds: 6);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester, rounds: 6);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '106');
    if (find.text('Journey').evaluate().isNotEmpty &&
        find.byKey(const Key('journey_level_tabs')).evaluate().isEmpty) {
      await tester.tap(find.text('Journey').last);
      await _settle(tester);
    }
    // Not locked: the map, its tabs open, no "Choose first".
    expect(_page('106'), findsNothing);
    expect(_chooseFirst, findsNothing);
    expect(find.byKey(const Key('journey_level_tabs')), findsOneWidget);
    final world =
        tester.widget<InkWell>(find.byKey(const Key('journey_tab_world')));
    expect(world.onTap, isNotNull);

    // "Work the next table" is a spot in the room, taken from the map.
    // (Called, not tapped: the room's spots may lie over each other.)
    final step = find.byWidgetPredicate((w) =>
        w is Semantics &&
        (w.properties.label ?? '').contains('next table') &&
        w.child is GestureDetector);
    expect(step, findsOneWidget);
    void tapStep() =>
        (tester.widget<Semantics>(step).child! as GestureDetector).onTap!();
    tapStep();
    await tester.pump();
    tapStep();
    await tester.pump();
    await _pumpUntil(
        tester, () => container.read(storyPlayProvider).currentNodeId == '110');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '110');
    // The dice tables: its ways are spots in the room too, so it does not
    // lock. Read as its page, the way back to the map is open.
    expect(_chooseFirst, findsNothing);
    final back = find.byKey(const ValueKey('journey_continue'));
    if (_page('110').evaluate().isNotEmpty) {
      expect(tester.widget<ButtonStyleButton>(back).onPressed, isNotNull);
      await tester.tap(back);
      await _settle(tester);
    }
    expect(_page('110'), findsNothing);
    expect(find.byKey(const Key('journey_level_tabs')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets(
      'a card into the wreck holds the party on its page; a card taken '
      'there lifts the lock', (tester) async {
    await _setUp(tester);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
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
            {'raceId': 'human', 'professionId': 'warrior', 'gold': 80})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);

    // A jump never locks: the high quay's map, its choices behind the
    // button that opens them (a mixed scene in Alster: no lock).
    container.read(storyPlayProvider.notifier).jumpTo('960');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(_chooseFirst, findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 500));
    await _take(tester, 0);
    await _pumpUntil(tester, () => _page('965').evaluate().isNotEmpty);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '965');
    // Every way of the wreck is acted out on the deck, none on a map: its
    // page holds the party.
    expect(_page('965'), findsOneWidget);
    expect(
        find.descendant(
            of: _card(0), matching: find.textContaining('Lash yourself')),
        findsOneWidget);
    _expectLocked(tester);

    // A card taken: the story moves on, the lock lifts.
    await _take(tester, 0);
    await _pumpUntil(tester,
        () => container.read(storyPlayProvider).currentNodeId == '1100');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '1100');
    expect(_chooseFirst, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('a save on a lockable scene reopens on its locked page',
      (tester) async {
    await _setUp(tester);
    SharedPreferences.setMockInitialValues({
      'tutorial_enabled': false,
      'player_session': json
          .encode({'raceId': 'human', 'professionId': 'warrior', 'gold': 80}),
      'autosave_story_node': '965',
      'autosave_story_history': json.encode(['0', '100', '250', '960']),
      'autosave_story_visited': json.encode(['0', '100', '250', '960', '965']),
    });
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester, rounds: 6);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _pumpUntil(tester, () => _page('965').evaluate().isNotEmpty);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '965');
    // Its page, with no map and no recap: the recap waits for a map.
    expect(_page('965'), findsOneWidget);
    expect(find.text(trFor(AppLanguage.en, 'previously_title')), findsNothing);
    expect(_card(0), findsOneWidget);
    expect(_card(1), findsOneWidget);
    _expectLocked(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

// The scene lock (v1.553, scene_lock.dart): a scene the story brought the
// party to, with a way acted out there, holds the Journey on its page until
// a way is taken. Every way is a card there (the ways somewhere as road
// cards), the map's tabs and buttons wait, greyed ("Choose first"); a road
// card goes back to the map and walks it; a card acted out here goes on,
// and the next lockable scene holds the party in turn.
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

/// [id]'s ways as the lock weighs them, every one takeable.
List<LockWay> _ways(String id, {bool takeable = true}) {
  final node = _story.nodeFor(id)!;
  return [
    for (final c in node.choices)
      (
        here: choiceShape(node, c, story: _story, geography: _geography).here,
        takeable: takeable,
      ),
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
  setUp(() => rootBundle.clear());

  group('sceneLocked', () {
    test('scene 250 locks: the Weaver\'s Alley is here, the bridge a road', () {
      final node = _story.nodeFor('250')!;
      final ways = _ways('250');
      expect(node.choices[0].text, contains('Stone Bridge'));
      expect(ways[0].here, isFalse);
      expect(node.choices[1].text, contains('Weaver'));
      expect(ways[1].here, isTrue);
      expect(_locks('250'), isTrue);
    });

    test('a hub does not lock', () {
      final camp = _story.nodeFor('4999_camp')!;
      expect(isHubScene(camp), isTrue);
      expect(_locks('4999_camp'), isFalse);
      // Even with a way acted out there.
      expect(
          sceneLocked(
              ways: const [(here: true, takeable: true)],
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
              ways: const [], hub: false, ending: false, editMode: false),
          isFalse);
    });

    test('a scene with no takeable way does not lock', () {
      expect(_locks('250', takeable: false), isFalse);
      // Only the road can be taken: nothing is acted out here.
      expect(
          sceneLocked(ways: const [
            (here: false, takeable: true),
            (here: true, takeable: false),
          ], hub: false, ending: false, editMode: false),
          isFalse);
    });

    test('Edit Mode does not lock', () {
      expect(_locks('250', editMode: true), isFalse);
    });
  });

  testWidgets(
      'a card into a lockable scene holds the party on its page, a road card '
      'walks it from the map, and the chain of cards stays locked',
      (tester) async {
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
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 80,
          // The gambling hall's tables are open ("Work the next table").
          'flags': ['casino_tables'],
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);

    // A jump (as in Edit Mode) never locks: the map, as before.
    container.read(storyPlayProvider.notifier).jumpTo('106');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(_page('106'), findsNothing);
    expect(_chooseFirst, findsNothing);

    // Its page, opened from the map, has its way back: not locked.
    await tester.tap(find.byKey(const ValueKey('journey_read')));
    await _settle(tester);
    expect(_page('106'), findsOneWidget);
    expect(_chooseFirst, findsNothing);
    final back = find.byKey(const ValueKey('journey_continue'));
    expect(tester.widget<ButtonStyleButton>(back).onPressed, isNotNull);
    await tester.tap(back);
    await _settle(tester);
    expect(_page('106'), findsNothing);

    // "Work the next table", a step on the map of the gambling hall (a
    // room: its ways are spots), leads to the dice tables: locked.
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
    await _pumpUntil(tester, () => _page('110').evaluate().isNotEmpty);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '110');
    expect(_page('110'), findsOneWidget);
    // Every way is a card, the road out too: "Rob the dice table" (the
    // other tables wait on it) and "Out before the roof goes".
    await _seeCard(tester, 0);
    expect(find.descendant(of: _card(0), matching: find.textContaining('dice')),
        findsOneWidget);
    await _seeCard(tester, 1);
    expect(
        find.descendant(
            of: _card(1), matching: find.textContaining('Out before the roof')),
        findsOneWidget);
    expect(_card(2), findsNothing);
    _expectLocked(tester);

    // The road card: the map comes back and the party walks the way, to
    // the street outside (scene 250), where the story's step holds it on
    // that scene's page in turn.
    await tester.tap(_card(1));
    await tester.pump();
    await tester.tap(_card(1));
    await tester.pump();
    // The page gave way to the map.
    expect(_page('110'), findsNothing);
    expect(find.byKey(const Key('journey_level_tabs')), findsOneWidget);
    await _pumpUntil(tester, () => _page('250').evaluate().isNotEmpty);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '250');
    expect(container.read(storyPlayProvider).history.last, '110');
    expect(_page('250'), findsOneWidget);
    expect(
        find.descendant(
            of: _card(0), matching: find.text('Take the Stone Bridge')),
        findsOneWidget);
    _expectLocked(tester);

    // The Weaver's Alley, a card acted out here, leads to another lockable
    // scene: still locked, every way a card, the road on too ("Leave them
    // both").
    await _take(tester, 1);
    await _pumpUntil(tester, () => _page('270').evaluate().isNotEmpty);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '270');
    expect(_page('270'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await _seeCard(tester, i);
      expect(_card(i), findsOneWidget);
    }
    expect(
        find.descendant(
            of: _card(2), matching: find.textContaining('Leave them both')),
        findsOneWidget);
    _expectLocked(tester);
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
      'autosave_story_node': '250',
      'autosave_story_history': json.encode(['0', '100', '105', '106']),
      'autosave_story_visited': json.encode(['0', '100', '105', '106', '250']),
    });
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester, rounds: 6);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _pumpUntil(tester, () => _page('250').evaluate().isNotEmpty);
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '250');
    // Its page, with no map and no recap: the recap waits for a map.
    expect(_page('250'), findsOneWidget);
    expect(find.text(trFor(AppLanguage.en, 'previously_title')), findsNothing);
    expect(_card(0), findsOneWidget);
    expect(_card(1), findsOneWidget);
    _expectLocked(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

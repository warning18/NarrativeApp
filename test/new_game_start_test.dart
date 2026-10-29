// A new game opens on its first scene ("Choose who you are…"), read as a
// page, not on the Journey map; and the "Previously…" recap shows only
// over a resumed story that has gone past its first scene.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/choice_shape.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder found) async {
  for (var i = 0; i < 40 && found.evaluate().isEmpty; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _start =
    StoryPlayState(currentNodeId: '0', history: [], visitedNodeIds: {'0'});

const _ending = '7005';

final _previously = find.text(trFor(AppLanguage.en, 'previously_title'));

Future<void> _launch(WidgetTester tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  usePhone(tester, const Size(420, 900));
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await _settle(tester, rounds: 6);
}

/// The Journey reading a scene full screen (its page), not the map.
final _readingPage = find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key! as ValueKey<String>).value.startsWith('journey_reading_0_'));

/// A way on drawn as a step on the Journey's map.
final _mapStep = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('journey_step_'),
    skipOffstage: false);

Future<ProviderContainer> _english(WidgetTester tester) async {
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  return container;
}

/// Taps [key] on the main menu, confirms if asked, and waits for the game.
Future<void> _enter(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await _settle(tester);
  final confirm = find.descendant(
      of: find.byType(AlertDialog), matching: find.byType(FilledButton));
  if (confirm.evaluate().isNotEmpty) {
    await tester.tap(confirm);
    await _settle(tester);
  }
  await _pumpUntilFound(tester, _readingPage);
}

void _expectFirstScenePage(WidgetTester tester, ProviderContainer container) {
  expect(container.read(storyPlayProvider).currentNodeId, '0');
  expect(container.read(homeTabIndexProvider), journeyTabIndex);
  // The first scene, read as a page: not the map.
  expect(_readingPage, findsOneWidget);
}

void main() {
  setUp(rootBundle.clear);

  group('hasRecapProgress', () {
    test('nothing to recap on a fresh story', () {
      expect(hasRecapProgress(_start, resumed: false), isFalse);
      expect(hasRecapProgress(_start, resumed: true), isFalse);
    });

    test('only the character made on the first scene: nothing to recap', () {
      const made = StoryPlayState(
          currentNodeId: '100', history: ['0'], visitedNodeIds: {'0', '100'});
      expect(hasRecapProgress(made, resumed: true), isFalse);
    });

    test('a resumed story past its first scene is recapped', () {
      const on = StoryPlayState(
          currentNodeId: '250',
          history: ['0', '100'],
          visitedNodeIds: {'0', '100', '250'});
      expect(hasRecapProgress(on, resumed: true), isTrue);
      // Played this launch, not picked back up: no recap.
      expect(hasRecapProgress(on, resumed: false), isFalse);
    });
  });

  test('a fresh story start is the first scene with nothing played', () {
    expect(isFreshStoryStart(_start), isTrue);
    // However it was reached: a save left on the first scene too.
    expect(
        isFreshStoryStart(const StoryPlayState(
            currentNodeId: '0', history: ['0'], visitedNodeIds: {'0'})),
        isTrue);
    expect(
        isFreshStoryStart(const StoryPlayState(
            currentNodeId: '100',
            history: ['0'],
            visitedNodeIds: {'0', '100'})),
        isFalse);
    // Back on the first scene after playing on: not a new game.
    expect(
        isFreshStoryStart(const StoryPlayState(
            currentNodeId: '0',
            history: ['0', '100'],
            visitedNodeIds: {'0', '100'})),
        isFalse);
  });

  test('a new game forgets the resumed story and outruns its autosave load',
      () async {
    SharedPreferences.setMockInitialValues({
      'autosave_story_node': '300',
      'autosave_story_history': json.encode(['0', '100', '250']),
    });
    // Loaded first: a story picked back up.
    final resumed = StoryPlayNotifier('0');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(resumed.restoredFromAutosave, isTrue);
    resumed.restart('0');
    expect(resumed.restoredFromAutosave, isFalse);
    expect(resumed.startedFresh, isTrue);

    // Restarted before the autosave finished loading: the new game stays.
    final racing = StoryPlayNotifier('0');
    racing.restart('0');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(racing.state.currentNodeId, '0');
    expect(racing.state.history, isEmpty);
    expect(racing.restoredFromAutosave, isFalse);
  });

  testWidgets(
      'New Game over a story in progress opens on the first scene, '
      'with no recap', (tester) async {
    SharedPreferences.setMockInitialValues({
      'player_session':
          json.encode({'raceId': 'human', 'professionId': 'warrior'}),
      'autosave_story_node': '300',
      'autosave_story_history': json.encode(['0', '100', '250', '270']),
      'autosave_story_visited': json.encode(['0', '100', '250', '270', '300']),
    });
    await _launch(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.tap(find.byKey(const Key('menu_new_game')));
    await _settle(tester);
    // Over a story under way, New Game asks first.
    final confirm = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton));
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await _settle(tester);
    }
    await _pumpUntilFound(tester, _readingPage);
    _expectFirstScenePage(tester, container);
    await _settle(tester);
    expect(_previously, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'first launch of a fresh install: New Game opens on the first '
      'scene', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _launch(tester);
    final container = await _english(tester);
    await _enter(tester, 'menu_new_game');
    _expectFirstScenePage(tester, container);
    await _settle(tester);
    expect(_previously, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a save that never left the first scene opens on it, '
      'not on the map', (tester) async {
    SharedPreferences.setMockInitialValues({
      'player_session':
          json.encode({'raceId': 'human', 'professionId': 'warrior'}),
      'autosave_story_node': '0',
      'autosave_story_history': json.encode([]),
      'autosave_story_visited': json.encode(['0']),
    });
    await _launch(tester);
    final container = await _english(tester);
    await _enter(tester, 'menu_continue');
    _expectFirstScenePage(tester, container);
    expect(_previously, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New Game after a finished story opens on the first scene',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'player_session':
          json.encode({'raceId': 'human', 'professionId': 'warrior'}),
      'autosave_story_node': _ending,
      'autosave_story_history': json.encode(['0', '100', '250']),
      'autosave_story_visited': json.encode(['0', '100', '250', _ending]),
    });
    await _launch(tester);
    final container = await _english(tester);
    await _enter(tester, 'menu_new_game');
    _expectFirstScenePage(tester, container);
    await _settle(tester);
    expect(_previously, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'beginning again from an ending on the Journey opens on the first '
      'scene', (tester) async {
    SharedPreferences.setMockInitialValues({
      'player_session':
          json.encode({'raceId': 'human', 'professionId': 'warrior'}),
      'autosave_story_node': _ending,
      'autosave_story_history': json.encode(['0', '100', '250']),
      'autosave_story_visited': json.encode(['0', '100', '250', _ending]),
    });
    await _launch(tester);
    final container = await _english(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    // The Journey's ending opens the story, whose ending begins again.
    final open = find.byKey(const ValueKey('journey_open_story'));
    await _pumpUntilFound(tester, open);
    // The recap first.
    await _pumpUntilFound(tester, _previously);
    await tester.tap(find.text('Go on'));
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, _ending);
    await tester.tap(open);
    await _settle(tester);
    final again = find.text('Begin again, changed');
    await _pumpUntilFound(tester, again);
    await tester.tap(again.last);
    await _settle(tester);
    await tester.pageBack();
    await _settle(tester);
    await _pumpUntilFound(tester, _readingPage);
    _expectFirstScenePage(tester, container);
    expect(tester.takeException(), isNull);
  });

  test(
      'the prologue\'s way on is acted out on its page; a way across the '
      'town stays a step on the map', () {
    Map<String, dynamic> table(String name) =>
        jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
            as Map<String, dynamic>;
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final geography =
        Geography.parse(geography: table('geography'), biomes: table('biomes'));
    final start = story.nodeFor(StoryRepository.startNodeId)!;
    for (final choice in start.choices) {
      expect(
          choiceShape(start, choice, story: story, geography: geography).here,
          isTrue);
    }
    // Every other way somewhere is still a step on the map.
    var ways = 0;
    for (final node in story.nodes.values) {
      for (final choice in node.choices) {
        if (choice.opensCharacterCreation) continue;
        final shape =
            choiceShape(node, choice, story: story, geography: geography);
        if (shape.action != ChoiceAction.go) continue;
        ways++;
        expect(shape.here, isFalse, reason: '${node.id} ${choice.text}');
      }
    }
    expect(ways, greaterThan(50));
  });

  testWidgets(
      'a new game makes its character from the first page and reads on '
      'into the Blind Beggar, with no map', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _launch(tester);
    final container = await _english(tester);
    await _enter(tester, 'menu_new_game');
    _expectFirstScenePage(tester, container);
    expect(_mapStep, findsNothing);
    // The way on is a card on the page, not a step on the map.
    final card = find.byKey(const ValueKey('journey_choice_card_0'));
    await _pumpUntilFound(tester, card);
    // It is on Alster's city chart too, so the page does not hold the
    // party (scene_lock.dart): its way back to the map is open, the button
    // under the cards and the corner's.
    expect(find.byKey(const ValueKey('journey_choose_first')), findsNothing);
    expect(
        tester
            .widget<ButtonStyleButton>(
                find.byKey(const ValueKey('journey_continue')))
            .onPressed,
        isNotNull);
    expect(find.text('Back to the map'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const ValueKey('journey_reading_exit')))
            .onPressed,
        isNotNull);
    expect(
        find.descendant(
            of: card, matching: find.textContaining('Choose who you are')),
        findsOneWidget);
    // Its one way on is picked already: one tap takes it.
    await tester.tap(card);
    // The character made (its screen stood in for), the story reads on.
    final making = find.byType(RaceProfessionScreen);
    await _pumpUntilFound(tester, making);
    expect(making, findsOneWidget);
    // Under the character's screen, the Journey is still on the page.
    expect(_mapStep, findsNothing);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    Navigator.of(tester.element(making)).pop(true);
    final beggar = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('journey_reading_100_'));
    await _pumpUntilFound(tester, beggar);
    expect(container.read(storyPlayProvider).currentNodeId, '100_dice');
    // The Blind Beggar's page: no map, no Lower Town step.
    expect(beggar, findsOneWidget);
    expect(_mapStep, findsNothing);
    expect(find.textContaining('Choose who you are'), findsNothing);
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a resumed story with progress shows the recap, on the map',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'player_session':
          json.encode({'raceId': 'human', 'professionId': 'warrior'}),
      'autosave_story_node': '300',
      'autosave_story_history': json.encode(['0', '100', '250', '270']),
      'autosave_story_visited': json.encode(['0', '100', '250', '270', '300']),
    });
    await _launch(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _pumpUntilFound(tester, _previously);
    expect(_previously, findsOneWidget);
    expect(container.read(storyPlayProvider).currentNodeId, '300');
    // A resumed story opens as before: not on the first scene's page.
    expect(container.read(storyPlayProvider.notifier).startedFresh, isFalse);
    expect(
        find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            RegExp(r'^journey_reading_\d')
                .hasMatch((w.key! as ValueKey<String>).value)),
        findsNothing);
    expect(tester.takeException(), isNull);
    // Let the recap's and the scene's timers run out.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

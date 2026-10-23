// A new game opens on its first scene ("Choose who you are…"), read as a
// page, not on the Journey map; and the "Previously…" recap shows only
// over a resumed story that has gone past its first scene.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

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

final _previously = find.text(trFor(AppLanguage.en, 'previously_title'));

Future<void> _launch(WidgetTester tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await _settle(tester, rounds: 6);
}

void main() {
  setUp(() => rootBundle.clear());

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

  test('a fresh story start is the first scene of a restarted story', () {
    expect(isFreshStoryStart(_start, startedFresh: true), isTrue);
    expect(isFreshStoryStart(_start, startedFresh: false), isFalse);
    expect(
        isFreshStoryStart(
            const StoryPlayState(
                currentNodeId: '100',
                history: ['0'],
                visitedNodeIds: {'0', '100'}),
            startedFresh: true),
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
    final page = find.byKey(const ValueKey('journey_continue'));
    await _pumpUntilFound(tester, page);

    expect(container.read(storyPlayProvider).currentNodeId, '0');
    expect(container.read(homeTabIndexProvider), journeyTabIndex);
    // The first scene, read as a page: not the map.
    expect(page, findsOneWidget);
    await _settle(tester);
    expect(_previously, findsNothing);
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
    expect(tester.takeException(), isNull);
    // Let the recap's and the scene's timers run out.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

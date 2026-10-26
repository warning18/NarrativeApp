// The Journey tab on a 360x640 phone: a timed scene has one clock, shared
// with the Story tab and kept while the scene is read full screen; the map
// keeps room for the party and its ways once a step is picked; and the
// party's walk can be neither cut short by reading the scene nor left
// hanging when its map goes (v1.186 left Go a spinner for good).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/city_provider.dart'
    show cityPlanRecordsProvider;
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/tutorial/guide_tour.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _step(int i) => find.byKey(ValueKey('journey_step_$i'));

/// The last pin on the map: a hub's last way on walks the party to a place.
Finder _lastStep() => find.byKey(ValueKey(
    'journey_step_${List.generate(40, (i) => 39 - i).firstWhere((i) => _step(i).evaluate().isNotEmpty)}'));

/// A choice acted out where the party stands is a card under the map.
Finder _card(int i) => find.byKey(ValueKey('journey_choice_card_$i'));

/// The choices acted out here are in the scene view, under the words; a
/// button under the map opens it.
Future<void> _openChoices(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
  await tester.pump(const Duration(milliseconds: 400));
}

/// The part of the Journey tab the tour calls [id] (see TutorialTarget).
Rect _target(WidgetTester tester, String id) => tester.getRect(
    find.byWidgetPredicate((w) => w is TutorialTarget && w.id == id).first);

void main() {
  testWidgets(
      'one clock for a timed scene, room for the map, and a walk that '
      'always ends', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
          // These test the streets' marks: the generated plan, not the stored
          // city chart (board 15, v1.355).
          overrides: [
            cityPlanRecordsProvider.overrideWith((ref) async => const {})
          ],
          child: const MyApp()),
    );
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
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    void show(int tab) =>
        container.read(homeTabIndexProvider.notifier).state = tab;
    // What arriving somewhere opens over the game (a new place's card, a
    // chapter's notice) is closed.
    Future<void> arrive(String id, {int walk = 2}) async {
      play.jumpTo(id);
      await _settle(tester);
      // The road walked to a place far off takes its time.
      await tester.pump(Duration(seconds: walk));
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    String secondsLeft() => tester
        .widget<Text>(find.byKey(const ValueKey('timed_choice_seconds')))
        .data!;
    Future<void> wait(int seconds) async {
      for (var s = 0; s < seconds * 4; s++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    final readButton = find.byKey(const ValueKey('journey_read'));
    Future<void> read() async {
      await tester.tap(readButton, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
    }

    // The siege: 20 seconds to choose. Its clock is not wound back by
    // reading the scene full screen, nor doubled by the Story tab.
    show(journeyTabIndex);
    await arrive('6002_siege');
    final started = int.parse(secondsLeft().replaceAll('s', ''));
    await wait(8);
    final left = int.parse(secondsLeft().replaceAll('s', ''));
    expect(left, lessThanOrEqualTo(started - 7));
    await read();
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsOneWidget);
    await wait(2);
    await tester.tap(find.byKey(const ValueKey('journey_reading_exit')));
    await tester.pump(const Duration(milliseconds: 100));
    // Paused while read, and on from where it stood.
    expect(int.parse(secondsLeft().replaceAll('s', '')),
        inInclusiveRange(left - 1, left));
    show(0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(int.parse(secondsLeft().replaceAll('s', '')),
        inInclusiveRange(left - 1, left));
    await wait(3);
    final onStory = int.parse(secondsLeft().replaceAll('s', ''));
    expect(onStory, lessThanOrEqualTo(left - 2));
    show(journeyTabIndex);
    await tester.pump(const Duration(milliseconds: 100));
    expect(int.parse(secondsLeft().replaceAll('s', '')),
        inInclusiveRange(onStory - 1, onStory));

    // On a short phone the map keeps its room: under it, a button opens the
    // choices acted out here (they are in the scene view, not on the map).
    await tester.pump(const Duration(seconds: 1));
    final chart = _target(tester, 'journey.chart');
    expect(chart.height, greaterThanOrEqualTo(159.5));
    expect(_step(0), findsNothing, reason: 'a choice acted out here is no pin');
    expect(find.byKey(const ValueKey('journey_open_choices')), findsOneWidget);
    expect(_card(0), findsNothing);
    expect(_target(tester, 'journey.pick').bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top));
    expect(tester.takeException(), isNull);

    // The alley: the same on a plain scene.
    await arrive('270', walk: 6);
    expect(
        _target(tester, 'journey.chart').height, greaterThanOrEqualTo(159.5));
    expect(_target(tester, 'journey.pick').bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top));

    // In the scene view, a card picked has its Go.
    await _openChoices(tester);
    await tester.tap(_card(0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('journey_go')), findsOneWidget);

    // Go: a choice acted out here sends no one walking, and the step is
    // taken.
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('journey_traveller')), findsNothing);
    // The beat at the party's mark, then the story goes on.
    await tester.pump(const Duration(milliseconds: 700));
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '300');
    expect(container.read(playerSessionProvider).flags,
        contains('companion_hound'));
    // The scene reached is read full screen. A card led to it and its ways
    // are all cards too: no way back to the map, the cards go on (v1.548).
    expect(
        find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>)
                .value
                .startsWith('journey_reading_300')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('journey_continue')), findsNothing);
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsNothing);

    // Go, and Read while the party walks (a plain way on, a pin): the map
    // stays put (the party walks on it), and the step is taken.
    await arrive('2015', walk: 6);
    await tester.tap(_lastStep());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('journey_traveller')), findsOneWidget);
    await read();
    expect(find.byKey(const ValueKey('journey_reading_exit')), findsNothing);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    expect(find.byKey(const ValueKey('journey_traveller')), findsNothing);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(JourneyScreen)))
        .popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));

    // The story moved on from under a walk (its map gone with it): the
    // step is not taken, and the next scene's steps are free to take.
    if (find.byKey(const ValueKey('journey_continue')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('journey_continue')));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await arrive('2015', walk: 6);
    await tester.tap(_lastStep());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('journey_traveller')), findsOneWidget);
    play.jumpTo('2005');
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '2005');
    Navigator.of(tester.element(find.byType(JourneyScreen)))
        .popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(_step(0));
    await tester.pump(const Duration(milliseconds: 400));
    final go =
        tester.widget<FilledButton>(find.byKey(const ValueKey('journey_go')));
    expect(go.onPressed, isNotNull);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('journey_go')),
            matching: find.byType(CircularProgressIndicator)),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}

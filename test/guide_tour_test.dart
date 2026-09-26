import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/tutorial_provider.dart';
import 'package:narrative_data_app/providers/walk_companion_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/tutorial/guide_tour.dart';
import 'package:narrative_data_app/tutorial/tutorial_launcher.dart';
import 'package:narrative_data_app/tutorial/tutorial_topics.dart';

/// A page with the Level Up tour's two targets on it.
class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TutorialTrigger(
        topic: TutorialTopic.levelUp,
        child: Column(
          children: [
            SizedBox(height: 120),
            TutorialTarget(id: 'levelUp.points', child: Text('Points: 2')),
            SizedBox(height: 300),
            TutorialTarget(id: 'levelUp.stats', child: Text('Strength')),
          ],
        ),
      ),
    );
  }
}

Widget _app({bool autoShow = true, Widget home = const _Page()}) =>
    ProviderScope(
      overrides: [tutorialAutoShowProvider.overrideWithValue(autoShow)],
      child: MaterialApp(
        theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
        home: home,
      ),
    );

/// Long enough for the trigger's pause, the walk and the words.
Future<void> _wait(WidgetTester tester, [int ms = 3000]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'app_mode': 'inGame'}));

  test('every tour line and title is written in both languages', () {
    for (final topic in TutorialTopic.values) {
      for (final key in [
        topic.titleKey,
        for (final step in topic.steps) step.textKey,
      ]) {
        final en = trFor(AppLanguage.en, key);
        final fr = trFor(AppLanguage.fr, key);
        expect(en, isNot(key), reason: key);
        expect(fr, isNot(en), reason: key);
      }
    }
  });

  test('the walking companion is on unless turned off', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(walkCompanionEnabledProvider), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(walkCompanionEnabledProvider), isTrue);
  });

  test('a player who saw the old tour has seen the Story tour', () async {
    SharedPreferences.setMockInitialValues({'tutorial_seen': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tutorialProvider);
    await Future<void>.delayed(Duration.zero);
    final settings = container.read(tutorialProvider);
    expect(settings.loaded, isTrue);
    expect(settings.hasSeen(TutorialTopic.story), isTrue);
    expect(settings.hasSeen(TutorialTopic.camp), isFalse);

    await container.read(tutorialProvider.notifier).reset();
    expect(container.read(tutorialProvider).seen, isEmpty);
  });

  testWidgets('a feature\'s tour plays once, step by step, lighting each part',
      (tester) async {
    await tester.pumpWidget(_app());
    await _wait(tester);

    expect(find.byKey(const Key('guide_dog')), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(
        _container(tester)
            .read(tutorialProvider)
            .hasSeen(TutorialTopic.levelUp),
        isTrue);

    await tester.tap(find.byKey(const Key('tutorial_next')));
    await _wait(tester);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial_next')));
    await _wait(tester, 800);
    expect(find.byKey(const Key('guide_dog')), findsNothing);

    // Seen: coming back doesn't play it again.
    await tester.pumpWidget(_app(home: const SizedBox()));
    await tester.pumpWidget(_app());
    await _wait(tester);
    expect(find.byKey(const Key('guide_dog')), findsNothing);
  });

  testWidgets('a tap while the words come shows the whole line',
      (tester) async {
    await tester.pumpWidget(_app());
    // Past the pause and the walk, but not the whole line.
    await _wait(tester, 1500);
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial_next')));
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial_skip')));
    await _wait(tester, 800);
  });

  testWidgets('Skip ends a tour at once', (tester) async {
    await tester.pumpWidget(_app());
    await _wait(tester);
    expect(find.byKey(const Key('tutorial_skip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial_skip')));
    await _wait(tester, 800);
    expect(find.byKey(const Key('guide_dog')), findsNothing);
    expect(find.text('Points: 2'), findsOneWidget);
  });

  testWidgets('with tutorials turned off, nothing plays by itself',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'app_mode': 'inGame', 'tutorial_enabled': false});
    await tester.pumpWidget(_app());
    await _wait(tester);
    expect(find.byKey(const Key('guide_dog')), findsNothing);
  });

  testWidgets('in Edit Mode, nothing plays by itself', (tester) async {
    SharedPreferences.setMockInitialValues({'app_mode': 'edit'});
    await tester.pumpWidget(_app());
    await _wait(tester);
    expect(find.byKey(const Key('guide_dog')), findsNothing);
  });

  testWidgets('a tour already seen plays again when asked for', (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_mode': 'inGame',
      'tutorial_seen_topics': ['levelUp'],
    });
    await tester.pumpWidget(_app());
    await _wait(tester);
    expect(find.byKey(const Key('guide_dog')), findsNothing);

    _container(tester).read(pendingTourProvider.notifier).state =
        TutorialTopic.levelUp;
    await _wait(tester);
    expect(find.byKey(const Key('guide_dog')), findsOneWidget);
    expect(_container(tester).read(pendingTourProvider), isNull);
  });

  testWidgets(
      'on a small phone with large text, Next stays on screen at every step',
      (tester) async {
    // A phone: 360 x 640, a navigation bar at the bottom, text at 150%.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // The Story tour, with the story text taking up half the screen.
    await tester.pumpWidget(_app(
      home: const Scaffold(
        body: TutorialTrigger(
          topic: TutorialTopic.story,
          child: Column(
            children: [
              SizedBox(height: 110),
              TutorialTarget(
                id: 'story.text',
                child: SizedBox(height: 320, child: Text('The story')),
              ),
            ],
          ),
        ),
      ),
    ));
    final steps = TutorialTopic.story.steps.length;
    for (var step = 1; step <= steps; step++) {
      await _wait(tester, 4000);
      expect(find.text('$step / $steps'), findsOneWidget);
      final next = tester.getRect(find.byKey(const Key('tutorial_next')));
      expect(next.bottom, lessThanOrEqualTo(640 - 48),
          reason: 'step $step: Next under the navigation bar');
      expect(next.top, greaterThanOrEqualTo(24), reason: 'step $step');
      await tester.tap(find.byKey(const Key('tutorial_next')));
    }
    await _wait(tester, 800);
    expect(find.byKey(const Key('guide_dog')), findsNothing);
  });

  testWidgets('a tour with no page of its own is told where the player is',
      (tester) async {
    await tester.pumpWidget(_app(
      autoShow: false,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => playTutorial(context, ref, TutorialTopic.fight),
            child: const Text('Replay'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Replay'));
    await _wait(tester);
    expect(find.byKey(const Key('guide_dog')), findsOneWidget);
    expect(
        find.text('1 / ${TutorialTopic.fight.steps.length}'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial_skip')));
    await _wait(tester, 800);
  });
}

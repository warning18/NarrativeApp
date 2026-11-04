// QA: the user's feedback of v1.665 to v1.696, so that it cannot come back.
// Each test names the words it holds.
//  1. "A page with one card has no way back to the map." (v1.692)
//  2. "The intro has none." No map before the hero is made. (v1.692)
//  3. "The reading page's text starts at the top." (v1.696)
//  4. "The dice are thrown slower, and I can speed them up." 1x, 2x, 4x. (v1.679)
//  5. "The Level up card covers the first lines of the page." (v1.696)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/feature_unlocks.dart';
import 'package:narrative_data_app/data/scene_lock.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/combat_settings_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/settings_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/feature_unlock.dart';

import 'player_session_provider_test.dart' show baseSession;
import 'support/pump.dart';

final _backToMap = find.byKey(const ValueKey('journey_continue'));
final _cornerMap = find.byKey(const ValueKey('journey_reading_exit'));
final _sceneText = find.byKey(const ValueKey('journey_scene_text'));

/// The app on a new game's first page, and a way to open any scene as the
/// story brings the party to it.
Future<ProviderContainer> _newGame(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  usePhone(tester, const Size(412, 880));
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await settleApp(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.tap(find.byKey(const Key('menu_new_game')));
  await settleApp(tester);
  final confirm = find.descendant(
      of: find.byType(AlertDialog), matching: find.byType(FilledButton));
  if (confirm.evaluate().isNotEmpty) {
    await tester.tap(confirm);
    await settleApp(tester);
  }
  return container;
}

Future<void> _open(
    WidgetTester tester, ProviderContainer container, String node) async {
  container.read(storyPlayProvider.notifier).restart(node);
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (find.text('Read').evaluate().isNotEmpty) {
    await tester.tap(find.text('Read'));
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  setUp(rootBundle.clear);

  group('a page that offers one choice is a tunnel (v1.692)', () {
    const one = (card: true, takeable: true, to: 'gate');

    test('one card the party can take hides the way back, whatever its pins',
        () {
      expect(
          pageExitHidden(
              ways: const [one], hub: false, ending: false, editMode: false),
          isTrue);
      expect(
          pageExitHidden(ways: const [
            (card: false, takeable: true, to: 'wharf'),
            one,
          ], hub: false, ending: false, editMode: false),
          isTrue,
          reason: 'its pins are listed as road cards: no way is lost');
    });

    test('a card that cannot be taken yet, a hub, an ending, Edit Mode keep it',
        () {
      expect(
          pageExitHidden(ways: const [
            (card: true, takeable: false, to: 'gate'),
          ], hub: false, ending: false, editMode: false),
          isFalse);
      expect(
          pageExitHidden(
              ways: const [one], hub: true, ending: false, editMode: false),
          isFalse);
      expect(
          pageExitHidden(
              ways: const [one], hub: false, ending: true, editMode: false),
          isFalse);
      expect(
          pageExitHidden(
              ways: const [one], hub: false, ending: false, editMode: true),
          isFalse);
    });
  });

  testWidgets(
      'the intro has no way to the map before the hero is made (v1.692)',
      (tester) async {
    final container = await _newGame(tester);
    expect(isFreshStoryStart(container.read(storyPlayProvider)), isTrue,
        reason: 'a new game opens on the first page');
    expect(_backToMap, findsNothing);
    expect(_cornerMap, findsNothing);
    expect(find.byKey(const Key('home_full_map')), findsNothing,
        reason: 'no map in the top bar either');
    expect(find.byKey(const ValueKey('journey_choice_card_0')), findsOneWidget,
        reason: 'the page shows its card');
    await _leave(tester);
  });

  testWidgets(
      'the reading page: the text starts at the top of the card (v1.696)',
      (tester) async {
    final container = await _newGame(tester);
    // A short scene is where centring left an empty gap above the words.
    for (final node in ['850_fed_failed', '2011_roof_fall', '250']) {
      await _open(tester, container, node);
      expect(_sceneText, findsOneWidget, reason: node);
      final card = tester.getRect(_sceneText);
      final first = tester.getRect(find
          .descendant(of: _sceneText, matching: find.byType(RichText))
          .first);
      expect(first.top - card.top, lessThan(60),
          reason: 'scene $node: the first line is at the top, not centred');
      // And near the top of the screen, not in the middle of an empty page.
      expect(first.top, lessThan(330),
          reason: 'scene $node: no empty gap opens above the words');
    }
    await _leave(tester);
  });

  group('the dice are thrown slower, with a speed setting (v1.679)', () {
    test('the numbers: 1.4 s a throw, 0.45 s at rest, 1x 2x 4x', () {
      expect(diceThrowBase, const Duration(milliseconds: 1400));
      expect(diceLandBase, const Duration(milliseconds: 450));
      expect([for (final s in DiceSpeed.values) s.factor], [1, 2, 4]);
      expect(DiceSpeed.values.first, DiceSpeed.normal,
          reason: '1x is the default');
      for (final base in [diceThrowBase, diceLandBase]) {
        expect(diceTimeFor(base, DiceSpeed.double), base ~/ 2);
        expect(diceTimeFor(base, DiceSpeed.quad), base ~/ 4);
      }
    });

    testWidgets('Settings offers 1x, 2x and 4x, and a tap sets it',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      usePhone(tester, const Size(412, 880));
      late ProviderContainer container;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
          home: const SettingsScreen(),
        ),
      ));
      container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() => container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.en));
      await tester.pump(const Duration(milliseconds: 300));
      final setting = find.byKey(const Key('dice_speed_setting'));
      await tester.scrollUntilVisible(setting, 300,
          scrollable: find.byType(Scrollable).first);
      for (final label in ['1×', '2×', '4×']) {
        expect(find.descendant(of: setting, matching: find.text(label)),
            findsOneWidget,
            reason: label);
      }
      await tester.tap(find.descendant(of: setting, matching: find.text('4×')));
      await tester.pump();
      expect(container.read(diceSpeedProvider), DiceSpeed.quad);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
    });
  });

  testWidgets(
      'the Level up card has a place of its own, above the page (v1.696)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(360, 640));
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
        home: const Scaffold(
          body: FeatureUnlockHost(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text('The first line of the scene.',
                    key: Key('page_first_line')),
              ),
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(baseSession()
            .copyWith(flags: const [featureLadderFlag, 'feat_quests'])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final card = find.byKey(const Key('unlock_card_quests'));
    expect(card, findsOneWidget);
    final line = tester.getRect(find.byKey(const Key('page_first_line')));
    final cardRect = tester.getRect(card);
    expect(cardRect.bottom, lessThanOrEqualTo(line.top),
        reason: 'the card sits above the first line, it does not cover it');
    // And the page comes back up when the card goes.
    await tester.tap(find.byKey(const Key('unlock_later')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('unlock_card_quests')), findsNothing);
    expect(tester.getRect(find.byKey(const Key('page_first_line'))).top,
        lessThan(line.top),
        reason: 'the page slides back up');
  });
}

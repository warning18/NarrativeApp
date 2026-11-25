// QA guard (the chapter chest on screen, v2.7.0): in the real app, crossing
// into the next chapter shows the chapter's title card and then its chest,
// at the tier the goals earned; Open gives it and the spoils sheet closes
// on it; the chest comes once: after it, a restart of the app on the same
// save shows no second one, and the next chapter's chest comes at its turn.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/data/chapter_goals.dart';
import 'support/pump.dart';

void main() {
  setUp(rootBundle.clear);

  testWidgets('the chest comes after the chapter card, once', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(390, 844));
    Future<ProviderContainer> start() async {
      await tester.pumpWidget(ProviderScope(
          key: UniqueKey(), overrides: const [], child: const MyApp()));
      await settleApp(tester);
      return ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)));
    }

    final c = await start();
    await tester.runAsync(
        () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
    // Chapter 4 done with two goals of three met.
    final met = [for (final g in chapterGoalTable[4]!.take(2)) g.id];
    await tester.runAsync(() => c
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'chapterGoalsMet': {'4': met},
        })));
    c.read(storyPlayProvider.notifier).jumpTo('5003');
    await settleApp(tester);
    // Into the game, on the story, where the chapters turn.
    await tester.tap(find.byKey(const Key('menu_continue')));
    await settleApp(tester);
    await settleApp(tester);
    expect(find.byKey(const Key('chapter_chest_dialog')), findsNothing,
        reason: 'no chest before the next chapter');
    final goldBefore = c.read(playerSessionProvider).gold;

    c.read(storyPlayProvider.notifier).jumpTo('6001');
    await settleApp(tester);
    // The title card first, then the chest (the card closes by itself).
    var shown = false;
    for (var i = 0; i < 120 && !shown; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 250));
      shown =
          find.byKey(const Key('chapter_chest_dialog')).evaluate().isNotEmpty;
    }
    expect(shown, isTrue, reason: 'the chest did not come after the card');
    expect(find.byKey(const Key('chapter_chest_silver')), findsOneWidget,
        reason: 'two goals of three: a Silver chest');
    expect(c.read(playerSessionProvider).chapterChestsGiven, isEmpty);
    await tester.tap(find.byKey(const Key('chapter_chest_open')));
    final take = find.text(trFor(AppLanguage.en, 'chest_take_button'));
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 200));
      if (take.evaluate().isNotEmpty) await tester.tap(take.first);
    }
    expect(c.read(playerSessionProvider).chapterChestsGiven, [4]);
    expect(c.read(playerSessionProvider).gold, greaterThan(goldBefore),
        reason: 'the chest gave no gold');
    expect(find.byKey(const Key('chapter_chest_dialog')), findsNothing);

    // A restart of the app on the same save: no second chest for chapter 4.
    final c2 = await start();
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byKey(const Key('chapter_chest_dialog')), findsNothing,
        reason: 'the chest came again after a restart');
    expect(c2.read(playerSessionProvider).chapterChestsGiven, [4]);
    final goldAfter = c2.read(playerSessionProvider).gold;
    // The next chapter's chest comes at its turn: none met, a Wooden one.
    c2.read(storyPlayProvider.notifier).jumpTo('7001');
    var shown2 = false;
    for (var i = 0; i < 120 && !shown2; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 250));
      shown2 =
          find.byKey(const Key('chapter_chest_dialog')).evaluate().isNotEmpty;
    }
    expect(shown2, isTrue, reason: "chapter 5's chest did not come");
    expect(find.byKey(const Key('chapter_chest_wooden')), findsOneWidget,
        reason: 'no goal met: a Wooden chest');
    expect(c2.read(playerSessionProvider).gold, goldAfter,
        reason: 'gold given before the chest was opened');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

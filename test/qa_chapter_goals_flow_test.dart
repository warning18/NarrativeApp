// QA guard (chapter goals and the chapter chest, v2.5.0): Core's
// chapter_goals_test holds each rule on its own; this holds the flow a player
// lives, with the real fight screen and the real saves:
//  - a fight won on the real fight screen in a goal chapter ticks the goals
//    it met (here "won in 4 rounds or fewer" in chapter 8), and only in a
//    story fight: the Tower's fights and the fight lab's tests tick nothing;
//  - the chest is given once: a second claim gives nothing and no gold, a
//    goal met after it does not count, and the due chapter is the earliest
//    one unclaimed;
//  - the goals met and the chests given survive a restart of the session store.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/data/chapter_goals.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Future<PlayerSessionNotifier> _open() async {
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return notifier;
}

const _won = ChapterFightFacts(
    won: true, rounds: 1, healthLeft: 1, maxHealth: 100, weaknessHits: 3);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final items = _json('assets/gamedata/items.json');
  // An asset load cached by an earlier test belongs to that test's clock.
  setUp(rootBundle.clear);

  test(
      'every goal chapter: goals count once, the chest is given once, the '
      'chapter owed is the earliest', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = await _open();
    await notifier.loadSession(PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
    }));
    expect(notifier.chapterChestDue(4), isNull, reason: 'nothing before 4');
    for (final chapter in chapterGoalTable.keys) {
      final goals = chapterGoalTable[chapter]!;
      expect(goals.length, 3, reason: 'chapter $chapter');
      // A perfect fight: every goal that a fight alone can meet is met, and a
      // second fight meets nothing new.
      final facts = ChapterFightFacts(
          won: true,
          rounds: 1,
          healthLeft: 1,
          maxHealth: 100,
          weaknessHits: 3,
          enemyIds: [
            for (final g in goals) ...g.bossIds,
          ]);
      final first = await notifier.noteChapterGoals(chapter, goals, facts);
      expect(first.toSet(), {for (final g in goals) g.id},
          reason: 'chapter $chapter: a perfect fight meets all three goals');
      final again = await notifier.noteChapterGoals(chapter, goals, facts);
      expect(again, isEmpty, reason: 'chapter $chapter: counted twice');
      expect(notifier.chapterGoalsMetIn(chapter), hasLength(3));
    }
    // Owed as the next chapter starts: the earliest first, one at a time.
    expect(notifier.chapterChestDue(5), 4);
    expect(notifier.chapterChestDue(9), 4);
    final goldBefore = notifier.state.gold;
    for (final chapter in chapterGoalTable.keys) {
      expect(notifier.chapterChestDue(9), chapter);
      final chest = await notifier.claimChapterChest(chapter,
          items: items, random: Random(chapter));
      expect(chest, isNotNull, reason: 'chapter $chapter');
      expect(chest!.tier, chapterChestTier(3),
          reason: 'chapter $chapter: three goals, a Gold chest');
      final gold = notifier.state.gold;
      // The second claim gives nothing at all.
      final second = await notifier.claimChapterChest(chapter,
          items: items, random: Random(1));
      expect(second, isNull, reason: 'chapter $chapter: given twice');
      expect(notifier.state.gold, gold, reason: 'gold given twice');
      // A goal met after the chest does not count.
      expect(
          await notifier.noteChapterGoals(
              chapter, chapterGoalTable[chapter]!, _won),
          isEmpty,
          reason: 'chapter $chapter: counted after the chest');
    }
    expect(notifier.chapterChestDue(9), isNull);
    expect(notifier.state.gold, greaterThan(goldBefore));
    expect(notifier.state.chapterChestsGiven.toSet(),
        chapterGoalTable.keys.toSet());
    // A chapter with no goals has no chest.
    expect(await notifier.claimChapterChest(2, items: items, random: Random(1)),
        isNull);
  });

  test('the goals met and the chests given survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    var notifier = await _open();
    await notifier.loadSession(
        PlayerSession.fromJson({'raceId': 'human', 'professionId': 'warrior'}));
    await notifier.noteChapterGoals(4, chapterGoalTable[4]!, _won);
    await notifier.noteChapterGoals(5, chapterGoalTable[5]!, _won);
    await notifier.claimChapterChest(4, items: items, random: Random(4));
    notifier = await _open();
    expect(notifier.chapterGoalsMetIn(4), isNotEmpty);
    expect(notifier.chapterGoalsMetIn(5), isNotEmpty);
    expect(notifier.state.chapterChestsGiven, [4]);
    expect(notifier.chapterChestDue(9), 5, reason: '4 is given, 5 is owed');
    // And the save as a file: written and read back.
    final back = PlayerSession.fromJson(
        jsonDecode(jsonEncode(notifier.state.toJson()))
            as Map<String, dynamic>);
    expect(back.chapterGoalsMet, notifier.state.chapterGoalsMet);
    expect(back.chapterChestsGiven, [4]);
    // An old save has none met and none given.
    final old = PlayerSession.fromJson({'raceId': 'human'});
    expect(old.chapterGoalsMet, isEmpty);
    expect(old.chapterChestsGiven, isEmpty);
  });

  Future<Map<String, List<String>>> fight(
      WidgetTester tester, EncounterModifiers modifiers) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues(
        {'tutorial_enabled': false, 'combat_dice_speed': 'quad'});
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('tutorial_enabled', false);
      await prefs.setString('combat_dice_speed', 'quad');
    });
    usePhone(tester, const Size(390, 844));
    await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await settleApp(tester);
    final c =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(
        () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
    // A strong hero, so the rat dies in a round or two.
    await tester.runAsync(() => c
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'level': 30,
          'strength': 40,
          'constitution': 40,
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
        })));
    final enemy = Map<String, dynamic>.from(
        _json('assets/gamedata/enemies.json')['harbor_rat'] as Map);
    tester.state<NavigatorState>(find.byType(Navigator).first).push(
        MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                enemyId: 'harbor_rat',
                enemy: {...enemy, 'skillMoves': const <dynamic>[]},
                modifiers: modifiers)));
    await settleApp(tester);
    await tester.tapAt(const Offset(4, 300));
    await settleApp(tester);
    final enter = find.text(trFor(AppLanguage.en, 'enter_battle_button'));
    if (enter.evaluate().isNotEmpty) {
      await tester.ensureVisible(enter);
      await tester.pump();
      await tester.tap(enter);
      await settleApp(tester);
    }
    final back = find.text(trFor(AppLanguage.en, 'victory_return_button'));
    for (var i = 0; i < 120 && back.evaluate().isEmpty; i++) {
      final confirm = find.text(trFor(AppLanguage.en, 'confirm_roll_button'));
      final roll =
          find.textContaining(trFor(AppLanguage.en, 'roll_dice_button'));
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm.first);
      } else if (roll.evaluate().isNotEmpty) {
        await tester.tap(roll.first);
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    expect(back, findsWidgets, reason: 'the fight was not won');
    // The spoils are settled as the party returns.
    for (var i = 0; i < 40; i++) {
      final b = find.ancestor(
          of: back,
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      if (b.evaluate().isNotEmpty &&
          (b.evaluate().first.widget as ButtonStyleButton).enabled) {
        break;
      }
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(back.first);
    final take = find.text(trFor(AppLanguage.en, 'chest_take_button'));
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 200));
      // The spoils chest stands before the settling: take what it holds.
      if (take.evaluate().isNotEmpty) {
        await tester.tap(take.first);
      }
    }
    return c.read(playerSessionProvider).chapterGoalsMet;
  }

  testWidgets('a story fight won on the real screen ticks its goals',
      (tester) async {
    final met = await fight(
        tester,
        const EncounterModifiers(
            chapter: 8,
            healthMultiplier: 0.02,
            difficultyMultiplier: 0.05,
            forcedGoal: FightGoal.slay));
    expect(met['8'], contains('rounds'),
        reason: 'a rat won in a round or two met no "few rounds" goal: $met');
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('a Tower fight and a lab test tick nothing', (tester) async {
    final tower = await fight(
        tester,
        const EncounterModifiers(
            chapter: 8,
            healthMultiplier: 0.02,
            difficultyMultiplier: 0.05,
            tower: true,
            forcedGoal: FightGoal.slay));
    expect(tower, isEmpty, reason: 'a Tower fight ticked a goal: $tower');
    final lab = await fight(
        tester,
        const EncounterModifiers(
            chapter: 8,
            healthMultiplier: 0.02,
            difficultyMultiplier: 0.05,
            isTest: true,
            forcedGoal: FightGoal.slay));
    expect(lab, isEmpty, reason: 'a lab test ticked a goal: $lab');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

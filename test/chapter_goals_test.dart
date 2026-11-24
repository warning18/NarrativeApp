// A chapter's goals and its chest (v2.5.0, Wave 4 brief 3, the user's
// option B): chapters 4 to 8 have three optional goals each; a fight won
// meets those it fits, once; the chest at the chapter's end is Wooden, Iron,
// Silver or Gold for 0 to 3 goals met, exactly that tier. Old saves start
// with none met.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/loot_box.dart';
import 'package:narrative_data_app/data/chapter_goals.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

ChapterFightFacts _won({
  int rounds = 6,
  int health = 80,
  List<String> foes = const ['slum_thug'],
  bool firstTry = true,
  int weakness = 0,
  bool potion = false,
}) =>
    ChapterFightFacts(
      won: true,
      rounds: rounds,
      healthLeft: health,
      maxHealth: 100,
      enemyIds: foes,
      firstTry: firstTry,
      weaknessHits: weakness,
      potionUsed: potion,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chapters 4 to 8 have three goals each, one of a kind', () {
    expect(chapterGoalTable.keys.toList()..sort(), [4, 5, 6, 7, 8]);
    final enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final MapEntry(key: chapter, value: goals)
        in chapterGoalTable.entries) {
      expect(goals, hasLength(3), reason: 'chapter $chapter');
      expect({for (final g in goals) g.id}, hasLength(3),
          reason: 'chapter $chapter: two goals of one kind');
      for (final g in goals) {
        if (g.kind == ChapterGoalKind.firstTry) {
          expect(g.bossIds, isNotEmpty);
          for (final id in g.bossIds) {
            expect(enemies, contains(id), reason: 'chapter $chapter: $id');
          }
        }
        if (g.kind == ChapterGoalKind.rounds) {
          expect(g.value, greaterThan(0));
        }
      }
    }
  });

  test('every goal and chest has its words, English and French', () {
    for (final lang in AppLanguage.values) {
      for (final MapEntry(key: chapter, value: goals)
          in chapterGoalTable.entries) {
        for (final g in goals) {
          final line = chapterGoalLine(lang, chapter, g);
          expect(line, isNot(startsWith('chapter_goal_')),
              reason: '$lang ch$chapter ${g.id}');
          expect(line, isNot(contains('{n}')));
        }
        expect(chapterChestLine(lang, chapter),
            isNot(startsWith('chapter_chest_')));
      }
      for (var met = 0; met <= 3; met++) {
        expect(chapterChestName(lang, met), isNot(startsWith('chapter_')));
      }
    }
    expect(chapterGoalLine(AppLanguage.en, 5, chapterGoalTable[5]!.first),
        contains('3'));
  });

  group('what a fight won meets', () {
    test('rounds: that many or fewer', () {
      const g = ChapterGoal(ChapterGoalKind.rounds, value: 3);
      expect(g.metBy(_won(rounds: 3)), isTrue);
      expect(g.metBy(_won(rounds: 4)), isFalse);
    });

    test('weakness: struck once with no count, else that many times', () {
      const g = ChapterGoal(ChapterGoalKind.weakness);
      expect(g.metBy(_won(weakness: 1)), isTrue);
      expect(g.metBy(_won()), isFalse);
      const three = ChapterGoal(ChapterGoalKind.weakness, value: 3);
      expect(three.metBy(_won(weakness: 2)), isFalse);
      expect(three.metBy(_won(weakness: 3)), isTrue);
      expect(three.metBy(_won(weakness: 5)), isTrue);
      expect(_won(weakness: 2).weaknessStruck, isTrue);
      expect(_won().weaknessStruck, isFalse);
    });

    test('weakness: chapters 4 to 6 ask 3 hits in one fight, 7 one', () {
      for (final chapter in [4, 5, 6]) {
        final g = chapterGoalTable[chapter]!
            .firstWhere((g) => g.kind == ChapterGoalKind.weakness);
        expect(g.weaknessHitsNeeded, 3, reason: 'chapter $chapter');
        expect(g.metBy(_won(weakness: 2)), isFalse);
        expect(g.metBy(_won(weakness: 3)), isTrue);
      }
      final ch7 = chapterGoalTable[7]!
          .firstWhere((g) => g.kind == ChapterGoalKind.weakness);
      expect(ch7.metBy(_won(weakness: 1)), isTrue);
    });

    test('first try: its boss, never beaten by it before', () {
      const g =
          ChapterGoal(ChapterGoalKind.firstTry, bossIds: {'void_sovereign'});
      expect(g.metBy(_won(foes: ['void_sovereign'])), isTrue);
      expect(g.metBy(_won(foes: ['void_sovereign'], firstTry: false)), isFalse);
      expect(g.metBy(_won(foes: ['tear_herald'])), isFalse);
    });

    test('no potion: a close fight, under half health, none drunk', () {
      const g = ChapterGoal(ChapterGoalKind.noPotion, value: 50);
      expect(g.metBy(_won(health: 40)), isTrue);
      expect(g.metBy(_won(health: 40, potion: true)), isFalse);
      expect(g.metBy(_won(health: 50)), isFalse);
    });

    test('a fight lost meets nothing', () {
      const lost =
          ChapterFightFacts(won: false, rounds: 1, healthLeft: 0, maxHealth: 9);
      for (final g in chapterGoalTable[5]!) {
        expect(g.metBy(lost), isFalse);
      }
    });
  });

  test('the chest: Wooden to Gold by goals met, exactly', () {
    expect([for (var n = 0; n <= 3; n++) chapterChestTier(n)],
        [ChestTier.wooden, ChestTier.iron, ChestTier.silver, ChestTier.gold]);
    final items =
        jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
            as Map<String, dynamic>;
    for (var met = 0; met <= 3; met++) {
      for (var seed = 0; seed < 40; seed++) {
        // A lucky hero still gets the chest its goals earned.
        final chest = rollChapterChest(
            chapter: 6, met: met, items: items, random: Random(seed), luck: 40);
        expect(chest.tier, chapterChestTier(met), reason: 'met $met, $seed');
      }
    }
  });

  test('the save: goals kept once, none after the chest, old saves empty',
      () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.loadSession(PlayerSession.fromJson(const {}));
    expect(notifier.state.chapterGoalsMet, isEmpty);
    final goals = chapterGoalTable[5]!;
    expect(
        await notifier.noteChapterGoals(5, goals, _won(rounds: 2)), ['rounds']);
    // Met already: not again.
    expect(await notifier.noteChapterGoals(5, goals, _won(rounds: 2)), isEmpty);
    expect(
        await notifier.noteChapterGoals(5, goals, _won(rounds: 2, weakness: 3)),
        ['weakness']);
    expect(notifier.chapterGoalsMetIn(5), ['rounds', 'weakness']);
    // Saved and read back.
    final back = PlayerSession.fromJson(
        jsonDecode(jsonEncode(notifier.state.toJson()))
            as Map<String, dynamic>);
    expect(back.chapterGoalsMet['5'], ['rounds', 'weakness']);
    await notifier.markChapterChestGiven(5);
    expect(
        await notifier.noteChapterGoals(5, goals, _won(health: 10)), isEmpty);
    expect(notifier.state.chapterChestsGiven, [5]);
  });

  test('the chest is owed as the next chapter starts, and given once',
      () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.loadSession(PlayerSession.fromJson(const {'gold': 0}));
    final items =
        jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
            as Map<String, dynamic>;
    // In chapter 4, nothing is owed; in chapter 5, chapter 4's chest.
    expect(notifier.chapterChestDue(4), isNull);
    expect(notifier.chapterChestDue(5), 4);
    await notifier.noteChapterGoals(4, chapterGoalTable[4]!, _won(rounds: 1));
    await notifier.noteChapterGoals(4, chapterGoalTable[4]!, _won(weakness: 3));
    final chest =
        await notifier.claimChapterChest(4, items: items, random: Random(3));
    expect(chest, isNotNull);
    expect(chest!.tier, ChestTier.silver);
    expect(notifier.state.gold, chest.gold);
    expect(notifier.state.chapterChestsGiven, [4]);
    expect(notifier.chapterChestDue(5), isNull);
    expect(await notifier.claimChapterChest(4, items: items, random: Random(3)),
        isNull);
    // Past the last chapter (the ending): chapters 5 to 8 owed in turn.
    expect(notifier.chapterChestDue(9), 5);
  });
}

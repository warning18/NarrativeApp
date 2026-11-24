// A chapter's optional goals and its chest (v2.5.0, Wave 4 brief 3 of
// docs/simulation/wave4-briefs.md, the user's option B): each chapter lists
// three goals (assets/gamedata/chapter_goals.json); every goal met in the
// chapter makes the chest given at its end one tier better, Wooden with
// none met to Gold with all three. Missing them costs nothing: no clock,
// no streak. The boss's own chest is untouched.
//
// A goal is read off a fight won ([ChapterFightFacts]), the same way in the
// fight screen and in the playthrough simulator, so the rates the goals
// were picked by (30 to 70% of runs each) are the game's.

import 'dart:math';

import '../combat/loot_box.dart';

/// What a goal asks of one fight won.
enum ChapterGoalKind {
  /// Won in [ChapterGoal.value] rounds or fewer.
  swift,

  /// Won with the hero at [ChapterGoal.value]% of max health or more.
  unhurt,

  /// A boss of the chapter beaten on the first try.
  bossFirstTry,

  /// Won with a face of the die in play striking a foe's weakness.
  weakness,
}

/// One goal: its id (the key of its words in app_strings, `goal_<id>`),
/// what it asks and its number (rounds, or a share of health).
class ChapterGoal {
  const ChapterGoal(this.id, this.kind, [this.value = 0]);

  factory ChapterGoal.fromJson(Map<String, dynamic> json) => ChapterGoal(
        json['id'].toString(),
        ChapterGoalKind.values.byName(json['kind'].toString()),
        (json['value'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final ChapterGoalKind kind;
  final int value;

  /// Whether the fight won described by [facts] meets this goal.
  bool metBy(ChapterFightFacts facts) {
    if (!facts.won) return false;
    switch (kind) {
      case ChapterGoalKind.swift:
        return facts.rounds <= value;
      case ChapterGoalKind.unhurt:
        return facts.maxHealth > 0 &&
            facts.healthLeft * 100 >= value * facts.maxHealth;
      case ChapterGoalKind.bossFirstTry:
        return facts.boss && facts.firstTry;
      case ChapterGoalKind.weakness:
        return facts.weaknessStruck;
    }
  }
}

/// What a goal reads of a fight.
class ChapterFightFacts {
  const ChapterFightFacts({
    required this.won,
    required this.rounds,
    required this.healthLeft,
    required this.maxHealth,
    this.boss = false,
    this.firstTry = true,
    this.weaknessStruck = false,
  });

  final bool won;
  final int rounds;

  /// The hero's health after the fight, and its max.
  final int healthLeft;
  final int maxHealth;

  /// A boss among the foes, and no earlier try lost against it.
  final bool boss;
  final bool firstTry;

  /// A face of the die in play struck a foe's weakness.
  final bool weaknessStruck;
}

/// Each chapter's three goals, picked so each is met by 30 to 70% of the
/// simulator's runs (docs/simulation/chapter-goals.md).
const Map<int, List<ChapterGoal>> chapterGoalTable = {};

/// chapter_goals.json: chapter number (as a string) -> its goals.
Map<int, List<ChapterGoal>> chapterGoalsFrom(Map<String, dynamic> table) => {
      for (final MapEntry(:key, :value) in table.entries)
        if (int.tryParse(key) case final chapter? when value is List)
          chapter: [
            for (final g in value)
              if (g is Map) ChapterGoal.fromJson(g.cast<String, dynamic>()),
          ],
    };

/// The ids of [goals] newly met by [facts], beyond those of [met].
List<String> chapterGoalsNewlyMet(List<ChapterGoal> goals, Iterable<String> met,
        ChapterFightFacts facts) =>
    [
      for (final g in goals)
        if (!met.contains(g.id) && g.metBy(facts)) g.id,
    ];

/// The chapter chest's tier for [met] goals of the chapter's three:
/// Wooden, Iron, Silver, Gold.
ChestTier chapterChestTier(int met) =>
    ChestTier.values[met.clamp(0, ChestTier.gold.index)];

/// The chapter chest of [chapter] with [met] goals met: the story's chest
/// (rollLootBox) held at exactly [chapterChestTier] (its floor and its
/// ceiling), for a hero of [luck].
LootBoxResult rollChapterChest({
  required int chapter,
  required int met,
  required Map<String, dynamic> items,
  required Random random,
  int luck = 0,
  String preferredScalingStat = '',
  List<String> ownedItemIds = const [],
}) {
  final tier = chapterChestTier(met);
  return rollLootBox(
    LootContext(
      chapter: chapter,
      playerLuck: luck,
      tierFloor: tier,
      tierCeiling: tier,
      preferredScalingStat: preferredScalingStat,
      ownedItemIds: ownedItemIds,
    ),
    items,
    random,
  );
}

// A chapter's optional goals and its chest (v2.5.0, Wave 4 brief 3 of
// docs/simulation/wave4-briefs.md, the user's option B): chapters 4 to 8
// list three goals each ([chapterGoalTable]); every goal met in the
// chapter makes the chest given at its end one tier better, Wooden with
// none met to Gold with all three. Missing them costs nothing: no clock,
// no streak. The boss's own chest is untouched.
//
// A goal is read off a fight won ([ChapterFightFacts]), the same way in the
// fight screen and in the playthrough simulator, so the rates the goals
// were picked by (30 to 70% of runs each) are the game's.

import 'dart:math';

import '../combat/loot_box.dart';
import '../l10n/app_locale.dart' show AppLanguage;
import '../l10n/app_strings.dart' show hasStringKey, trFor;

/// What a goal asks of one fight won (its words: `chapter_goal_<key>`,
/// and `chapter_goal_<key>_ch<N>` for a chapter's own line).
enum ChapterGoalKind {
  /// Won in [ChapterGoal.value] rounds or fewer.
  rounds('rounds'),

  /// Won with a die striking a foe's weakness.
  weakness('weakness'),

  /// One of [ChapterGoal.bossIds] beaten with no try lost to it before.
  firstTry('first_try'),

  /// A close fight won without a potion: no potion drunk, and the hero left
  /// under [ChapterGoal.value]% of max health.
  noPotion('no_potion');

  const ChapterGoalKind(this.key);

  /// The key of its words.
  final String key;
}

/// One goal: what it asks, its number (rounds, or a share of health) and,
/// for [ChapterGoalKind.firstTry], the bosses it means.
class ChapterGoal {
  const ChapterGoal(this.kind, {this.value = 0, this.bossIds = const {}});

  final ChapterGoalKind kind;
  final int value;
  final Set<String> bossIds;

  /// Its id in the save: one goal of each kind a chapter.
  String get id => kind.key;

  /// Whether the fight won described by [facts] meets this goal.
  bool metBy(ChapterFightFacts facts) {
    if (!facts.won) return false;
    switch (kind) {
      case ChapterGoalKind.rounds:
        return facts.rounds <= value;
      case ChapterGoalKind.weakness:
        return facts.weaknessStruck;
      case ChapterGoalKind.firstTry:
        return facts.firstTry && facts.enemyIds.any(bossIds.contains);
      case ChapterGoalKind.noPotion:
        return !facts.potionUsed &&
            facts.maxHealth > 0 &&
            facts.healthLeft * 100 < value * facts.maxHealth;
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
    this.enemyIds = const [],
    this.firstTry = true,
    this.weaknessStruck = false,
    this.potionUsed = false,
  });

  final bool won;
  final int rounds;

  /// The hero's health after the fight, and its max.
  final int healthLeft;
  final int maxHealth;

  /// The foes beaten, and whether none of them had beaten the party before.
  final List<String> enemyIds;
  final bool firstTry;

  /// A die struck a foe's weakness in the fight.
  final bool weaknessStruck;

  /// A potion was drunk in the fight.
  final bool potionUsed;
}

/// Each chapter's three goals (4 to 8), picked so each is met by about 30
/// to 70% of the simulator's runs (100 typical + 100 competent, v2.1.5;
/// docs/simulation/chapter-goals.md). Chapter 7, the short one, keeps its
/// duel: the rival claimant beaten first time is the likeliest of all.
const Map<int, List<ChapterGoal>> chapterGoalTable = {
  4: [
    ChapterGoal(ChapterGoalKind.rounds, value: 2),
    ChapterGoal(ChapterGoalKind.weakness),
    ChapterGoal(ChapterGoalKind.noPotion, value: 50),
  ],
  5: [
    ChapterGoal(ChapterGoalKind.rounds, value: 3),
    ChapterGoal(ChapterGoalKind.weakness),
    ChapterGoal(ChapterGoalKind.noPotion, value: 50),
  ],
  6: [
    ChapterGoal(ChapterGoalKind.rounds, value: 3),
    ChapterGoal(ChapterGoalKind.weakness),
    ChapterGoal(ChapterGoalKind.noPotion, value: 50),
  ],
  7: [
    ChapterGoal(ChapterGoalKind.rounds, value: 4),
    ChapterGoal(ChapterGoalKind.weakness),
    ChapterGoal(ChapterGoalKind.firstTry,
        bossIds: {'claimant_tallis', 'claimant_morrow', 'claimant_vane'}),
  ],
  8: [
    ChapterGoal(ChapterGoalKind.rounds, value: 4),
    ChapterGoal(ChapterGoalKind.firstTry, bossIds: {'void_sovereign'}),
    ChapterGoal(ChapterGoalKind.noPotion, value: 50),
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

/// [goal]'s line for [chapter] in [language] (Narrative's words): the
/// chapter's own line when it has one, else the kind's; `{n}` is its value.
String chapterGoalLine(AppLanguage language, int chapter, ChapterGoal goal) {
  final own = 'chapter_goal_${goal.kind.key}_ch$chapter';
  final key = hasStringKey(own) ? own : 'chapter_goal_${goal.kind.key}';
  return trFor(language, key).replaceAll('{n}', '${goal.value}');
}

/// The chapter chest's name for [met] goals ("Silver Chapter Chest").
String chapterChestName(AppLanguage language, int met) =>
    trFor(language, 'chapter_chest_${chapterChestTier(met).name}');

/// The line as [chapter]'s chest opens.
String chapterChestLine(AppLanguage language, int chapter) {
  final own = 'chapter_chest_line_ch$chapter';
  return trFor(language, hasStringKey(own) ? own : 'chapter_chest_line');
}

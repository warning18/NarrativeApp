import 'dart:math';

import '../models/story_node.dart';
import 'map_themes.dart';

/// Generates short chains of procedural "excursion" nodes inserted between
/// the fixed main story beats — a shop visit, an enemy encounter, a quest
/// pickup, a small treasure find, a moment of rest, or a bit of ambient
/// flavor. If a quest pickup is rolled, the chain is lengthened to 4-7
/// nodes to represent that quest's own mini-arc; otherwise it's a short
/// 1-3 node detour. The wording of these excursions comes from [theme]
/// (see map_themes.dart) — the main story beats themselves never change,
/// only the flavor of what happens between them.
class SubNodeEngine {
  static int _counter = 0;

  /// Returns null when no excursion is rolled this time.
  static List<StoryNode>? maybeGenerate({
    required Random random,
    required int chapter,
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
    required Map<String, dynamic> quests,
    required List<String> unlockedShopIds,
    required List<String> unlockedEnemyIds,
    required List<String> unlockedQuestIds,
    required List<String> completedQuestIds,
    MapTheme theme = defaultMapTheme,
    double triggerChance = 0.7,
  }) {
    if (random.nextDouble() > triggerChance) return null;

    final flavor = flavorFor(theme);

    final shopPool = shops.keys.where((id) => !unlockedShopIds.contains(id)).toList();
    // Unfiltered, this could roll a late-game enemy (e.g. a 230hp/27dmg
    // chapter-5 monster) into the very first chapter-1 excursion -- an
    // unwinnable fight for a level-1 character with no way to decline it
    // and no way to progress past it. minChapter (see enemies.json) caps
    // the pool to enemies the main story has already introduced by now.
    final enemyPool = enemies.entries
        .where((e) => !unlockedEnemyIds.contains(e.key))
        .where((e) {
          final minChapter =
              ((e.value as Map<String, dynamic>)['minChapter'] as num?)?.toInt() ?? 1;
          return minChapter <= chapter;
        })
        .map((e) => e.key)
        .toList();
    // A quest already completed shouldn't come back around in a later
    // excursion -- questIDToProgress (the main-path way into a quest) only
    // ever adds to activeQuestIds, never unlockedQuestIds, so that alone
    // isn't enough to keep a finished quest out of this pool.
    final questPool = quests.entries
        .where((e) {
          final q = e.value as Map<String, dynamic>;
          final questChapter = (q['chapter'] as num?)?.toInt() ?? 1;
          return questChapter == chapter &&
              !unlockedQuestIds.contains(e.key) &&
              !completedQuestIds.contains(e.key);
        })
        .map((e) => e.key)
        .toList();

    final includeQuest = questPool.isNotEmpty && random.nextDouble() < 0.35;
    final length = includeQuest ? 4 + random.nextInt(4) : 1 + random.nextInt(3);
    // A companion-recruit quest (rewardAllyId set) that's still eligible
    // this chapter is a second chance at a companion the player didn't
    // pick at their one-shot recruitment hub (e.g. node 2015's Kelda-vs-
    // Sable choice) -- worth surfacing over an ordinary side quest instead
    // of leaving it to compete equally in the full pool.
    final recruitQuestPool = questPool.where((id) {
      final rewardAllyId = (quests[id] as Map<String, dynamic>?)?['rewardAllyId']?.toString();
      return rewardAllyId != null && rewardAllyId.isNotEmpty;
    }).toList();
    final questSlotId = !includeQuest
        ? null
        : recruitQuestPool.isNotEmpty
            ? (recruitQuestPool..shuffle(random)).first
            : (questPool..shuffle(random)).first;

    return [
      for (var i = 0; i < length; i++)
        buildNode(
          random: random,
          flavor: flavor,
          shopPool: shopPool,
          enemyPool: enemyPool,
          questId: i == 0 ? questSlotId : null,
        ),
    ];
  }

  /// Builds a single typed flavor-pool node (shop/enemy/treasure/rest/quest,
  /// or a plain generic beat if none of those roll) — the same weighted
  /// draw [maybeGenerate] chains together for excursions, exposed on its
  /// own so other callers (e.g. the expedition system) can draw one event
  /// at a time from the same themed pools instead of a whole chain.
  static StoryNode buildNode({
    required Random random,
    required ExcursionFlavor flavor,
    required List<String> shopPool,
    required List<String> enemyPool,
    String? questId,
  }) {
    _counter++;
    final id = 'gen_$_counter';

    if (questId != null) {
      final idx = random.nextInt(flavor.quest.length);
      return StoryNode(
        id: id,
        description: flavor.quest[idx],
        descriptionFr: flavor.questFr[idx],
        choices: [
          StoryChoice(
            text: 'Take the job',
            textFr: 'Accepter le travail',
            nextId: id,
            unlockQuestId: questId,
          ),
        ],
      );
    }

    final roll = random.nextDouble();
    if (shopPool.isNotEmpty && roll < 0.25) {
      final shopId = shopPool[random.nextInt(shopPool.length)];
      final idx = random.nextInt(flavor.shop.length);
      return StoryNode(
        id: id,
        description: flavor.shop[idx],
        descriptionFr: flavor.shopFr[idx],
        choices: [
          StoryChoice(
            text: 'Take a look',
            textFr: 'Jeter un œil',
            nextId: id,
            unlockShopId: shopId,
          ),
        ],
      );
    }
    if (enemyPool.isNotEmpty && roll < 0.5) {
      final enemyId = enemyPool[random.nextInt(enemyPool.length)];
      final idx = random.nextInt(flavor.enemy.length);
      return StoryNode(
        id: id,
        description: flavor.enemy[idx],
        descriptionFr: flavor.enemyFr[idx],
        choices: [
          StoryChoice(
            text: 'Fight',
            textFr: 'Combattre',
            nextId: id,
            triggerEnemyId: enemyId,
          ),
        ],
      );
    }
    if (roll < 0.65) {
      final goldFound = 5 + random.nextInt(16);
      final idx = random.nextInt(flavor.treasure.length);
      return StoryNode(
        id: id,
        description: flavor.treasure[idx],
        descriptionFr: flavor.treasureFr[idx],
        choices: [
          StoryChoice(
            text: 'Take it ($goldFound gold)',
            textFr: 'Le prendre ($goldFound or)',
            nextId: id,
            goldMod: goldFound,
          ),
        ],
      );
    }
    if (roll < 0.8) {
      final idx = random.nextInt(flavor.rest.length);
      return StoryNode(
        id: id,
        description: flavor.rest[idx],
        descriptionFr: flavor.restFr[idx],
        choices: const [
          StoryChoice(text: 'Rest a while', textFr: 'Se reposer un moment', nextId: '', healAmount: 20),
        ],
      );
    }
    final idx = random.nextInt(flavor.generic.length);
    return StoryNode(
      id: id,
      description: flavor.generic[idx],
      descriptionFr: flavor.genericFr[idx],
      choices: const [
        StoryChoice(text: 'Move on', textFr: 'Continuer', nextId: ''),
      ],
    );
  }
}

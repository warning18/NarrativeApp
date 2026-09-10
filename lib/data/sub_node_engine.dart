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
    MapTheme theme = defaultMapTheme,
    double triggerChance = 0.7,
  }) {
    if (random.nextDouble() > triggerChance) return null;

    final flavor = flavorFor(theme);

    final shopPool = shops.keys.where((id) => !unlockedShopIds.contains(id)).toList();
    final enemyPool = enemies.keys.where((id) => !unlockedEnemyIds.contains(id)).toList();
    final questPool = quests.entries
        .where((e) {
          final q = e.value as Map<String, dynamic>;
          final questChapter = (q['chapter'] as num?)?.toInt() ?? 1;
          return questChapter == chapter && !unlockedQuestIds.contains(e.key);
        })
        .map((e) => e.key)
        .toList();

    final includeQuest = questPool.isNotEmpty && random.nextDouble() < 0.35;
    final length = includeQuest ? 4 + random.nextInt(4) : 1 + random.nextInt(3);
    final questSlotId = includeQuest ? (questPool..shuffle(random)).first : null;

    return [
      for (var i = 0; i < length; i++)
        _buildNode(
          random: random,
          flavor: flavor,
          shopPool: shopPool,
          enemyPool: enemyPool,
          questId: i == 0 ? questSlotId : null,
        ),
    ];
  }

  static StoryNode _buildNode({
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

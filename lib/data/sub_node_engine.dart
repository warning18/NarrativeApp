import 'dart:math';

import '../models/story_node.dart';

/// Generates short chains of procedural "excursion" nodes inserted between
/// the fixed main story beats — a shop visit, an enemy encounter, a quest
/// pickup, or a bit of ambient flavor. If a quest pickup is rolled, the
/// chain is lengthened to 4-7 nodes to represent that quest's own mini-arc;
/// otherwise it's a short 1-3 node detour.
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
    double triggerChance = 0.7,
  }) {
    if (random.nextDouble() > triggerChance) return null;

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
          shopPool: shopPool,
          enemyPool: enemyPool,
          questId: i == 0 ? questSlotId : null,
        ),
    ];
  }

  static StoryNode _buildNode({
    required Random random,
    required List<String> shopPool,
    required List<String> enemyPool,
    String? questId,
  }) {
    _counter++;
    final id = 'gen_$_counter';

    if (questId != null) {
      return StoryNode(
        id: id,
        description: _pick(random, _questFlavor),
        choices: [
          StoryChoice(text: 'Take the job', nextId: id, unlockQuestId: questId),
        ],
      );
    }

    final roll = random.nextDouble();
    if (shopPool.isNotEmpty && roll < 0.35) {
      final shopId = shopPool[random.nextInt(shopPool.length)];
      return StoryNode(
        id: id,
        description: _pick(random, _shopFlavor),
        choices: [
          StoryChoice(text: 'Take a look', nextId: id, unlockShopId: shopId),
        ],
      );
    }
    if (enemyPool.isNotEmpty && roll < 0.7) {
      final enemyId = enemyPool[random.nextInt(enemyPool.length)];
      return StoryNode(
        id: id,
        description: _pick(random, _enemyFlavor),
        choices: [
          StoryChoice(text: 'Fight', nextId: id, triggerEnemyId: enemyId),
        ],
      );
    }
    return StoryNode(
      id: id,
      description: _pick(random, _genericFlavor),
      choices: const [
        StoryChoice(text: 'Move on', nextId: ''),
      ],
    );
  }

  static String _pick(Random random, List<String> options) =>
      options[random.nextInt(options.length)];

  static const List<String> _shopFlavor = [
    'A stall has been set up in a doorway, its owner watching the street more than the goods.',
    'Someone has laid out wares on a cart, calling out to anyone who passes.',
    'A shopfront, half-boarded, is still somehow open for business.',
    'Lantern light spills from a half-hidden storefront tucked between the ruins.',
  ];

  static const List<String> _enemyFlavor = [
    'Something moves in the shadows ahead, blocking the only clear path.',
    'A figure steps out, weapon already drawn.',
    'A low growl rises from the debris just off the path.',
    'Footsteps close in fast from behind — there is no time to think.',
  ];

  static const List<String> _questFlavor = [
    'Someone catches your sleeve, desperate and low-voiced, with a job that needs doing.',
    'A notice is nailed to a post, offering coin for a task nobody else wants.',
    'A stranger falls into step beside you, explaining what they need before you can refuse.',
    'A voice from an alley asks — carefully — if you are willing to help.',
  ];

  static const List<String> _genericFlavor = [
    'The path continues, quiet for now.',
    'Nothing moves here but the wind through broken shutters.',
    'A moment of stillness before the road presses on.',
    'The street is empty, save for the echo of your own footsteps.',
  ];
}

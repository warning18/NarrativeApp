import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../utils/game_icons.dart';
import '../widgets/player_stats_bar.dart';
import 'character_screen.dart';
import 'fight_screen.dart';
import 'shop_detail_screen.dart';

class PlayScreen extends ConsumerWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final questsAsync = ref.watch(gameDbProvider(questsSchema));
    final shopsAsync = ref.watch(gameDbProvider(shopsSchema));
    final enemiesAsync = ref.watch(gameDbProvider(enemiesSchema));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PlayerStatsBar(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Player Session', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: () async {
                await ref.read(playerSessionProvider.notifier).resetSession();
                ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Character'),
            subtitle: Text(
              'Lvl ${session.level} · ${session.inventoryItemIds.length} item(s) · '
              '${session.skillPoints} skill pt(s) · ${session.statPoints} stat pt(s)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CharacterScreen()),
              );
            },
          ),
        ),
        const Divider(height: 32),
        Text('Quests', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        questsAsync.when(
          data: (records) => _QuestList(records: records),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Failed to load quests: $error'),
        ),
        const Divider(height: 32),
        Text('Shops', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        shopsAsync.when(
          data: (records) => _ShopList(records: records),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Failed to load shops: $error'),
        ),
        const Divider(height: 32),
        Text('Bestiary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        enemiesAsync.when(
          data: (records) => _EnemyList(records: records),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Failed to load enemies: $error'),
        ),
      ],
    );
  }
}

class _QuestList extends ConsumerWidget {
  const _QuestList({required this.records});

  final Map<String, dynamic> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return const Text('No quests defined yet.');
    }
    final session = ref.watch(playerSessionProvider);
    final keys = records.keys.toList()..sort();

    return Column(
      children: keys.map((questId) {
        final quest = records[questId] as Map<String, dynamic>;
        final questName = quest['questName']?.toString() ?? questId;
        final category = quest['category']?.toString();
        final dialogue = quest['npcDialogueText']?.toString() ?? '';
        final isCompleted = session.completedQuestIds.contains(questId);
        final isActive = session.activeQuestIds.contains(questId);
        final isDiscovered =
            isCompleted || isActive || session.unlockedQuestIds.contains(questId);
        final requiredGold = (quest['requiredGold'] as num?)?.toInt() ?? 0;
        final requiredFlags =
            (quest['requiredFlags'] as List?)?.map((e) => e.toString()).toList() ?? const [];
        final meetsRequirements =
            session.meetsRequirements(reqGold: requiredGold, reqFlags: requiredFlags);

        String statusLabel;
        if (isCompleted) {
          statusLabel = 'Completed';
        } else if (isActive) {
          statusLabel = 'Active';
        } else if (!isDiscovered) {
          statusLabel = 'Undiscovered';
        } else if (!meetsRequirements) {
          statusLabel = 'Locked';
        } else {
          statusLabel = 'Available';
        }

        Widget trailing;
        if (isCompleted) {
          trailing = const Icon(Icons.check_circle, color: Colors.green);
        } else if (!isDiscovered) {
          trailing = const Icon(Icons.lock_outline);
        } else if (isActive) {
          trailing = ElevatedButton(
            onPressed: () async {
              final rewardGold = (quest['rewardGold'] as num?)?.toInt() ?? 0;
              final rewardXp = (quest['rewardXP'] as num?)?.toInt() ?? 0;
              final rewardItemId = quest['rewardItemID']?.toString();
              final nextQuestId = quest['nextQuestID']?.toString();
              final rewardDiceId = quest['rewardDiceID']?.toString();
              await ref.read(playerSessionProvider.notifier).completeQuest(
                    questId,
                    rewardGold: rewardGold,
                    rewardItemId: rewardItemId,
                    nextQuestId: nextQuestId,
                    rewardDiceId: rewardDiceId,
                  );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Quest complete: $questName (+$rewardGold gold, +$rewardXp XP'
                    '${rewardItemId != null && rewardItemId.isNotEmpty ? ", +$rewardItemId" : ""}'
                    '${rewardDiceId != null && rewardDiceId.isNotEmpty ? ", +$rewardDiceId" : ""})',
                  ),
                ),
              );
            },
            child: const Text('Complete'),
          );
        } else {
          trailing = ElevatedButton(
            onPressed: !meetsRequirements
                ? null
                : () async {
                    await ref.read(playerSessionProvider.notifier).acceptQuest(questId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Quest accepted: $questName')),
                    );
                  },
            child: const Text('Accept'),
          );
        }

        return Card(
          child: ListTile(
            leading: Icon(questCategoryIcon(category)),
            title: Text(questName),
            subtitle: Text(
              dialogue.isNotEmpty ? '$dialogue\nStatus: $statusLabel' : 'Status: $statusLabel',
            ),
            isThreeLine: dialogue.isNotEmpty,
            trailing: trailing,
          ),
        );
      }).toList(),
    );
  }
}

class _ShopList extends ConsumerWidget {
  const _ShopList({required this.records});

  final Map<String, dynamic> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return const Text('No shops defined yet.');
    }
    final session = ref.watch(playerSessionProvider);
    final keys = records.keys.toList()..sort();

    return Column(
      children: keys.map((shopId) {
        final shop = records[shopId] as Map<String, dynamic>;
        final shopName = shop['shopName']?.toString() ?? shopId;
        final accessible = session.unlockedShopIds.contains(shopId);
        return Card(
          child: ListTile(
            leading: Icon(accessible ? shopIcon : Icons.lock_outline),
            title: Text(shopName),
            subtitle: Text(
              accessible
                  ? shop['shopDescription']?.toString() ?? ''
                  : 'Undiscovered — find this shop during the story.',
            ),
            trailing: accessible ? const Icon(Icons.chevron_right) : null,
            onTap: !accessible
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopDetailScreen(shopId: shopId, shop: shop),
                      ),
                    );
                  },
          ),
        );
      }).toList(),
    );
  }
}

class _EnemyList extends ConsumerWidget {
  const _EnemyList({required this.records});

  final Map<String, dynamic> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return const Text('No enemies defined yet.');
    }
    final session = ref.watch(playerSessionProvider);
    final keys = records.keys.toList()..sort();

    return Column(
      children: keys.map((enemyId) {
        final enemy = records[enemyId] as Map<String, dynamic>;
        final enemyName = enemy['enemyName']?.toString() ?? enemyId;
        final maxHealth = (enemy['maxHealth'] as num?)?.toInt() ?? 0;
        final damage = (enemy['damage'] as num?)?.toInt() ?? 0;
        final accessible = session.unlockedEnemyIds.contains(enemyId);
        return Card(
          child: ListTile(
            leading: Icon(accessible ? enemyIcon : Icons.lock_outline),
            title: Text(enemyName),
            subtitle: Text(
              accessible ? 'HP $maxHealth · Damage $damage' : 'Not yet encountered.',
            ),
            trailing: !accessible
                ? null
                : ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FightScreen(enemyId: enemyId, enemy: enemy),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sports_martial_arts),
                    label: const Text('Fight'),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

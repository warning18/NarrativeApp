import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../models/story_node.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../widgets/player_stats_bar.dart';
import 'fight_screen.dart';

class StoryPlayerScreen extends ConsumerWidget {
  const StoryPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDataProvider);

    return storyAsync.when(
      data: (story) => _StoryView(story: story),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load story: $error'),
        ),
      ),
    );
  }
}

class _StoryView extends ConsumerWidget {
  const _StoryView({required this.story});

  final StoryData story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playState = ref.watch(storyPlayProvider);
    final notifier = ref.read(storyPlayProvider.notifier);
    final session = ref.watch(playerSessionProvider);
    final node = story.nodeFor(playState.currentNodeId);

    if (node == null) {
      return _EndingView(
        title: 'The trail goes cold',
        message: 'This path leads nowhere in the current story data.',
        onRestart: () => notifier.restart(StoryRepository.startNodeId),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PlayerStatsBar(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (playState.history.isNotEmpty)
                  TextButton.icon(
                    onPressed: notifier.goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                const Spacer(),
                Text(
                  'Node ${node.id}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  node.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (node.choices.isEmpty)
              _EndingView(
                title: 'The End',
                message: 'You have reached the end of this branch.',
                onRestart: () => notifier.restart(StoryRepository.startNodeId),
              )
            else
              ...node.choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChoiceButton(choice: choice, story: story, session: session),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends ConsumerWidget {
  const _ChoiceButton({required this.choice, required this.story, required this.session});

  final StoryChoice choice;
  final StoryData story;
  final PlayerSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetNode = choice.isEnding ? null : story.nodeFor(choice.nextId);
    final locked = targetNode != null &&
        targetNode.hasRequirements &&
        !session.meetsRequirements(
          reqGold: targetNode.reqGold,
          reqAlignmentScore: targetNode.reqAlignmentScore,
          reqFlags: targetNode.reqFlags,
        );

    final label = locked && (choice.lockedText?.isNotEmpty ?? false)
        ? choice.lockedText!
        : choice.text;

    if (choice.triggersCombat) {
      // Keep the enemies database warm so it's ready by the time this
      // button is tapped.
      ref.watch(gameDbProvider(enemiesSchema));
    }

    return ElevatedButton(
      onPressed: locked
          ? null
          : () async {
              if (choice.triggersCombat) {
                final enemies = ref.read(gameDbProvider(enemiesSchema)).value;
                final enemy = enemies?[choice.triggerEnemyId] as Map<String, dynamic>?;
                if (enemy != null) {
                  final won = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => FightScreen(
                        enemyId: choice.triggerEnemyId!,
                        enemy: enemy,
                      ),
                    ),
                  );
                  if (won != true) return;
                }
              }

              final playNotifier = ref.read(storyPlayProvider.notifier);
              if (choice.hasEffects) {
                ref.read(playerSessionProvider.notifier).applyChoiceEffects(
                      goldMod: choice.goldMod,
                      alignmentMod: choice.alignmentMod,
                      flagsToAdd: choice.flagsToAdd,
                      questIDToProgress: choice.questIDToProgress,
                    );
              }
              if (choice.hasUnlocks) {
                ref.read(playerSessionProvider.notifier).unlockContent(
                      shopId: choice.unlockShopId,
                      questId: choice.unlockQuestId,
                      enemyId: choice.triggerEnemyId,
                    );
              }
              if (choice.isEnding) {
                playNotifier.restart(StoryRepository.startNodeId);
              } else {
                playNotifier.choose(choice.nextId);
              }
            },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
    );
  }
}

class _EndingView extends StatelessWidget {
  const _EndingView({
    required this.title,
    required this.message,
    required this.onRestart,
  });

  final String title;
  final String message;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRestart,
              child: const Text('Restart Story'),
            ),
          ],
        ),
      ),
    );
  }
}

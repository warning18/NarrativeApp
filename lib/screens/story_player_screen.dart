import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_spine.dart';
import '../data/story_repository.dart';
import '../data/sub_node_engine.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../widgets/player_stats_bar.dart';
import 'fight_screen.dart';
import 'race_profession_screen.dart';

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
    final node = playState.activeExcursionNode ?? story.nodeFor(playState.currentNodeId);
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;

    if (node == null) {
      return _EndingView(
        title: tr(ref, 'trail_cold_title'),
        message: tr(ref, 'trail_cold_message'),
        restartLabel: tr(ref, 'restart_story'),
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
                if (playState.history.isNotEmpty && !playState.isInExcursion)
                  TextButton.icon(
                    onPressed: notifier.goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(tr(ref, 'back')),
                  ),
                const Spacer(),
                Text(
                  playState.isInExcursion ? tr(ref, 'detour') : '${tr(ref, 'node')} ${node.id}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  node.descriptionFor(french),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (node.choices.isEmpty)
              _EndingView(
                title: tr(ref, 'the_end'),
                message: tr(ref, 'branch_end_message'),
                restartLabel: tr(ref, 'restart_story'),
                onRestart: () => notifier.restart(StoryRepository.startNodeId),
              )
            else
              ...node.choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChoiceButton(
                    choice: choice,
                    story: story,
                    session: session,
                    currentNodeId: playState.currentNodeId,
                    isExcursion: playState.isInExcursion,
                    french: french,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends ConsumerWidget {
  const _ChoiceButton({
    required this.choice,
    required this.story,
    required this.session,
    required this.currentNodeId,
    required this.isExcursion,
    required this.french,
  });

  final StoryChoice choice;
  final StoryData story;
  final PlayerSession session;
  final String currentNodeId;
  final bool isExcursion;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetNode =
        (isExcursion || choice.isEnding) ? null : story.nodeFor(choice.nextId);
    final locked = targetNode != null &&
        targetNode.hasRequirements &&
        !session.meetsRequirements(
          reqGold: targetNode.reqGold,
          reqAlignmentScore: targetNode.reqAlignmentScore,
          reqFlags: targetNode.reqFlags,
        );

    final label = locked && (choice.lockedText?.isNotEmpty ?? false)
        ? choice.lockedText!
        : choice.textFor(french);

    if (choice.triggersCombat) {
      // Keep the enemies database warm so it's ready by the time this
      // button is tapped.
      ref.watch(gameDbProvider(enemiesSchema));
    }

    return ElevatedButton(
      onPressed: locked
          ? null
          : () async {
              if (choice.opensCharacterCreation) {
                await ref.read(playerSessionProvider.notifier).resetSession();
                if (!context.mounted) return;
                final started = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const RaceProfessionScreen()),
                );
                if (started != true) return;
              }

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

              if (isExcursion) {
                playNotifier.advanceExcursion();
                return;
              }

              if (choice.isEnding) {
                playNotifier.restart(StoryRepository.startNodeId);
                return;
              }

              final chapter = chapterForNode(currentNodeId);
              if (chapter != null && !choice.opensCharacterCreation) {
                final shops = ref.read(gameDbProvider(shopsSchema)).value ?? const {};
                final enemies = ref.read(gameDbProvider(enemiesSchema)).value ?? const {};
                final quests = ref.read(gameDbProvider(questsSchema)).value ?? const {};
                final excursion = SubNodeEngine.maybeGenerate(
                  random: Random(),
                  chapter: chapter,
                  shops: shops,
                  enemies: enemies,
                  quests: quests,
                  unlockedShopIds: session.unlockedShopIds,
                  unlockedEnemyIds: session.unlockedEnemyIds,
                  unlockedQuestIds: session.unlockedQuestIds,
                );
                if (excursion != null) {
                  playNotifier.startExcursion(excursion, choice.nextId);
                  return;
                }
              }
              playNotifier.choose(choice.nextId);
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
    required this.restartLabel,
    required this.onRestart,
  });

  final String title;
  final String message;
  final String restartLabel;
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
              child: Text(restartLabel),
            ),
          ],
        ),
      ),
    );
  }
}

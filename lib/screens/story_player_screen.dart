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
import '../providers/app_mode_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_theme_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../providers/tts_provider.dart';
import '../providers/walk_companion_provider.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/walking_companion_strip.dart';
import 'fight_screen.dart';
import 'race_profession_screen.dart';
import 'shop_detail_screen.dart';
import 'story_node_editor_screen.dart';

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
          child: Text('${tr(ref, 'failed_to_load_story')}: $error'),
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
    final language = ref.watch(appLanguageProvider);
    final french = language == AppLanguage.fr;
    final walkCompanionEnabled = ref.watch(walkCompanionEnabledProvider);

    // Stop any in-progress narration when the story moves to a different
    // node, so stale audio never plays over newly-displayed text.
    ref.listen<StoryPlayState>(storyPlayProvider, (previous, next) {
      final prevId = previous?.activeExcursionNode?.id ?? previous?.currentNodeId;
      final nextId = next.activeExcursionNode?.id ?? next.currentNodeId;
      if (prevId != nextId) {
        ref.read(ttsProvider.notifier).stop();
      }
    });

    final pendingDiscovery = ref.watch(pendingDiscoveryProvider);
    if (pendingDiscovery != null) {
      final shopsAsync = ref.watch(gameDbProvider(shopsSchema));
      final questsAsync = ref.watch(gameDbProvider(questsSchema));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(pendingDiscoveryProvider.notifier).state = null;
        _showDiscoveryModal(
          context,
          ref,
          pendingDiscovery,
          shops: shopsAsync.value ?? const {},
          quests: questsAsync.value ?? const {},
        );
      });
    }

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
            if (session.activeQuestIds.isNotEmpty || session.unlockedShopIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (session.activeQuestIds.isNotEmpty)
                    ActionChip(
                      avatar: const Icon(Icons.assignment, size: 16),
                      label: Text('${tr(ref, 'quests')} (${session.activeQuestIds.length})'),
                      onPressed: () => ref.read(homeTabIndexProvider.notifier).state = 1,
                    ),
                  if (session.unlockedShopIds.isNotEmpty)
                    ActionChip(
                      avatar: const Icon(Icons.storefront, size: 16),
                      label: Text('${tr(ref, 'shops')} (${session.unlockedShopIds.length})'),
                      onPressed: () => ref.read(homeTabIndexProvider.notifier).state = 1,
                    ),
                ],
              ),
            ],
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
                _ReadAloudButton(text: node.descriptionFor(french), language: language),
                const SizedBox(width: 4),
                Text(
                  playState.isInExcursion ? tr(ref, 'detour') : '${tr(ref, 'node')} ${node.id}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (!playState.isInExcursion && ref.watch(appModeProvider) == AppMode.edit) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: tr(ref, 'edit_node'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoryNodeEditorScreen(node: node),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _nodeTransition,
                child: SingleChildScrollView(
                  key: ValueKey('${node.id}_${playState.isInExcursion}_text'),
                  child: _StoryText(text: node.descriptionFor(french)),
                ),
              ),
            ),
            if (walkCompanionEnabled)
              WalkingCompanionStrip(trigger: '${node.id}_${playState.isInExcursion}')
            else
              const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: _nodeTransition,
              child: Column(
                key: ValueKey('${node.id}_${playState.isInExcursion}_choices'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (node.choices.isEmpty)
                    _EndingView(
                      title: tr(ref, 'the_end'),
                      message: tr(ref, 'branch_end_message'),
                      restartLabel: tr(ref, 'restart_story'),
                      onRestart: () => notifier.restart(StoryRepository.startNodeId),
                      session: session,
                    )
                  else
                    for (var i = 0; i < node.choices.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _StaggeredReveal(
                          delay: Duration(milliseconds: 60 * i),
                          child: _ChoiceButton(
                            choice: node.choices[i],
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
          ],
        ),
      ),
    );
  }
}

/// Fade + subtle upward slide used whenever the story advances to a
/// different node (or leaves/enters an excursion), for both the narrative
/// text and the choice list below it.
Widget _nodeTransition(Widget child, Animation<double> animation) {
  final offset = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation);
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(position: offset, child: child),
  );
}

/// Fades and slides [child] up into place, starting after [delay] — used to
/// stagger each choice button's entrance so a fresh node's options reveal
/// one after another instead of popping in all at once.
class _StaggeredReveal extends StatefulWidget {
  const _StaggeredReveal({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
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
          reqAlignmentMax: targetNode.reqAlignmentMax,
          reqFlags: targetNode.reqFlags,
        );

    final lockedLabel = locked ? choice.lockedTextFor(french) : null;
    final label = (lockedLabel?.isNotEmpty ?? false) ? lockedLabel! : choice.textFor(french);

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
                      healAmount: choice.healAmount,
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
                final newShopId = choice.unlockShopId ?? '';
                final newQuestId = choice.unlockQuestId ?? '';
                if (!isExcursion && (newShopId.isNotEmpty || newQuestId.isNotEmpty)) {
                  ref.read(pendingDiscoveryProvider.notifier).state = PendingDiscovery(
                    shopId: newShopId.isNotEmpty ? newShopId : null,
                    questId: newQuestId.isNotEmpty ? newQuestId : null,
                  );
                }
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
                  theme: ref.read(mapThemeProvider),
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

/// Toggles reading the current node's narrative text aloud via the device's
/// text-to-speech engine — voiced in whichever language the app is set to.
/// Tapping again while speaking stops it.
class _ReadAloudButton extends ConsumerWidget {
  const _ReadAloudButton({required this.text, required this.language});

  final String text;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpeaking = ref.watch(ttsProvider);
    return IconButton(
      icon: Icon(isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 18),
      tooltip: isSpeaking ? tr(ref, 'stop_reading_tooltip') : tr(ref, 'read_aloud_tooltip'),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        final notifier = ref.read(ttsProvider.notifier);
        if (isSpeaking) {
          notifier.stop();
        } else {
          notifier.speak(storyBodyFor(text), language);
        }
      },
    );
  }
}

final RegExp _storyHeaderPattern = RegExp(r'^\[(.+?)\]\s*');

/// This node's `[CHAPTER N: TITLE]`-style leading header, if present.
String? storyHeaderFor(String text) => _storyHeaderPattern.firstMatch(text)?.group(1);

/// This node's narrative text with any leading `[CHAPTER N: TITLE]`-style
/// header stripped off — used both for on-screen rendering and for what
/// the read-aloud button speaks, so the header isn't read out loud.
String storyBodyFor(String text) {
  final match = _storyHeaderPattern.firstMatch(text);
  return (match != null ? text.substring(match.end) : text).trim();
}

/// Renders a story node's narrative text with a book-like presentation:
/// a leading `[CHAPTER N: TITLE]`-style header (if present) is pulled out
/// and styled as a centered heading with a divider, and the body gets
/// generous spacing, justified alignment, and a soft parchment-like card.
class _StoryText extends StatelessWidget {
  const _StoryText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final header = storyHeaderFor(text);
    final body = storyBodyFor(text);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null && header.isNotEmpty) ...[
            Text(
              header.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 56,
                height: 2,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            body,
            textAlign: TextAlign.justify,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'serif',
                  height: 1.55,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _EndingView extends ConsumerWidget {
  const _EndingView({
    required this.title,
    required this.message,
    required this.restartLabel,
    required this.onRestart,
    this.session,
  });

  final String title;
  final String message;
  final String restartLabel;
  final VoidCallback onRestart;

  /// When set, a recap card (level/gold/alignment/quests) is shown below
  /// the message — only passed for a genuine story ending, not the "trail
  /// goes cold" data-error state.
  final PlayerSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapSession = session;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (recapSession != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(ref, 'path_summary_label'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('${tr(ref, 'final_level_label')}: ${recapSession.level}'),
                      Text('${tr(ref, 'final_gold_label')}: ${recapSession.gold}'),
                      Text(
                        '${tr(ref, 'final_alignment_label')}: '
                        '${trAlignmentLabel(ref, recapSession.alignmentLabel)} '
                        '(${recapSession.alignmentScore})',
                      ),
                      Text(
                        '${tr(ref, 'quests_completed_label')}: '
                        '${recapSession.completedQuestIds.length}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

/// Shown once, right after a choice unlocks a shop and/or quest, on the
/// node the player just arrived at — lets them jump straight in instead of
/// only noticing the Play-tab CTA chip.
Future<void> _showDiscoveryModal(
  BuildContext context,
  WidgetRef ref,
  PendingDiscovery discovery, {
  required Map<String, dynamic> shops,
  required Map<String, dynamic> quests,
}) async {
  final lang = ref.read(appLanguageProvider);
  final shopId = discovery.shopId;
  final questId = discovery.questId;
  final shop = shopId != null ? shops[shopId] as Map<String, dynamic>? : null;
  final quest = questId != null ? quests[questId] as Map<String, dynamic>? : null;
  final session = ref.read(playerSessionProvider);

  final questActive = questId != null && session.activeQuestIds.contains(questId);
  final questCompleted = questId != null && session.completedQuestIds.contains(questId);
  final requiredGold = (quest?['requiredGold'] as num?)?.toInt() ?? 0;
  final requiredFlags =
      (quest?['requiredFlags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
  final questEligible = questId != null &&
      !questActive &&
      !questCompleted &&
      session.meetsRequirements(reqGold: requiredGold, reqFlags: requiredFlags);

  Future<void> acceptDiscoveredQuest() async {
    await ref.read(playerSessionProvider.notifier).acceptQuest(questId!);
    if (!context.mounted) return;
    showImmersiveNotice(
      context,
      icon: Icons.assignment_turned_in_outlined,
      message:
          '${trFor(lang, 'quest_accepted_prefix')}: ${quest?['questName']?.toString() ?? questId}',
    );
  }

  void viewDiscoveredQuest() {
    final questName = quest?['questName']?.toString() ?? questId!;
    final category = quest?['category']?.toString();
    final dialogue = quest?['npcDialogueText']?.toString() ?? '';
    final rewardGold = (quest?['rewardGold'] as num?)?.toInt() ?? 0;
    final rewardXp = (quest?['rewardXP'] as num?)?.toInt() ?? 0;
    final rewardItemId = quest?['rewardItemID']?.toString() ?? '';
    final rewardDiceId = quest?['rewardDiceID']?.toString() ?? '';

    showDetailDialog(
      context,
      title: questName,
      description: dialogue,
      icon: Icons.assignment,
      closeLabel: trFor(lang, 'close_button'),
      rows: [
        if (category != null && category.isNotEmpty)
          MapEntry(trFor(lang, 'category_label'), category),
        if (requiredGold > 0) MapEntry(trFor(lang, 'required_gold_label'), '$requiredGold'),
        if (requiredFlags.isNotEmpty)
          MapEntry(trFor(lang, 'required_flags_label'), requiredFlags.join(', ')),
        if (rewardGold > 0) MapEntry(trFor(lang, 'reward_gold_label'), '$rewardGold'),
        if (rewardXp > 0) MapEntry(trFor(lang, 'reward_xp_label'), '$rewardXp'),
        if (rewardItemId.isNotEmpty) MapEntry(trFor(lang, 'reward_item_label'), rewardItemId),
        if (rewardDiceId.isNotEmpty) MapEntry(trFor(lang, 'reward_dice_label'), rewardDiceId),
        MapEntry(
          trFor(lang, 'status_label'),
          questCompleted
              ? trFor(lang, 'status_completed')
              : (questActive ? trFor(lang, 'status_active') : trFor(lang, 'status_available')),
        ),
      ],
      extraActionLabel: questEligible ? trFor(lang, 'accept') : null,
      onExtraAction: questEligible ? () => acceptDiscoveredQuest() : null,
    );
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(trFor(lang, 'discovery_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shopId != null) ...[
            Text(trFor(lang, 'shop_discovered_message')),
            const SizedBox(height: 4),
            Text(
              shop?['shopName']?.toString() ?? shopId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          if (shopId != null && questId != null) const SizedBox(height: 12),
          if (questId != null) ...[
            Text(trFor(lang, 'quest_discovered_message')),
            const SizedBox(height: 4),
            Text(
              quest?['questName']?.toString() ?? questId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(trFor(lang, 'maybe_later_button')),
        ),
        if (shopId != null && shop != null)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: shopId, shop: shop)),
              );
            },
            child: Text(trFor(lang, 'open_shop_button')),
          ),
        if (questId != null)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              viewDiscoveredQuest();
            },
            child: Text(trFor(lang, 'view_quest_button')),
          ),
        if (questEligible)
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              acceptDiscoveredQuest();
            },
            child: Text(trFor(lang, 'accept')),
          ),
      ],
    ),
  );
}

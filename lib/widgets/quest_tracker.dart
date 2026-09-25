import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart';
import '../data/quest_objectives.dart';
import '../data/quest_tracking.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';
import 'quest_turn_in.dart';

/// The followed quest above the story: its name and the goal it waits on
/// ("Defeat catacomb ghouls (1/3)"), a Turn in button once every objective
/// is met, and a short highlight when the goal moves on. Tapping it opens
/// the quest (see [showQuestSheet]). Nothing when no quest is in progress.
class QuestTrackerBar extends ConsumerStatefulWidget {
  const QuestTrackerBar({super.key});

  @override
  ConsumerState<QuestTrackerBar> createState() => _QuestTrackerBarState();
}

class _QuestTrackerBarState extends ConsumerState<QuestTrackerBar> {
  String? _lastQuestId;
  String? _lastSignature;
  bool _highlight = false;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _noteGoal(String questId, String signature) {
    final moved = _lastQuestId == questId &&
        _lastSignature != null &&
        _lastSignature != signature;
    _lastQuestId = questId;
    _lastSignature = signature;
    if (!moved) return;
    _highlight = true;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _highlight = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final quests =
        ref.watch(localizedDbProvider(questsSchema)).value ?? const {};
    final questId = followedQuestIdOf(session);
    final quest =
        questId == null ? null : quests[questId] as Map<String, dynamic>?;
    if (questId == null || quest == null) return const SizedBox.shrink();
    final goal = questGoalFor(questId, quest, session);
    _noteGoal(questId, goal.signature);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lang = ref.watch(appLanguageProvider);
    final accent = goal.ready ? Colors.green.shade700 : colors.primary;
    final objectives =
        (quest['objectives'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Material(
        color: _highlight
            ? accent.withValues(alpha: 0.18)
            : colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: const Key('quest_tracker'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => showQuestSheet(context, ref, questId),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  questIcon(
                      quest['category']?.toString(),
                      objectives.isEmpty
                          ? null
                          : objectives.first['type']?.toString()),
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quest['questName']?.toString() ?? questId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        goal.ready
                            ? trFor(lang, 'quest_goal_ready')
                            : '${trFor(lang, 'quest_goal_prefix')} ${goal.label}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: goal.ready ? accent : colors.onSurfaceVariant,
                          fontWeight: goal.ready ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_highlight && !goal.ready)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(trFor(lang, 'quest_updated_label'),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: accent, fontWeight: FontWeight.bold)),
                  ),
                if (goal.ready)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilledButton.tonal(
                      key: const Key('quest_tracker_turn_in'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => turnInQuest(context, ref, questId),
                      child: Text(trFor(lang, 'quest_turn_in_button')),
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quest in full: what was asked, each objective with its progress, the
/// reward, and what can be done now -- turn it in, follow it, or switch
/// to another quest in progress.
Future<void> showQuestSheet(
    BuildContext context, WidgetRef ref, String questId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        _QuestSheet(questId: questId, hostContext: context, hostRef: ref),
  );
}

class _QuestSheet extends ConsumerWidget {
  const _QuestSheet({
    required this.questId,
    required this.hostContext,
    required this.hostRef,
  });

  final String questId;

  /// The screen that opened the sheet: turning a quest in closes the
  /// sheet, so its notices and level-up dialog open from here.
  final BuildContext hostContext;
  final WidgetRef hostRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    Map<String, dynamic> db(DbSchema schema) =>
        ref.watch(localizedDbProvider(schema)).value ?? const {};
    final quests = db(questsSchema);
    final quest = quests[questId] as Map<String, dynamic>?;
    if (quest == null) return const SizedBox.shrink();
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final active = session.activeQuestIds.contains(questId);
    final followed = followedQuestIdOf(session) == questId;
    final ready = active && allObjectivesMet(questId, quest, session);
    final statuses = objectiveStatusesFor(questId, quest, session);
    final dialogue = quest['npcDialogueText']?.toString() ?? '';
    final category = quest['category']?.toString() ?? '';
    final rewards = _rewardsLine(quest, db, lang);
    final others = [
      for (final id in session.activeQuestIds)
        if (id != questId && quests[id] != null) id,
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(quest['questName']?.toString() ?? questId,
                      style: theme.textTheme.titleLarge),
                ),
                if (category.isNotEmpty)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(trFor(lang,
                        category == 'Main' ? 'quest_main' : 'quest_side')),
                  ),
              ],
            ),
            if (followed)
              Text(trFor(lang, 'quest_following_label'),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.primary)),
            if (dialogue.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(dialogue,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontFamily: 'serif', height: 1.5)),
            ],
            const SizedBox(height: 14),
            Text(trFor(lang, 'quest_objectives_title'),
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final status in statuses)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      status.met
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: status.met
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.required > 1
                            ? '${status.description} '
                                '(${status.current}/${status.required})'
                            : status.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration:
                              status.met ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (rewards.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${trFor(lang, 'quest_rewards_label')}: $rewards',
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ready)
                  FilledButton.icon(
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: Text(trFor(lang, 'quest_turn_in_button')),
                    onPressed: () {
                      Navigator.of(context).pop();
                      turnInQuest(hostContext, hostRef, questId);
                    },
                  ),
                if (active && !followed)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.push_pin_outlined),
                    label: Text(trFor(lang, 'quest_follow_button')),
                    onPressed: () => ref
                        .read(playerSessionProvider.notifier)
                        .trackQuest(questId),
                  ),
              ],
            ),
            if (active && others.isNotEmpty) ...[
              const Divider(height: 28),
              Text(trFor(lang, 'quest_others_title'),
                  style: theme.textTheme.titleSmall),
              for (final id in others)
                Builder(builder: (context) {
                  final other = quests[id] as Map<String, dynamic>;
                  final goal = questGoalFor(id, other, session);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(goal.ready
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked),
                    title: Text(other['questName']?.toString() ?? id),
                    subtitle: Text(goal.ready
                        ? trFor(lang, 'quest_goal_ready')
                        : goal.label),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref
                            .read(playerSessionProvider.notifier)
                            .trackQuest(id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text(trFor(lang, 'quest_follow_button')),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

/// "80 gold · 150 XP · Iron Die · Kelda joins": what [quest] pays.
String _rewardsLine(Map<String, dynamic> quest,
    Map<String, dynamic> Function(DbSchema) db, AppLanguage lang) {
  final gold = (quest['rewardGold'] as num?)?.toInt() ?? 0;
  final xp = (quest['rewardXP'] as num?)?.toInt() ?? 0;
  final itemId = quest['rewardItemID']?.toString() ?? '';
  final diceId = quest['rewardDiceID']?.toString() ?? '';
  final allyId = quest['rewardAllyId']?.toString() ?? '';
  return [
    if (gold > 0) '$gold ${trFor(lang, 'gold_label')}',
    if (xp > 0) '$xp XP',
    if (itemId.isNotEmpty)
      (db(itemsSchema)[itemId] as Map<String, dynamic>?)?['itemName']
              ?.toString() ??
          itemId,
    if (diceId.isNotEmpty) dieDisplayName(diceId, language: lang),
    if (allyId.isNotEmpty)
      '${(db(companionsSchema)[allyId] as Map<String, dynamic>?)?['companionName'] ?? allyId} '
          '${trFor(lang, 'quest_ally_joins_suffix')}',
  ].join(' · ');
}

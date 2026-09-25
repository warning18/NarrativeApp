import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_grid_layout.dart';
import '../data/port_helpers.dart';
import '../data/quest_objectives.dart';
import '../data/settlements.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/permadeath_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/save_game_provider.dart';
import '../providers/story_providers.dart';
import '../providers/tab_badges_provider.dart';
import '../providers/tutorial_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_launcher.dart';
import '../tutorial/tutorial_topics.dart';
import '../utils/game_icons.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/save_slots_sheet.dart';
import 'achievements_screen.dart';
import 'boat_screen.dart';
import 'camp_screen.dart';
import 'character_screen.dart';
import 'fight_lab_screen.dart';
import 'fight_screen.dart';
import 'npc_detail_screen.dart';
import 'shop_detail_screen.dart';
import 'port_screen.dart';

class PlayScreen extends ConsumerWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final playState = ref.watch(storyPlayProvider);
    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final hasSavedGame =
        ref.watch(savedGamesProvider).any((slot) => slot != null);
    // Ironman: with permadeath on, a saved game can't be loaded.
    final ironman = ref.watch(permadeathEnabledProvider);
    final questsAsync = ref.watch(localizedDbProvider(questsSchema));
    final shopsAsync = ref.watch(localizedDbProvider(shopsSchema));
    final enemiesAsync = ref.watch(localizedDbProvider(enemiesSchema));
    final npcsAsync = ref.watch(localizedDbProvider(npcsSchema));
    final achievementsCount =
        ref.watch(localizedDbProvider(achievementsSchema)).value?.length ?? 0;

    // The town is a place in the story: its page opens only while the
    // story stands in it (the town's own node or one of its scenes).
    final story = ref.watch(storyDataProvider).value;
    final townNode =
        story == null ? null : settlementNodeAt(playState.currentNodeId, story);
    final town = townNode?.settlement;
    final townPortId = town != null && !town.isCamp ? town.portId : null;
    final townHubUnlocked = townPortId != null;
    final campUnlocked = chapterOfNode(playState.currentNodeId) >= campChapter;
    // In play this page is the Other tab: the character and the camp (with
    // the boat) have tabs of their own.
    final asOtherTab = !isEditMode;
    final boatUnlocked = campUnlocked;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ??
        const <String, dynamic>{};
    final mooredPortId = currentPortIdFor(ports, session.currentPortId);
    final mooredPortName = mooredPortId == null
        ? ''
        : portNameFor(ports[mooredPortId] as Map<String, dynamic>,
            ref.watch(appLanguageProvider) == AppLanguage.fr);

    final unseenQuests = session.unlockedQuestIds
        .where((id) => !session.seenQuestIds.contains(id))
        .length;
    final unseenShops = session.unlockedShopIds
        .where((id) => !session.seenShopIds.contains(id))
        .length;
    final unseenEnemies = session.unlockedEnemyIds
        .where((id) => !session.seenEnemyIds.contains(id))
        .length;

    final list = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isEditMode)
          Card(
            child: ListTile(
              key: const Key('open_fight_lab'),
              leading: const Icon(Icons.science_outlined),
              title: Text(tr(ref, 'fight_lab_title')),
              subtitle: Text(tr(ref, 'fight_lab_card_desc')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FightLabScreen()),
              ),
            ),
          ),
        if (ref.read(playerSessionProvider.notifier).loadFailed)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: Text(tr(ref, 'session_unreadable_notice')),
            ),
          ),
        const PlayerStatsBar(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(tr(ref, 'player_session'),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis),
            ),
            TutorialTarget(
              id: 'other.saves',
              child: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.save_outlined),
                    tooltip: tr(ref, 'save_game_tooltip'),
                    onPressed: () => showSaveSlotsSheet(context, saving: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open_outlined),
                    tooltip: ironman
                        ? tr(ref, 'ironman_load_tooltip')
                        : tr(ref, 'load_game_tooltip'),
                    onPressed: !hasSavedGame || ironman
                        ? null
                        : () => showSaveSlotsSheet(context, saving: false),
                  ),
                  if (isEditMode)
                    TextButton.icon(
                      onPressed: () async {
                        await ref
                            .read(playerSessionProvider.notifier)
                            .resetSession(keepLegacy: false);
                        ref
                            .read(storyPlayProvider.notifier)
                            .restart(StoryRepository.startNodeId);
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: Text(tr(ref, 'reset')),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (!asOtherTab)
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(tr(ref, 'character')),
              subtitle: Text(
                '${tr(ref, 'level_abbrev')} ${session.level} · ${session.inventoryItemIds.length} '
                '${tr(ref, 'item_count_label')} · ${session.skillPoints} ${tr(ref, 'skill_pt_label')} · '
                '${session.statPoints} ${tr(ref, 'stat_pt_label')}',
              ),
              // Spending stat/skill points is entirely manual and nothing else
              // nudges toward it, so an unspent balance is easy to forget —
              // same badge treatment as the unseen-content sections below.
              trailing: session.statPoints + session.skillPoints > 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${session.statPoints + session.skillPoints}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onError,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CharacterScreen()),
                );
              },
            ),
          ),
        // Places open as the story reaches them; until then they share one
        // quiet line instead of a locked card each.
        if (campUnlocked && !asOtherTab)
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: Text(tr(ref, 'camp_title')),
              subtitle: Text(
                '${session.recruitedAllies.length} ${tr(ref, 'roster_section').toLowerCase()} · '
                '${session.activeAllyIds.length} ${tr(ref, 'active_label').toLowerCase()}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CampScreen()),
              ),
            ),
          ),
        if (boatUnlocked && !asOtherTab)
          Card(
            child: ListTile(
              leading: const Icon(Icons.sailing),
              title: Text(tr(ref, 'boat_title')),
              subtitle:
                  Text('${tr(ref, 'boat_at_port_prefix')}: $mooredPortName'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BoatScreen()),
              ),
            ),
          ),
        if (townHubUnlocked)
          Card(
            child: ListTile(
              leading: const Icon(Icons.cottage_outlined),
              title: Text(town!
                  .nameFor(ref.watch(appLanguageProvider) == AppLanguage.fr)),
              subtitle: Text('${session.completedZoneIds.length} '
                  '${tr(ref, 'zones_cleared_label').toLowerCase()}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => PortScreen(portId: townPortId)),
              ),
            ),
          ),
        _LockedPlacesLine(entries: [
          if (!campUnlocked && !asOtherTab)
            (tr(ref, 'camp_title'), tr(ref, 'camp_locked_subtitle')),
          if (!boatUnlocked && !asOtherTab)
            (tr(ref, 'boat_title'), tr(ref, 'boat_locked_subtitle')),
          if (!townHubUnlocked)
            (tr(ref, 'town_hub_title'), tr(ref, 'town_hub_locked_subtitle')),
        ]),
        TutorialTarget(
          id: 'other.achievements',
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: Text(tr(ref, 'achievements_title')),
              subtitle: Text(
                '${session.unlockedAchievementIds.length} / $achievementsCount '
                '${tr(ref, 'achievements_progress_label').toLowerCase()}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                );
              },
            ),
          ),
        ),
        const Divider(height: 24),
        TutorialTarget(
          id: 'other.sections',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CollapsibleSection(
                title: tr(ref, 'quests'),
                badgeCount: unseenQuests,
                readyCount: isEditMode
                    ? 0
                    : ref.watch(tabBadgesProvider).readyQuestCount,
                readyLabel: tr(ref, 'quests_ready_label'),
                onExpanded: () => ref
                    .read(playerSessionProvider.notifier)
                    .markAllSeenInCategory(quests: true),
                child: questsAsync.when(
                  data: (records) => _QuestList(records: records),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Text('${tr(ref, 'failed_to_load_quests')}: $error'),
                ),
              ),
              const Divider(height: 24),
              _CollapsibleSection(
                title: tr(ref, 'shops'),
                badgeCount: unseenShops,
                onExpanded: () => ref
                    .read(playerSessionProvider.notifier)
                    .markAllSeenInCategory(shops: true),
                child: shopsAsync.when(
                  data: (records) => _ShopList(records: records),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Text('${tr(ref, 'failed_to_load_shops')}: $error'),
                ),
              ),
              const Divider(height: 24),
              _CollapsibleSection(
                title: tr(ref, 'bestiary'),
                badgeCount: unseenEnemies,
                onExpanded: () => ref
                    .read(playerSessionProvider.notifier)
                    .markAllSeenInCategory(enemies: true),
                child: enemiesAsync.when(
                  data: (records) => _EnemyList(records: records),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Text('${tr(ref, 'failed_to_load_enemies')}: $error'),
                ),
              ),
              const Divider(height: 24),
              _CollapsibleSection(
                title: tr(ref, 'npcs_section'),
                child: npcsAsync.when(
                  data: (records) => _NpcList(records: records),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Text('${tr(ref, 'failed_to_load_npcs')}: $error'),
                ),
              ),
            ],
          ),
        ),
        if (asOtherTab) ...[
          const Divider(height: 24),
          TutorialTarget(
            id: 'other.tutorials',
            child: _CollapsibleSection(
              title: tr(ref, 'tutorials_section'),
              child: const _TutorialList(),
            ),
          ),
        ],
      ],
    );
    return asOtherTab
        ? TutorialTrigger(topic: TutorialTopic.other, child: list)
        : list;
  }
}

/// Every feature's tour, to play again: those not seen yet marked New.
class _TutorialList extends ConsumerWidget {
  const _TutorialList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(tutorialProvider);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr(ref, 'tutorials_section_hint'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        for (final topic in TutorialTopic.values)
          ListTile(
            key: Key('tutorial_replay_${topic.name}'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(topic.icon),
            title: Text(tr(ref, topic.titleKey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(
                      ref,
                      settings.hasSeen(topic)
                          ? 'tut_seen_label'
                          : 'tut_new_label'),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: settings.hasSeen(topic)
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.play_arrow_rounded),
              ],
            ),
            onTap: () => playTutorial(context, ref, topic),
          ),
      ],
    );
  }
}

/// A titled section that can be collapsed to reduce scrolling once the
/// player has several quests/shops/enemies unlocked. Collapsed by default;
/// each section remembers its own open/closed state independently. An
/// optional [badgeCount] shows how many entries were newly unlocked and not
/// yet viewed, cleared via [onExpanded] the first time the section opens.
class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.child,
    this.badgeCount = 0,
    this.readyCount = 0,
    this.readyLabel = '',
    this.onExpanded,
  });

  final String title;
  final Widget child;
  final int badgeCount;

  /// Entries ready to act on (quests to turn in), shown whether or not
  /// the section has been opened before.
  final int readyCount;
  final String readyLabel;
  final VoidCallback? onExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (readyCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8, right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '$readyCount $readyLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        initiallyExpanded: false,
        onExpansionChanged: (expanded) {
          if (expanded) onExpanded?.call();
        },
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [child],
      ),
    );
  }
}

class _QuestList extends ConsumerWidget {
  const _QuestList({required this.records});

  final Map<String, dynamic> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return Text(tr(ref, 'no_quests_defined'));
    }
    final session = ref.watch(playerSessionProvider);
    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final companions =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
    final races = ref.watch(localizedDbProvider(racesSchema)).value ?? const {};
    final professions =
        ref.watch(localizedDbProvider(professionsSchema)).value ?? const {};
    final achievements =
        ref.watch(localizedDbProvider(achievementsSchema)).value ?? const {};
    final keys = records.keys.toList()..sort();

    return Column(
      children: keys.map((questId) {
        final quest = records[questId] as Map<String, dynamic>;
        final questName = quest['questName']?.toString() ?? questId;
        final category = quest['category']?.toString();
        final objectivesList =
            (quest['objectives'] as List?)?.cast<Map<String, dynamic>>() ??
                const [];
        final firstObjectiveType = objectivesList.isEmpty
            ? null
            : objectivesList.first['type']?.toString();
        final dialogue = quest['npcDialogueText']?.toString() ?? '';
        final isCompleted = session.completedQuestIds.contains(questId);
        final isActive = session.activeQuestIds.contains(questId);
        final isDiscovered = isEditMode ||
            isCompleted ||
            isActive ||
            session.unlockedQuestIds.contains(questId);
        final requiredGold = (quest['requiredGold'] as num?)?.toInt() ?? 0;
        final requiredFlags = (quest['requiredFlags'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [];
        final meetsRequirements = isEditMode ||
            session.meetsRequirements(
                reqGold: requiredGold, reqFlags: requiredFlags);
        final objectiveStatuses = objectiveStatusesFor(questId, quest, session);
        final objectivesMet =
            isEditMode || allObjectivesMet(questId, quest, session);

        String statusLabel;
        if (isCompleted) {
          statusLabel = tr(ref, 'status_completed');
        } else if (isActive) {
          statusLabel = tr(ref, 'status_active');
        } else if (!isDiscovered) {
          statusLabel = tr(ref, 'status_undiscovered');
        } else if (!meetsRequirements) {
          statusLabel = tr(ref, 'status_locked');
        } else {
          statusLabel = tr(ref, 'status_available');
        }

        Widget trailing;
        if (isCompleted) {
          trailing = const Icon(Icons.check_circle, color: Colors.green);
        } else if (!isDiscovered) {
          trailing = const Icon(Icons.lock_outline);
        } else if (isActive) {
          trailing = ElevatedButton(
            onPressed: !objectivesMet
                ? null
                : () async {
                    final rewardGold =
                        (quest['rewardGold'] as num?)?.toInt() ?? 0;
                    final rewardXp = (quest['rewardXP'] as num?)?.toInt() ?? 0;
                    final rewardItemId = quest['rewardItemID']?.toString();
                    final nextQuestId = quest['nextQuestID']?.toString();
                    final rewardDiceId = quest['rewardDiceID']?.toString();
                    final rewardAllyId = quest['rewardAllyId']?.toString();
                    final grantsBannerPieceId =
                        quest['grantsBannerPieceId']?.toString();
                    final alignmentMod =
                        (quest['alignmentChange'] as num?)?.toInt() ?? 0;
                    final leveledUp = await ref
                        .read(playerSessionProvider.notifier)
                        .completeQuest(
                          questId,
                          rewardGold: rewardGold,
                          rewardXP: rewardXp,
                          rewardItemId: rewardItemId,
                          nextQuestId: nextQuestId,
                          rewardDiceId: rewardDiceId,
                          grantsBannerPieceId: grantsBannerPieceId,
                          alignmentMod: alignmentMod,
                          rewardItem: rewardItemId == null
                              ? null
                              : ref
                                      .read(localizedDbProvider(itemsSchema))
                                      .value?[rewardItemId]
                                  as Map<String, dynamic>?,
                        );
                    String? recruitedName;
                    if (rewardAllyId != null && rewardAllyId.isNotEmpty) {
                      final companion =
                          companions[rewardAllyId] as Map<String, dynamic>?;
                      final race = races[companion?['raceId']?.toString() ?? '']
                          as Map<String, dynamic>?;
                      final profession = professions[
                              companion?['professionId']?.toString() ?? '']
                          as Map<String, dynamic>?;
                      await ref
                          .read(playerSessionProvider.notifier)
                          .recruitAlly(
                            rewardAllyId,
                            race: race,
                            profession: profession,
                            companion: companion,
                            dice: ref
                                    .read(localizedDbProvider(diceSchema))
                                    .value ??
                                const {},
                            houses: ref
                                    .read(localizedDbProvider(housesSchema))
                                    .value ??
                                const {},
                            requiredHouseId:
                                companion?['requiredHouseId']?.toString(),
                          );
                      recruitedName = companion?['companionName']?.toString() ??
                          rewardAllyId;
                    }
                    final newAchievements = await ref
                        .read(playerSessionProvider.notifier)
                        .checkAchievements(
                            totalCompanionCount: companions.length);
                    if (!context.mounted) return;
                    final lang = ref.read(appLanguageProvider);
                    final achievementNames = newAchievements
                        .map((id) =>
                            (achievements[id] as Map<String, dynamic>?)?[
                                    'achievementName']
                                ?.toString() ??
                            id)
                        .toList();
                    showImmersiveNotice(
                      context,
                      icon: Icons.emoji_events_outlined,
                      message:
                          '${trFor(lang, 'quest_complete_prefix')}: $questName '
                          '(+$rewardGold ${trFor(lang, 'gold_label')}, +$rewardXp XP'
                          '${rewardItemId != null && rewardItemId.isNotEmpty ? ", +$rewardItemId" : ""}'
                          '${rewardDiceId != null && rewardDiceId.isNotEmpty ? ", +$rewardDiceId" : ""}'
                          '${recruitedName != null ? ", ${trFor(lang, 'recruited_prefix')} $recruitedName" : ""})'
                          '${grantsBannerPieceId != null && grantsBannerPieceId.isNotEmpty ? "\n${trFor(lang, 'banner_piece_found_prefix')}" : ""}'
                          '${achievementNames.isNotEmpty ? "\n${trFor(lang, 'achievement_unlocked_prefix')}: ${achievementNames.join(", ")}" : ""}',
                    );
                    if (leveledUp) {
                      final newLevel = ref.read(playerSessionProvider).level;
                      showLevelUpDialog(context, ref, newLevel: newLevel);
                    }
                  },
            child: Text(tr(ref, 'complete')),
          );
        } else {
          trailing = ElevatedButton(
            onPressed: !meetsRequirements
                ? null
                : () async {
                    await ref
                        .read(playerSessionProvider.notifier)
                        .acceptQuest(questId);
                    if (!context.mounted) return;
                    final lang = ref.read(appLanguageProvider);
                    showImmersiveNotice(
                      context,
                      icon: Icons.assignment_turned_in_outlined,
                      message:
                          '${trFor(lang, 'quest_accepted_prefix')}: $questName',
                    );
                  },
            child: Text(tr(ref, 'accept')),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(questIcon(category, firstObjectiveType)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(questName,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                if (dialogue.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogue,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'serif',
                          height: 1.55,
                          letterSpacing: 0.1,
                        ),
                  ),
                ],
                if (isActive && objectiveStatuses.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...objectiveStatuses.map((status) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              status.met
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: status.met
                                  ? Colors.green
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                status.required > 1
                                    ? '${status.description} '
                                        '(${status.current}/${status.required})'
                                    : status.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      decoration: status.met
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${tr(ref, 'status_label')}: $statusLabel',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    trailing,
                  ],
                ),
              ],
            ),
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
      return Text(tr(ref, 'no_shops_defined'));
    }
    final session = ref.watch(playerSessionProvider);
    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final currentNodeId = ref.watch(storyPlayProvider).currentNodeId;
    final keys = records.keys.toList()..sort();

    return Column(
      children: keys.map((shopId) {
        final shop = records[shopId] as Map<String, dynamic>;
        final shopName = shop['shopName']?.toString() ?? shopId;
        final discovered = session.unlockedShopIds.contains(shopId);
        final onTriggerNode =
            session.shopUnlockNodeIds[shopId] == currentNodeId;
        final accessible = isEditMode || (discovered && onTriggerNode);
        return Card(
          child: ListTile(
            leading: Icon(accessible ? shopIcon : Icons.lock_outline),
            title: Text(shopName),
            subtitle: Text(
              accessible
                  ? shop['shopDescription']?.toString() ?? ''
                  : (discovered
                      ? tr(ref, 'shop_left_behind')
                      : tr(ref, 'shop_undiscovered')),
            ),
            trailing: accessible ? const Icon(Icons.chevron_right) : null,
            onTap: !accessible
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ShopDetailScreen(shopId: shopId, shop: shop),
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
      return Text(tr(ref, 'no_enemies_defined'));
    }
    final session = ref.watch(playerSessionProvider);
    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final keys = records.keys.toList()..sort();

    return Column(
      children: keys.map((enemyId) {
        final enemy = records[enemyId] as Map<String, dynamic>;
        final enemyName = enemy['enemyName']?.toString() ?? enemyId;
        final maxHealth = (enemy['maxHealth'] as num?)?.toInt() ?? 0;
        final damage = (enemy['damage'] as num?)?.toInt() ?? 0;
        final accessible =
            isEditMode || session.unlockedEnemyIds.contains(enemyId);
        return Card(
          child: ListTile(
            leading: Icon(accessible ? enemyIcon : Icons.lock_outline),
            title: Text(enemyName),
            subtitle: Text(
              accessible
                  ? '${tr(ref, 'hp_label')} $maxHealth · ${tr(ref, 'damage_label')} $damage'
                  : tr(ref, 'not_yet_encountered'),
            ),
            trailing: !accessible
                ? null
                : ElevatedButton.icon(
                    onPressed: () async {
                      ref.read(combatActiveProvider.notifier).state = true;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FightScreen(enemyId: enemyId, enemy: enemy),
                        ),
                      );
                      ref.read(combatActiveProvider.notifier).state = false;
                    },
                    icon: const Icon(Icons.sports_martial_arts),
                    label: Text(tr(ref, 'fight')),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class _NpcList extends ConsumerWidget {
  const _NpcList({required this.records});

  final Map<String, dynamic> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return Text(tr(ref, 'no_npcs_defined'));
    }
    final session = ref.watch(playerSessionProvider);
    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final keys = records.keys.toList()..sort();

    return Column(
      children: keys.map((npcId) {
        final npc = records[npcId] as Map<String, dynamic>;
        final npcName = npc['npcName']?.toString() ?? npcId;
        final requiredFlag = npc['requiredFlag']?.toString() ?? '';
        final discovered =
            requiredFlag.isEmpty || session.flags.contains(requiredFlag);
        final accessible = isEditMode || discovered;
        final talkedTo = session.talkedToNpcIds.contains(npcId);
        return Card(
          child: ListTile(
            leading: Icon(accessible
                ? (talkedTo ? Icons.check_circle : Icons.person_outline)
                : Icons.lock_outline),
            title: Text(npcName),
            subtitle: Text(
              accessible
                  ? (french
                      ? (npc['description_fr']?.toString().isNotEmpty ?? false)
                          ? npc['description_fr'].toString()
                          : npc['description']?.toString() ?? ''
                      : npc['description']?.toString() ?? '')
                  : tr(ref, 'npc_not_yet_met'),
            ),
            trailing: accessible ? const Icon(Icons.chevron_right) : null,
            onTap: !accessible
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NpcDetailScreen(npcId: npcId, npc: npc),
                      ),
                    );
                  },
          ),
        );
      }).toList(),
    );
  }
}

/// The places not open yet (camp, boat, town), on one dimmed line grouped
/// by what opens them: "Camp, The Rusty Eel: Reach Chapter 3 to unlock".
/// Nothing when every place is open.
class _LockedPlacesLine extends StatelessWidget {
  const _LockedPlacesLine({required this.entries});

  /// Each place's name and what opens it.
  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final byReason = <String, List<String>>{};
    for (final (name, reason) in entries) {
      byReason.putIfAbsent(reason, () => []).add(name);
    }
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 18, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              [
                for (final entry in byReason.entries)
                  '${entry.value.join(', ')}: ${entry.key}',
              ].join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

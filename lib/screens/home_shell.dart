import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_state.dart';
import '../data/chapter_grid_layout.dart';
import '../data/port_helpers.dart';
import '../data/world_map.dart' show mapChapters;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../gamedata/db_schema.dart';
import '../providers/app_mode_provider.dart';
import '../providers/camp_presence_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/home_tab_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../providers/tab_badges_provider.dart';
import '../widgets/camp_travel.dart';
import '../widgets/immersive_notice.dart';
import 'ai_generator_screen.dart';
import 'camp_screen.dart';
import 'character_screen.dart';
import 'game_data_home_screen.dart';
import 'play_screen.dart';
import 'settings_screen.dart';
import 'ship_screen.dart';
import 'story_graph_screen.dart';
import 'story_player_screen.dart';
import 'world_map_screen.dart';

/// The game under the main menu. In play: Story, Character, Camp and
/// Other (quests, shops, bestiary, people, saves); while the party is at
/// the camp (its scene, or gone back to it from a town), the camp takes
/// the Story tab's place until the party leaves; away from it the Camp tab
/// is the way back, and the ship while the Eel is out. In Edit Mode: Story,
/// Play, Generate and Data. The header opens a map in both: the story's
/// scenes in Edit Mode, the world the story has reached in play.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const List<Widget> _editScreens = [
    StoryPlayerScreen(),
    PlayScreen(),
    AiGeneratorScreen(),
    GameDataHomeScreen(),
  ];

  static const List<Widget> _inGameScreens = [
    StoryPlayerScreen(),
    CharacterScreen(embedded: true),
    _CampTab(),
    PlayScreen(),
  ];

  /// Goals reached during a fight, announced once it is over.
  final List<String> _pendingReadyQuestIds = [];

  void _announceReady(List<String> questIds) {
    final quests =
        ref.read(localizedDbProvider(questsSchema)).value ?? const {};
    final lang = ref.read(appLanguageProvider);
    final names = [
      for (final id in questIds)
        (quests[id] as Map<String, dynamic>?)?['questName']?.toString() ?? id,
    ];
    if (names.isEmpty || !mounted) return;
    showImmersiveNotice(
      context,
      icon: Icons.flag_circle_outlined,
      message: trFor(lang, 'quest_ready_notice')
          .replaceAll('{quest}', names.join(', ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reset to the Story tab whenever the mode changes, so a stale index
    // from the other mode's tab list never points at the wrong page.
    ref.listen<AppMode>(appModeProvider, (previous, next) {
      ref.read(homeTabIndexProvider.notifier).state = 0;
    });
    // A quest in progress whose goal is reached says so once, in play;
    // during a fight it waits for the fight to end.
    ref.listen<QuestReadiness>(questReadinessProvider, (previous, next) {
      if (previous == null || ref.read(appModeProvider) == AppMode.edit) {
        return;
      }
      final reached = QuestReadiness.newlyReady(previous, next);
      if (reached.isEmpty) return;
      if (ref.read(combatActiveProvider)) {
        _pendingReadyQuestIds.addAll(reached);
      } else {
        _announceReady(reached);
      }
    });
    ref.listen<bool>(combatActiveProvider, (previous, next) {
      if (previous == true && !next && _pendingReadyQuestIds.isNotEmpty) {
        final ids = [..._pendingReadyQuestIds];
        _pendingReadyQuestIds.clear();
        _announceReady(ids);
      }
    });
    // The story coming to the camp brings the party home, the Rusty Eel
    // with it; the camp then opens in the Story tab's place, and the story
    // comes back when the party leaves.
    ref.listen<StoryPlayState>(storyPlayProvider, (previous, next) {
      if (previous == null || ref.read(appModeProvider) == AppMode.edit) {
        return;
      }
      if (previous.currentNodeId == next.currentNodeId ||
          next.history.isEmpty ||
          next.history.last != previous.currentNodeId) {
        return;
      }
      final story = ref.read(storyDataProvider).value;
      bool isCamp(String id) => story?.nodeFor(id)?.settlement?.isCamp ?? false;
      if (!isCamp(next.currentNodeId) || isCamp(previous.currentNodeId)) {
        return;
      }
      final ports = ref.read(gameDbProvider(portsSchema)).value;
      final home = ports == null ? null : homePortId(ports);
      if (home != null) {
        ref.read(playerSessionProvider.notifier).arriveAtPort(home);
      }
    });
    ref.listen<bool>(partyAtCampProvider, (previous, next) {
      if (previous == null ||
          previous == next ||
          ref.read(appModeProvider) == AppMode.edit) {
        return;
      }
      ref.read(homeTabIndexProvider.notifier).state = next ? _campTab : 0;
    });

    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final screens = isEditMode ? _editScreens : _inGameScreens;
    final presence = ref.watch(campPresenceProvider);
    // The camp's tab is the ship only while the Eel is out on an
    // expedition from the camp.
    final atCampTab = presence != CampPresence.sailedOut;
    final titles = isEditMode
        ? [
            tr(ref, 'title_story'),
            tr(ref, 'title_play'),
            tr(ref, 'title_generate'),
            tr(ref, 'title_data'),
          ]
        : [
            tr(ref, 'title_story'),
            tr(ref, 'character'),
            tr(ref, atCampTab ? 'camp_title' : 'boat_title'),
            tr(ref, 'title_other'),
          ];
    final language = ref.watch(appLanguageProvider);
    // While the story stands at the camp its tab is closed: the tabs are
    // Camp, Character and Other, and the Story tab's index means the camp.
    final storyHidden = !isEditMode && ref.watch(partyAtCampProvider);
    final visibleTabs =
        storyHidden ? const [_campTab, 1, 3] : const [0, 1, 2, 3];
    var index = ref.watch(homeTabIndexProvider).clamp(0, screens.length - 1);
    if (!visibleTabs.contains(index)) index = _campTab;
    final canLeave = Navigator.of(context).canPop();
    final badges = ref.watch(tabBadgesProvider);

    // A dot on a tab when something there waits on the player; the
    // tooltip (and screen readers) say what.
    NavigationDestination dotted(
      IconData icon,
      String label, {
      required bool show,
      required String reason,
    }) =>
        NavigationDestination(
          icon: Badge(isLabelVisible: show, child: Icon(icon)),
          label: label,
          tooltip: show ? '$label · $reason' : label,
        );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canLeave
            ? IconButton(
                icon: const Icon(Icons.home_outlined),
                tooltip: tr(ref, 'menu_back_to_menu'),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              )
            : null,
        title: !isEditMode && index == 0
            ? _ChapterTitle(fallback: titles[0])
            : Text(titles[index]),
        actions: [
          // Edit Mode maps the story's scenes and paths; play mode shows
          // the world the story has reached.
          IconButton(
            icon: Icon(
                isEditMode ? Icons.account_tree_outlined : Icons.map_outlined),
            tooltip: tr(ref, isEditMode ? 'title_map' : 'world_map_title'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    isEditMode ? const StoryMapPage() : const WorldMapPage(),
              ),
            ),
          ),
          IconButton(
            icon: Text(language == AppLanguage.fr ? '🇫🇷' : '🇬🇧'),
            tooltip: tr(ref, 'language'),
            onPressed: () {
              ref.read(appLanguageProvider.notifier).setLanguage(
                    language == AppLanguage.fr
                        ? AppLanguage.en
                        : AppLanguage.fr,
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: tr(ref, 'settings'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: visibleTabs.indexOf(index),
        onDestinationSelected: (i) =>
            ref.read(homeTabIndexProvider.notifier).state = visibleTabs[i],
        destinations: isEditMode
            ? [
                NavigationDestination(
                    icon: const Icon(Icons.menu_book),
                    label: tr(ref, 'nav_story')),
                NavigationDestination(
                    icon: const Icon(Icons.videogame_asset),
                    label: tr(ref, 'nav_play')),
                NavigationDestination(
                    icon: const Icon(Icons.auto_awesome),
                    label: tr(ref, 'nav_generate')),
                NavigationDestination(
                    icon: const Icon(Icons.storage),
                    label: tr(ref, 'nav_data')),
              ]
            : [
                for (final tab in visibleTabs)
                  switch (tab) {
                    0 => NavigationDestination(
                        icon: const Icon(Icons.menu_book),
                        label: tr(ref, 'nav_story')),
                    1 => dotted(Icons.person_outline, tr(ref, 'nav_character'),
                        show: badges.character,
                        reason: tr(ref, 'badge_points_waiting')),
                    2 => atCampTab
                        ? dotted(Icons.local_fire_department_outlined,
                            tr(ref, 'nav_camp'),
                            show: badges.camp,
                            reason: tr(ref, 'badge_house_affordable'))
                        : NavigationDestination(
                            icon: const Icon(Icons.sailing_outlined),
                            label: tr(ref, 'nav_ship')),
                    _ => dotted(Icons.more_horiz, tr(ref, 'nav_other'),
                        show: badges.other,
                        reason: tr(ref, 'badge_quest_ready')),
                  },
              ],
      ),
    );
  }
}

/// The Camp tab's index among the play-mode tabs.
const int _campTab = 2;

/// The Camp tab: the camp while the party is at it, the Rusty Eel while
/// it has sailed out from it, the way back to it when the story has taken
/// the party away, and before chapter 3 a word on what it will be.
class _CampTab extends ConsumerWidget {
  const _CampTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(campPresenceProvider)) {
      case CampPresence.atCamp:
        return const CampScreen(embedded: true);
      case CampPresence.sailedOut:
        return const ShipScreen(embedded: true);
      case CampPresence.away:
        return const CampAwayView();
      case CampPresence.notYet:
        break;
    }
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(tr(ref, 'camp_title'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              tr(ref, 'camp_tab_locked_body'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Story tab's header in play: the chapter the story is in, its
/// number over its name, in the chapter's colour. The prologue shows
/// [fallback].
class _ChapterTitle extends ConsumerWidget {
  const _ChapterTitle({required this.fallback});

  final String fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final number = chapterOfNode(ref.watch(storyPlayProvider).currentNodeId);
    final chapter = mapChapters.where((c) => c.number == number).firstOrNull;
    if (chapter == null) return Text(fallback);
    final title = chapter.title(ref.watch(appLanguageProvider));
    final split = title.indexOf(':');
    final label = split < 0 ? title : title.substring(0, split).trim();
    final name = split < 0 ? fallback : title.substring(split + 1).trim();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: theme.brightness == Brightness.dark
                ? chapter.dark
                : chapter.light,
          ),
        ),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 19)),
      ],
    );
  }
}

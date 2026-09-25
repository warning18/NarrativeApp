import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_grid_layout.dart';
import '../data/world_map.dart' show mapChapters;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/story_providers.dart';
import '../providers/tab_badges_provider.dart';
import '../tutorial/guide_tour.dart';
import 'ai_generator_screen.dart';
import 'camp_screen.dart';
import 'character_screen.dart';
import 'game_data_home_screen.dart';
import 'play_screen.dart';
import 'settings_screen.dart';
import 'story_graph_screen.dart';
import 'story_player_screen.dart';
import 'world_map_screen.dart';

/// The game under the main menu. In play: Story, Character, Camp and
/// Other (quests, shops, bestiary, people, saves). In Edit Mode: Story,
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

  @override
  Widget build(BuildContext context) {
    // Reset to the Story tab whenever the mode changes, so a stale index
    // from the other mode's tab list never points at the wrong page.
    ref.listen<AppMode>(appModeProvider, (previous, next) {
      ref.read(homeTabIndexProvider.notifier).state = 0;
    });

    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final screens = isEditMode ? _editScreens : _inGameScreens;
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
            tr(ref, 'camp_title'),
            tr(ref, 'title_other'),
          ];
    final language = ref.watch(appLanguageProvider);
    final index = ref.watch(homeTabIndexProvider).clamp(0, screens.length - 1);
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
            ? TutorialTarget(
                id: 'home.chapter', child: _ChapterTitle(fallback: titles[0]))
            : Text(titles[index]),
        actions: [
          // Edit Mode maps the story's scenes and paths; play mode shows
          // the world the story has reached.
          TutorialTarget(
            id: 'home.map',
            child: IconButton(
              icon: Icon(isEditMode
                  ? Icons.account_tree_outlined
                  : Icons.map_outlined),
              tooltip: tr(ref, isEditMode ? 'title_map' : 'world_map_title'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      isEditMode ? const StoryMapPage() : const WorldMapPage(),
                ),
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
      bottomNavigationBar: TutorialTarget(
        id: 'home.nav',
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(homeTabIndexProvider.notifier).state = i,
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
                  NavigationDestination(
                      icon: const Icon(Icons.menu_book),
                      label: tr(ref, 'nav_story')),
                  dotted(Icons.person_outline, tr(ref, 'nav_character'),
                      show: badges.character,
                      reason: tr(ref, 'badge_points_waiting')),
                  dotted(
                      Icons.local_fire_department_outlined, tr(ref, 'nav_camp'),
                      show: badges.camp,
                      reason: tr(ref, 'badge_house_affordable')),
                  dotted(Icons.more_horiz, tr(ref, 'nav_other'),
                      show: badges.other, reason: tr(ref, 'badge_quest_ready')),
                ],
        ),
      ),
    );
  }
}

/// The Camp tab: the camp itself once the story reaches chapter 3, and
/// until then a word on what it will be.
class _CampTab extends ConsumerWidget {
  const _CampTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = chapterOfNode(ref.watch(storyPlayProvider).currentNodeId);
    if (chapter >= campChapter) return const CampScreen(embedded: true);
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
/// [fallback], and so does a chapter title with no name after its colon.
/// Large text sizes shrink it to fit the app bar rather than overflow.
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
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
      ),
    );
  }
}

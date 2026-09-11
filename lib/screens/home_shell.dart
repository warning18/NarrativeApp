import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_overlay.dart';
import 'ai_generator_screen.dart';
import 'game_data_home_screen.dart';
import 'play_screen.dart';
import 'settings_screen.dart';
import 'story_graph_screen.dart';
import 'story_player_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const List<Widget> _editScreens = [
    StoryPlayerScreen(),
    PlayScreen(),
    StoryGraphScreen(),
    AiGeneratorScreen(),
    GameDataHomeScreen(),
  ];

  static const List<Widget> _inGameScreens = [
    StoryPlayerScreen(),
    PlayScreen(),
  ];

  // Guards the initial (cold-start) tutorial check so it only ever
  // schedules once per HomeShell lifetime, regardless of how many times
  // build() reruns before the dialog is actually shown.
  bool _checkedInitialTutorial = false;

  void _maybeShowTutorial() {
    if (!mounted) return;
    final tutorial = ref.read(tutorialProvider);
    final isEditMode = ref.read(appModeProvider) == AppMode.edit;
    if (!isEditMode && tutorial.enabled && !tutorial.seen) {
      showTutorialOverlay(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Covers a returning player who quit while already in In-Game mode:
    // no mode *transition* happens on the next launch, so the listener
    // below wouldn't fire — this one-time check catches that case too.
    if (!_checkedInitialTutorial) {
      _checkedInitialTutorial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
    }

    // Reset to the Story tab whenever the mode changes, so a stale index
    // from the other mode's (longer) tab list never goes out of range.
    ref.listen<AppMode>(appModeProvider, (previous, next) {
      ref.read(homeTabIndexProvider.notifier).state = 0;
      if (next == AppMode.inGame) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
      }
    });

    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final screens = isEditMode ? _editScreens : _inGameScreens;
    final allTitles = [
      tr(ref, 'title_story'),
      tr(ref, 'title_play'),
      tr(ref, 'title_map'),
      tr(ref, 'title_generate'),
      tr(ref, 'title_data'),
    ];
    final titles = isEditMode ? allTitles : allTitles.sublist(0, 2);
    final language = ref.watch(appLanguageProvider);
    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          IconButton(
            icon: Text(language == AppLanguage.fr ? '🇫🇷' : '🇬🇧'),
            tooltip: tr(ref, 'language'),
            onPressed: () {
              ref.read(appLanguageProvider.notifier).setLanguage(
                    language == AppLanguage.fr ? AppLanguage.en : AppLanguage.fr,
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
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.menu_book), label: tr(ref, 'nav_story')),
          NavigationDestination(
            icon: const Icon(Icons.videogame_asset),
            label: tr(ref, 'nav_play'),
          ),
          if (isEditMode) ...[
            NavigationDestination(icon: const Icon(Icons.account_tree), label: tr(ref, 'nav_map')),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome),
              label: tr(ref, 'nav_generate'),
            ),
            NavigationDestination(icon: const Icon(Icons.storage), label: tr(ref, 'nav_data')),
          ],
        ],
      ),
    );
  }
}

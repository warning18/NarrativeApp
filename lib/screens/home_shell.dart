import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
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
  int _index = 0;

  static const List<Widget> _screens = [
    StoryPlayerScreen(),
    PlayScreen(),
    StoryGraphScreen(),
    AiGeneratorScreen(),
    GameDataHomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final titles = [
      tr(ref, 'title_story'),
      tr(ref, 'title_play'),
      tr(ref, 'title_map'),
      tr(ref, 'title_generate'),
      tr(ref, 'title_data'),
    ];
    final language = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
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
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.menu_book), label: tr(ref, 'nav_story')),
          NavigationDestination(
            icon: const Icon(Icons.videogame_asset),
            label: tr(ref, 'nav_play'),
          ),
          NavigationDestination(icon: const Icon(Icons.account_tree), label: tr(ref, 'nav_map')),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome),
            label: tr(ref, 'nav_generate'),
          ),
          NavigationDestination(icon: const Icon(Icons.storage), label: tr(ref, 'nav_data')),
        ],
      ),
    );
  }
}

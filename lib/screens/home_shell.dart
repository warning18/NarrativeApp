import 'package:flutter/material.dart';

import 'ai_generator_screen.dart';
import 'game_data_home_screen.dart';
import 'play_screen.dart';
import 'settings_screen.dart';
import 'story_graph_screen.dart';
import 'story_player_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<String> _titles = [
    'Story',
    'Play',
    'Story Map',
    'AI Generator',
    'Game Data',
  ];

  static const List<Widget> _screens = [
    StoryPlayerScreen(),
    PlayScreen(),
    StoryGraphScreen(),
    AiGeneratorScreen(),
    GameDataHomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Story'),
          NavigationDestination(icon: Icon(Icons.videogame_asset), label: 'Play'),
          NavigationDestination(icon: Icon(Icons.account_tree), label: 'Map'),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: 'Generate',
          ),
          NavigationDestination(icon: Icon(Icons.storage), label: 'Data'),
        ],
      ),
    );
  }
}

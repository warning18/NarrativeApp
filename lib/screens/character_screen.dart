import 'package:flutter/material.dart';

import '../widgets/player_stats_bar.dart';
import 'dice_loadout_screen.dart';
import 'inventory_screen.dart';
import 'level_up_screen.dart';
import 'skills_screen.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PlayerStatsBar(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backpack),
              title: const Text('Inventory & Equipment'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Skills'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SkillsScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Level Up'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LevelUpScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.casino),
              title: const Text('Dice Loadout'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiceLoadoutScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

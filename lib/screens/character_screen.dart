import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../widgets/player_stats_bar.dart';
import 'dice_loadout_screen.dart';
import 'inventory_screen.dart';
import 'level_up_screen.dart';
import 'race_profession_screen.dart';
import 'skills_screen.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));

    String subtitle = tr(ref, 'char_not_set');
    final races = racesAsync.value;
    final professions = professionsAsync.value;
    if (session.raceId.isNotEmpty && session.professionId.isNotEmpty) {
      final race = races?[session.raceId] as Map<String, dynamic>?;
      final profession = professions?[session.professionId] as Map<String, dynamic>?;
      final raceName = race?['raceName']?.toString() ?? session.raceId;
      final professionName = profession?['professionName']?.toString() ?? session.professionId;
      subtitle = '$raceName $professionName';
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'character'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PlayerStatsBar(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(tr(ref, 'race_profession_title')),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RaceProfessionScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backpack),
              title: Text(tr(ref, 'inventory_equipment')),
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
              title: Text(tr(ref, 'skills')),
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
              title: Text(tr(ref, 'level_up')),
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
              title: Text(tr(ref, 'dice_loadout')),
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

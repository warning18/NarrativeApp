import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

class LevelUpScreen extends ConsumerWidget {
  const LevelUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final notifier = ref.read(playerSessionProvider.notifier);

    Widget statRow(
        String label, IconData icon, String valueText, String statKey) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          subtitle: Text(valueText),
          trailing: ElevatedButton(
            onPressed: session.statPoints > 0
                ? () async {
                    await notifier.spendStatPoint(stat: statKey);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('$label ${tr(ref, 'increased_suffix')}')),
                    );
                  }
                : null,
            child: Text(tr(ref, 'plus_one_point')),
          ),
        ),
      );
    }

    final xpRatio = session.xpToNextLevel == 0
        ? 0.0
        : session.currentXP / session.xpToNextLevel;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'level_up'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${tr(ref, 'level_field_label')} ${session.level}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
              '${tr(ref, 'xp_label')}: ${session.currentXP} / ${session.xpToNextLevel}'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: xpRatio, minHeight: 8),
          ),
          const SizedBox(height: 16),
          Text(
            '${tr(ref, 'stat_points_available')}: ${session.statPoints}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          statRow(tr(ref, 'base_damage_label'), Icons.gavel,
              '${session.baseDamage}', 'damage'),
          statRow(tr(ref, 'base_armor_label'), Icons.shield,
              '${session.baseArmor}', 'armor'),
          statRow(
            tr(ref, 'max_health_label'),
            Icons.favorite,
            '${session.currentHealth} / ${session.maxHealth}',
            'health',
          ),
          statRow(tr(ref, 'luck_label'), Icons.auto_awesome, '${session.luck}',
              'luck'),
          statRow(tr(ref, 'charisma_label'), Icons.forum, '${session.charisma}',
              'charisma'),
          statRow(tr(ref, 'strength_label'), Icons.fitness_center,
              '${session.strength}', 'strength'),
          statRow(tr(ref, 'dexterity_label'), Icons.directions_run,
              '${session.dexterity}', 'dexterity'),
          statRow(tr(ref, 'constitution_label'), Icons.health_and_safety,
              '${session.constitution}', 'constitution'),
          statRow(tr(ref, 'intelligence_label'), Icons.psychology,
              '${session.intelligence}', 'intelligence'),
          statRow(tr(ref, 'wisdom_label'), Icons.visibility,
              '${session.wisdom}', 'wisdom'),
        ],
      ),
    );
  }
}

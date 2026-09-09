import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_session_provider.dart';

class LevelUpScreen extends ConsumerWidget {
  const LevelUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final notifier = ref.read(playerSessionProvider.notifier);

    Widget statRow(String label, IconData icon, String valueText, String statKey) {
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
                      SnackBar(content: Text('$label increased!')),
                    );
                  }
                : null,
            child: const Text('+1 Point'),
          ),
        ),
      );
    }

    final xpRatio =
        session.xpToNextLevel == 0 ? 0.0 : session.currentXP / session.xpToNextLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('Level Up')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Level ${session.level}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('XP: ${session.currentXP} / ${session.xpToNextLevel}'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: xpRatio, minHeight: 8),
          ),
          const SizedBox(height: 16),
          Text(
            'Stat Points Available: ${session.statPoints}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          statRow('Base Damage', Icons.gavel, '${session.baseDamage}', 'damage'),
          statRow('Base Armor', Icons.shield, '${session.baseArmor}', 'armor'),
          statRow(
            'Max Health',
            Icons.favorite,
            '${session.currentHealth} / ${session.maxHealth}',
            'health',
          ),
        ],
      ),
    );
  }
}

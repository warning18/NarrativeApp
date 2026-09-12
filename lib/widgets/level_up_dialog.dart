import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// Shown right after a fight that leveled the character up. Lets the player
/// spend their new stat point(s) immediately, right in the modal, or close
/// it and distribute them later from the Level Up screen — either way the
/// points aren't lost.
Future<void> showLevelUpDialog(BuildContext context, WidgetRef ref, {required int newLevel}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LevelUpDialog(newLevel: newLevel),
  );
}

class _LevelUpDialog extends ConsumerWidget {
  const _LevelUpDialog({required this.newLevel});

  final int newLevel;

  Widget _statButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required String valueText,
    required String statKey,
    required bool enabled,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(valueText),
        trailing: ElevatedButton(
          onPressed: enabled
              ? () => ref.read(playerSessionProvider.notifier).spendStatPoint(stat: statKey)
              : null,
          child: Text(tr(ref, 'plus_one_point')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final hasPoints = session.statPoints > 0;

    return AlertDialog(
      icon: const Icon(Icons.military_tech, size: 36),
      title: Text('${tr(ref, 'level_up')}! ${tr(ref, 'level_field_label')} $newLevel'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tr(ref, 'stat_points_available')}: ${session.statPoints}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _statButton(
              context,
              ref,
              label: tr(ref, 'base_damage_label'),
              icon: Icons.gavel,
              valueText: '${session.baseDamage}',
              statKey: 'damage',
              enabled: hasPoints,
            ),
            _statButton(
              context,
              ref,
              label: tr(ref, 'base_armor_label'),
              icon: Icons.shield,
              valueText: '${session.baseArmor}',
              statKey: 'armor',
              enabled: hasPoints,
            ),
            _statButton(
              context,
              ref,
              label: tr(ref, 'max_health_label'),
              icon: Icons.favorite,
              valueText: '${session.currentHealth} / ${session.maxHealth}',
              statKey: 'health',
              enabled: hasPoints,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(tr(ref, hasPoints ? 'distribute_later_button' : 'close_button')),
        ),
      ],
    );
  }
}

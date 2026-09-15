import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// Shown right after a fight that leveled the character up. Lets the player
/// spend their new stat point(s) immediately, right in the modal, or close
/// it and distribute them later from the Level Up screen — either way the
/// points aren't lost.
Future<void> showLevelUpDialog(BuildContext context, WidgetRef ref,
    {required int newLevel}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LevelUpDialog(newLevel: newLevel),
  );
}

class _LevelUpDialog extends ConsumerWidget {
  const _LevelUpDialog({required this.newLevel});

  final int newLevel;

  static const _gold = Color(0xFFD4A017);

  Widget _statButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required String valueText,
    required String statKey,
    required bool enabled,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Icon(icon, size: 20),
        ),
        title: Text(label),
        subtitle: Text(valueText),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          onPressed: enabled
              ? () => ref
                  .read(playerSessionProvider.notifier)
                  .spendStatPoint(stat: statKey)
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
      icon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5D57A), _gold],
          ),
          boxShadow: [
            BoxShadow(
                color: Color(0x55D4A017), blurRadius: 16, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.military_tech, size: 32, color: Colors.white),
      ),
      title: Text(
        '${tr(ref, 'level_up')}! ${tr(ref, 'level_field_label')} $newLevel',
        textAlign: TextAlign.center,
        style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tr(ref, 'stat_points_available')}: ${session.statPoints}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: _gold, fontWeight: FontWeight.w600),
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
              color: Colors.redAccent,
            ),
            _statButton(
              context,
              ref,
              label: tr(ref, 'base_armor_label'),
              icon: Icons.shield,
              valueText: '${session.baseArmor}',
              statKey: 'armor',
              enabled: hasPoints,
              color: Colors.blueAccent,
            ),
            _statButton(
              context,
              ref,
              label: tr(ref, 'max_health_label'),
              icon: Icons.favorite,
              valueText: '${session.currentHealth} / ${session.maxHealth}',
              statKey: 'health',
              enabled: hasPoints,
              color: Colors.pinkAccent,
            ),
            _statButton(
              context,
              ref,
              label: tr(ref, 'luck_label'),
              icon: Icons.auto_awesome,
              valueText: '${session.luck}',
              statKey: 'luck',
              enabled: hasPoints,
              color: Colors.purpleAccent,
            ),
            _statButton(
              context,
              ref,
              label: tr(ref, 'charisma_label'),
              icon: Icons.forum,
              valueText: '${session.charisma}',
              statKey: 'charisma',
              enabled: hasPoints,
              color: Colors.teal,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(
              tr(ref, hasPoints ? 'distribute_later_button' : 'close_button')),
        ),
      ],
    );
  }
}

// "Qui combat ?" -- the pre-fight pick (combat redesign, round 6/7): with
// more companions able to fight than seats, the player chooses who goes
// (the player and two at most). The hero is locked in, the picked ones are
// checked, the bench is dimmed once the seats are full, and a toggle keeps
// the pick as the party. The state is Core's (fightPickProvider, v1.667).
import 'package:flutter/material.dart';

import 'head_avatar.dart';
import '../theme/icon_sizes.dart';

/// One companion who could fight.
class FightPickOption {
  const FightPickOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class FightPickCard extends StatelessWidget {
  const FightPickCard({
    super.key,
    required this.title,
    required this.hint,
    required this.heroName,
    required this.options,
    required this.picked,
    required this.seats,
    required this.onToggle,
    required this.keepLabel,
    required this.keep,
    required this.onKeep,
  });

  final String title;
  final String hint;
  final String heroName;
  final List<FightPickOption> options;
  final List<String> picked;
  final int seats;
  final void Function(String id, bool on) onToggle;
  final String keepLabel;
  final bool keep;
  final ValueChanged<bool> onKeep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = picked.length >= seats;
    return Card(
      key: const Key('fight_pick_card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(hint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: HeadAvatar(id: 'hero', name: heroName, size: 40),
              title: Text(heroName),
              trailing: const Icon(Icons.lock_outline, size: IconSize.s16),
            ),
            for (final o in options)
              Builder(builder: (context) {
                final on = picked.contains(o.id);
                final disabled = !on && full;
                return CheckboxListTile(
                  key: Key('fight_pick_${o.id}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: HeadAvatar(
                      id: o.id, name: o.name, size: 40, dim: disabled),
                  title: Text(o.name),
                  value: on,
                  onChanged:
                      disabled ? null : (v) => onToggle(o.id, v ?? false),
                );
              }),
            SwitchListTile(
              key: const Key('fight_pick_keep'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(keepLabel, style: theme.textTheme.bodySmall),
              value: keep,
              onChanged: onKeep,
            ),
          ],
        ),
      ),
    );
  }
}

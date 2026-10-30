// "Qui combat ?" -- the pre-fight pick (combat redesign, round 6/7): with
// more companions able to fight than seats, the player chooses who goes
// (the player and two at most). The hero is locked in, the picked ones are
// checked, the bench is dimmed once the seats are full, and a toggle keeps
// the pick as the party. The state is Core's (fightPickProvider, v1.667).
import 'package:flutter/material.dart';

/// One companion who could fight.
class FightPickOption {
  const FightPickOption({
    required this.id,
    required this.name,
    this.headAsset,
  });

  final String id;
  final String name;
  final String? headAsset;
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

  Widget _head(BuildContext context, String? asset, String name,
      {bool dim = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: asset == null
            ? Center(
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.primary,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.bold)),
                ),
              )
            : Image.asset(asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
      ),
    );
  }

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
              leading:
                  _head(context, 'assets/visuals/heads/hero.png', heroName),
              title: Text(heroName),
              trailing: const Icon(Icons.lock_outline, size: 18),
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
                  secondary: _head(context, o.headAsset, o.name, dim: disabled),
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

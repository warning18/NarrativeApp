// How the eight abilities look wherever they are shown (v1.223): one icon
// each, and a pill that names an ability with its icon.
import 'package:flutter/material.dart';
import '../theme/icon_sizes.dart';
import '../theme/pixel_chip.dart';

/// The icon of an ability (one of abilityScoreKeys).
IconData abilityIcon(String key) => switch (key) {
      'strength' => Icons.fitness_center,
      'dexterity' => Icons.directions_run,
      'constitution' => Icons.health_and_safety,
      'intelligence' => Icons.psychology,
      'wisdom' => Icons.visibility,
      'perception' => Icons.radar,
      'luck' => Icons.auto_awesome,
      'charisma' => Icons.forum,
      _ => Icons.auto_awesome,
    };

/// A rounded tag: an icon and a short [label] in [color].
class AbilityPill extends StatelessWidget {
  const AbilityPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.14),
        shape: PixelChipBorder(
            side: BorderSide(color: color.withValues(alpha: 0.7))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSize.s16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

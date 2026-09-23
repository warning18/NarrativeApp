import 'package:flutter/material.dart';

import '../utils/game_icons.dart';

/// A row of small pips, one per point of the mana pool, filled up to the
/// current mana -- the same meter the battle screen's action bar shows.
/// Pips are skipped past ten points (the text next to it carries the
/// number then), so a late-game pool never turns into a wall of dots.
class ManaMeter extends StatelessWidget {
  const ManaMeter({
    super.key,
    required this.mana,
    required this.maxMana,
    this.pipSize = 7,
  });

  final int mana;
  final int maxMana;
  final double pipSize;

  @override
  Widget build(BuildContext context) {
    if (maxMana <= 0 || maxMana > 10) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < maxMana; i++)
          Container(
            width: pipSize,
            height: pipSize,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < mana ? manaColor : manaColor.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }
}

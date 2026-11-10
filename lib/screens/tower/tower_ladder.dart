// The Tower's ladder (v1.847+, the-tower-designs.md direction B's idea kept
// inside A's look): 30 floors from the bottom (1) to the top (30), the floors
// climbed filled in gold, the floor the party stands on lit with its number,
// the wardens (5, 15, 25) wider and the bosses (10, 20, 30) widest, with
// their number beside them.
import 'package:flutter/material.dart';

import '../../data/tower/tower_tables.dart';
import '../../theme/stitched_ink.dart';
import 'tower_look.dart';

/// The width the ladder takes.
const double towerLadderWidth = 40;

class TowerLadder extends StatelessWidget {
  const TowerLadder({super.key, required this.floor});

  /// The floor the party stands on (1 to 30).
  final int floor;

  static bool isWarden(int n) => n % 10 == 5;
  static bool isBoss(int n) => n % 10 == 0;

  /// The stone of floor [n] in the proposed looks (A: courses of stone in the
  /// band's colour with a bevel, the floor stood on a lit lantern stone; B:
  /// a stair of arched windows, lit up to the floor climbed to).
  Widget _proposed(BuildContext context, int n) {
    final ink = InkColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelSmall;
    final dark = scheme.brightness == Brightness.dark;
    final band = n <= 10
        ? 0
        : n <= 20
            ? 1
            : 2;
    final stone = [
      const Color(0xFFB59A74),
      const Color(0xFF8F8AA8),
      const Color(0xFF8A8076),
    ][band];
    final here = n == floor;
    final done = n < floor;
    final w = isBoss(n)
        ? towerLadderWidth - 4
        : isWarden(n)
            ? 28.0
            : 20.0;
    if (towerLook == TowerLookOption.b) {
      final lit = here || done;
      return Container(
        width: w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF211E28) : const Color(0xFF3B3446),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(
              color: isBoss(n) ? ink.blood : const Color(0xFF14121A),
              width: 1.2),
          boxShadow: here
              ? [
                  BoxShadow(
                      color: ink.gold.withValues(alpha: .7), blurRadius: 9)
                ]
              : null,
        ),
        child: here
            ? Text('$n',
                style: label?.copyWith(
                    fontWeight: FontWeight.w800, color: ink.gold, height: 1))
            : isBoss(n)
                ? Text('$n',
                    style: label?.copyWith(color: Colors.white70, height: 1))
                : Container(
                    width: w * 0.36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: lit
                          ? ink.gold.withValues(alpha: .85)
                          : const Color(0xFF14121A),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
      );
    }
    return Container(
      width: w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: here
            ? ink.gold
            : done
                ? ink.gold.withValues(alpha: .7)
                : stone.withValues(alpha: .55),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .5), width: 1),
          left: BorderSide(color: Colors.white.withValues(alpha: .3), width: 1),
          bottom: BorderSide(
              color:
                  isBoss(n) ? ink.blood : Colors.black.withValues(alpha: .35),
              width: isBoss(n) ? 1.6 : 1),
          right:
              BorderSide(color: Colors.black.withValues(alpha: .25), width: 1),
        ),
        boxShadow: here
            ? [BoxShadow(color: ink.gold.withValues(alpha: .6), blurRadius: 6)]
            : null,
      ),
      child: here || isBoss(n)
          ? Text('$n',
              style: label?.copyWith(
                  fontWeight: here ? FontWeight.w800 : FontWeight.w500,
                  color: here ? scheme.surface : scheme.onSurface,
                  height: 1))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelSmall;
    if (towerLooked) {
      return SizedBox(
        key: const Key('tower_ladder'),
        width: towerLadderWidth,
        child: Column(children: [
          for (var n = towerTop; n >= 1; n--)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Center(child: _proposed(context, n)),
              ),
            ),
        ]),
      );
    }
    return SizedBox(
      key: const Key('tower_ladder'),
      width: towerLadderWidth,
      child: Column(
        children: [
          for (var n = towerTop; n >= 1; n--)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Center(
                  child: n == floor
                      ? Container(
                          key: const Key('tower_ladder_here'),
                          width: towerLadderWidth - 4,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ink.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text('$n',
                              style: label?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.surface,
                                  height: 1)),
                        )
                      : Container(
                          width: isBoss(n)
                              ? towerLadderWidth - 4
                              : isWarden(n)
                                  ? 26
                                  : 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: n < floor
                                ? ink.gold.withValues(alpha: .55)
                                : ink.seam.withValues(alpha: .55),
                            border: isBoss(n)
                                ? Border.all(color: ink.blood, width: 1.2)
                                : null,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: isBoss(n)
                              ? Text('$n',
                                  style: label?.copyWith(
                                      color: scheme.onSurface, height: 1))
                              : null,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

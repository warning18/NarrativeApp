// The block of a fighter on the fight board (UX, the user's pick "C,
// nameplate and gems"): a nameplate across the top (the side's or the group's
// colour, its emblem, the name, the rank), under it the head with the armour
// and the damage as two gems on its corner, the health bar beside it, the
// status chips and the intent under the bar. The numbers sit in the same place
// on every block; only the nameplate, the emblem and the corner ornament say
// whom the party fights (enemy_groups.dart).
//
// This widget only draws: what each part holds (the bar, the chips, the
// intent) and what a tap does stay with the fight (fight_board_view.dart).
import 'package:flutter/material.dart';

import '../theme/icon_sizes.dart';
import '../theme/palette.dart';
import '../theme/pixel_chip.dart';
import '../theme/stitched_ink.dart';
import 'enemy_groups.dart';

/// How a fighter ranks: an Elite's frame goes gold, a boss's too, with its mark.
enum FightRank { normal, elite, boss }

class FightBlock extends StatelessWidget {
  const FightBlock({
    super.key,
    required this.name,
    required this.plateColor,
    required this.head,
    required this.bar,
    this.chips = const [],
    this.intent,
    this.order,
    this.rank = FightRank.normal,
    this.group,
    this.armor,
    this.damage,
    this.fill,
    this.borderColor,
    this.borderWidth,
  });

  /// The nameplate's text, its colour, and the turn number before the name.
  final String name;
  final Color plateColor;
  final int? order;
  final FightRank rank;

  /// The enemy's group: its emblem on the nameplate and its corner ornament.
  /// Null for the party.
  final EnemyGroup? group;

  /// The head (about 32 dp), the health bar, the status chips and the intent.
  final Widget head;
  final Widget bar;
  final List<Widget> chips;
  final Widget? intent;

  /// The gems on the head's corner; null hides one (an enemy with no guard).
  final int? armor;
  final int? damage;

  /// The block's fill and frame; the frame defaults to the plate's colour (gold
  /// for a rank).
  final Color? fill;
  final Color? borderColor;
  final double? borderWidth;

  static const double plateHeight = 17;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ranked = rank != FightRank.normal;
    final frame = borderColor ?? (ranked ? Palette.goldDeep : plateColor);
    final plateInk =
        ThemeData.estimateBrightnessForColor(plateColor) == Brightness.light
            ? const Color(0xFF090A14)
            : const Color(0xFFEBEDE9);
    final g = group;
    return DecoratedBox(
      key: Key('fight_block_${name}_${g?.id ?? 'ally'}'),
      decoration: ShapeDecoration(
        color: fill ?? scheme.surface,
        shape: PixelChipBorder(
          side:
              BorderSide(color: frame, width: borderWidth ?? (ranked ? 3 : 2)),
          step: 3,
          steps: 3,
        ),
      ),
      child: CustomPaint(
        foregroundPainter: g == null
            ? null
            : OrnamentPainter(
                g.ornament,
                Color.lerp(plateColor, const Color(0xFFEBEDE9), 0.55)!,
                const Color(0xFF090A14)),
        child: Column(
          children: [
            Container(
              height: plateHeight,
              margin: const EdgeInsets.fromLTRB(3, 3, 3, 0),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: plateColor,
              child: Row(
                children: [
                  if (g != null) ...[
                    GroupEmblem(g, size: 13, color: plateInk),
                    const SizedBox(width: 3),
                  ] else if (order != null) ...[
                    Text('$order',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: plateInk)),
                    const SizedBox(width: 3),
                  ],
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name,
                        maxLines: 1,
                        style: TextStyle(
                            fontFamily: InkFonts.display,
                            fontSize: 13,
                            height: 1,
                            color: plateInk),
                      ),
                    ),
                  ),
                  if (rank != FightRank.normal) _rankMark(plateInk),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 3, 5, 2),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(width: 32, height: 32, child: head),
                        if (armor != null)
                          Positioned(
                            left: -2,
                            bottom: -12,
                            child: _gem(context, Icons.shield_outlined,
                                '$armor', Palette.slate),
                          ),
                        if (damage != null)
                          Positioned(
                            right: -6,
                            bottom: -12,
                            child: _gem(
                                context, Icons.bolt, '$damage', Palette.hot),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          bar,
                          const SizedBox(height: 3),
                          SizedBox(
                            height: 20,
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: chips),
                                  ),
                                ),
                                if (intent != null)
                                  Flexible(
                                    flex: 0,
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 92),
                                      child: intent,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rankMark(Color ink) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rank == FightRank.boss ? Icons.workspace_premium : Icons.star,
              size: IconSize.inline, color: ink),
          const SizedBox(width: 1),
          Text(rank == FightRank.boss ? 'BOSS' : 'ELITE',
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 8,
                  height: 1,
                  color: ink)),
        ],
      );

  /// A gem on the head's corner: the number in the readable face, a small mark
  /// over it.
  Widget _gem(BuildContext context, IconData icon, String value, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 19,
      height: 19,
      decoration: ShapeDecoration(
        color: scheme.surface,
        shape: PixelChipBorder(
            side: BorderSide(color: color, width: 1.5), step: 2, steps: 2),
      ),
      alignment: Alignment.center,
      // A long number (a boss's armour, a big blow) shrinks to the gem.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: IconSize.inline, color: color),
              Text(value,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                      fontFamily: InkFonts.prose,
                      fontWeight: FontWeight.w700,
                      fontSize: 8,
                      height: 1,
                      color: scheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

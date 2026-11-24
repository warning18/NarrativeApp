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

import '../screens/tower/ink/ink_palette.dart';
import '../screens/tower/tower_look.dart' show TowerPanelStyle;
import '../theme/icon_sizes.dart';
import '../theme/palette.dart';
import '../theme/pixel_chip.dart';
import '../theme/stitched_ink.dart';
import 'enemy_groups.dart';

/// A weakness (×3, red) or a resistance (×½, grey) on a foe's nameplate:
/// the element's icon and the factor. [lit] rings the weak mark while the
/// picked die is of that element (the hint under the dice says the same).
class FightMark {
  const FightMark(
      {required this.icon,
      required this.text,
      required this.weak,
      this.lit = false,
      this.tip});
  final IconData icon;
  final String text;
  final bool weak;
  final bool lit;
  final String? tip;
}

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
    this.groupName,
    this.marks = const [],
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

  /// The group's name in the player's language, said by the emblem's tooltip
  /// and its screen-reader label (v1.1003).
  final String? groupName;

  /// Weakness and resistance marks, on the nameplate after the name.
  final List<FightMark> marks;

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

  Widget _emblem(EnemyGroup g, Color ink) {
    final emblem = GroupEmblem(g, size: 13, color: ink);
    final label = groupName;
    if (label == null || label.isEmpty) return emblem;
    return Tooltip(
      message: label,
      child: Semantics(label: label, child: emblem),
    );
  }

  /// A plate whose name takes two lines (#1100).
  static const double plateHeightTwoLines = 26;

  Widget _markChip(BuildContext context, FightMark m, Color ink) {
    final inked = TowerPanelStyle.of(context);
    final colour = inked
        ? (m.weak ? inkRed : inkSlate)
        : (m.weak ? Palette.hot : Palette.slate);
    final chip = Container(
      key: Key(
          'fight_mark_${m.weak ? 'weak' : 'resist'}_${m.text}_${m.icon.codePoint}'),
      margin: const EdgeInsets.only(left: 3),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Palette.apolloOutline,
        border: Border.all(color: colour, width: m.lit ? 2 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(m.icon, size: IconSize.inline, color: Palette.apolloCream),
        const SizedBox(width: 1),
        Text(m.text,
            style: TextStyle(
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.bold,
                color: m.weak ? Palette.apolloCream : Palette.slate)),
      ]),
    );
    final tip = m.tip;
    return tip == null ? chip : Tooltip(message: tip, child: chip);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ranked = rank != FightRank.normal;
    // The Tower's fights are in ink (v1.1006): a black block, a paper bar on
    // its left (red for an Elite or a boss, or the fighter aimed at), a black
    // nameplate; no colour of the side, no ornament.
    final inked = TowerPanelStyle.of(context);
    final frame = inked
        ? (ranked || borderColor != null ? inkRed : inkPaper)
        : borderColor ?? (ranked ? Palette.goldDeep : plateColor);
    final plateInk = inked
        ? inkPaper
        : ThemeData.estimateBrightnessForColor(plateColor) == Brightness.light
            ? Palette.apolloOutline
            : Palette.apolloCream;
    final plate = inked ? inkBlack : plateColor;
    final g = group;
    return DecoratedBox(
      key: Key('fight_block_${name}_${g?.id ?? 'ally'}'),
      decoration: inked
          ? BoxDecoration(
              color: inkBlack,
              border: Border(
                  left: BorderSide(color: frame, width: 4),
                  top: const BorderSide(color: inkSlate),
                  right: const BorderSide(color: inkSlate),
                  bottom: const BorderSide(color: inkSlate)),
            )
          : ShapeDecoration(
              color: fill ?? scheme.surface,
              shape: PixelChipBorder(
                side: BorderSide(
                    color: frame, width: borderWidth ?? (ranked ? 3 : 2)),
                step: 3,
                steps: 3,
              ),
            ),
      child: CustomPaint(
        foregroundPainter: g == null || inked
            ? null
            : OrnamentPainter(
                g.ornament,
                Color.lerp(plateColor, Palette.apolloCream, 0.55)!,
                Palette.apolloOutline),
        child: LayoutBuilder(builder: (context, box) {
          // The marks sit on the plate while the name stays readable beside
          // them; otherwise they drop to the chip row under it.
          final ranked = rank != FightRank.normal;
          // A name that cannot stay readable on one line takes two, and its
          // marks go under the plate.
          final twoLines =
              !_nameFitsBeside(box.maxWidth, ranked: ranked, marks: 0);
          final onPlate = !twoLines &&
              (marks.isEmpty ||
                  _nameFitsBeside(box.maxWidth,
                      ranked: ranked, marks: marks.length));
          return Column(
            children: [
              Container(
                height: twoLines ? plateHeightTwoLines : plateHeight,
                margin: const EdgeInsets.fromLTRB(3, 3, 3, 0),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: plate,
                child: Row(
                  children: [
                    if (g != null) ...[
                      _emblem(g, plateInk),
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
                      child: twoLines
                          ? LayoutBuilder(
                              builder: (context, line) => FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints:
                                      BoxConstraints(maxWidth: line.maxWidth),
                                  child: Text(
                                    name,
                                    maxLines: 3,
                                    style: TextStyle(
                                        fontFamily: InkFonts.display,
                                        fontSize: 11,
                                        height: 1.02,
                                        color: plateInk),
                                  ),
                                ),
                              ),
                            )
                          : FittedBox(
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
                    if (marks.isNotEmpty && onPlate)
                      for (final m in marks) _markChip(context, m, plateInk),
                    // A two-line plate keeps the badge's icon only: the frame says the rest.
                    if (ranked) _rankMark(plateInk, iconOnly: twoLines),
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
                          SizedBox(
                              width: 32,
                              height: 32,
                              child: inked
                                  // The Tower's ink: the portrait in greys.
                                  ? ColorFiltered(
                                      colorFilter: _inkHead, child: head)
                                  : head),
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
                                  if (!onPlate)
                                    Flexible(
                                      flex: 2,
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 104),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Row(children: [
                                            if (!onPlate)
                                              for (final m in marks)
                                                _markChip(context, m, plateInk),
                                          ]),
                                        ),
                                      ),
                                    ),
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
          );
        }),
      ),
    );
  }

  /// Whether the name stays at a readable size (at least 85 % of its 13 sp,
  /// on one line) on a plate [width] wide with its emblem or number, [marks]
  /// marks and its rank beside it.
  bool _nameFitsBeside(double width,
      {required bool ranked, required int marks}) {
    final painter = TextPainter(
      text: TextSpan(
          text: name,
          style: const TextStyle(
              fontFamily: InkFonts.display, fontSize: 13, height: 1)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    // Margins 6, padding 8, emblem or number 16, a mark about 33, the rank 48.
    final room = width - 6 - 8 - 16 - marks * 33 - (ranked ? 48 : 0);
    return room >= painter.width * 0.85;
  }

  Widget _rankMark(Color ink, {bool iconOnly = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rank == FightRank.boss ? Icons.workspace_premium : Icons.star,
              size: IconSize.inline, color: ink),
          if (!iconOnly) ...[
            const SizedBox(width: 1),
            Text(rank == FightRank.boss ? 'BOSS' : 'ELITE',
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 8,
                    height: 1,
                    color: ink)),
          ],
        ],
      );

  /// A gem on the head's corner: the number in the readable face, a small mark
  /// over it.
  Widget _gem(BuildContext context, IconData icon, String value, Color color) {
    final scheme = Theme.of(context).colorScheme;
    // Ink: a square gem, paper (red for the damage).
    final inked = TowerPanelStyle.of(context);
    if (inked) color = icon == Icons.bolt ? inkRed : inkPaper;
    return Container(
      width: 19,
      height: 19,
      decoration: inked
          ? BoxDecoration(
              color: inkBlack, border: Border.all(color: color, width: 1.5))
          : ShapeDecoration(
              color: scheme.surface,
              shape: PixelChipBorder(
                  side: BorderSide(color: color, width: 1.5),
                  step: 2,
                  steps: 2),
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

/// A portrait in the ink greys.
const ColorFilter _inkHead = ColorFilter.matrix(<double>[
  0.40, 0.40, 0.40, 0, 0, //
  0.40, 0.40, 0.40, 0, 4,
  0.42, 0.42, 0.42, 0, 8,
  0, 0, 0, 1, 0,
]);

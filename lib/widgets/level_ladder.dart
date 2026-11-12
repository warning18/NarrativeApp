// The ladder of maps: one strip of four rungs, World · Town · District ·
// Room. The rung looked at is lit; a rung that does not exist here (no town
// plan, no room) is dimmed, never hidden, so the strip keeps its shape and
// every rung its place. Its look is UX's; the Journey says which rung is
// lit, which are open, and what a tap does.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart' show ChartPalette;
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';

/// The rungs, from the widest view to the closest, in the order they are
/// drawn.
enum LadderRung { world, town, district, room }

// ---- The look, in one place (the map's own palette, no frame). ----

/// A rung's height and side padding, and its text.
const double ladderRungHeight = 36;
const double ladderRungPadding = 12;
const double ladderTextSize = 12;

/// The strip's border, and the line under the lit rung.
const double ladderBorderWidth = 2;
const double ladderLitLineWidth = 2;

/// How strongly the lit rung is washed with its colour, how solid the
/// strip's ground is, and how faint a rung that cannot be taken is.
const double ladderLitWash = 0.18;
const double ladderGroundAlpha = 0.92;
const double ladderClosedAlpha = 0.5;

/// The colours, by role, from the map's palette.
Color ladderLitColour(ChartPalette p) => p.mark;
Color ladderOpenColour(ChartPalette p) => p.place;
Color ladderClosedColour(ChartPalette p) =>
    p.label.withValues(alpha: ladderClosedAlpha);
Color ladderGroundColour(ChartPalette p) =>
    p.land.withValues(alpha: ladderGroundAlpha);
Color ladderBorderColour(ChartPalette p) => p.coast;

class LevelLadder extends ConsumerWidget {
  const LevelLadder({
    super.key,
    required this.lit,
    required this.open,
    required this.palette,
    required this.onPick,
    this.busy = false,
  });

  /// The rung looked at; null on a locked page, where none is lit.
  final LadderRung? lit;

  /// The rungs that can be taken from here; the others are dimmed.
  final Set<LadderRung> open;

  /// While true (a move is playing) no rung answers a tap.
  final bool busy;
  final ChartPalette palette;
  final ValueChanged<LadderRung> onPick;

  static const _labels = {
    LadderRung.world: 'journey_tab_world',
    LadderRung.town: 'journey_tab_town',
    LadderRung.district: 'journey_tab_district',
    LadderRung.room: 'journey_tab_room',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget rung(LadderRung r) {
      final on = r == lit;
      final canTake = open.contains(r);
      final colour = on
          ? ladderLitColour(palette)
          : canTake
              ? ladderOpenColour(palette)
              : ladderClosedColour(palette);
      return InkWell(
        key: Key('journey_tab_${r.name}'),
        onTap: canTake && !busy && !on ? () => onPick(r) : null,
        child: Container(
          height: ladderRungHeight,
          padding: const EdgeInsets.symmetric(horizontal: ladderRungPadding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on
                ? ladderLitColour(palette).withValues(alpha: ladderLitWash)
                : null,
            border: Border(
              bottom: BorderSide(
                  color: on ? ladderLitColour(palette) : Colors.transparent,
                  width: ladderLitLineWidth),
            ),
          ),
          child: Text(tr(ref, _labels[r]!),
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: ladderTextSize,
                  height: 1,
                  color: colour)),
        ),
      );
    }

    // Four rungs on one line: on a narrow screen the strip shrinks as a
    // whole and never wraps or overflows.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: ladderGroundColour(palette),
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: ladderBorderColour(palette), width: ladderBorderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          key: const Key('journey_level_tabs'),
          mainAxisSize: MainAxisSize.min,
          children: [for (final r in LadderRung.values) rung(r)],
        ),
      ),
    );
  }
}

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
const double _ladderRungHeight = 36;
const double _ladderRungPadding = 12;
const double _ladderTextSize = 12;

/// The strip's border, and the line under the lit rung.
const double _ladderBorderWidth = 2;
const double _ladderLitLineWidth = 2;

/// How strongly the lit rung is washed with its colour, how solid the
/// strip's ground is, and how faint a rung that cannot be taken is.
const double _ladderLitWash = 0.18;
const double _ladderGroundAlpha = 0.92;
const double _ladderClosedAlpha = 0.5;

/// The colours, by role, from the map's palette.
Color _ladderLitColour(ChartPalette p) => p.mark;
Color _ladderOpenColour(ChartPalette p) => p.place;
Color _ladderClosedColour(ChartPalette p) =>
    p.label.withValues(alpha: _ladderClosedAlpha);
Color _ladderGroundColour(ChartPalette p) =>
    p.land.withValues(alpha: _ladderGroundAlpha);
Color _ladderBorderColour(ChartPalette p) => p.coast;

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
          ? _ladderLitColour(palette)
          : canTake
              ? _ladderOpenColour(palette)
              : _ladderClosedColour(palette);
      return InkWell(
        key: Key('journey_tab_${r.name}'),
        onTap: canTake && !busy && !on ? () => onPick(r) : null,
        child: Container(
          height: _ladderRungHeight,
          padding: const EdgeInsets.symmetric(horizontal: _ladderRungPadding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on
                ? _ladderLitColour(palette).withValues(alpha: _ladderLitWash)
                : null,
            border: Border(
              bottom: BorderSide(
                  color: on ? _ladderLitColour(palette) : Colors.transparent,
                  width: _ladderLitLineWidth),
            ),
          ),
          child: Text(tr(ref, _labels[r]!),
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: _ladderTextSize,
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
        color: _ladderGroundColour(palette),
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: _ladderBorderColour(palette), width: _ladderBorderWidth),
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

// The Tower's Heat in the ink (v2.9.1, UX-2): the door's picker, the chip on
// a floor with its curse list, and the end screen's lines. Rules, names and
// words are Core's and Narrative's (towerHeatLevels, tower_heat_* strings);
// this file only draws them. Paper and ink, one spot of colour: the picked
// level's ring and the chip's line take the level's flame colour, never red.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_tables.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/stitched_ink.dart';
import 'ink/ink_kit.dart';
import 'ink/ink_palette.dart';

/// Ashen Ink's `ember` (the picked level's ring and the chip's line, levels 1
/// to 4) and `ash` (the last level); the plain climb stays grey. Never red.
const Color _ember = Color(0xFFE0762B);
const Color _ash = Color(0xFF8A8478);

/// The Ashen Ink corner of panels, rows, chips and tabs (`radius-seam`, 4 px).
const double towerSeamRadius = 4;

Color towerHeatColor(int heat) => heat <= 0
    ? inkGrey
    : heat >= towerHeatMax
        ? _ash
        : _ember;

/// A level's name; the plain climb for 0.
String towerHeatName(WidgetRef ref, int heat) =>
    tr(ref, towerHeatLevelOf(heat)?.nameKey ?? towerHeatPlainKey);

String towerHeatLine(WidgetRef ref, int heat) =>
    tr(ref, towerHeatLevelOf(heat)?.lineKey ?? towerHeatPlainLineKey);

/// "1.25", "1.5", "2": no trailing zero (the French comma comes from the
/// reader's language).
String towerHeatMarksText(WidgetRef ref, int heat) {
  final f = towerHeatMarksFactor(heat);
  var s = f.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return ref.read(appLanguageProvider) == AppLanguage.fr
      ? s.replaceAll('.', ',')
      : s;
}

String towerHeatMarksLine(WidgetRef ref, int heat) => tr(
      ref,
      'tower_heat_marks',
    ).replaceAll('{n}', towerHeatMarksText(ref, heat));

Widget _flames(int n, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          Icon(Icons.local_fire_department, size: IconSize.s16, color: color),
      ],
    );

/// The door's picker: the plain climb and the open levels, one row each (its
/// flames, name, marks, and its curse in one line), the next one locked.
/// Hide it while nothing is open (`open` 0).
class TowerHeatPicker extends ConsumerWidget {
  const TowerHeatPicker({
    super.key,
    required this.open,
    required this.selected,
    required this.onChanged,
  });

  /// The highest level a new run may take (TowerProgress.heatOpen).
  final int open;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var h = 0; h <= towerHeatMax; h++)
          if (h <= open + 1) _row(context, ref, theme, h),
      ],
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, ThemeData theme, int h) {
    final locked = h > open;
    final on = h == selected && !locked;
    final ink = locked ? inkGrey : inkPaper;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        key: Key('tower_heat_$h'),
        onTap: locked ? null : () => onChanged(h),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(towerSeamRadius),
            color: inkBlack,
            border: Border.all(
              color: on ? towerHeatColor(h) : (locked ? inkSlate : inkGrey),
              width: on ? 2.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: locked
                    ? Icon(Icons.lock_outline, size: IconSize.s16, color: ink)
                    : h == 0
                        ? Icon(
                            Icons.horizontal_rule,
                            size: IconSize.s16,
                            color: ink,
                          )
                        : _flames(h, on ? towerHeatColor(h) : inkPaper),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      towerHeatName(ref, h),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: InkFonts.display,
                        color: ink,
                      ),
                    ),
                    Text(
                      locked
                          ? tr(
                              ref,
                              'tower_heat_locked',
                            ).replaceAll('{heat}', towerHeatName(ref, h - 1))
                          : towerHeatLine(ref, h),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: locked ? inkGrey : inkPaper,
                      ),
                    ),
                    if (h > 0 && !locked)
                      Text(
                        towerHeatMarksLine(ref, h),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: InkFonts.prose,
                          color: inkGrey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chip under a floor's number: the level's flame and name, in its colour
/// line; it opens the curse list.
class TowerHeatChip extends ConsumerWidget {
  const TowerHeatChip({super.key, required this.heat});

  final int heat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        key: const Key('tower_heat_chip'),
        onTap: () => showTowerHeatCurses(context, ref, heat),
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(towerSeamRadius),
            color: inkBlack,
            border: Border.all(color: towerHeatColor(heat), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: IconSize.s16,
                color: towerHeatColor(heat),
              ),
              const SizedBox(width: 4),
              Text(
                towerHeatName(ref, heat),
                style: theme.textTheme.labelLarge?.copyWith(color: inkPaper),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every curse in force at [heat], the newest tagged.
Future<void> showTowerHeatCurses(
  BuildContext context,
  WidgetRef ref,
  int heat,
) =>
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final rows = towerHeatCursesOf(heat);
        return Dialog(
          backgroundColor: inkBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(towerSeamRadius),
            side: const BorderSide(color: inkPaper, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(ref, 'tower_heat_curses_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: InkFonts.display,
                    color: inkPaper,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final l in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      tr(ref, l.nameKey),
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontFamily: InkFonts.display,
                                        color: inkPaper,
                                      ),
                                    ),
                                    if (l == rows.last) ...[
                                      const SizedBox(width: 8),
                                      InkTag(tr(ref, 'tower_heat_curse_new')),
                                    ],
                                  ],
                                ),
                                Text(
                                  tr(ref, l.lineKey),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: inkPaper,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkButton(
                    label: tr(ref, 'tower_continue'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

/// The end screen's Heat lines (on paper): the level and its marks, the level
/// opened by a win, or Ash conquered.
class TowerHeatEndLines extends ConsumerWidget {
  const TowerHeatEndLines({
    super.key,
    required this.heat,
    required this.openedNew,
    this.won = false,
  });

  final int heat;

  /// A level opened by this win (run.heat > the record's heatWon before).
  final bool openedNew;
  final bool won;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (heat <= 0 && !openedNew) return const SizedBox.shrink();
    final style = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: inkOnPaper, fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (heat > 0)
          Text(
            tr(ref, 'tower_heat_end')
                .replaceAll('{heat}', towerHeatName(ref, heat))
                .replaceAll('{n}', towerHeatMarksText(ref, heat)),
            key: const Key('tower_end_heat'),
            style: style,
          ),
        if (won && openedNew && heat < towerHeatMax)
          Text(
            tr(
              ref,
              'tower_heat_opened',
            ).replaceAll('{heat}', towerHeatName(ref, heat + 1)),
            key: const Key('tower_end_heat_opened'),
            style: style,
          ),
        if (won && heat >= towerHeatMax)
          Text(
            tr(ref, 'tower_heat_ash_done'),
            key: const Key('tower_end_heat_ash'),
            style: style,
          ),
      ],
    );
  }
}

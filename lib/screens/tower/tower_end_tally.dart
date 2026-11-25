// The end of a run, tallied (v2.10.1, UX-2): floors, wardens, bosses,
// refusals, the Heat's marks, the first-win bonus, the marks banked, the
// coins left (lost) and the next perk. Core's numbers (TowerRun,
// TowerProgress.firstWinBonusOf, nextPerk), Narrative's words; plain rows in
// the prose face, no colour.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_tables.dart';
import '../../data/tower/tower_progress.dart';
import '../../data/tower/tower_run.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import 'ink/ink_palette.dart';
import 'tower_coin_view.dart';
import 'tower_heat_view.dart';

class TowerEndTally extends ConsumerWidget {
  const TowerEndTally(
      {super.key,
      required this.run,
      required this.after,
      required this.firstWinBonus});

  final TowerRun run;

  /// The record with this run's marks banked.
  final TowerProgress after;

  /// The first-win bonus this run earned (firstWinBonusOf, read before end).
  final int firstWinBonus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final row = theme.textTheme.bodyMedium
        ?.copyWith(fontFamily: InkFonts.prose, color: inkOnPaper);
    var wardens = 0, bosses = 0;
    for (var f = 1; f <= run.floorsCleared; f++) {
      switch (towerBudgetOf(f).kind) {
        case TowerFloorKind.warden:
          wardens++;
        case TowerFloorKind.boss:
          bosses++;
        case TowerFloorKind.fight:
          break;
      }
    }
    Widget line(String key, Object n, {Key? k}) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(children: [
            Expanded(child: Text(tr(ref, key), style: row)),
            Text('$n',
                key: k, style: row?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        );
    final heatMarks = run.heat > 0
        ? tr(ref, 'tower_end_heat')
            .replaceAll('{heat}', towerHeatName(ref, run.heat))
            .replaceAll('{n}', towerHeatMarksText(ref, run.heat))
        : null;
    final next = after.treeFull ? after.nextPerk : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      line('tower_end_floors', run.floorsCleared),
      line('tower_end_wardens', wardens),
      line('tower_end_bosses', bosses),
      line('tower_end_refusals', run.refused.length),
      if (heatMarks != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child:
                Text(heatMarks, key: const Key('tower_end_heat'), style: row)),
      if (firstWinBonus > 0)
        line('tower_end_first_win', '+$firstWinBonus',
            k: const Key('tower_end_first_win')),
      const Divider(color: inkSlate, height: 14),
      line('tower_end_banked', run.marks + firstWinBonus,
          k: const Key('tower_end_banked')),
      const SizedBox(height: 6),
      Row(children: [
        const TowerCoinDisc(),
        const SizedBox(width: 6),
        Expanded(
            child: Text(
                tr(ref, 'tower_end_coins_lost')
                    .replaceAll('{n}', '${run.coins}'),
                key: const Key('tower_end_coins_lost'),
                style: row)),
      ]),
      if (next != null) ...[
        const SizedBox(height: 6),
        Text(
            tr(ref, 'tower_perk_next')
                .replaceAll('{perk}', tr(ref, next.nameKey))
                .replaceAll(
                    '{n}', '${(next.cost - after.marks).clamp(0, next.cost)}'),
            key: const Key('tower_end_next_perk'),
            style: row?.copyWith(fontStyle: FontStyle.italic)),
      ],
    ]);
  }
}

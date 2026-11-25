// The Tower in cross-section, on a page of its own (Maps, held prototype):
// opened by a tap on the floor screen's rail. The whole Tower, its three
// bands named, the floors won lit, and the run where it stands; the page
// opens with the run's floor in view. See lib/widgets/tower_cut.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tower/tower_run.dart';
import '../data/tower/tower_tables.dart';
import '../l10n/app_strings.dart';
import '../widgets/fit_title.dart';
import '../widgets/tower_cut.dart';
import 'tower/ink/ink_palette.dart';
import 'tower/tower_look.dart';

class TowerCutScreen extends ConsumerStatefulWidget {
  const TowerCutScreen({super.key, required this.run});

  final TowerRun run;

  @override
  ConsumerState<TowerCutScreen> createState() => _TowerCutScreenState();
}

class _TowerCutScreenState extends ConsumerState<TowerCutScreen> {
  static const double _row = 38;
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final view = TowerCutView.of(run);
    return TowerNight(
      floor: run.floor,
      child: Scaffold(
        backgroundColor: inkBlack,
        appBar: AppBar(title: FitTitle(tr(ref, 'tower_name'))),
        body: LayoutBuilder(builder: (context, box) {
          // (Under TowerNight: the Tower's own theme and fonts.)
          final theme = Theme.of(context);
          // Open on the run's floor, a third of the way down the page.
          final height = TowerCut.heightFor(_row);
          final at = (towerTop - view.floor) * _row - box.maxHeight / 3;
          _scroll ??= ScrollController(
              initialScrollOffset: at.clamp(
                  0.0, (height + 26 + 70 - box.maxHeight).clamp(0.0, 1e9)));
          return Column(children: [
            Expanded(
              child: SingleChildScrollView(
                key: const Key('tower_cut_scroll'),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                child: TowerCut(
                  key: const Key('tower_cut'),
                  view: view,
                  rowHeight: _row,
                  bands: [
                    for (var b = 1; b <= 3; b++) tr(ref, 'tower_band_$b'),
                  ],
                  highestLabel: tr(ref, 'tower_cut_highest'),
                ),
              ),
            ),
            // The legend stays in view under the Tower.
            Container(
              width: double.infinity,
              color: inkDeep,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Text(
                  '${tr(ref, 'tower_cut_legend')} '
                  '${tr(ref, view.over ? 'tower_cut_ended' : 'tower_cut_here')}',
                  key: const Key('tower_cut_legend'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: inkGrey, fontStyle: FontStyle.italic)),
            ),
          ]);
        }),
      ),
    );
  }
}

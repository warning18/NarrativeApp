// The Tower's marks and unlocks (v1.847): the marks in hand, then the ten
// unlocks by kind with their cost, "Buy" when affordable, "Owned" when held
// (docs/proposals/the-tower-designs.md, screen 7).
import '../../widgets/fit_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_tables.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import 'tower_look.dart';
import 'tower_marks_shop.dart';
import 'tower_providers.dart';
import '../../widgets/ink_panel.dart' show InkLabel;
import 'ink/ink_kit.dart';
import 'ink/ink_palette.dart';
import '../../theme/icon_sizes.dart';
import '../../utils/pixel_icons/game_pixel_icons.dart' show ItemPixelIcon;

/// The marks and unlocks, in the Tower's night theme (its body below).
class TowerMarksScreen extends StatelessWidget {
  const TowerMarksScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const TowerNight(child: _TowerMarksBody());
}

class _TowerMarksBody extends ConsumerStatefulWidget {
  const _TowerMarksBody();

  @override
  ConsumerState<_TowerMarksBody> createState() => _TowerMarksBodyState();
}

class _TowerMarksBodyState extends ConsumerState<_TowerMarksBody> {
  /// 0 unlocks, 1 perks, 2 looks.
  int _tab = 0;

  static const _groups = <(String, Set<TowerUnlockKind>)>[
    (
      'tower_group_peoples',
      {TowerUnlockKind.profession},
    ),
    ('tower_group_clans', {TowerUnlockKind.clan}),
    (
      'tower_group_kit',
      {TowerUnlockKind.startDie, TowerUnlockKind.startItem},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paper =
        theme.textTheme.apply(bodyColor: inkOnPaper, displayColor: inkOnPaper);
    final progress =
        (ref.watch(towerProvider).value ?? const TowerState()).progress;

    return Scaffold(
      appBar: AppBar(title: FitTitle(tr(ref, 'tower_marks_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // The marks in hand, on paper (Art's wide frame).
            InkPaperPanel(
              child: Row(
                children: [
                  const ItemPixelIcon('marks', 'Material', size: IconSize.s32),
                  const SizedBox(width: 8),
                  Text('${progress.marks}',
                      key: const Key('tower_marks_balance'),
                      style: paper.headlineMedium
                          ?.copyWith(fontFamily: InkFonts.display)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(tr(ref, 'tower_marks_name'),
                        style: paper.titleMedium),
                  ),
                ],
              ),
            ),
            TowerMarksTabs(tab: _tab, onTab: (i) => setState(() => _tab = i)),
            if (_tab == 1) const TowerPerksTab(),
            if (_tab == 2) const TowerLooksTab(),
            if (_tab == 0 && progress.treeFull)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(tr(ref, 'tower_tree_full'),
                    key: const Key('tower_tree_full'),
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: inkGrey)),
              ),
            if (_tab == 0)
              for (final (labelKey, kinds) in _groups) ...[
                InkLabel(tr(ref, labelKey)),
                for (final u
                    in towerUnlocks.where((u) => kinds.contains(u.kind)))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Opacity(
                      opacity: !progress.unlocked.contains(u.id) &&
                              u.needs != null &&
                              !progress.unlocked.contains(u.needs)
                          ? 0.55
                          : 1,
                      child: InkPaperPanel(
                        key: Key('tower_unlock_${u.id}'),
                        padding: const EdgeInsets.fromLTRB(46, 16, 20, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr(ref, 'tower_unlock_${u.id}'),
                                      style: paper.bodyMedium),
                                  Text(
                                      tr(ref, 'tower_marks_cost')
                                          .replaceAll('{n}', '${u.cost}'),
                                      style: paper.bodySmall
                                          ?.copyWith(color: inkSlate)),
                                ],
                              ),
                            ),
                            if (progress.unlocked.contains(u.id))
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.check, size: IconSize.s16),
                                const SizedBox(width: 4),
                                Text(tr(ref, 'tower_owned')),
                              ])
                            else
                              InkButton(
                                buttonKey: Key('tower_buy_${u.id}'),
                                onPaper: true,
                                primary: progress.canBuy(u.id),
                                label: tr(ref, 'tower_buy'),
                                onPressed: progress.canBuy(u.id)
                                    ? () => ref
                                        .read(towerProvider.notifier)
                                        .buy(u.id)
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

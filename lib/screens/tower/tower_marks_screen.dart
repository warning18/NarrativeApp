// The Tower's marks and unlocks (v1.847): the marks in hand, then the ten
// unlocks by kind with their cost, "Buy" when affordable, "Owned" when held
// (docs/proposals/the-tower-designs.md, screen 7).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_tables.dart';
import '../../l10n/app_strings.dart';
import '../../theme/stitched_ink.dart';
import 'tower_look.dart';
import 'tower_providers.dart';
import '../../widgets/ink_panel.dart';
import '../../theme/icon_sizes.dart';

/// The marks and unlocks, in the Tower's night theme (its body below).
class TowerMarksScreen extends StatelessWidget {
  const TowerMarksScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const TowerNight(child: _TowerMarksBody());
}

class _TowerMarksBody extends ConsumerWidget {
  const _TowerMarksBody();

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final progress =
        (ref.watch(towerProvider).value ?? const TowerState()).progress;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'tower_marks_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            InkPanel(
              lit: true,
              child: Row(
                children: [
                  Text('${progress.marks}',
                      key: const Key('tower_marks_balance'),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: ink.gold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(tr(ref, 'tower_marks_name'),
                        style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
            for (final (labelKey, kinds) in _groups) ...[
              InkLabel(tr(ref, labelKey)),
              for (final u in towerUnlocks.where((u) => kinds.contains(u.kind)))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkPanel(
                    key: Key('tower_unlock_${u.id}'),
                    dim: !progress.unlocked.contains(u.id) &&
                        u.needs != null &&
                        !progress.unlocked.contains(u.needs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr(ref, 'tower_unlock_${u.id}'),
                                  style: theme.textTheme.bodyMedium),
                              Text(
                                  tr(ref, 'tower_marks_cost')
                                      .replaceAll('{n}', '${u.cost}'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        if (progress.unlocked.contains(u.id))
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check,
                                size: IconSize.s16, color: ink.heal),
                            const SizedBox(width: 4),
                            Text(tr(ref, 'tower_owned')),
                          ])
                        else
                          FilledButton(
                            key: Key('tower_buy_${u.id}'),
                            onPressed: progress.canBuy(u.id)
                                ? () =>
                                    ref.read(towerProvider.notifier).buy(u.id)
                                : null,
                            child: Text(tr(ref, 'tower_buy')),
                          ),
                      ],
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

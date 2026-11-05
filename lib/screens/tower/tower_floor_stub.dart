// A stand-in for the floor screen (v1.847): the climb itself (the fight on
// a ladder, the cards) is the next release (docs/proposals/the-tower-
// wave.md, phase 3b). Until then a run can be started and left from here,
// so the start, marks and end screens can be looked at.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_run.dart';
import '../../l10n/app_strings.dart';
import 'tower_end_screen.dart';
import 'tower_providers.dart';
import 'tower_widgets.dart';

class TowerFloorStubScreen extends ConsumerWidget {
  const TowerFloorStubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final run = ref.watch(towerProvider).value?.run;

    Future<void> leave() async {
      final run = ref.read(towerProvider).value?.run;
      if (run == null) return;
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(tr(ref, 'tower_leave_confirm')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text(MaterialLocalizations.of(context).cancelButtonLabel)),
            FilledButton(
                key: const Key('tower_leave_yes'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr(ref, 'tower_leave'))),
          ],
        ),
      );
      if (yes != true || !context.mounted) return;
      final over = towerAbandon(run);
      final progress = await ref.read(towerProvider.notifier).end(over);
      if (!context.mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => TowerEndScreen(run: over, progress: progress)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'tower_name'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TowerPanel(
              lit: true,
              child: Text(
                  tr(ref, 'tower_floor_of')
                      .replaceAll('{n}', '${run?.floor ?? 1}'),
                  key: const Key('tower_stub_floor'),
                  style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 10),
            Text(tr(ref, 'tower_stub_floor'),
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('tower_leave'),
              onPressed: run == null ? null : leave,
              child: Text(tr(ref, 'tower_leave')),
            ),
          ],
        ),
      ),
    );
  }
}

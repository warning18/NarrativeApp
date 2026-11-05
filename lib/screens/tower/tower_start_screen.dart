// The Tower's door and start screen (v1.847, docs/proposals/
// the-tower-designs.md, direction A): the marks and the best floor, a run
// to continue, and the pick of a people, a calling and a clan for a new
// one (the ones not bought yet lie locked), then Climb.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_tables.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_strings.dart';
import '../../providers/game_db_providers.dart';
import '../../theme/stitched_ink.dart';
import 'tower_floor_screen.dart';
import 'tower_marks_screen.dart';
import 'tower_providers.dart';
import 'tower_widgets.dart';

class TowerStartScreen extends ConsumerStatefulWidget {
  const TowerStartScreen({super.key});

  @override
  ConsumerState<TowerStartScreen> createState() => _TowerStartScreenState();
}

class _TowerStartScreenState extends ConsumerState<TowerStartScreen> {
  String? _race;
  String? _profession;
  bool _starting = false;

  String _fill(String text, Map<String, Object> values) {
    var out = text;
    values.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }

  Future<void> _begin() async {
    final race = _race, profession = _profession;
    if (race == null || profession == null || _starting) return;
    setState(() => _starting = true);
    final data = await ref.read(towerDataProvider.future);
    await ref
        .read(towerProvider.notifier)
        .start(data: data, raceId: race, professionId: profession);
    if (!mounted) return;
    setState(() => _starting = false);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TowerFloorScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final state = ref.watch(towerProvider).value ?? const TowerState();
    final progress = state.progress;
    final run = state.run;
    final races = ref.watch(localizedDbProvider(racesSchema)).value ?? const {};
    final professions =
        ref.watch(localizedDbProvider(professionsSchema)).value ?? const {};
    final open = progress.professions;
    final ready = _race != null && _profession != null;

    Widget option({
      required Key key,
      required String title,
      String? line,
      required bool picked,
      bool locked = false,
      required VoidCallback onTap,
    }) =>
        TowerPanel(
          key: key,
          lit: picked,
          dim: locked,
          onTap: locked ? null : onTap,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (line != null && line.isNotEmpty)
                      Text(line,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (locked)
                const Icon(Icons.lock_outline, size: 18)
              else if (picked)
                Icon(Icons.check_circle, size: 20, color: ink.gold),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'tower_name'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(tr(ref, 'tower_tagline'),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            TowerPanel(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${progress.marks} ${tr(ref, 'tower_marks_name')}',
                            key: const Key('tower_marks_total'),
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: ink.gold)),
                        Text(
                            [
                              _fill(tr(ref, 'tower_best'),
                                  {'n': progress.bestFloor}),
                              _fill(tr(ref, 'tower_runs_line'),
                                  {'r': progress.runs, 'w': progress.wins}),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('tower_marks_button'),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TowerMarksScreen())),
                    child: Text(tr(ref, 'tower_marks_button')),
                  ),
                ],
              ),
            ),
            if (run != null && !run.isOver) ...[
              const SizedBox(height: 10),
              FilledButton(
                key: const Key('tower_continue'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TowerFloorScreen())),
                child: Text(
                    '${tr(ref, 'tower_continue')} · ${_fill(tr(ref, 'tower_floor_of'), {
                      'n': run.floor
                    })}'),
              ),
            ],
            TowerLabel(tr(ref, 'tower_pick_race')),
            for (final id in races.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: option(
                  key: Key('tower_race_$id'),
                  title: '${(races[id] as Map)['raceName'] ?? id}',
                  line: '${(races[id] as Map)['playstyle'] ?? ''}',
                  picked: _race == id,
                  onTap: () => setState(() => _race = id),
                ),
              ),
            TowerLabel(tr(ref, 'tower_pick_profession')),
            for (final id in professions.keys)
              if (towerStartProfessions.contains(id) ||
                  towerUnlocks.any((u) =>
                      u.kind == TowerUnlockKind.profession && u.value == id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: option(
                    key: Key('tower_profession_$id'),
                    title:
                        '${(professions[id] as Map)['professionName'] ?? id}',
                    line: open.contains(id)
                        ? '${(professions[id] as Map)['playstyle'] ?? ''}'
                        : tr(ref, 'tower_locked'),
                    picked: _profession == id,
                    locked: !open.contains(id),
                    onTap: () => setState(() => _profession = id),
                  ),
                ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('tower_climb'),
              onPressed: ready && !_starting ? _begin : null,
              child: Text(tr(ref, 'tower_climb')),
            ),
            const SizedBox(height: 8),
            Text(tr(ref, 'tower_save_note'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

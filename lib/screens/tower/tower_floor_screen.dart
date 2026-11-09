// The Tower's floor (v1.848, docs/proposals/the-tower-designs.md: A's panels
// with B's vertical ladder): the floor the party stands on, what waits on it
// and the way to fight it; once it is won, its cards (take one, or none).
// A run is moved only through lib/data/tower/ and the controller; the fight
// itself is played by the launcher (tower_providers.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/enemy_affix.dart';
import '../../data/tower/tower_hero.dart';
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_tables.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_strings.dart';
import '../../providers/clans_provider.dart';
import '../../providers/game_db_providers.dart';
import '../../providers/tower_level_up_session.dart';
import '../level_up_screen.dart';
import '../../widgets/race_profession_cards.dart' show ClanDisc;
import '../../theme/stitched_ink.dart';
import 'tower_end_screen.dart';
import 'tower_ladder.dart';
import 'tower_offer_view.dart';
import 'tower_providers.dart';
import 'tower_spoils_view.dart';
import 'tower_widgets.dart';

class TowerFloorScreen extends ConsumerStatefulWidget {
  const TowerFloorScreen({super.key});

  @override
  ConsumerState<TowerFloorScreen> createState() => _TowerFloorScreenState();
}

class _TowerFloorScreenState extends ConsumerState<TowerFloorScreen> {
  bool _busy = false;
  bool _resumed = false;

  /// The floor whose spoils sheet was taken: its boon or oath comes next.
  int _spoilsTaken = 0;

  /// The Level Up screen, the main game's own, under the run's hero: a pick
  /// is owed after a floor that gained a level (the engine holds the points,
  /// Core's v1.857). What is picked goes back to the run.
  Future<void> _levelUp(TowerRun run, TowerData data) async {
    _resumed = true;
    final session = TowerLevelUpSession(run, data);
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => session.wrap(const LevelUpScreen())));
    if (!mounted) return;
    await ref.read(towerProvider.notifier).setRun(session.run);
  }

  /// An ended run: its marks banked, its end screen in this one's place.
  Future<void> _finish(TowerRun over) async {
    final progress = await ref.read(towerProvider.notifier).end(over);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TowerEndScreen(run: over, progress: progress)));
  }

  Future<void> _fight(TowerRun run, TowerData data) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(towerFightLauncherProvider)(context, run, data);
      if (!mounted) return;
      // Not fought (Back before the first roll): the floor stays as it was.
      if (result == null) return;
      final next = towerAfterFight(run, data,
          won: result.won,
          healthLeft: result.healthLeft,
          potionsLeft: result.potionsLeft,
          antidotesLeft: result.antidotesLeft);
      if (next.isOver) {
        await _finish(next);
      } else {
        _resumed = true; // this visit opens the Level Up itself
        await ref.read(towerProvider.notifier).setRun(next);
        // A floor that gained a level: its pick, before the cards.
        if (towerPendingPicks(next) > 0 && mounted) {
          await _levelUp(next, data);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(TowerRun run, TowerData data, int? index) async {
    final next = towerPick(run, data, index);
    await ref.read(towerProvider.notifier).setRun(next);
  }

  Future<void> _leave(TowerRun run) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(tr(ref, 'tower_leave_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
          FilledButton(
              key: const Key('tower_leave_yes'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(ref, 'tower_leave'))),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await _finish(towerAbandon(run));
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(towerProvider).value?.run;
    final data = ref.watch(towerDataProvider).value;
    if (run == null || data == null || run.isOver) {
      return Scaffold(
          appBar: AppBar(title: Text(tr(ref, 'tower_name'))),
          body: const Center(child: CircularProgressIndicator()));
    }
    final choosing = run.status == TowerStatus.choosing;
    // Back on a floor won with a pick still owed: the Level Up first.
    if (!_resumed && choosing && towerPendingPicks(run) > 0) {
      _resumed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _levelUp(run, data);
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'tower_name')),
        actions: [
          IconButton(
            key: const Key('tower_leave'),
            tooltip: tr(ref, 'tower_leave'),
            icon: const Icon(Icons.logout),
            onPressed: _busy ? null : () => _leave(run),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
              child: TowerLadder(floor: run.floor),
            ),
            Expanded(
              child: choosing && _spoilsTaken != run.floor
                  ? TowerSpoilsView(
                      run: run,
                      onTake: () => run.offer.isEmpty
                          ? _pick(run, data, null)
                          : setState(() => _spoilsTaken = run.floor),
                    )
                  : choosing
                      ? TowerOfferView(
                          run: run,
                          data: data,
                          onPick: (i) => _pick(run, data, i),
                        )
                      : _FloorIntro(
                          run: run,
                          data: data,
                          busy: _busy,
                          onFight: () => _fight(run, data),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorIntro extends ConsumerWidget {
  const _FloorIntro({
    required this.run,
    required this.data,
    required this.busy,
    required this.onFight,
  });

  final TowerRun run;
  final TowerData data;
  final bool busy;
  final VoidCallback onFight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final floor = towerFloorOf(run, data);
    final hero = towerHeroOf(run, data);
    final enemies =
        ref.watch(localizedDbProvider(enemiesSchema)).value ?? const {};
    final band = floor.floor <= 10
        ? 1
        : floor.floor <= 20
            ? 2
            : 3;
    final danger = floor.kind != TowerFloorKind.fight;
    final hp = hero.maxHealth <= 0
        ? 0.0
        : (run.health / hero.maxHealth).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
      children: [
        Text(tr(ref, 'tower_band_$band').toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
        Text(tr(ref, 'tower_floor_of').replaceAll('{n}', '${run.floor}'),
            key: const Key('tower_floor_label'),
            style: theme.textTheme.headlineSmall),
        Text(tr(ref, 'tower_floor_${run.floor}'),
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontStyle: FontStyle.italic)),
        if (danger) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('tower_danger_band'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ink.blood.withValues(alpha: .12),
              border: Border.all(color: ink.blood),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    tr(
                            ref,
                            floor.kind == TowerFloorKind.boss
                                ? 'tower_floor_boss'
                                : 'tower_floor_warden')
                        .replaceAll('{n}', '${run.floor}'),
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: ink.blood, letterSpacing: 1)),
                if (floor.kind == TowerFloorKind.boss)
                  Text(tr(ref, 'tower_boss_line_${run.floor}'),
                      style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        TowerLabel(tr(ref, 'tower_oaths_label')),
        _SwornRow(run: run),
        TowerLabel(tr(ref, 'tower_foes')),
        for (final id in floor.enemyIds)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TowerPanel(
              lit: danger,
              child: Row(
                children: [
                  Expanded(
                    child: Text('${(enemies[id] as Map?)?['enemyName'] ?? id}',
                        style: theme.textTheme.titleSmall),
                  ),
                  if (id == floor.enemyIds.first) ...[
                    for (final a in floor.affixes)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(tr(ref, affixLabelKey(a))),
                        ),
                      ),
                    if (floor.elite)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(tr(ref, 'tower_floor_elite'),
                            style: theme.textTheme.labelSmall),
                      ),
                  ],
                ],
              ),
            ),
          ),
        TowerLabel(tr(ref, 'tower_your_health')),
        TowerPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: hp, color: ink.heal, minHeight: 8),
              const SizedBox(height: 4),
              Text('${run.health} / ${hero.maxHealth}',
                  key: const Key('tower_health'),
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('tower_fight'),
          onPressed: busy ? null : onFight,
          child: Text(tr(ref, 'tower_fight')),
        ),
      ],
    );
  }
}

/// The clans the run has sworn to, the main one first: their banners, or
/// "Unsworn" before the first oath.
class _SwornRow extends ConsumerWidget {
  const _SwornRow({required this.run});

  final TowerRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final factions = ref.watch(factionsProvider);
    final sworn = run.clanIds;
    return TowerPanel(
      key: const Key('tower_sworn'),
      child: sworn.isEmpty
          ? Text(tr(ref, 'tower_unsworn'),
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant))
          : Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final id in sworn)
                  if (factions[id] case final faction?)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClanDisc(faction, size: 28, name: true),
                        if (id == run.mainClanId && sworn.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('(${tr(ref, 'tower_main_clan')})',
                                style: theme.textTheme.labelSmall),
                          ),
                      ],
                    ),
              ],
            ),
    );
  }
}

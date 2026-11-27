// The Tower's floor (v1.848, docs/proposals/the-tower-designs.md: A's panels
// with B's vertical ladder): the floor the party stands on, what waits on it
// and the way to fight it; once it is won, its cards (take one, or none).
// A run is moved only through lib/data/tower/ and the controller; the fight
// itself is played by the launcher (tower_providers.dart).
import '../../widgets/fit_title.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/enemy_affix.dart';
import '../../data/tower/tower_coins.dart';
import '../../data/tower/tower_dice.dart';
import '../../data/tower/tower_events.dart';
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
import 'ink/ink_bands.dart';
import 'ink/ink_kit.dart';
import 'ink/ink_palette.dart';
import '../../widgets/fight_sprites.dart';
import 'tower_end_screen.dart';
import 'tower_backdrop.dart';
import 'tower_dice_panel.dart';
import 'tower_event_card.dart';
import 'tower_coin_view.dart';
import 'tower_heat_view.dart';
import 'tower_look.dart';
import 'tower_ladder.dart';
import '../../data/tower/tower_rules4.dart'
    show towerCanBuyPotion, towerHexedOf, towerPedlarPrice;
import '../../theme/icon_sizes.dart';
import 'tower_oath_moment.dart';
import 'tower_rules4_views.dart';
import 'tower_offer_view.dart';
import 'tower_providers.dart';
import 'tower_bookmarks.dart';
import 'tower_spoils_view.dart';
import '../../theme/frame_style.dart' show EnvParts;
import '../../widgets/ink_panel.dart';
import '../../widgets/ink_confirm.dart';
import '../../widgets/ink_loading.dart';

/// The Tower's floor, in the Tower's night theme (its body below).
class TowerFloorScreen extends StatelessWidget {
  const TowerFloorScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const TowerNight(child: _TowerFloorBody());
}

class _TowerFloorBody extends ConsumerStatefulWidget {
  const _TowerFloorBody();

  @override
  ConsumerState<_TowerFloorBody> createState() => _TowerFloorScreenState();
}

class _TowerFloorScreenState extends ConsumerState<_TowerFloorBody> {
  bool _busy = false;
  bool _resumed = false;

  /// The rail, to skip its step on a tap.
  final _ladder = GlobalKey<TowerLadderState>();

  /// The floor whose spoils sheet was taken: its boon or oath comes next.
  int _spoilsTaken = 0;

  /// The card picked on a table, waiting for Confirm (its index in the offer):
  /// the choice only counts then, and Change goes back to the cards.
  int? _pending;

  /// The open bookmark's view (stats, gear, dice), or null.
  TowerBookmark? _bookmark;

  @override
  void dispose() {
    super.dispose();
  }

  /// The Level Up screen, the main game's own, under the run's hero: a pick
  /// is owed after a floor that gained a level (the engine holds the points,
  /// Core's v1.857). What is picked goes back to the run.
  Future<void> _levelUp(TowerRun run, TowerData data) async {
    _resumed = true;
    final session = TowerLevelUpSession(run, data);
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TowerNight(
            child: session.wrap(const LevelUpScreen(
                doneLabelKey: 'tower_continue', tower: true)))));
    if (!mounted) return;
    await ref.read(towerProvider.notifier).setRun(session.run);
  }

  /// An ended run: its marks banked, its end screen in this one's place.
  Future<void> _finish(TowerRun over) async {
    final before = ref.read(towerProvider).value?.progress;
    final heatBefore = before?.heatWon ?? -1;
    final firstWin = before?.firstWinBonusOf(over) ?? 0;
    final progress = await ref.read(towerProvider.notifier).end(over);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TowerEndScreen(
            run: over,
            progress: progress,
            heatBefore: heatBefore,
            firstWinBonus: firstWin)));
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
          antidotesLeft: result.antidotesLeft,
          rounds: result.rounds);
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

  Future<void> _pick(TowerRun run, TowerData data, int? index,
      {String? stat}) async {
    final gamble = index != null &&
        index < run.offer.length &&
        run.offer[index].kind == TowerRewardKind.gamble;
    final next = towerPick(run, data, index, stat: stat);
    await ref.read(towerProvider.notifier).setRun(next);
    // A gamble card turns over: what it was.
    final revealed = next.lastGamble;
    if (gamble && revealed != null && mounted) {
      await towerShowGambleReveal(context, ref, revealed);
    }
    // A rival's skip lands two floors up and the skipped floor's level-ups
    // wait there: their pick opens on the landing floor.
    if (!next.isOver &&
        next.status == TowerStatus.climbing &&
        towerPendingPicks(next) > 0 &&
        mounted) {
      _resumed = true;
      await _levelUp(next, data);
    }
  }

  /// The parley's choice: talk (a pass lands on the next floor, its level's
  /// pick waits there like a rival's) or fight.
  Future<void> _parley(TowerRun run, TowerData data, bool talk) async {
    final next = towerChooseParley(run, data, talk);
    await ref.read(towerProvider.notifier).setRun(next);
    if (!next.isOver &&
        next.status == TowerStatus.climbing &&
        towerPendingPicks(next) > 0 &&
        mounted) {
      _resumed = true;
      await _levelUp(next, data);
    }
  }

  /// The merchant's Buy; the stall stays open for the next one.
  Future<void> _buy(TowerRun run, TowerData data, String id) =>
      ref.read(towerProvider.notifier).setRun(towerBuy(run, data, id));

  /// The merchant's Leave: the store closes and the fight is next.
  Future<void> _leaveStore(TowerRun run) =>
      ref.read(towerProvider.notifier).setRun(towerLeaveStore(run));

  /// The bargain's choice; its hero change shows in the health at once.
  Future<void> _bargain(TowerRun run, TowerData data, bool accept) => ref
      .read(towerProvider.notifier)
      .setRun(towerChooseBargain(run, data, accept));

  Future<void> _leave(TowerRun run) async {
    final yes = await showInkConfirm(
      context,
      body: tr(ref, 'tower_leave_confirm'),
      cancel: MaterialLocalizations.of(context).cancelButtonLabel,
      confirm: tr(ref, 'tower_leave'),
      confirmKey: const Key('tower_leave_yes'),
    );
    if (!yes || !mounted) return;
    await _finish(towerAbandon(run));
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(towerProvider).value?.run;
    final data = ref.watch(towerDataProvider).value;
    if (run == null || data == null || run.isOver) {
      return Scaffold(
          appBar: AppBar(title: FitTitle(tr(ref, 'tower_name'))),
          body: const InkLoading());
    }
    final choosing = run.status == TowerStatus.choosing;
    // The floor's event (off for a run that plays without them).
    final event = towerEventOf(run, data);
    // How the last event moved the run, for the rail: an arrow down a fall,
    // up a skip, ending on this floor.
    final last = event?.result;
    // A shortcut offered or taken: the arrow up to where it lands.
    final stair = event?.kind == TowerEventKind.shortcut &&
            (event?.accepted ?? true) &&
            event?.landsOn != null
        ? (run.floor, event!.landsOn!)
        : null;
    // Where the hero's head stands on the rail: on the floor won, it is
    // already on the next notch (or the stair's landing), so the step is
    // taken as the cards open, never after a defeat (the run is over then).
    final headFloor = !choosing
        ? run.floor
        : (event?.kind == TowerEventKind.shortcut &&
                (event?.accepted ?? false) &&
                event?.landsOn != null)
            ? event!.landsOn!
            : min(run.floor + 1, towerTop);
    final jump = stair ??
        (last != null &&
                last.to == run.floor &&
                (last.to < last.from || last.to > last.from + 1)
            ? (last.from, last.to)
            : null);
    // Back on a floor won with a pick still owed: the Level Up first.
    if (!_resumed && choosing && towerPendingPicks(run) > 0) {
      _resumed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _levelUp(run, data);
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(tr(ref, 'tower_name'))),
        actions: [
          IconButton(
            key: const Key('tower_leave'),
            tooltip: tr(ref, 'tower_leave'),
            icon: const Icon(Icons.logout),
            onPressed: _busy ? null : () => _leave(run),
          ),
        ],
      ),
      body: Stack(children: [
        TowerBackdrop(
          floor: run.floor,
          // The picture of the event on offer (the parley's guardian), until it
          // is chosen; the floor's own otherwise.
          asset: event != null && event.accepted == null
              ? towerEventPlate(event.background)
              : null,
          child: SafeArea(
            child: Listener(
              // A tap anywhere puts the head on its notch at once.
              onPointerDown: (_) => _ladder.currentState?.skip(),
              child: Stack(children: [
                Positioned.fill(
                    // While a bookmark is open the floor's pieces are not built, so
                    // the snow field's drifts (it draws over everything) leave with
                    // them instead of lying over the panel.
                    child: _bookmark != null
                        ? const SizedBox.shrink()
                        : Row(
                            // Tight height: the floor's scroll view fills it and starts at
                            // the top (a Row would centre a short one).
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // The rail keeps its place and its width on every screen of the
                              // floor, the card choices included: nothing jumps when they open.
                              SizedBox(
                                width: towerLadderWidth + 12,
                                child: ClipRect(
                                  child: OverflowBox(
                                    alignment: Alignment.centerLeft,
                                    minWidth: 0,
                                    maxWidth: towerLadderWidth + 12,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(8, 4, 4, 8),
                                      child: TowerLadder(
                                          key: _ladder,
                                          floor: headFloor,
                                          jump: jump),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                // A setback's check waiting (the event modal): the
                                // floor under a dimmed sheet, one button to roll it.
                                // The oath is a Yes/No moment, never a card.
                                child: choosing &&
                                        run.checkPending &&
                                        event?.kind == TowerEventKind.test
                                    ? _FloorIntro(
                                        key: const Key('tower_check_modal'),
                                        run: run,
                                        data: data,
                                        event: event,
                                        busy: _busy,
                                        onFight: () => _fight(run, data),
                                        onFace: () => ref
                                            .read(towerProvider.notifier)
                                            .resolveCheck(data: data),
                                      )
                                    : choosing &&
                                            run.table == TowerTableKind.oath
                                        ? TowerOathMoment(
                                            key: ValueKey(
                                                'tower_oath_${run.floor}'),
                                            run: run,
                                            data: data,
                                            onPick: (i) {
                                              if (i != null) {
                                                towerShowStandingToast(
                                                    context,
                                                    ref,
                                                    run,
                                                    data,
                                                    run.offer[i]);
                                              }
                                              _pick(run, data, i);
                                            },
                                          )
                                        : choosing &&
                                                _pending != null &&
                                                _pending! < run.offer.length &&
                                                run.offer[_pending!].kind ==
                                                    TowerRewardKind.statPick
                                            ? TowerStatChoice(
                                                run: run,
                                                data: data,
                                                onChange: () => setState(
                                                    () => _pending = null),
                                                onConfirm: (stat) {
                                                  final i = _pending!;
                                                  setState(
                                                      () => _pending = null);
                                                  _pick(run, data, i,
                                                      stat: stat);
                                                },
                                              )
                                            : choosing &&
                                                    _pending != null &&
                                                    _pending! < run.offer.length
                                                ? TowerPickConfirm(
                                                    run: run,
                                                    data: data,
                                                    reward:
                                                        run.offer[_pending!],
                                                    loot: run.rules >= 2 &&
                                                        run.table ==
                                                            TowerTableKind.loot,
                                                    styled: run.rules >= 2 &&
                                                        (run.table ==
                                                                TowerTableKind
                                                                    .loot ||
                                                            run.table ==
                                                                TowerTableKind
                                                                    .levelUp),
                                                    coinsGained: towerCoinsFor(
                                                        towerFloorOf(
                                                            run, data)),
                                                    onChange: () => setState(
                                                        () => _pending = null),
                                                    onConfirm: () {
                                                      final i = _pending!;
                                                      setState(() =>
                                                          _pending = null);
                                                      towerShowStandingToast(
                                                          context,
                                                          ref,
                                                          run,
                                                          data,
                                                          run.offer[i]);
                                                      _pick(run, data, i);
                                                    },
                                                  )
                                                : choosing &&
                                                        run.rules < 2 &&
                                                        _spoilsTaken !=
                                                            run.floor
                                                    ? TowerSpoilsView(
                                                        run: run,
                                                        coinsGained:
                                                            towerCoinsFor(
                                                                towerFloorOf(
                                                                    run, data)),
                                                        onTake: () => run.offer
                                                                    .isEmpty &&
                                                                event?.kind !=
                                                                    TowerEventKind
                                                                        .test
                                                            ? _pick(
                                                                run, data, null)
                                                            : setState(() =>
                                                                _spoilsTaken =
                                                                    run.floor),
                                                      )
                                                    : choosing
                                                        ? TowerOfferView(
                                                            // Rules 2 deals tables one after another on a
                                                            // floor (loot, Level Ups): each its own view.
                                                            key: run.rules >= 2
                                                                ? ValueKey(
                                                                    'tower_table_${run.floor}_'
                                                                    '${run.table?.name}_'
                                                                    '${run.levelUps[run.floor]?.length ?? 0}_'
                                                                    '${run.rerolls[run.floor] ?? 0}')
                                                                : null,
                                                            run: run,
                                                            data: data,
                                                            event: event,
                                                            // A card picked waits for Confirm; leaving the
                                                            // table (Not now) is final at once.
                                                            onPick: (i) => i ==
                                                                    null
                                                                ? _pick(run,
                                                                    data, null)
                                                                : setState(() =>
                                                                    _pending =
                                                                        i),
                                                          )
                                                        : run.stallOffer
                                                                .isNotEmpty
                                                            ? TowerOfferView(
                                                                key: const Key(
                                                                    'tower_stall_boon_table'),
                                                                run: run.copyWith(
                                                                    offer: run
                                                                        .stallOffer),
                                                                data: data,
                                                                onPick: (i) => i ==
                                                                        null
                                                                    ? _leaveStore(
                                                                        run)
                                                                    : ref
                                                                        .read(towerProvider
                                                                            .notifier)
                                                                        .takeStallBoon(
                                                                            i),
                                                              )
                                                            : _FloorIntro(
                                                                run: run,
                                                                data: data,
                                                                event: event,
                                                                busy: _busy,
                                                                onFight: () =>
                                                                    _fight(run,
                                                                        data),
                                                                onParley: (talk) =>
                                                                    _parley(
                                                                        run,
                                                                        data,
                                                                        talk),
                                                                onBuy: (id) =>
                                                                    _buy(
                                                                        run,
                                                                        data,
                                                                        id),
                                                                onLeaveStore: () =>
                                                                    _leaveStore(
                                                                        run),
                                                                onBargain: (take) =>
                                                                    _bargain(
                                                                        run,
                                                                        data,
                                                                        take),
                                                                onShortcut: (take) => ref
                                                                    .read(towerProvider
                                                                        .notifier)
                                                                    .setRun(towerChooseShortcut(
                                                                        run,
                                                                        data,
                                                                        take)),
                                                              ),
                              ),
                            ],
                          )),
              ]),
            ),
          ),
        ),
        // The bookmarks sit over the whole floor (the weather too).
        Positioned(
          top: 0,
          right: 6,
          child: TowerBookmarkTabs(
              open: _bookmark,
              onTap: (b) =>
                  setState(() => _bookmark = _bookmark == b ? null : b)),
        ),
        if (_bookmark != null)
          Positioned(
            top: 82,
            left: 8,
            right: 8,
            bottom: 8 + MediaQuery.paddingOf(context).bottom,
            child: TowerBookmarkPanel(
                run: run,
                data: data,
                which: _bookmark!,
                onClose: () => setState(() => _bookmark = null)),
          ),
      ]),
    );
  }
}

class _FloorIntro extends ConsumerWidget {
  const _FloorIntro({
    super.key,
    required this.run,
    required this.data,
    required this.busy,
    required this.onFight,
    this.onShortcut,
    this.onParley,
    this.onBuy,
    this.onLeaveStore,
    this.onBargain,
    this.onFace,
    this.event,
  });

  /// The setback's check waiting (the event modal): Face it rolls it.
  final VoidCallback? onFace;

  final TowerRun run;
  final TowerData data;

  /// The floor's event: the last result, the floor met again, a rival.
  final TowerEventView? event;
  final bool busy;
  final VoidCallback onFight;

  /// The shortcut's choice (true: the stair); the fight waits for it.
  final void Function(bool take)? onShortcut;

  /// The parley's choice (true: talk); the fight waits for it.
  final void Function(bool talk)? onParley;

  /// The merchant's Buy and Leave, and the bargain's choice (true takes
  /// it); the fight waits for the store to close or the bargain to be chosen.
  final void Function(String id)? onBuy;
  final VoidCallback? onLeaveStore;
  final void Function(bool accept)? onBargain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    // The event modal: a choice still open (a shortcut, a parley, a bargain) or
    // a setback's check waiting is put on arrival in a sheet over the dimmed
    // floor, which cannot be left without choosing; its card is the same one
    // that would sit in the floor.
    final open = event?.accepted == null;
    final modalCard = switch (event) {
      final e? when towerEventModalOn && onFace != null =>
        TowerEventCard(e, bagFull: false, onFace: onFace),
      final e?
          when towerEventModalOn &&
              open &&
              e.kind == TowerEventKind.shortcut &&
              onShortcut != null =>
        TowerEventCard(e, onShortcut: onShortcut),
      final e?
          when towerEventModalOn &&
              open &&
              e.kind == TowerEventKind.parley &&
              onParley != null =>
        TowerEventCard(e, onParley: onParley, foeId: floor.enemyIds.first),
      final e?
          when towerEventModalOn &&
              open &&
              e.kind == TowerEventKind.bargain &&
              onBargain != null =>
        TowerEventCard(e, onBargain: onBargain),
      _ => null,
    };
    final scroll = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr(ref, 'tower_band_$band').toUpperCase(),
                style: theme.textTheme.labelMedium
                    ?.copyWith(letterSpacing: 1.2, color: inkGrey)),
            // The floor's number, large and paper white (v1.1005).
            Text(tr(ref, 'tower_floor_of').replaceAll('{n}', '${run.floor}'),
                key: const Key('tower_floor_label'),
                style: theme.textTheme.headlineMedium?.copyWith(
                    color: inkPaper,
                    fontWeight: FontWeight.w800,
                    shadows: const [Shadow(blurRadius: 8, color: inkBlack)])),
            Wrap(spacing: 8, children: [
              TowerCoinChip(coins: run.coins),
              if (run.heat > 0) TowerHeatChip(heat: run.heat),
            ]),
            // The pedlar (the Purse perk on rules 4): a potion on any landing.
            if (towerCanBuyPotion(run))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('tower_buy_potion'),
                  onPressed: () => ref.read(towerProvider.notifier).buyPotion(),
                  icon: const Icon(Icons.local_pharmacy,
                      size: IconSize.s16, color: inkGold),
                  label: Text(
                      tr(ref, 'tower_buy_potion')
                          .replaceAll('{n}', '$towerPedlarPrice'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: inkGold, fontWeight: FontWeight.w700)),
                ),
              ),
            Text(tr(ref, 'tower_floor_${run.floor}'),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontStyle: FontStyle.italic, color: inkGrey)),
            if (event case final e?) ...[
              const SizedBox(height: 10),
              if (e.result case final r? when r.to == run.floor)
                TowerEventResultLine(r,
                    rolls: ref.read(towerProvider.notifier).eventIsNew(r),
                    onShown: ref.read(towerProvider.notifier).markEventShown),
              if (e.revisit) ...[
                const SizedBox(height: 6),
                const TowerRevisitLine(),
              ],
              // The setback ahead, as a line: the test and its odds, rolled when
              // the climb goes on.
              if (e.kind == TowerEventKind.test &&
                  onFace == null &&
                  e.ability != null) ...[
                const SizedBox(height: 6),
                TowerEventRecap(e),
              ],
              if (e.kind == TowerEventKind.rival) ...[
                const SizedBox(height: 6),
                TowerEventCard(e),
              ],
              if (e.kind == TowerEventKind.shortcut && modalCard == null) ...[
                const SizedBox(height: 6),
                TowerEventCard(e, onShortcut: onShortcut),
              ],
              if (e.kind == TowerEventKind.parley && modalCard == null) ...[
                const SizedBox(height: 6),
                TowerEventCard(e,
                    onParley: onParley, foeId: floor.enemyIds.first),
              ],
              if (e.kind == TowerEventKind.merchant ||
                  (e.kind == TowerEventKind.bargain && modalCard == null)) ...[
                const SizedBox(height: 6),
                TowerEventCard(e,
                    onBuy: onBuy,
                    onLeaveStore: onLeaveStore,
                    onBargain: onBargain),
              ],
            ],
            if (danger) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('tower_danger_band'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: inkBlack,
                  border: Border(
                      left: BorderSide(color: inkRed, width: 4),
                      top: BorderSide(color: inkRed),
                      right: BorderSide(color: inkRed),
                      bottom: BorderSide(color: inkRed)),
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
                            ?.copyWith(color: inkRed, letterSpacing: 1)),
                    if (floor.kind == TowerFloorKind.boss)
                      Text(tr(ref, 'tower_boss_line_${run.floor}'),
                          style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
            InkLabel(tr(ref, 'tower_oaths_label')),
            _SwornRow(run: run),
            InkLabel(tr(ref, 'tower_foes')),
            InkFoeBand(
              plate: towerFloorPlate(floor.floor) ?? towerBackdropAsset(band),
              lit: danger,
              foes: [
                for (final id in floor.enemyIds)
                  InkBandFoe(
                      id, '${(enemies[id] as Map?)?['enemyName'] ?? id}'),
              ],
            ),
            // The marks wrap under the picture: an Elite with an affix is too
            // wide for a nameplate. A lone Elite wears its mark, a pack made an
            // Elite pack (the shortcut's tougher fight) its own.
            if (floor.affixes.isNotEmpty ||
                floor.elite ||
                floor.elitePack ||
                towerHexedOf(run))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // The Hex of a gamble card: this floor's foes 15% stronger.
                    if (towerHexedOf(run))
                      InkTag(tr(ref, 'tower_hex_tag'), red: true),
                    for (final a in floor.affixes)
                      InkTag(tr(ref, affixLabelKey(a)), red: true),
                    for (var i = 0; i < floor.enemyIds.length; i++)
                      if ((i == 0 && floor.elite) || floor.elitePack)
                        InkTag(tr(ref, 'tower_floor_elite')),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            InkHeroBand(
              plate: towerBackdropAsset(band),
              sprite: heroSpriteFor(run.raceId, run.professionId),
              health: hp,
              healthText: '${run.health} / ${hero.maxHealth}',
              healthKey: const Key('tower_health'),
              title: tr(ref, 'tower_your_health'),
            ),
            // The bag: shown once the hero owns more than its first die.
            ..._dicePanel(ref),
            const SizedBox(height: 16),
            // A shortcut is chosen first: its card holds the two buttons.
            // A shortcut or a parley is chosen first, a bargain too, and an open
            // store is left first: their cards hold the buttons.
            if ((!(event?.kind == TowerEventKind.shortcut ||
                        event?.kind == TowerEventKind.parley ||
                        event?.kind == TowerEventKind.bargain) ||
                    event?.accepted != null) &&
                !((event?.storeOpen ?? false) &&
                    event?.kind == TowerEventKind.merchant))
              InkButton(
                buttonKey: const Key('tower_fight'),
                label: tr(ref, 'tower_fight'),
                onPressed: busy ? null : onFight,
                primary: true,
              ),
          ],
        ));
    if (modalCard == null) return scroll;
    final note = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: onFace != null ? inkRed : inkGrey, fontWeight: FontWeight.w700);
    final noteText = tr(
        ref,
        onFace != null
            ? 'tower_event_modal_forced'
            : 'tower_event_modal_choose');
    return _SheetOverSnow(
      under: IgnorePointer(child: Opacity(opacity: 0.35, child: scroll)),
      sheet: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              key: const Key('tower_event_modal'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: inkBlack.withValues(alpha: 0.97),
                  border: Border.all(color: inkPaper, width: 2),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(noteText, style: note),
                  const SizedBox(height: 8),
                  modalCard,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sheet over the floor in the route's overlay, above the snow (which is
/// drawn over everything under the weather scope): the drifts never lie on
/// it. The floor sits dimmed under it; the sheet follows the floor's area.
class _SheetOverSnow extends StatefulWidget {
  const _SheetOverSnow({required this.under, required this.sheet});

  final Widget under;
  final Widget sheet;

  @override
  State<_SheetOverSnow> createState() => _SheetOverSnowState();
}

class _SheetOverSnowState extends State<_SheetOverSnow> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_portal.isShowing) _portal.show();
    });
  }

  @override
  void dispose() {
    if (_portal.isShowing) _portal.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = InheritedTheme.capture(from: context, to: null);
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (overlayContext) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          child: SizedBox(
            width: _size.width,
            height: _size.height,
            child: Material(
              type: MaterialType.transparency,
              child: theme.wrap(widget.sheet),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: LayoutBuilder(builder: (_, c) {
          _size = c.biggest;
          return widget.under;
        }),
      ),
    );
  }
}

extension on _FloorIntro {
  List<Widget> _dicePanel(WidgetRef ref) {
    final dice = towerDiceOf(run, data, clans: ref.watch(clanDataProvider));
    if (dice.length < 2) return const [];
    final tower = ref.read(towerProvider.notifier);
    return [
      InkLabel(tr(ref, 'tower_dice_title')),
      TowerDicePanel(
        dice: dice,
        onChoose: (id) => tower.chooseDie(id, data: data),
        onSeen: tower.markDieSeen,
      ),
    ];
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
    return InkPanel(
      key: const Key('tower_sworn'),
      decor: const EnvParts(corners: true),
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

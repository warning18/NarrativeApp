// The Tower's state for its screens (v1.847): the tables the engine reads,
// the Tower's own save (tower_save.dart: its two keys, apart from the
// story's) and the one place a run or the marks change. The screens move a
// run only through lib/data/tower/ and this controller.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/tower/tower_coins.dart';
import '../../data/tower/tower_dice.dart';
import '../../data/tower/tower_events.dart';
import '../../data/tower/tower_hero.dart';
import '../../data/tower/tower_progress.dart';
import '../../data/tower/tower_rules4.dart' show towerBuyPotion;
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_save.dart';
import '../../data/tower/tower_tables.dart'
    show towerEventsLive, towerRulesLive;
import '../../gamedata/db_schema.dart';
import '../../providers/game_config_provider.dart';
import '../../providers/game_db_providers.dart';
import 'tower_fight_launcher.dart';

/// The tables the Tower's engine reads (races, professions, game config,
/// dice, skills, items, enemies, spells), as the engine's rules see them
/// (English records: names are read from the localized tables).
final towerDataProvider = FutureProvider<TowerData>((ref) async {
  Future<Map<String, dynamic>> table(DbSchema schema) async {
    await ref.read(gameDbProvider(schema).notifier).whenLoaded();
    return ref.read(gameDbProvider(schema)).value ?? const {};
  }

  return TowerData.fromTables({
    'races': await table(racesSchema),
    'professions': await table(professionsSchema),
    'game_config': await ref.watch(gameConfigProvider.future),
    'dice': await table(diceSchema),
    'skills': await table(skillsSchema),
    'items': await table(itemsSchema),
    'enemies': await table(enemiesSchema),
    'spells': await table(spellsSchema),
    // The level-up's paths (v1.857): the stat picks the player takes.
    'training_paths': jsonDecode(
            await rootBundle.loadString('assets/gamedata/training_paths.json'))
        as Map<String, dynamic>,
    // The clans' offers (docs/simulation/tower-clan-offers.md): the
    // branches each clan sponsors, the steps between them, the trees.
    'factions': await table(factionsSchema),
    for (final name in const ['relations', 'skill_trees'])
      name:
          jsonDecode(await rootBundle.loadString('assets/gamedata/$name.json'))
              as Map<String, dynamic>,
  });
});

/// What the Tower holds now: the marks and unlocks, and the run in
/// progress (null between runs).
class TowerState {
  const TowerState(
      {this.progress = const TowerProgress(), this.run, this.fightLeft});

  final TowerProgress progress;
  final TowerRun? run;

  /// A run that loaded with its fight begun and never finished (the app
  /// closed mid-fight, TowerRun.fightBegun): lost on that floor, its marks
  /// banked, its end screen still to show (once, [TowerController.fightLeftSeen]).
  final TowerRun? fightLeft;
}

/// Loads the Tower's save and changes it: a run started, a card picked,
/// an unlock bought, a run ended. Each change is saved at once.
class TowerController extends StateNotifier<AsyncValue<TowerState>> {
  TowerController() : super(const AsyncValue.loading()) {
    _load();
  }

  TowerSave? _save;

  Future<void> _load() async {
    final save = _save = await TowerSave.open();
    final run = save.loadRun();
    // A fight begun and never finished counts as lost: the run ends there.
    if (run != null && run.fightBegun) {
      final lost = towerFightLost(run);
      final progress = await save.endRun(lost);
      state = AsyncValue.data(TowerState(progress: progress, fightLeft: lost));
      return;
    }
    state =
        AsyncValue.data(TowerState(progress: save.loadProgress(), run: run));
  }

  /// The fight of the run's floor begun (its first round): saved at once,
  /// so that leaving the app mid-fight loses it (towerBeginFight).
  Future<void> beginFight() async {
    final run = _now.run;
    if (run == null) return;
    final begun = towerBeginFight(run);
    if (!identical(begun, run)) await setRun(begun);
  }

  /// The end screen of [TowerState.fightLeft] shown: it is not shown again.
  void fightLeftSeen() {
    if (_now.fightLeft == null) return;
    state = AsyncValue.data(TowerState(progress: _now.progress, run: _now.run));
  }

  Future<TowerSave> _opened() async => _save ??= await TowerSave.open();

  TowerState get _now => state.value ?? const TowerState();

  /// A new run begun with this people, calling and clan, at Heat [heat]
  /// (TowerRun.heat; 0, the plain climb, by default until the door's picker
  /// passes one): a Heat not open (TowerProgress.isHeatOpen) starts at the
  /// highest open one. It wears the perks chosen at the door
  /// (TowerProgress.wornPerks, [wear]); [friend] is Old friend's clan (one
  /// of the pool; null, the one the seed points to).
  Future<TowerRun> start({
    required TowerData data,
    required String raceId,
    required String professionId,
    int? seed,
    int heat = 0,
    String? friend,
  }) async {
    final save = await _opened();
    final progress = _now.progress;
    final run = towerStart(
      seed: seed ?? Random().nextInt(1 << 31),
      raceId: raceId,
      professionId: professionId,
      // The clans that may offer their oath on the way up (v1.855).
      clanPool: progress.clans,
      startUnlocks: progress.startUnlocks,
      unlocksOwned: progress.unlocksOwned,
      events: towerEventsLive,
      // The Level Up and loot rules (Core's rules 2).
      rules: towerRulesLive,
      heat: progress.isHeatOpen(heat) ? heat : progress.heatOpen,
      perks: progress.wornPerks,
      friend: friend ?? '',
      data: data,
    );
    await save.saveRun(run);
    state = AsyncValue.data(TowerState(progress: progress, run: run));
    return run;
  }

  /// The run as it is after a move (saved at once).
  Future<void> setRun(TowerRun run) async {
    final save = await _opened();
    await save.saveRun(run);
    final last = run.lastEvent;
    if (last != null && last != _now.run?.lastEvent) _newEvent = last;
    state = AsyncValue.data(TowerState(progress: _now.progress, run: run));
  }

  /// The run's hero rolling its die [dieId] from the next fight on
  /// (towerChooseDie), saved at once; nothing when it does not own it.
  Future<void> chooseDie(String dieId, {required TowerData data}) async {
    final run = _now.run;
    if (run == null) return;
    final chosen = towerChooseDie(run, data, dieId);
    if (!identical(chosen, run)) await setRun(chosen);
  }

  /// The die [dieId] of the bag seen, no longer new (towerMarkDieSeen),
  /// saved at once.
  Future<void> markDieSeen(String dieId) async {
    final run = _now.run;
    if (run == null) return;
    final seen = towerMarkDieSeen(run, dieId);
    if (!identical(seen, run)) await setRun(seen);
  }

  /// The last event's result made by a move of this session (setRun), its
  /// d20 not yet shown: the only one that tumbles. A result read from the
  /// save (Continue climb) was rolled and shown already: it is set down.
  TowerEventResult? _newEvent;

  /// [result] was rolled by a move just made, its d20 still to tumble.
  bool eventIsNew(TowerEventResult result) => _newEvent == result;

  /// The new result's d20 shown: it is not rolled again (nothing saved: the
  /// roll itself was saved when it was made).
  void markEventShown() => _newEvent = null;

  /// [run] ended: its marks banked, the run cleared. Returns the record
  /// with them.
  Future<TowerProgress> end(TowerRun run) async {
    final save = await _opened();
    final progress = await save.endRun(run);
    state = AsyncValue.data(TowerState(progress: progress));
    return progress;
  }

  /// The unlock [id] bought, if its marks and its need are there.
  Future<void> buy(String id) => _setProgress(_now.progress.buy(id));

  /// The record changed to [progress] (saved), nothing when it is the same.
  Future<void> _setProgress(TowerProgress progress) async {
    if (identical(progress, _now.progress)) return;
    final save = await _opened();
    await save.saveProgress(progress);
    state = AsyncValue.data(TowerState(progress: progress, run: _now.run));
  }

  // The marks shop after the tree and the coins (v2.10.0,
  // docs/simulation/tower-coins.md).

  /// Perk [id] bought (TowerProgress.buyPerk: the tree full, its marks in
  /// hand), worn at once when a slot is free.
  Future<void> buyPerk(String id) => _setProgress(_now.progress.buyPerk(id));

  /// The perks [ids] worn on the next climbs (owned ones, the first
  /// towerPerkSlots: one).
  Future<void> wearPerks(Iterable<String> ids) =>
      _setProgress(_now.progress.wear(ids));

  /// Perk [id] put on or taken off (TowerProgress.toggleWorn).
  Future<void> toggleWorn(String id) =>
      _setProgress(_now.progress.toggleWorn(id));

  /// Trim [id] bought (TowerProgress.buyTrim) and shown.
  Future<void> buyTrim(String id) => _setProgress(_now.progress.buyTrim(id));

  /// Trim [id] shown on the banner (an owned one), or none (null).
  Future<void> showTrim(String? id) => _setProgress(_now.progress.showTrim(id));

  /// The run changed by [move] (saved), nothing when it is the same.
  Future<void> _moveRun(TowerRun Function(TowerRun run) move) async {
    final run = _now.run;
    if (run == null) return;
    final moved = move(run);
    if (!identical(moved, run)) await setRun(moved);
  }

  /// The table rerolled for its price in coins (towerReroll).
  Future<void> reroll({required TowerData data}) =>
      _moveRun((run) => towerReroll(run, data));

  /// Card [index] of the table banished for its price (towerBanish).
  Future<void> banish(int index) => _moveRun((run) => towerBanish(run, index));

  /// [stockId] ('salve', 'potions' or towerStallBoonId) bought at the open
  /// stall for coins (towerBuy); the boon's cards then wait on
  /// TowerRun.stallOffer for [takeStallBoon].
  Future<void> buyAtStall(String stockId, {required TowerData data}) =>
      _moveRun((run) => towerBuy(run, data, stockId));

  /// Card [index] of the stall's boon taken (towerTakeStallBoon).
  Future<void> takeStallBoon(int index) =>
      _moveRun((run) => towerTakeStallBoon(run, index));

  /// Rules 4, Purse's pedlar: a potion bought for its coins on the landing
  /// (towerBuyPotion; the button shows while towerCanBuyPotion).
  Future<void> buyPotion() => _moveRun(towerBuyPotion);
}

final towerProvider =
    StateNotifierProvider<TowerController, AsyncValue<TowerState>>(
        (ref) => TowerController());

/// How a floor's fight ended.
class TowerFightResult {
  const TowerFightResult(
      {required this.won,
      required this.healthLeft,
      this.potionsLeft,
      this.antidotesLeft,
      this.rounds});

  final bool won;

  /// The hero's health when the fight ended.
  final int healthLeft;

  /// The potions and antidotes it left (v1.860, the bag's); null, as it
  /// was.
  final int? potionsLeft;
  final int? antidotesLeft;

  /// The rounds the fight took (floor events PR 2, a rival's floor); null,
  /// not counted.
  final int? rounds;
}

/// Plays the fight of [run]'s floor and says how it ended; null when it was
/// fought (Back before the first roll).
typedef TowerFightLauncher = Future<TowerFightResult?> Function(
    BuildContext context, TowerRun run, TowerData data);

/// The fight of a floor: [towerFightFor] plays it for real. Tests give a
/// fake (or null: not fought).
final towerFightLauncherProvider = Provider<TowerFightLauncher>(
    (ref) => (context, run, data) => towerFightFor(ref, context, run, data));

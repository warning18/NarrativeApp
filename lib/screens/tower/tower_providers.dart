// The Tower's state for its screens (v1.847): the tables the engine reads,
// the Tower's own save (tower_save.dart: its two keys, apart from the
// story's) and the one place a run or the marks change. The screens move a
// run only through lib/data/tower/ and this controller.
import 'dart:math';

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/tower/tower_hero.dart';
import '../../data/tower/tower_progress.dart';
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_save.dart';
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
  });
});

/// What the Tower holds now: the marks and unlocks, and the run in
/// progress (null between runs).
class TowerState {
  const TowerState({this.progress = const TowerProgress(), this.run});

  final TowerProgress progress;
  final TowerRun? run;
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
    state = AsyncValue.data(
        TowerState(progress: save.loadProgress(), run: save.loadRun()));
  }

  Future<TowerSave> _opened() async => _save ??= await TowerSave.open();

  TowerState get _now => state.value ?? const TowerState();

  /// A new run begun with this people, calling and clan.
  Future<TowerRun> start({
    required TowerData data,
    required String raceId,
    required String professionId,
    required String clanId,
    int? seed,
  }) async {
    final save = await _opened();
    final progress = _now.progress;
    final run = towerStart(
      seed: seed ?? Random().nextInt(1 << 31),
      raceId: raceId,
      professionId: professionId,
      clanId: clanId,
      // The clans that may offer their oath on the way up (v1.855).
      clanPool: progress.clans,
      startUnlocks: progress.startUnlocks,
      unlocksOwned: progress.unlocksOwned,
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
    state = AsyncValue.data(TowerState(progress: _now.progress, run: run));
  }

  /// [run] ended: its marks banked, the run cleared. Returns the record
  /// with them.
  Future<TowerProgress> end(TowerRun run) async {
    final save = await _opened();
    final progress = await save.endRun(run);
    state = AsyncValue.data(TowerState(progress: progress));
    return progress;
  }

  /// The unlock [id] bought, if its marks and its need are there.
  Future<void> buy(String id) async {
    final save = await _opened();
    final progress = _now.progress.buy(id);
    if (identical(progress, _now.progress)) return;
    await save.saveProgress(progress);
    state = AsyncValue.data(TowerState(progress: progress, run: _now.run));
  }
}

final towerProvider =
    StateNotifierProvider<TowerController, AsyncValue<TowerState>>(
        (ref) => TowerController());

/// How a floor's fight ended.
class TowerFightResult {
  const TowerFightResult({required this.won, required this.healthLeft});

  final bool won;

  /// The hero's health when the fight ended.
  final int healthLeft;
}

/// Plays the fight of [run]'s floor and says how it ended; null when it was
/// fought (Back before the first roll).
typedef TowerFightLauncher = Future<TowerFightResult?> Function(
    BuildContext context, TowerRun run, TowerData data);

/// The fight of a floor: [towerFightFor] plays it for real. Tests give a
/// fake (or null: not fought).
final towerFightLauncherProvider = Provider<TowerFightLauncher>(
    (ref) => (context, run, data) => towerFightFor(ref, context, run, data));

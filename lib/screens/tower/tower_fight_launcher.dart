// Plays the fight of a Tower floor (v1.850): the fight screen of the story's
// fights, under the Tower hero's own session (TowerFightSession, Core's
// v1.849: it never reads or writes the story save), with the floor's foes and
// settings. What it says goes back to the run through towerAfterFight.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/field_anomaly.dart' show FightStage;
import '../../data/tower/tower_events.dart'
    show TowerEventKind, towerEventKindOf;
import '../../data/tower/tower_floors.dart' show TowerFloor;
import '../../data/tower/tower_hero.dart';
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_tables.dart' show towerEnemyRecord;
import '../../gamedata/db_schema.dart';
import '../../providers/game_db_providers.dart';
import '../../providers/combat_active_provider.dart';
import '../../providers/tower_fight_session.dart';
import '../fight_screen.dart';
import '../../widgets/fight_plates.dart' show FightPlateOverride;
import 'tower_backdrop.dart'
    show towerBackdropAsset, towerBandOf, towerFloorPlate;
import 'tower_look.dart' show TowerNight;
import 'tower_providers.dart';

/// Whether [run]'s floor is a rival's (TowerEventKind.rival: won within
/// towerRivalRounds, the next floor is skipped): FightScreen's `rival`
/// (UX's panels stand the two fighters side by side). Looks only.
bool towerFightIsRival(TowerRun run) =>
    towerEventKindOf(run) == TowerEventKind.rival;

/// The fight screen of [run]'s [floor], its foes' [records] by id: the
/// floor's foes and settings, and `rival` on a rival's floor.
FightScreen towerFightScreen(
  TowerRun run,
  TowerFloor floor,
  Map<String, Map<String, dynamic>> records, {
  void Function(int round)? onRound,
}) =>
    FightScreen(
      enemyId: floor.enemyIds.first,
      enemy: records[floor.enemyIds.first]!,
      additionalEnemyIds: floor.enemyIds.skip(1).toList(),
      additionalEnemies: {
        for (final id in floor.enemyIds.skip(1)) id: records[id]!,
      },
      modifiers: floor.modifiersFor(run.professionId,
          raceId: run.raceId, unlocksOwned: run.unlocksOwned),
      rival: towerFightIsRival(run),
      onRound: onRound,
    );

/// Plays [run]'s floor and says how it ended; null when it was not fought (a
/// foe missing from the tables, or Back before the first roll). There is no
/// retreat in the Tower: once begun, a fight is won or lost.
Future<TowerFightResult?> towerFightFor(
    Ref ref, BuildContext context, TowerRun run, TowerData data) async {
  await ref.read(gameDbProvider(enemiesSchema).notifier).whenLoaded();
  final enemies =
      ref.read(localizedDbProvider(enemiesSchema)).value ?? const {};
  final floor = towerFloorOf(run, data);
  final records = <String, Map<String, dynamic>>{
    for (final id in floor.enemyIds)
      if (enemies[id] case final Map<String, dynamic> record)
        id: towerEnemyRecord(id, record),
  };
  // A floor may hold the same foe twice (two Harbour Rats): the records are
  // by id, so it is the distinct foes that must all be found (v1.914, QA's
  // blocker: a repeat read as a missing foe and the fight never began).
  // FightScreen spawns one foe per id in additionalEnemyIds, repeats too.
  if (records.length != floor.enemyIds.toSet().length || !context.mounted) {
    return null;
  }
  final fight = TowerFightSession(run, data);
  ref.read(combatActiveProvider.notifier).state = true;
  final won = await Navigator.of(context).push<bool>(MaterialPageRoute(
    builder: (_) {
      final screen = fight.wrap(towerFightScreen(
        run,
        floor,
        records,
        onRound: (round) {
          fight.onRound(round);
          // Begun: from here the fight is won or lost, even if the app closes.
          if (round == 1) ref.read(towerProvider.notifier).beginFight();
        },
      ));
      // The Tower's fights wear the Tower: a warden's or a boss's floor its
      // own picture, the others their band's, the hall's stone under the dice
      // and the floor named in the ground line (looks only).
      // In the Tower's ink look (v1.1006): its dark theme and square buttons.
      return TowerNight(
        floor: run.floor,
        frames: false,
        child: FightPlateOverride(
            asset: towerFloorPlate(run.floor) ??
                towerBackdropAsset(towerBandOf(run.floor)),
            boardStage: FightStage.hall,
            floor: run.floor,
            child: screen),
      );
    },
  ));
  ref.read(combatActiveProvider.notifier).state = false;
  // Back before the first roll pops null: the floor was not fought (a
  // marker set all the same is taken back: the run as it was).
  if (won == null) {
    if (fight.rounds > 0) {
      await ref.read(towerProvider.notifier).setRun(run);
    }
    return null;
  }
  return TowerFightResult(
      won: won,
      healthLeft: fight.healthLeft,
      potionsLeft: fight.potionsLeft,
      antidotesLeft: fight.antidotesLeft,
      rounds: fight.rounds > 0 ? fight.rounds : null);
}

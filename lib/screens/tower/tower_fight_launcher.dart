// Plays the fight of a Tower floor (v1.850): the fight screen of the story's
// fights, under the Tower hero's own session (TowerFightSession, Core's
// v1.849: it never reads or writes the story save), with the floor's foes and
// settings. What it says goes back to the run through towerAfterFight.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_hero.dart';
import '../../data/tower/tower_run.dart';
import '../../gamedata/db_schema.dart';
import '../../providers/aftermath_provider.dart';
import '../../providers/game_db_providers.dart';
import '../../providers/combat_active_provider.dart';
import '../../providers/tower_fight_session.dart';
import '../fight_screen.dart';
import 'tower_providers.dart';

/// Plays [run]'s floor and says how it ended; null when it could not start
/// (a foe missing from the tables).
Future<TowerFightResult?> towerFightFor(
    Ref ref, BuildContext context, TowerRun run, TowerData data) async {
  await ref.read(gameDbProvider(enemiesSchema).notifier).whenLoaded();
  final enemies =
      ref.read(localizedDbProvider(enemiesSchema)).value ?? const {};
  final floor = towerFloorOf(run, data);
  final records = <String, Map<String, dynamic>>{
    for (final id in floor.enemyIds)
      if (enemies[id] case final Map<String, dynamic> record) id: record,
  };
  if (records.length != floor.enemyIds.length || !context.mounted) {
    return null;
  }
  final fight = TowerFightSession(run, data);
  ref.read(combatActiveProvider.notifier).state = true;
  final won = await Navigator.of(context).push<bool>(MaterialPageRoute(
    builder: (_) => fight.wrap(FightScreen(
      enemyId: floor.enemyIds.first,
      enemy: records[floor.enemyIds.first]!,
      additionalEnemyIds: floor.enemyIds.skip(1).toList(),
      additionalEnemies: {
        for (final id in floor.enemyIds.skip(1)) id: records[id]!,
      },
      modifiers: floor.modifiersFor(run.professionId),
    )),
  ));
  ref.read(combatActiveProvider.notifier).state = false;
  final cleared = won ?? false;
  final retreated = ref.read(lastFightRetreatedProvider);
  ref.read(lastFightRetreatedProvider.notifier).state = false;
  return TowerFightResult(
    won: cleared,
    healthLeft: fight.healthLeft,
    retreated: !cleared && retreated,
  );
}

// The ground a fight is fought on (v1.884, round 4 item 1): its stage and
// the context rule it plays, from the place the story stands at. The fight
// screen and the playthrough simulator both call [fightGroundAt]; before
// it, the screen held these steps in two private helpers and the simulator
// played every fight on the Tide.
import '../data/geography.dart';
import 'combat_engine.dart' show isBossEnemy, zoneBossEnemyIds;
import 'context_rules.dart';
import 'field_anomaly.dart';

/// The stage a fight at [placeId] is drawn on: [forcedStage] when the
/// scene names one; else the stage the place names (a hall for a prison or
/// a crypt); else a town's streets; else the pattern of the land's biome;
/// else open country, one of whose faces the place picks and keeps.
FightStage fightStageAt(Geography geography, String? placeId,
    {FightStage? forcedStage}) {
  if (forcedStage != null) return forcedStage;
  final named = fightStageFromName(geography.placeStageNameOf(placeId));
  if (named != null) return named;
  return poolStageOf(
      fightStageOf(geography.biomeOf(placeId)?.pattern,
          town:
              guardedPlaceKinds.contains(geography.locationOf(placeId)?.kind)),
      placeId);
}

/// Whether a fight against [enemies] is a boss's: a zone boss's
/// ([zoneBoss]), or any foe a boss.
bool isBossFight(Iterable<MapEntry<String, Map<String, dynamic>>> enemies,
        {bool zoneBoss = false}) =>
    zoneBoss ||
    enemies.any(
        (e) => isBossEnemy(e.key, e.value) || zoneBossEnemyIds.contains(e.key));

/// The ground of a fight at [placeId]: its stage ([fightStageAt]) and its
/// context rule (the watch in a city, a holy place's ground, the stage's
/// own, the Tide where none applies or a boss is fought).
({FightStage stage, ContextRule rule}) fightGroundAt(
    Geography geography, String? placeId,
    {FightStage? forcedStage, bool bossFight = false}) {
  final stage = fightStageAt(geography, placeId, forcedStage: forcedStage);
  return (
    stage: stage,
    rule: contextRuleFor(
      stage: stage,
      bossFight: bossFight,
      city: guardedPlaceKinds.contains(geography.place(placeId)?.kind),
      holy: geography.tagsOf(placeId).contains('holy'),
    ),
  );
}

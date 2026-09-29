import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ship_battle.dart';
import '../combat/ship_combat.dart';
import '../data/sail_powers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../screens/ship_battle_panel.dart';
import '../screens/voyage_screen.dart' show buildShipCrew;

/// A sea battle the story itself starts (a choice's `shipBattleId`, see
/// StoryChoice.shipBattleId): the Eel as she is fitted out and as damaged
/// as she is, against [enemyShipId] of enemy_ships.json, on the voyage's
/// own battle screen. Won (or the enemy fled), the prize is paid as at sea
/// and true comes back; lost, the Eel limps off with a quarter of her hull
/// and false comes back. Null when the game data is missing.
Future<bool?> runStoryShipBattle(
  BuildContext context,
  WidgetRef ref,
  String enemyShipId, {
  required int chapter,
}) async {
  final ships = await loadedGameDb(ref, shipsSchema);
  final parts = await loadedGameDb(ref, shipPartsSchema);
  final enemyShips = await loadedGameDb(ref, enemyShipsSchema);
  final companions = await loadedGameDb(ref, companionsSchema);
  final races = await loadedGameDb(ref, racesSchema);
  final professions = await loadedGameDb(ref, professionsSchema);
  final gameConfig = await ref.read(gameConfigProvider.future);
  await ref.read(shipTurnTimerProvider.notifier).loaded;
  final data = enemyShips[enemyShipId] as Map<String, dynamic>?;
  if (data == null || !context.mounted) return null;
  final lang = ref.read(appLanguageProvider);
  final fr = lang == AppLanguage.fr;
  final enemyName = (fr ? data['displayName_fr']?.toString() : null) ??
      data['displayName']?.toString() ??
      enemyShipId;
  final session = ref.read(playerSessionProvider);
  final ship = ships['rusty_eel'] as Map<String, dynamic>? ??
      (ships.values.isEmpty
          ? const <String, dynamic>{}
          : ships.values.first as Map<String, dynamic>);
  final sail = installedSail(parts, session.shipPartIds);
  final strength = sail == null ? 1 : sailStrength(sail.medium, session.raceId);
  List<ShipCrew> crew() => buildShipCrew(
        session: ref.read(playerSessionProvider),
        companions: companions,
        races: races,
        professions: professions,
        gameConfig: gameConfig,
        youLabel: trFor(lang, 'you_label'),
      );
  final notifier = ref.read(playerSessionProvider.notifier);
  final active = ref.read(combatActiveProvider.notifier);
  active.state = true;
  final outcome = await Navigator.of(context).push<ShipBattleOutcome>(
    MaterialPageRoute(
      builder: (pageContext) => PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(enemyName),
          ),
          body: ShipBattlePanel(
            player: buildPlayerShip(
              ship: ship,
              parts: parts,
              installedPartIds: session.shipPartIds,
              currentHull: session.shipHull,
              voidVolleyPartId:
                  sail?.power == SailPower.voidmark ? sail!.partId : null,
              voidVolleyBonus: voidVolleyBonus(strength),
            ),
            enemy: buildEnemyShip(data),
            shipName: trFor(lang, 'boat_title'),
            enemyName: enemyName,
            enemyShipId: data['shipName']?.toString() ?? enemyShipId,
            crew: crew(),
            foresight: sail?.power == SailPower.foresight,
            windKnot: sail?.power == SailPower.windknot,
            random: Random(),
            boarding: boardingProfileFor(data),
            chapter: boardingChapterFor(chapter, data),
            buildCrew: crew,
            turnSeconds: ref.read(shipTurnTimerProvider)
                ? shipTurnSeconds(
                    ship: ship,
                    parts: parts,
                    installedPartIds: session.shipPartIds)
                : null,
            habit: habitFromName(data['habit']?.toString()),
            onFinished: (outcome) => Navigator.of(pageContext).pop(outcome),
          ),
        ),
      ),
    ),
  );
  active.state = false;
  if (outcome == null) return false;
  final won = outcome.won || outcome.escaped;
  var gold = outcome.won ? (data['goldReward'] as num?)?.toInt() ?? 0 : 0;
  final xp = outcome.won ? (data['xpReward'] as num?)?.toInt() ?? 0 : 0;
  if (outcome.boarded) gold += boardingProfileFor(data).prizeGold;
  for (final member in outcome.crew) {
    if (member.isPlayer) {
      await notifier.applyCombatResult(
          hpAfter: max(1, member.health), goldGain: gold, xpGain: xp);
    } else {
      await notifier.applyAllyCombatResult(member.id,
          hpAfter: max(1, member.health));
    }
  }
  await notifier.setShipHull(
      won ? outcome.player.hull : limpHomeHull(outcome.player.maxHull));
  return won;
}

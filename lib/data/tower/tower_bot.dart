// The Tower's bot (v1.845): plays whole runs on the headless fight
// (simulateSimFight), for the tests and QA's balance batch (phase 2). It
// moves the run through the same functions the screens will
// (towerAfterFight, towerPick), so what it measures is the Tower itself.
// Its fights are set up as the app's Tower fight sets them (towerBotFight):
// the clans' standings, the floor's affixes and Elite, a die rerolled as a
// player would.

import 'dart:io';
import 'dart:convert';
import 'dart:math';

import '../../combat/clan_dice.dart';
import '../../combat/combat_engine.dart' show isBossEnemy, isRandomDrawEnemy;
import '../../combat/doctrine.dart';
import '../../combat/enemy_affix.dart';
import '../../combat/fight_numbers.dart';
import '../factions.dart' show ClanData;
import '../sim_combat.dart';
import '../training.dart' show statPickForShares;
import 'tower_floors.dart';
import 'tower_hero.dart';
import 'tower_progress.dart';
import 'tower_rewards.dart';
import 'tower_run.dart';
import 'tower_session.dart' show towerPoliticsOf;
import 'tower_tables.dart';

/// The Tower's tables read from assets/gamedata/ (for tests and tools; the
/// app reads them from its own database).
TowerData towerDataFromAssets([String dir = 'assets/gamedata']) =>
    TowerData.fromTables({
      for (final name in TowerData.tableNames)
        name: jsonDecode(File('$dir/$name.json').readAsStringSync())
            as Map<String, dynamic>,
    });

/// The clans' records read from assets/gamedata/factions.json (the
/// standings of the clans not sworn start where the story's do).
ClanData towerClanDataFromAssets([String dir = 'assets/gamedata']) =>
    ClanData.fromTables(
        factions: jsonDecode(File('$dir/factions.json').readAsStringSync())
            as Map<String, dynamic>);

final ClanData _assetClans = towerClanDataFromAssets();

/// [floor] of [run] fought by [hero] on the headless fight, set up as the
/// app's Tower fight sets it (tower_fight_launcher.dart, FightScreen with
/// TowerFloor.modifiersFor, fight_setup.dart's _ensureEnemiesBuilt):
/// - the clans' standings of the Tower's session (towerPoliticsOf), and
///   the main clan's die resonating when it is the one in play;
/// - the Elite: the floor's, else a lone ordinary foe's own roll on a
///   floor that forces no affix ([eliteChance]);
/// - the affixes rolled by rollEncounterAffixes under the foes' doctrine,
///   the floor's forced ones in place of the first foe's;
/// - no goal (a fight whose loss goes on, `lossContinues`, rolls none);
/// - the hero rerolling a weak face, within the round's three rolls.
/// Not played (the headless fight has none): the battlefield conditions
/// the screen rolls, momentum, Quick Resolve.
SimFightOutcome towerBotFight({
  required TowerRun run,
  required TowerFloor floor,
  required SimCharacter hero,
  required TowerData data,
  required Random random,
  ClanData? clans,
}) {
  final clanData = clans ?? _assetClans;
  final politics = towerPoliticsOf(run);
  final enemies = [
    for (final id in floor.enemyIds)
      MapEntry(id, data.enemies[id] as Map<String, dynamic>),
  ];
  final elite = enemies.length == 1 &&
      (floor.elite ||
          (isRandomDrawEnemy(enemies.first.key) &&
              floor.affixes.isEmpty &&
              random.nextDouble() < eliteChance));
  final factions = [
    for (final e in enemies) e.value['faction']?.toString() ?? '',
  ];
  final doctrine = doctrineForFight(
      factions: factions,
      isBoss: [for (final e in enemies) isBossEnemy(e.key, e.value)]);
  final affixes = rollEncounterAffixes(
    enemyIds: floor.enemyIds,
    isElite: elite,
    random: random,
    tastes: [
      for (final faction in factions)
        if (doctrine != null && faction == doctrine.factionId)
          doctrine.affixes
        else
          const <EnemyAffix>[],
    ],
  );
  if (floor.affixes.isNotEmpty) affixes[0] = floor.affixes;
  // A clan's die with its Resonance lit rolls its low faces one more
  // (clan_dice.dart), for this fight.
  final ownFaces = hero.diceFaces;
  if (resonanceOf(data.dice[hero.diceId] as Map<String, dynamic>?,
          politics: politics, data: clanData) ==
      Resonance.lit) {
    hero.diceFaces = resonantFaces(ownFaces);
  }
  final outcome = simulateSimFight(
    character: hero,
    enemies: enemies,
    chapter: floor.chapter,
    zoneMultiplier: floor.extraFor(run.professionId),
    skills: data.skills,
    items: data.items,
    random: random,
    clashOff: const {'goal'},
    clanStanding: (id) => politics.standingOf(id, clanData),
    affixes: affixes,
    elite: elite,
    rerollWeakFaces: true,
  );
  hero.diceFaces = ownFaces;
  return outcome;
}

/// Plays one whole run of [seed] with the unlocks of [progress] (none by
/// default, [towerAllUnlocked] for all) and returns it ended: won, or dead
/// on the floor it lost. The race and profession are drawn by the seed
/// among those open, unless given; it starts unsworn ([clanId] swears one
/// from the start) and takes the first oath it is offered.
TowerRun playTowerRun({
  required int seed,
  required TowerData data,
  TowerProgress progress = const TowerProgress(),
  String? raceId,
  String? professionId,
  String? clanId,
}) {
  final pick = towerRandom(seed, 0, TowerStream.start);
  T draw<T>(List<T> from) => from[pick.nextInt(from.length)];
  final races = data.races.keys.toList()..sort();
  final professions = progress.professions.toList()..sort();
  final clans = progress.clans.toList()..sort();
  var run = towerStart(
    seed: seed,
    raceId: raceId ?? draw(races),
    professionId: professionId ?? draw(professions),
    clanId: clanId ?? '',
    clanPool: clans,
    startUnlocks: progress.startUnlocks,
    unlocksOwned: progress.unlocksOwned,
    data: data,
  );
  final floors = towerFloorsFor(seed, data.enemies);
  while (!run.isOver) {
    final floor = floors[run.floor - 1];
    final hero = towerHeroOf(run, data);
    final maxHealth = hero.maxHealth;
    final outcome = towerBotFight(
      run: run,
      floor: floor,
      hero: hero,
      data: data,
      random: towerRandom(seed, floor.floor, TowerStream.fight),
    );
    run = towerAfterFight(run, data,
        won: outcome.won,
        healthLeft: hero.currentHealth,
        potionsLeft: hero.potions,
        maxHealthBefore: maxHealth);
    if (run.status == TowerStatus.choosing) {
      // The level-up first, as the story's bot takes its picks.
      // Each step's hero built once and handed on (towerHeroOf replays the
      // whole run).
      while (towerPendingPicks(run) > 0) {
        final hero = towerHeroOf(run, data);
        final offer = towerStatPickOffer(run, data, hero: hero);
        if (offer.isEmpty) break;
        run = towerTakeStatPick(
            run,
            data,
            statPickForShares(
                offer,
                simBuildShares[run.professionId] ?? {hero.preferredStat: 1.0},
                hero.pickedPoints),
            offer: offer);
      }
      final hero = towerHeroOf(run, data);
      run = towerPick(run, data, towerBotChoice(run), hero: hero);
    }
  }
  return run;
}

/// The card the bot takes from [run]'s offer: the first of a clan's oath
/// (a player's habit), a skill (a boon's first: the measure of v1.860, a
/// die first left the ranger at 1 top in 70), a die, a spell.
int? towerBotChoice(TowerRun run) {
  if (run.offer.isEmpty) return null;
  int? find(bool Function(TowerReward r) test) {
    for (var i = 0; i < run.offer.length; i++) {
      if (test(run.offer[i])) return i;
    }
    return null;
  }

  return find((r) => r.kind == TowerRewardKind.clanOath) ??
      find((r) => r.kind == TowerRewardKind.skill) ??
      find((r) => r.kind == TowerRewardKind.die) ??
      find((r) => r.kind == TowerRewardKind.spell) ??
      0;
}

/// A batch of [seeds] runs (QA's balance report): each run's floor
/// reached, and whether it won.
List<TowerRun> playTowerBatch(Iterable<int> seeds, TowerData data,
        {TowerProgress progress = const TowerProgress()}) =>
    [
      for (final seed in seeds)
        playTowerRun(seed: seed, data: data, progress: progress),
    ];

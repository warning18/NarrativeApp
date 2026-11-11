// The Tower's bot (v1.845): plays whole runs on the headless fight
// (simulateSimFight), for the tests and QA's balance batch (phase 2). It
// moves the run through the same functions the screens will
// (towerAfterFight, towerPick), so what it measures is the Tower itself.
// Its fights are set up as the app's Tower fight sets them (towerBotFight):
// the clans' standings, the floor's affixes and Elite, the die's own
// skills, a die rerolled as a player would. A die gained goes to the bag;
// the bot tries it before it rolls it (towerBotRollBest).

import 'dart:io';
import 'dart:convert';
import 'dart:math';

import '../../combat/clan_dice.dart';
import '../../combat/dice_faces.dart' show dieSignatureSkillIds;
import '../../combat/combat_engine.dart' show isBossEnemy, isRandomDrawEnemy;
import '../../combat/doctrine.dart';
import '../../combat/enemy_affix.dart';
import '../../combat/fight_numbers.dart';
import '../factions.dart' show ClanData;
import '../sim_combat.dart';
import '../training.dart' show statPickForShares;
import 'tower_dice.dart' show towerChooseDie;
import 'tower_events.dart';
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
/// - the skills of the die's own Skill faces (its signature skills, as
///   fight_setup.dart lends them), learned or not;
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
  // The die's signature skills, lent for the fight (fight_setup.dart): the
  // headless fight casts only the skills learned.
  final lent = [
    for (final id in dieSignatureSkillIds(
        data.dice[hero.diceId] as Map<String, dynamic>?))
      if (id.isNotEmpty && hero.unlockedSkillIds.add(id)) id,
  ];
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
  hero.unlockedSkillIds.removeAll(lent);
  return outcome;
}

/// Plays one whole run of [seed] with the unlocks of [progress] (none by
/// default, [towerAllUnlocked] for all) and returns it ended: won, or dead
/// on the floor it lost. The race and profession are drawn by the seed
/// among those open, unless given; it starts unsworn ([clanId] swears one
/// from the start) and takes the first oath it is offered ([choice], when
/// given, picks its cards instead: an offer's index, or null to refuse).
/// [events] is the floor events' version the run plays (towerStart; 0,
/// none, every test's and band's climb as before them).
TowerRun playTowerRun({
  required int seed,
  required TowerData data,
  TowerProgress progress = const TowerProgress(),
  String? raceId,
  String? professionId,
  String? clanId,
  int? Function(TowerRun run)? choice,
  int events = 0,
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
    events: events,
    data: data,
  );
  final floors = towerFloorsFor(seed, data.enemies);
  // The start's dice (its unlocks', a clan sworn at the start) tried
  // against the calling's own.
  final start = towerHeroOf(run, data);
  run = towerBotRollBest(run, data, floors, [
    for (final id in start.ownedDice.keys)
      if (id != start.diceId) id,
  ]);
  while (!run.isOver) {
    if (run.status == TowerStatus.climbing) {
      var hero = towerHeroOf(run, data);
      // A shortcut (floor events PR 2): taken with health to spare.
      if (towerEventKindOf(run) == TowerEventKind.shortcut &&
          run.shortcut == null) {
        run = towerChooseShortcut(run, data,
            hero.currentHealth >= towerBotShortcutHealth * hero.maxHealth);
        hero = towerHeroOf(run, data);
      }
      final floor = run.shortcut ?? false
          ? towerShortcutFloor(floors[run.floor - 1])
          : floors[run.floor - 1];
      final maxHealth = hero.maxHealth;
      final outcome = towerBotFight(
        run: run,
        floor: floor,
        hero: hero,
        data: data,
        random: towerRandom(seed, towerBotFightDraw(run), TowerStream.fight),
      );
      run = towerAfterFight(run, data,
          won: outcome.won,
          healthLeft: hero.currentHealth,
          potionsLeft: hero.potions,
          maxHealthBefore: maxHealth,
          rounds: outcome.rounds);
    }
    if (run.status == TowerStatus.choosing) {
      // The level-up first, as the story's bot takes its picks.
      run = _botStatPicks(run, data);
      final hero = towerHeroOf(run, data);
      final owned = hero.ownedDice.keys.toSet();
      final index = (choice ?? towerBotChoice)(run);
      final card = index != null && index >= 0 && index < run.offer.length
          ? run.offer[index]
          : null;
      run = towerPick(run, data, index, hero: hero);
      // A skip's landing: the skipped floors' picks, taken there (a
      // shortcut's landing card, if any, is the next pass's choice).
      run = _botStatPicks(run, data);
      // A die gained (a die card's, an oath's) goes to the bag: tried.
      final gained = switch (card?.kind) {
        TowerRewardKind.die => card!.id,
        TowerRewardKind.clanOath => towerClanDieOf(card!.id, data.dice),
        _ => null,
      };
      if (gained != null && !owned.contains(gained)) {
        run = towerBotRollBest(run, data, floors, [gained]);
      }
    }
  }
  return run;
}

/// [run] with the level-up picks it waits on taken as the bot takes them
/// (the story's bot's shares). Each step's hero built once and handed on
/// (towerHeroOf replays the whole run).
TowerRun _botStatPicks(TowerRun run, TowerData data) {
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
  return run;
}

/// How far apart a floor's refights draw on the fight stream: a floor met
/// again after the run's nth setback draws floor + n x this (floor events
/// PR 1, as the proposal's harness drew them), so a refight is a fresh
/// fight, not the one won before.
const int towerBotRevisitSalt = 1000;

/// The fight stream's index of [run]'s fight (towerRandom's floor): its
/// floor, or on a floor met again (at or below TowerRun.crest) its floor
/// salted by the setbacks taken, so a refight is a fresh fight.
int towerBotFightDraw(TowerRun run) => run.floor <= run.crest
    ? run.floor + towerBotRevisitSalt * run.setbacks
    : run.floor;

/// The health share at which the bot takes a shortcut (floor events PR 2;
/// the proposal measured 70, 80 and 90%: at 80% it took 57 to 64% of the
/// offers and won 91 to 92%).
const double towerBotShortcutHealth = .80;

/// The trial fights the bot gives each die it tries ([towerBotRollBest]).
const int towerBotDieTrialFights = 4;

/// The most dice the bot tries at once: the one in play, those just gained,
/// then the others owned.
const int towerBotDiceTried = 3;

/// [run] rolling the die its bot would choose after gaining [gained] (a
/// player's sensible choice, as the story's competent player tries a die
/// before it rolls it): each die tried ([towerBotDiceTried] at most) fights
/// [run]'s next floor [towerBotDieTrialFights] times at full health, on the
/// Tower's own trial stream; the most wins is rolled, the die in play
/// keeping a tie. [run] as it is when it is over, saved before the bag, or
/// has nothing to try.
TowerRun towerBotRollBest(TowerRun run, TowerData data, List<TowerFloor> floors,
    Iterable<String> gained) {
  if (run.isOver || run.dieChoice == null) return run;
  final hero = towerHeroOf(run, data);
  final current = hero.diceId;
  final tried = <String>[current];
  for (final id in [...gained, ...hero.ownedDice.keys.toList()..sort()]) {
    if (tried.length >= towerBotDiceTried) break;
    if (hero.ownedDice.containsKey(id) && !tried.contains(id)) tried.add(id);
  }
  if (tried.length < 2) return run;
  final floor = floors[run.floor - 1];
  var best = current, bestWins = -1;
  for (final id in tried) {
    final trial = run.copyWith(dieChoice: id);
    final rolled = towerHeroOf(trial, data);
    var wins = 0;
    for (var i = 0; i < towerBotDieTrialFights; i++) {
      final fighter = rolled.copy()..currentHealth = rolled.maxHealth;
      if (towerBotFight(
        run: trial,
        floor: floor,
        hero: fighter,
        data: data,
        random: towerRandom(run.seed, run.floor * towerBotDieTrialFights + i,
            TowerStream.dieTrial),
      ).won) {
        wins++;
      }
    }
    if (wins > bestWins) {
      best = id;
      bestWins = wins;
    }
  }
  return towerChooseDie(run, data, best);
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

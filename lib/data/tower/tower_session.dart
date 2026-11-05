// The Tower's hero as the fight screen reads it (v1.849): a PlayerSession
// built from the run alone (towerHeroOf), for a fight that never touches
// the story save (tower_fight_session.dart).

import '../../providers/player_session_provider.dart';
import '../factions.dart' show PoliticsState;
import 'tower_hero.dart';
import 'tower_run.dart';

/// The standing the run's clan is held at: Friend, the tier its die
/// resonates from (tower-mechanics.md §6).
const double towerClanStanding = 22;

/// [run]'s hero as a session: its race, profession, level, health, stats,
/// dice (the one in play and its skills on its faces), skills, spells,
/// worn and carried gear, the potions it carries into a fight, and its
/// clan at Friend. Nothing of the story: no gold, quests, allies or flags.
PlayerSession towerSessionOf(TowerRun run, TowerData data) {
  final hero = towerHeroOf(run, data);
  return PlayerSession(
    level: hero.level,
    currentXP: 0,
    gold: 0,
    alignmentScore: 0,
    maxHealth: hero.maxHealth,
    currentHealth: hero.currentHealth,
    baseDamage: hero.baseDamage,
    baseArmor: hero.baseArmor,
    luck: hero.luck,
    charisma: hero.charisma,
    strength: hero.strength,
    dexterity: hero.dexterity,
    constitution: hero.constitution,
    intelligence: hero.intelligence,
    wisdom: hero.wisdom,
    perception: hero.perception,
    potionCount: hero.potions,
    // The level-up's picks waiting (v1.857): the main game's Level Up screen
    // reads them, the Tower's own pick on the table (tower_level_up_session).
    statPoints: towerPendingPicks(run),
    maxSkillSlots: 3,
    flags: const [],
    activeQuestIds: const [],
    completedQuestIds: const [],
    inventoryItemIds: hero.ownedItemIds.toList()..sort(),
    equippedItemIds: hero.equippedItemIds,
    unlockedSkillIds: hero.unlockedSkillIds.toList()..sort(),
    unlockedShopIds: const [],
    unlockedQuestIds: const [],
    unlockedEnemyIds: const [],
    diceSkillAssignments: {hero.diceId: hero.diceSkillAssignments},
    raceId: run.raceId,
    professionId: run.professionId,
    ownedDiceIds: hero.ownedDice.keys.toList()..sort(),
    equippedDiceId: hero.diceId,
  ).copyWith(
    mana: hero.mana,
    knownSpellIds: [for (final s in hero.knownSpells) s.id],
    trainingTaken: {...hero.trainingTaken},
    statPickOffer: towerStatPickOffer(run, data),
    // Each clan sworn at Friend; the first (the main one) a point above, so
    // it is the patron and its die the one that resonates (one main clan,
    // the story's rule: the others' dice roll plain).
    politics: PoliticsState(standings: {
      for (final c in run.clanIds)
        c: c == run.mainClanId ? towerClanStanding + 1 : towerClanStanding,
    }),
  );
}

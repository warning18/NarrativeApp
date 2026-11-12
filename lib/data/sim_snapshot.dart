// A simulated character as a save (the playthrough simulator): the build a
// run brings to a fight, in the keys of PlayerSession.toJson, so a real
// fight can be replayed with it (docs/simulation/typical-player.md). Only
// what the fight reads is filled; PlayerSession.fromJson defaults the rest.
import '../models/ally_state.dart' show AllyState;
import 'dice_sizes_save.dart' show diceDataVersion, diceDataVersionKey;
import 'sim_combat.dart';
import 'sim_companions.dart';
import 'sim_growth.dart';
import 'stat_scale_save.dart' show statScaleSaveVersion;

/// The walk's hook before a fight's first try: the scene [nodeId] (the
/// walk's node), its [chapter] and [enemyIds], and [save], the build on
/// arrival ([simSessionSave]), built only when called. Read-only: the run
/// goes on as it would without it.
typedef SimFightWatch = void Function(
  String nodeId,
  int chapter,
  List<String> enemyIds,
  Map<String, dynamic> Function() save,
);

/// [character] (with its [growth] and [party]) as a PlayerSession save:
/// level, stats, health, potions, mana, gear worn, skills and their faces,
/// the die in play and those owned, spells, signs, perks, specialisations,
/// titles, the politics, the companions and their seats, [gold], [flags]
/// and [alignment].
Map<String, dynamic> simSessionSave({
  required SimCharacter character,
  SimGrowth? growth,
  SimParty? party,
  int gold = 0,
  Iterable<String> flags = const [],
  int alignment = 0,
}) {
  final c = character;
  return {
    'saveVersion': statScaleSaveVersion,
    diceDataVersionKey: diceDataVersion,
    'level': c.level,
    'currentXP': c.xp,
    'gold': gold,
    'alignmentScore': alignment,
    'maxHealth': c.maxHealth,
    'currentHealth': c.currentHealth,
    'baseDamage': c.baseDamage,
    'baseArmor': c.baseArmor,
    'luck': c.luck,
    'charisma': c.charisma,
    'strength': c.strength,
    'dexterity': c.dexterity,
    'constitution': c.constitution,
    'intelligence': c.intelligence,
    'wisdom': c.wisdom,
    'perception': c.perception,
    'potionCount': c.potions,
    'flags': flags.toList()..sort(),
    'equippedItemIds': c.equippedBySlot.values.toList()..sort(),
    'inventoryItemIds': c.ownedItemIds
        .where((id) => !c.equippedBySlot.containsValue(id))
        .toList()
      ..sort(),
    'unlockedSkillIds': c.unlockedSkillIds.toList()..sort(),
    'diceSkillAssignments': c.diceSkillAssignments,
    'raceId': c.raceId,
    'professionId': c.professionId,
    'ownedDiceIds': c.ownedDice.keys.toList()..sort(),
    'equippedDiceId': c.diceId,
    'specIds': c.specIds,
    'mana': c.mana,
    'knownSpellIds': [for (final s in c.knownSpells) s.id],
    'heldSigns': [for (final h in c.heldSigns) h.toJson()],
    if (growth != null) ...{
      'perkRanks': growth.perkRanks,
      'heldTitleIds': growth.titles,
      'activeTitleId': growth.activeTitle,
      'swornBoonIds': growth.boons,
      'politics': growth.politics.toJson(),
    },
    'recruitedAllies': [
      if (party != null)
        for (final s in party.roster.values)
          {
            'companionId': s.id,
            'currentHealth': s.health ?? AllyState.fullHealthSentinel,
            'approval': s.approval,
          },
    ],
    'activeAllyIds': party == null ? const <String>[] : [...party.active],
  };
}

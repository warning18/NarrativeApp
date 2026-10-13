import '../combat/dice_faces.dart';
import '../models/ally_state.dart'
    show equipmentScalingBonusFor, meetsItemAlignment, meetsItemStatRequirement;
import '../providers/player_session_provider.dart'
    show PlayerSession, playerWearerId;
import 'sim_growth.dart' show simSkillScore;

/// The build "Play to chapter" (autoplay_engine.dart) leaves the player
/// with before handing back: the stat points spent, the best gear worn and
/// the best skills on the die. The same policy the playthrough simulator
/// plays with (sim_combat.dart, sim_growth.dart), so the session it hands
/// back is the one the simulator's numbers describe.
class AutoplayBuild {
  const AutoplayBuild({
    required this.statToRaise,
    required this.statPoints,
    required this.equip,
    required this.faceAssignments,
  });

  /// The ability every waiting stat point goes to: the profession's
  /// `preferredScalingStat`, or Wisdom when it names none (the Cleric).
  final String statToRaise;
  final int statPoints;

  /// The item to wear in each slot (slot -> item id), only where it beats
  /// what is worn now.
  final Map<String, String> equip;

  /// The equipped die's face assignments to set (face index -> skill id);
  /// null when the player has no die.
  final Map<String, String>? faceAssignments;
}

/// The ability scores a stat point can raise, as
/// `PlayerSessionNotifier.spendStatPoint` names them.
const Set<String> _abilityStats = {
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
};

/// What [AutoplayBuild] to apply to [session]. Pure and free of
/// randomness: every tie goes to the lower id, so the same session always
/// gets the same build.
///
/// - Stat points: all of them to the profession's preferred stat (first,
///   since a score gates and scales the gear).
/// - Gear: per slot, the carried piece with the most attack plus armor
///   (its scaling bonus included) that the player may wear (stat and
///   alignment requirements, a copy no ally wears).
/// - Die: the equipped die's open Skill faces get the unlocked skills by
///   [simSkillScore], best first, as often as each one's rarity allows
///   (see [canSetSkillOnFace]); the mana skill keeps its face.
AutoplayBuild planAutoplayBuild(
  PlayerSession session, {
  required Map<String, dynamic> items,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> dice,
  required Map<String, dynamic> professions,
}) {
  final profession = professions[session.professionId] as Map?;
  final preferred = profession?['preferredScalingStat']?.toString() ?? '';
  final stat = _abilityStats.contains(preferred) ? preferred : 'wisdom';
  final points = session.statPoints < 0 ? 0 : session.statPoints;
  int raised(String name, int value) => name == stat ? value + points : value;
  final strength = raised('strength', session.strength);
  final dexterity = raised('dexterity', session.dexterity);
  final constitution = raised('constitution', session.constitution);
  final intelligence = raised('intelligence', session.intelligence);

  int scoreOf(String itemId) {
    final item = items[itemId] as Map<String, dynamic>?;
    if (item == null) return -1;
    final scaling = equipmentScalingBonusFor([itemId], items,
        strength: strength,
        dexterity: dexterity,
        constitution: constitution,
        intelligence: intelligence);
    return ((item['attackDamage'] as num?)?.toInt() ?? 0) +
        ((item['armor'] as num?)?.toInt() ?? 0) +
        scaling.damageBonus +
        scaling.armorBonus;
  }

  String slotOf(String itemId) =>
      (items[itemId] as Map?)?['equipSlot']?.toString() ?? '';

  final worn = <String, String>{
    for (final id in session.equippedItemIds)
      if (slotOf(id).isNotEmpty) slotOf(id): id,
  };
  final best = <String, String>{};
  final carried = session.inventoryItemIds.toSet().toList()..sort();
  for (final id in carried) {
    final item = items[id] as Map<String, dynamic>?;
    if (item == null || item['isEquippable'] != true) continue;
    final slot = slotOf(id);
    if (slot.isEmpty || session.equippedItemIds.contains(id)) continue;
    if (session.freeCopiesOf(id, wearerId: playerWearerId) <= 0) continue;
    if (!meetsItemStatRequirement(item,
            strength: strength,
            dexterity: dexterity,
            constitution: constitution,
            intelligence: intelligence) ||
        !meetsItemAlignment(item, session.alignmentLabel)) {
      continue;
    }
    final against = best[slot] ?? worn[slot];
    if (against == null || scoreOf(id) > scoreOf(against)) best[slot] = id;
  }

  return AutoplayBuild(
    statToRaise: stat,
    statPoints: points,
    equip: best,
    faceAssignments: _bestFaces(session, skills: skills, dice: dice),
  );
}

/// The equipped die's assignments with the best skills on its open Skill
/// faces (see [planAutoplayBuild]); every other face keeps what it has.
Map<String, String>? _bestFaces(
  PlayerSession session, {
  required Map<String, dynamic> skills,
  required Map<String, dynamic> dice,
}) {
  final dieId = session.equippedDiceId;
  final faces = ((dice[dieId] as Map?)?['faces'] as List?)
      ?.whereType<Map<String, dynamic>>()
      .toList();
  if (dieId == null || faces == null || faces.isEmpty) return null;
  bool isManaSkill(String id) =>
      (((skills[id] as Map?)?['damageMultiplier'] as num?)?.toDouble() ?? 1) <=
      0;
  final open = [
    for (var i = 0; i < faces.length; i++)
      if (faces[i]['type'] == 'Skill' && isAssignableFace(faces[i])) i,
  ];
  final assignments = <String, String>{
    ...?session.diceSkillAssignments[dieId],
  };
  // The open Skill faces are refilled; the mana skill keeps its own.
  for (final i in open) {
    final current = assignments['$i'];
    if (current == null || !isManaSkill(current)) assignments.remove('$i');
  }
  final ranked = [
    for (final id in session.unlockedSkillIds.toSet())
      if (skills[id] is Map<String, dynamic> && !isManaSkill(id)) id,
  ]..sort((a, b) {
      final byScore = simSkillScore(skills[b] as Map<String, dynamic>)
          .compareTo(simSkillScore(skills[a] as Map<String, dynamic>));
      return byScore != 0 ? byScore : a.compareTo(b);
    });
  for (final i in open) {
    if (assignments.containsKey('$i')) continue;
    for (final id in ranked) {
      if (canSetSkillOnFace(id, i, faces, assignments, skills)) {
        assignments['$i'] = id;
        break;
      }
    }
  }
  return assignments;
}

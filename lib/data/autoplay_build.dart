import '../combat/dice_faces.dart';
import '../models/ally_state.dart'
    show equipmentScalingBonusFor, meetsItemAlignment, meetsItemStatRequirement;
import '../providers/player_session_provider.dart'
    show PlayerSession, playerWearerId;
import 'shop_stock.dart' show allShopStock;
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

/// Where a typical run stands as it reaches each chapter's hub: the
/// median level and gold of the playthrough simulator's 800-run check
/// (seeds 11 and 23, v1.270.0, its `arrivals`; see docs/simulation/).
const Map<int, ({int level, int gold})> typicalArrival = {
  2: (level: 3, gold: 400),
  3: (level: 5, gold: 780),
  4: (level: 6, gold: 1350),
  5: (level: 8, gold: 1780),
  6: (level: 9, gold: 2330),
  7: (level: 10, gold: 2690),
  8: (level: 10, gold: 3240),
};

/// What "Play to chapter" adds on arrival at [chapter] so the character
/// handed back is one a player could have there (see [planArrivalTopUp]).
class ArrivalTopUp {
  const ArrivalTopUp({
    required this.xp,
    required this.gold,
    required this.items,
  });

  static const none = ArrivalTopUp(xp: 0, gold: 0, items: []);

  /// XP that brings the character to the chapter's typical level.
  final int xp;

  /// Gold that brings the purse to the chapter's typical gold.
  final int gold;

  /// The best piece per slot the chapter's shops and chests hold, for the
  /// slots where it beats everything carried.
  final List<String> items;

  bool get isEmpty => xp <= 0 && gold <= 0 && items.isEmpty;
}

/// The top-up for [session] reaching [chapter]: only ever up, never down
/// (a stronger character keeps what it has). Level and gold to
/// [typicalArrival]'s; then, per slot, the best piece the character could
/// have met by then (stocked by a shop open by [chapter], or a chest's
/// loot of a chapter up to it) that it may wear once the new levels' stat
/// points are spent as [planAutoplayBuild] spends them. Pure and free of
/// randomness, ties to the lower id.
ArrivalTopUp planArrivalTopUp(
  PlayerSession session, {
  required int chapter,
  required Map<String, dynamic> items,
  required Map<String, dynamic> shops,
  required Map<String, dynamic> professions,
}) {
  final target = typicalArrival[chapter.clamp(2, 8)];
  if (target == null || session.professionId.isEmpty) return ArrivalTopUp.none;

  var xp = -session.currentXP;
  for (var l = session.level; l < target.level; l++) {
    xp += l * 100;
  }
  if (session.level >= target.level) xp = 0;
  final levelsGained =
      session.level >= target.level ? 0 : target.level - session.level;
  final gold = target.gold > session.gold ? target.gold - session.gold : 0;

  // The scores the build will have: every point to the profession's stat.
  final profession = professions[session.professionId] as Map?;
  final preferred = profession?['preferredScalingStat']?.toString() ?? '';
  final stat = _abilityStats.contains(preferred) ? preferred : 'wisdom';
  final points =
      (session.statPoints < 0 ? 0 : session.statPoints) + 5 * levelsGained;
  int raised(String name, int value) => name == stat ? value + points : value;
  final strength = raised('strength', session.strength);
  final dexterity = raised('dexterity', session.dexterity);
  final constitution = raised('constitution', session.constitution);
  final intelligence = raised('intelligence', session.intelligence);
  int scoreOf(String id) {
    final item = items[id] as Map<String, dynamic>?;
    if (item == null) return -1;
    final scaling = equipmentScalingBonusFor([id], items,
        strength: strength,
        dexterity: dexterity,
        constitution: constitution,
        intelligence: intelligence);
    return ((item['attackDamage'] as num?)?.toInt() ?? 0) +
        ((item['armor'] as num?)?.toInt() ?? 0) +
        scaling.damageBonus +
        scaling.armorBonus;
  }

  String slotOf(String id) =>
      (items[id] as Map?)?['equipSlot']?.toString() ?? '';

  // What the chapter's shops and chests hold.
  final available = <String>{
    for (final shop in shops.values)
      if (shop is Map<String, dynamic> &&
          ((shop['minChapter'] as num?)?.toInt() ?? 1) <= chapter)
        ...allShopStock(shop),
    for (final entry in items.entries)
      if (entry.value is Map &&
          ((entry.value as Map)['lootChapter'] as num?) != null &&
          ((entry.value as Map)['lootChapter'] as num).toInt() >= 1 &&
          ((entry.value as Map)['lootChapter'] as num).toInt() <= chapter)
        entry.key,
  }.toList()
    ..sort();

  final bestHeld = <String, int>{};
  for (final id in session.inventoryItemIds) {
    final slot = slotOf(id);
    if (slot.isEmpty) continue;
    final score = scoreOf(id);
    if (score > (bestHeld[slot] ?? -1)) bestHeld[slot] = score;
  }
  final best = <String, String>{};
  for (final id in available) {
    final item = items[id] as Map<String, dynamic>?;
    if (item == null || item['isEquippable'] != true) continue;
    final slot = slotOf(id);
    if (slot.isEmpty || session.inventoryItemIds.contains(id)) continue;
    if (!meetsItemStatRequirement(item,
            strength: strength,
            dexterity: dexterity,
            constitution: constitution,
            intelligence: intelligence) ||
        !meetsItemAlignment(item, session.alignmentLabel)) {
      continue;
    }
    final score = scoreOf(id);
    if (score <= (bestHeld[slot] ?? -1)) continue;
    final current = best[slot];
    if (current == null || score > scoreOf(current)) best[slot] = id;
  }
  return ArrivalTopUp(
    xp: xp < 0 ? 0 : xp,
    gold: gold,
    items: [for (final slot in best.keys.toList()..sort()) best[slot]!],
  );
}

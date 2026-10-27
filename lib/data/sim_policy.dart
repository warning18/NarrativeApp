// The simulated player's policy (the playthrough simulator): how it plays
// the choices a real player makes between fights -- the gear it wears, the
// die it rolls, the skills it crafts and the clan banner it takes.
//
// [SimPolicy.naive] is the simulator as it always played (every CI band is
// measured with it); [SimPolicy.competent] plays those choices the way a
// competent real player would, so its numbers read as "the game for
// someone who plays it well".
import '../combat/combat_engine.dart' show elementFieldPrefixes;
import '../combat/dice_faces.dart' show isOpenSkillFace;
import '../combat/gear_effects.dart';
import '../models/ally_state.dart' show equipmentBonusFor;
import 'sim_growth.dart' show simSkillScore;

/// How the simulated player plays its choices:
/// - [naive]: the simulator's old ways (gear by flat damage plus armor when
///   it comes, the die it starts with or the sage die, the 25%-favour-best
///   banner policy kept to its clan);
/// - [competent]: the best loadout per slot for the build (sets weighed),
///   the best die it owns with the signature skills placed, the merges
///   worth crafting, and the banner that raises its power most without
///   turning a clan it needs Hostile.
enum SimPolicy { naive, competent }

/// One clan offer as the run took it: when ([chapter], [source]: level,
/// boss, chapter, tome...), the banners offered (`clan:kind:gift`), the one
/// [taken] and [reason], why.
class SimOfferPick {
  const SimOfferPick({
    required this.chapter,
    required this.source,
    required this.offered,
    required this.taken,
    required this.reason,
  });

  final int chapter;
  final String source;
  final List<String> offered;
  final String taken;
  final String reason;

  /// The report's line.
  String get line =>
      'Ch$chapter $source: [${offered.join(' | ')}] -> $taken ($reason)';
}

// --- Gear --------------------------------------------------------------------

/// What a loadout is worth in a fight, in "one point of damage on every
/// hit" units: its flat attack and armor (sets' tiers included), a little
/// for its elemental bonuses and resists (they count only on a matching
/// face or blow), and the uniques' and sets' crit, dodge, block,
/// lifesteal, thorns, mana on hit and second wind. [caster]: a character
/// with spells, for whom mana on hit is worth more.
double simLoadoutValue(
  Iterable<String> loadout,
  Map<String, dynamic> items,
  Map<String, ItemSet> sets, {
  bool caster = false,
}) {
  final ids = loadout.toList();
  int sum(String field) => equipmentBonusFor(ids, items, field);
  final gear = gearEffectsFor(ids, items, sets);
  var elemental = 0, resist = 0;
  for (final prefix in elementFieldPrefixes.values) {
    elemental += sum('${prefix}DmgBonus');
    resist += sum('${prefix}Resist');
  }
  return (sum('attackDamage') + gear.attackDamage) * 1.0 +
      (sum('armor') + gear.armor) * 0.8 +
      elemental * 0.3 +
      resist * 0.1 +
      (gear.critChance + gear.dodgeChance + gear.blockChance) * 0.08 +
      gear.lifestealPercent * 0.05 +
      gear.thornsPercent * 0.03 +
      gear.manaOnHit * (caster ? 0.5 : 0.1) +
      (gear.secondWind ? 2 : 0);
}

/// The loadout (slot -> item) a competent player wears out of [owned] and
/// what is [worn]: per slot the piece that raises [simLoadoutValue] most,
/// slot after slot until nothing changes, then each set tried whole (two
/// pieces swapped at once, which one slot at a time never sees) and kept
/// when the set's bonus beats the single upgrades it replaces. [canWear]
/// is the stat requirement; a worn piece is never taken off for nothing.
Map<String, String> simBestLoadout({
  required Map<String, String> worn,
  required Iterable<String> owned,
  required Map<String, dynamic> items,
  required Map<String, ItemSet> sets,
  required bool Function(Map<String, dynamic> item) canWear,
  bool caster = false,
}) {
  final bySlot = <String, List<String>>{};
  for (final id in {...owned, ...worn.values}.toList()..sort()) {
    final item = items[id];
    if (item is! Map<String, dynamic> || item['isEquippable'] != true) {
      continue;
    }
    final slot = item['equipSlot']?.toString() ?? '';
    if (slot.isEmpty || !canWear(item)) continue;
    bySlot.putIfAbsent(slot, () => []).add(id);
  }
  var best = <String, String>{
    for (final MapEntry(:key, :value) in worn.entries)
      if (bySlot[key]?.contains(value) ?? false) key: value,
  };
  double value(Map<String, String> l) =>
      simLoadoutValue(l.values, items, sets, caster: caster);
  void climb() {
    for (var pass = 0; pass < 4; pass++) {
      var moved = false;
      for (final slot in bySlot.keys.toList()..sort()) {
        var bestValue = value(best);
        for (final id in bySlot[slot]!) {
          if (best[slot] == id) continue;
          final tried = {...best, slot: id};
          final v = value(tried);
          if (v > bestValue + 1e-9) {
            best = tried;
            bestValue = v;
            moved = true;
          }
        }
      }
      if (!moved) return;
    }
  }

  climb();
  for (final set in sets.values) {
    final tried = {...best};
    for (final id in set.itemIds) {
      final item = items[id] as Map<String, dynamic>?;
      final slot = item?['equipSlot']?.toString() ?? '';
      if (bySlot[slot]?.contains(id) ?? false) tried[slot] = id;
    }
    if (value(tried) > value(best) + 1e-9) best = tried;
  }
  climb();
  return best;
}

// --- The die -----------------------------------------------------------------

bool _isManaSkill(Map<String, dynamic> skills, String skillId) {
  final skill = skills[skillId] as Map<String, dynamic>?;
  return ((skill?['damageMultiplier'] as num?)?.toDouble() ?? 1) <= 0;
}

/// Every learned skill of [unlocked] on [faces]' open Skill faces, the best
/// on them: a mana skill on a face ([current]) keeps it, the rest go by
/// [simSkillScore] (ties by id). The simulator's assignment
/// (SimGrowth.assignSkills).
Map<String, String> simSkillAssignments({
  required List<Map<String, dynamic>> faces,
  required Map<String, String> current,
  required Iterable<String> unlocked,
  required Map<String, dynamic> skills,
}) {
  final open = [
    for (var i = 0; i < faces.length; i++)
      if (isOpenSkillFace(faces[i])) i,
  ];
  final assignments = <String, String>{};
  final placed = <String>{};
  for (final i in open) {
    final id = current['$i'];
    if (id != null && _isManaSkill(skills, id)) {
      assignments['$i'] = id;
      placed.add(id);
    }
  }
  final ranked = [
    for (final id in unlocked)
      if (!placed.contains(id) &&
          !_isManaSkill(skills, id) &&
          skills[id] is Map<String, dynamic>)
        id,
  ]..sort((a, b) {
      final byScore = simSkillScore(skills[b] as Map<String, dynamic>)
          .compareTo(simSkillScore(skills[a] as Map<String, dynamic>));
      return byScore != 0 ? byScore : a.compareTo(b);
    });
  var next = 0;
  for (final i in open) {
    if (assignments.containsKey('$i')) continue;
    if (next >= ranked.length) break;
    assignments['$i'] = ranked[next++];
  }
  return assignments;
}

/// What a roll of the die is worth on average (faces by their weight), in
/// the same units as [simLoadoutValue]: an Attack face the character's
/// [damage] plus its value, a Skill face [damage] plus what its skill adds
/// ([simSkillScore]; the assigned one, else its own, else Heavy Attack), a
/// Defend face most of its block, a Heal face most of its mending, a Mana
/// face (and a mana skill) only for a [caster].
double simDieValue(
  List<Map<String, dynamic>> faces,
  Map<String, String> assignments,
  Map<String, dynamic> skills, {
  required int damage,
  bool caster = false,
}) {
  var total = 0.0, weights = 0.0;
  for (var i = 0; i < faces.length; i++) {
    final face = faces[i];
    final w = (face['weight'] as num?)?.toDouble() ?? 1.0;
    final v = (face['value'] as num?)?.toDouble() ?? 0;
    final worth = switch (face['type']?.toString()) {
      'Attack' => damage + v,
      'Defend' => v * 0.8,
      'Heal' => v * 0.7,
      'Mana' => caster ? v * 1.5 : 0.0,
      'Skill' => () {
          final linked = face['linkedSkillID']?.toString() ?? '';
          final id =
              assignments['$i'] ?? (linked.isEmpty ? 'heavy_attack' : linked);
          if (_isManaSkill(skills, id)) return caster ? 2.0 : 0.0;
          return damage + simSkillScore(skills[id] as Map<String, dynamic>?);
        }(),
      _ => 0.0,
    };
    total += w * worth;
    weights += w;
  }
  return weights <= 0 ? 0 : total / weights;
}

/// Whether [die] (a dice.json record) is one the character may roll: no
/// profession or race listed, or its own among them.
bool simCanUseDie(Map<String, dynamic> die,
    {required String professionId, required String raceId}) {
  final professions = [
    for (final p in (die['professions'] as List?) ?? const []) p.toString(),
  ];
  final races = [
    for (final r in (die['races'] as List?) ?? const []) r.toString(),
  ];
  return (professions.isEmpty || professions.contains(professionId)) &&
      (races.isEmpty || races.contains(raceId));
}

/// The skill_merges.json recipes a competent player crafts at the
/// Skillwright knowing [unlocked], best first: one whose result, put on
/// the die in place of its two inputs, raises [simDieValue] (the inputs are
/// consumed, so a merge that empties a face or loses a better skill is
/// left alone). Returns the recipe's (inputs, result), or null.
({List<String> inputs, String result})? simMergeWorthIt({
  required Map<String, dynamic> merges,
  required Set<String> unlocked,
  required List<Map<String, dynamic>> faces,
  required Map<String, String> current,
  required Map<String, dynamic> skills,
  required int damage,
  bool caster = false,
}) {
  double valueWith(Set<String> known) => simDieValue(
      faces,
      simSkillAssignments(
          faces: faces, current: current, unlocked: known, skills: skills),
      skills,
      damage: damage,
      caster: caster);
  final now = valueWith(unlocked);
  ({List<String> inputs, String result})? best;
  var bestValue = now + 0.01;
  for (final key in merges.keys.toList()..sort()) {
    final recipe = merges[key];
    if (recipe is! Map) continue;
    final inputs = [
      for (final id in (recipe['inputSkillIDs'] as List?) ?? const [])
        id.toString(),
    ];
    final result = recipe['resultSkillID']?.toString() ?? key;
    if (inputs.isEmpty ||
        unlocked.contains(result) ||
        skills[result] is! Map<String, dynamic> ||
        !inputs.every(unlocked.contains)) {
      continue;
    }
    final v = valueWith({...unlocked.difference(inputs.toSet()), result});
    if (v > bestValue) {
      bestValue = v;
      best = (inputs: inputs, result: result);
    }
  }
  return best;
}

/// A recruited companion's persistent, player-managed state — the ally
/// equivalent of the handful of [PlayerSession] fields that aren't derived
/// automatically (equipment, learned skills, current health).
///
/// Deliberately does *not* carry level/XP/maxHealth/baseDamage/baseArmor:
/// an ally's combat stats are always derived live (see [deriveAllyBaseStats]
/// plus the existing `scaledMaxHealth`/`scaledDamage` scaling functions in
/// combat_engine.dart, keyed on the player's current level) rather than
/// tracked independently — "an ally's stats scale up automatically as you
/// level" is satisfied by recomputing, never by storing a second leveling
/// track. There's likewise no `statPoints`: allies have nothing to manually
/// allocate, only skills to unlock.
class AllyState {
  const AllyState({
    required this.companionId,
    required this.currentHealth,
    this.equippedItemIds = const [],
    this.unlockedSkillIds = const [],
    this.skillPoints = 0,
    this.diceSkillAssignments = const {},
  });

  /// A deliberately-oversized `currentHealth` meaning "fully healed,"
  /// clamped down to the live-derived max wherever it's actually read (see
  /// class doc). An ally's true max health moves as the player levels, so
  /// "full" can't be a fixed stored number the way [PlayerSession] can use
  /// its own concrete `maxHealth` — this sentinel plus always clamping at
  /// read time keeps a rested ally at 100% relative to whatever their
  /// current derived max is, without needing to recompute and rewrite it on
  /// every player level-up.
  static const int fullHealthSentinel = 1 << 30;

  final String companionId;

  /// Persisted raw HP — clamp against the live-derived max wherever it's
  /// read (see [deriveAllyBaseStats] + scaling), the same way
  /// [PlayerSession.currentHealth] is stored raw and clamped at use sites.
  final int currentHealth;

  final List<String> equippedItemIds;
  final List<String> unlockedSkillIds;

  /// +1 whenever the player levels up (see
  /// `PlayerSessionNotifier.applyCombatResult`), mirroring the player's own
  /// "+1 skillPoint per level" rule so a companion's learnable-skill pool
  /// keeps pace without a separate ally leveling system.
  final int skillPoints;

  /// faceIndex (as string) -> skillId, for the one open "Skill" face on the
  /// companion's fixed signature die (their locked, thematic faces already
  /// have a hardcoded linkedSkillID and can't be reassigned — see
  /// `dice_loadout_screen.dart`'s `_isFixedSkillFace`). Flat, unlike
  /// [PlayerSession.diceSkillAssignments]' dice-keyed nested map, because an
  /// ally only ever has the one die.
  final Map<String, String> diceSkillAssignments;

  AllyState copyWith({
    int? currentHealth,
    List<String>? equippedItemIds,
    List<String>? unlockedSkillIds,
    int? skillPoints,
    Map<String, String>? diceSkillAssignments,
  }) {
    return AllyState(
      companionId: companionId,
      currentHealth: currentHealth ?? this.currentHealth,
      equippedItemIds: equippedItemIds ?? this.equippedItemIds,
      unlockedSkillIds: unlockedSkillIds ?? this.unlockedSkillIds,
      skillPoints: skillPoints ?? this.skillPoints,
      diceSkillAssignments: diceSkillAssignments ?? this.diceSkillAssignments,
    );
  }

  Map<String, dynamic> toJson() => {
        'companionId': companionId,
        'currentHealth': currentHealth,
        'equippedItemIds': equippedItemIds,
        'unlockedSkillIds': unlockedSkillIds,
        'skillPoints': skillPoints,
        'diceSkillAssignments': diceSkillAssignments,
      };

  factory AllyState.fromJson(Map<String, dynamic> json) {
    return AllyState(
      companionId: json['companionId'] as String? ?? '',
      currentHealth: (json['currentHealth'] as num?)?.toInt() ?? 0,
      equippedItemIds: (json['equippedItemIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unlockedSkillIds: (json['unlockedSkillIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      skillPoints: (json['skillPoints'] as num?)?.toInt() ?? 0,
      diceSkillAssignments: (json['diceSkillAssignments'] as Map?)?.map(
            (faceIndex, skillId) =>
                MapEntry(faceIndex.toString(), skillId.toString()),
          ) ??
          const {},
    );
  }
}

/// An ally's unscaled base stats, derived the same way
/// `PlayerSessionNotifier.startNewGame` derives the player's own: New Game
/// Defaults plus the race and profession preset bonuses. Callers then run
/// these through combat_engine.dart's `scaledMaxHealth`/`scaledDamage`,
/// keyed on the player's current level, to get an ally's live combat stats.
class AllyBaseStats {
  const AllyBaseStats({
    required this.maxHealth,
    required this.baseDamage,
    required this.baseArmor,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
  });

  final int maxHealth;
  final int baseDamage;
  final int baseArmor;

  /// Ability scores, derived the same additive way as the player's own (see
  /// `PlayerSessionNotifier.startNewGame`) -- feed [equipmentScalingBonusFor]
  /// and [meetsItemStatRequirement] so an ally's gear scales with, and is
  /// gated by, their own race/profession-derived scores, exactly like the
  /// player. Wisdom/Luck/Charisma aren't included: they don't affect combat
  /// for the player either (see [PlayerSession]'s doc comment), so an ally
  /// has no use for them.
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
}

AllyBaseStats deriveAllyBaseStats({
  required Map<String, dynamic> gameConfig,
  required Map<String, dynamic> race,
  required Map<String, dynamic> profession,
}) {
  int bonus(Map<String, dynamic> preset, String key) =>
      (preset[key] as num?)?.toInt() ?? 0;
  return AllyBaseStats(
    maxHealth: ((gameConfig['maxHealth'] as num?)?.toInt() ?? 100) +
        bonus(race, 'bonusMaxHealth') +
        bonus(profession, 'bonusMaxHealth'),
    baseDamage: ((gameConfig['baseDamage'] as num?)?.toInt() ?? 10) +
        bonus(race, 'bonusBaseDamage') +
        bonus(profession, 'bonusBaseDamage'),
    baseArmor: ((gameConfig['baseArmor'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusBaseArmor') +
        bonus(profession, 'bonusBaseArmor'),
    strength: ((gameConfig['strength'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusStrength') +
        bonus(profession, 'bonusStrength'),
    dexterity: ((gameConfig['dexterity'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusDexterity') +
        bonus(profession, 'bonusDexterity'),
    constitution: ((gameConfig['constitution'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusConstitution') +
        bonus(profession, 'bonusConstitution'),
    intelligence: ((gameConfig['intelligence'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusIntelligence') +
        bonus(profession, 'bonusIntelligence'),
  );
}

/// Sum of an equipped-item list's relevant bonus field ('attackDamage' or
/// 'armor') looked up against the items db — the same computation
/// `fight_screen.dart` already does for the player, generalized to take an
/// explicit id list so it works identically for an ally's own equipment.
int equipmentBonusFor(
  List<String> equippedItemIds,
  Map<String, dynamic> items,
  String bonusField,
) {
  var bonus = 0;
  for (final id in equippedItemIds) {
    final item = items[id] as Map<String, dynamic>?;
    bonus += (item?[bonusField] as num?)?.toInt() ?? 0;
  }
  return bonus;
}

/// The extra attackDamage/armor an equipped-item list contributes on top of
/// its own flat bonuses, from each item's `scalingStat` (e.g. a staff
/// scaling with Intelligence). Only ever adds — a low or negative stat never
/// subtracts below an item's flat value, so picking up gear your build
/// doesn't favor never actively hurts, it just doesn't reach its full
/// potential. The modifier is the classic D&D-style ability-score halving
/// (`stat ~/ 2`), matching the doc comment on [PlayerSession]'s ability
/// scores.
class EquipmentScalingBonus {
  const EquipmentScalingBonus({this.damageBonus = 0, this.armorBonus = 0});

  final int damageBonus;
  final int armorBonus;
}

EquipmentScalingBonus equipmentScalingBonusFor(
  List<String> equippedItemIds,
  Map<String, dynamic> items, {
  required int strength,
  required int dexterity,
  required int constitution,
  required int intelligence,
}) {
  var damageBonus = 0;
  var armorBonus = 0;
  for (final id in equippedItemIds) {
    final item = items[id] as Map<String, dynamic>?;
    final scalingStat = item?['scalingStat']?.toString() ?? '';
    if (scalingStat.isEmpty) continue;
    final statValue = switch (scalingStat) {
      'strength' => strength,
      'dexterity' => dexterity,
      'constitution' => constitution,
      'intelligence' => intelligence,
      _ => 0,
    };
    final modifier = statValue ~/ 2;
    if (modifier <= 0) continue;
    if (((item?['attackDamage'] as num?) ?? 0) > 0) damageBonus += modifier;
    if (((item?['armor'] as num?) ?? 0) > 0) armorBonus += modifier;
  }
  return EquipmentScalingBonus(
      damageBonus: damageBonus, armorBonus: armorBonus);
}

/// Whether the equipping character's own ability scores meet [item]'s
/// reqStrength/reqDexterity/reqConstitution/reqIntelligence gate, if it has
/// one — e.g. a heavy sword's top tiers require both Strength and
/// Constitution. An item with no requirement fields set (the common case —
/// most gear, and every early weapon tier) is always equippable.
bool meetsItemStatRequirement(
  Map<String, dynamic>? item, {
  required int strength,
  required int dexterity,
  required int constitution,
  required int intelligence,
}) {
  if (item == null) return true;
  int req(String key) => (item[key] as num?)?.toInt() ?? 0;
  return strength >= req('reqStrength') &&
      dexterity >= req('reqDexterity') &&
      constitution >= req('reqConstitution') &&
      intelligence >= req('reqIntelligence');
}

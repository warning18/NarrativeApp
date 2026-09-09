import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _playerSessionPrefsKey = 'player_session';
const String _newGameDefaultsAssetPath = 'assets/gamedata/game_config.json';
const String _newGameDefaultsPrefsKey = 'gamedb_game_config';

class PlayerSession {
  const PlayerSession({
    required this.level,
    required this.currentXP,
    required this.gold,
    required this.alignmentScore,
    required this.maxHealth,
    required this.currentHealth,
    required this.baseDamage,
    required this.baseArmor,
    required this.potionCount,
    required this.statPoints,
    required this.skillPoints,
    required this.maxSkillSlots,
    required this.flags,
    required this.activeQuestIds,
    required this.completedQuestIds,
    required this.inventoryItemIds,
    required this.equippedItemIds,
    required this.unlockedSkillIds,
    required this.unlockedShopIds,
    required this.unlockedQuestIds,
    required this.unlockedEnemyIds,
    required this.diceSkillAssignments,
    required this.raceId,
    required this.professionId,
  });

  final int level;
  final int currentXP;
  final int gold;
  final int alignmentScore;
  final int maxHealth;
  final int currentHealth;
  final int baseDamage;
  final int baseArmor;
  final int potionCount;
  final int statPoints;
  final int skillPoints;
  final int maxSkillSlots;
  final List<String> flags;
  final List<String> activeQuestIds;
  final List<String> completedQuestIds;
  final List<String> inventoryItemIds;
  final List<String> equippedItemIds;
  final List<String> unlockedSkillIds;
  final List<String> unlockedShopIds;
  final List<String> unlockedQuestIds;
  final List<String> unlockedEnemyIds;

  /// diceId -> {faceIndex (as string) -> skillId}
  final Map<String, Map<String, String>> diceSkillAssignments;

  final String raceId;
  final String professionId;

  int get xpToNextLevel => level * 100;

  String get alignmentLabel {
    if (alignmentScore >= 20) return 'Good';
    if (alignmentScore <= -20) return 'Evil';
    return 'Neutral';
  }

  bool meetsRequirements({
    int reqGold = 0,
    int? reqAlignmentScore,
    List<String> reqFlags = const [],
  }) {
    if (gold < reqGold) return false;
    if (reqAlignmentScore != null && alignmentScore < reqAlignmentScore) return false;
    for (final flag in reqFlags) {
      if (!flags.contains(flag)) return false;
    }
    return true;
  }

  PlayerSession copyWith({
    int? level,
    int? currentXP,
    int? gold,
    int? alignmentScore,
    int? maxHealth,
    int? currentHealth,
    int? baseDamage,
    int? baseArmor,
    int? potionCount,
    int? statPoints,
    int? skillPoints,
    int? maxSkillSlots,
    List<String>? flags,
    List<String>? activeQuestIds,
    List<String>? completedQuestIds,
    List<String>? inventoryItemIds,
    List<String>? equippedItemIds,
    List<String>? unlockedSkillIds,
    List<String>? unlockedShopIds,
    List<String>? unlockedQuestIds,
    List<String>? unlockedEnemyIds,
    Map<String, Map<String, String>>? diceSkillAssignments,
    String? raceId,
    String? professionId,
  }) {
    return PlayerSession(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      gold: gold ?? this.gold,
      alignmentScore: alignmentScore ?? this.alignmentScore,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      baseDamage: baseDamage ?? this.baseDamage,
      baseArmor: baseArmor ?? this.baseArmor,
      potionCount: potionCount ?? this.potionCount,
      statPoints: statPoints ?? this.statPoints,
      skillPoints: skillPoints ?? this.skillPoints,
      maxSkillSlots: maxSkillSlots ?? this.maxSkillSlots,
      flags: flags ?? this.flags,
      activeQuestIds: activeQuestIds ?? this.activeQuestIds,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
      equippedItemIds: equippedItemIds ?? this.equippedItemIds,
      unlockedSkillIds: unlockedSkillIds ?? this.unlockedSkillIds,
      unlockedShopIds: unlockedShopIds ?? this.unlockedShopIds,
      unlockedQuestIds: unlockedQuestIds ?? this.unlockedQuestIds,
      unlockedEnemyIds: unlockedEnemyIds ?? this.unlockedEnemyIds,
      diceSkillAssignments: diceSkillAssignments ?? this.diceSkillAssignments,
      raceId: raceId ?? this.raceId,
      professionId: professionId ?? this.professionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'currentXP': currentXP,
        'gold': gold,
        'alignmentScore': alignmentScore,
        'maxHealth': maxHealth,
        'currentHealth': currentHealth,
        'baseDamage': baseDamage,
        'baseArmor': baseArmor,
        'potionCount': potionCount,
        'statPoints': statPoints,
        'skillPoints': skillPoints,
        'maxSkillSlots': maxSkillSlots,
        'flags': flags,
        'activeQuestIds': activeQuestIds,
        'completedQuestIds': completedQuestIds,
        'inventoryItemIds': inventoryItemIds,
        'equippedItemIds': equippedItemIds,
        'unlockedSkillIds': unlockedSkillIds,
        'unlockedShopIds': unlockedShopIds,
        'unlockedQuestIds': unlockedQuestIds,
        'unlockedEnemyIds': unlockedEnemyIds,
        'diceSkillAssignments': diceSkillAssignments,
        'raceId': raceId,
        'professionId': professionId,
      };

  factory PlayerSession.fromJson(Map<String, dynamic> json) {
    return PlayerSession(
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentXP: (json['currentXP'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      alignmentScore: (json['alignmentScore'] as num?)?.toInt() ?? 0,
      maxHealth: (json['maxHealth'] as num?)?.toInt() ?? 100,
      currentHealth: (json['currentHealth'] as num?)?.toInt() ?? 100,
      baseDamage: (json['baseDamage'] as num?)?.toInt() ?? 10,
      baseArmor: (json['baseArmor'] as num?)?.toInt() ?? 0,
      potionCount: (json['potionCount'] as num?)?.toInt() ?? 0,
      statPoints: (json['statPoints'] as num?)?.toInt() ?? 0,
      skillPoints: (json['skillPoints'] as num?)?.toInt() ?? 0,
      maxSkillSlots: (json['maxSkillSlots'] as num?)?.toInt() ?? 3,
      flags: (json['flags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      activeQuestIds:
          (json['activeQuestIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      completedQuestIds:
          (json['completedQuestIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      inventoryItemIds:
          (json['inventoryItemIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      equippedItemIds:
          (json['equippedItemIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      unlockedSkillIds:
          (json['unlockedSkillIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      unlockedShopIds:
          (json['unlockedShopIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      unlockedQuestIds:
          (json['unlockedQuestIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      unlockedEnemyIds:
          (json['unlockedEnemyIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      diceSkillAssignments: (json['diceSkillAssignments'] as Map?)?.map(
            (diceId, faces) => MapEntry(
              diceId.toString(),
              (faces as Map).map(
                (faceIndex, skillId) => MapEntry(faceIndex.toString(), skillId.toString()),
              ),
            ),
          ) ??
          const {},
      raceId: json['raceId'] as String? ?? '',
      professionId: json['professionId'] as String? ?? '',
    );
  }
}

class PlayerSessionNotifier extends StateNotifier<PlayerSession> {
  PlayerSessionNotifier()
      : super(const PlayerSession(
          level: 1,
          currentXP: 0,
          gold: 0,
          alignmentScore: 0,
          maxHealth: 100,
          currentHealth: 100,
          baseDamage: 10,
          baseArmor: 0,
          potionCount: 0,
          statPoints: 0,
          skillPoints: 0,
          maxSkillSlots: 3,
          flags: [],
          activeQuestIds: [],
          completedQuestIds: [],
          inventoryItemIds: [],
          equippedItemIds: [],
          unlockedSkillIds: [],
          unlockedShopIds: [],
          unlockedQuestIds: [],
          unlockedEnemyIds: [],
          diceSkillAssignments: {},
          raceId: '',
          professionId: '',
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_playerSessionPrefsKey);
    if (saved != null) {
      state = PlayerSession.fromJson(json.decode(saved) as Map<String, dynamic>);
      return;
    }
    await _resetToDefaults(prefs);
  }

  Future<void> _resetToDefaults(SharedPreferences prefs) async {
    Map<String, dynamic> defaults;
    final savedConfig = prefs.getString(_newGameDefaultsPrefsKey);
    if (savedConfig != null) {
      defaults = json.decode(savedConfig) as Map<String, dynamic>;
    } else {
      final raw = await rootBundle.loadString(_newGameDefaultsAssetPath);
      defaults = json.decode(raw) as Map<String, dynamic>;
    }
    final maxHealth = (defaults['maxHealth'] as num?)?.toInt() ?? 100;
    state = PlayerSession(
      level: (defaults['playerLevel'] as num?)?.toInt() ?? 1,
      currentXP: 0,
      gold: (defaults['gold'] as num?)?.toInt() ?? 0,
      alignmentScore: 0,
      maxHealth: maxHealth,
      currentHealth: maxHealth,
      baseDamage: (defaults['baseDamage'] as num?)?.toInt() ?? 10,
      baseArmor: (defaults['baseArmor'] as num?)?.toInt() ?? 0,
      potionCount: (defaults['potionCount'] as num?)?.toInt() ?? 0,
      statPoints: 0,
      skillPoints: 0,
      maxSkillSlots: (defaults['maxSkillSlots'] as num?)?.toInt() ?? 3,
      flags: const [],
      activeQuestIds: const [],
      completedQuestIds: const [],
      inventoryItemIds: const [],
      equippedItemIds: const [],
      unlockedSkillIds: const [],
      unlockedShopIds: const [],
      unlockedQuestIds: const [],
      unlockedEnemyIds: const [],
      diceSkillAssignments: const {},
      raceId: '',
      professionId: '',
    );
    await _persist();
  }

  /// Starts a fresh game as the given race/profession, combining the base
  /// New Game Defaults with each preset's stat bonuses. [race] and
  /// [profession] are the raw records from the Races/Professions db.
  Future<void> startNewGame({
    required String raceId,
    required Map<String, dynamic> race,
    required String professionId,
    required Map<String, dynamic> profession,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> defaults;
    final savedConfig = prefs.getString(_newGameDefaultsPrefsKey);
    if (savedConfig != null) {
      defaults = json.decode(savedConfig) as Map<String, dynamic>;
    } else {
      final raw = await rootBundle.loadString(_newGameDefaultsAssetPath);
      defaults = json.decode(raw) as Map<String, dynamic>;
    }

    int bonus(Map<String, dynamic> preset, String key) => (preset[key] as num?)?.toInt() ?? 0;

    final maxHealth = ((defaults['maxHealth'] as num?)?.toInt() ?? 100) +
        bonus(race, 'bonusMaxHealth') +
        bonus(profession, 'bonusMaxHealth');
    final baseDamage = ((defaults['baseDamage'] as num?)?.toInt() ?? 10) +
        bonus(race, 'bonusBaseDamage') +
        bonus(profession, 'bonusBaseDamage');
    final baseArmor = ((defaults['baseArmor'] as num?)?.toInt() ?? 0) +
        bonus(race, 'bonusBaseArmor') +
        bonus(profession, 'bonusBaseArmor');
    final gold = ((defaults['gold'] as num?)?.toInt() ?? 0) +
        bonus(race, 'startingGoldBonus') +
        bonus(profession, 'startingGoldBonus');
    final skillPoints = bonus(profession, 'startingSkillPoints');

    state = PlayerSession(
      level: (defaults['playerLevel'] as num?)?.toInt() ?? 1,
      currentXP: 0,
      gold: gold,
      alignmentScore: 0,
      maxHealth: maxHealth,
      currentHealth: maxHealth,
      baseDamage: baseDamage,
      baseArmor: baseArmor,
      potionCount: (defaults['potionCount'] as num?)?.toInt() ?? 0,
      statPoints: 0,
      skillPoints: skillPoints,
      maxSkillSlots: (defaults['maxSkillSlots'] as num?)?.toInt() ?? 3,
      flags: const [],
      activeQuestIds: const [],
      completedQuestIds: const [],
      inventoryItemIds: const [],
      equippedItemIds: const [],
      unlockedSkillIds: const [],
      unlockedShopIds: const [],
      unlockedQuestIds: const [],
      unlockedEnemyIds: const [],
      diceSkillAssignments: const {},
      raceId: raceId,
      professionId: professionId,
    );
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerSessionPrefsKey, json.encode(state.toJson()));
  }

  Future<void> resetSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetToDefaults(prefs);
  }

  Future<void> applyChoiceEffects({
    int goldMod = 0,
    int alignmentMod = 0,
    List<String> flagsToAdd = const [],
    String? questIDToProgress,
  }) async {
    final newFlags = <String>{...state.flags, ...flagsToAdd}.toList();
    var newActiveQuests = state.activeQuestIds;
    if (questIDToProgress != null &&
        questIDToProgress.isNotEmpty &&
        !state.activeQuestIds.contains(questIDToProgress) &&
        !state.completedQuestIds.contains(questIDToProgress)) {
      newActiveQuests = [...state.activeQuestIds, questIDToProgress];
    }
    final newGoldRaw = state.gold + goldMod;
    state = state.copyWith(
      gold: newGoldRaw < 0 ? 0 : newGoldRaw,
      alignmentScore: state.alignmentScore + alignmentMod,
      flags: newFlags,
      activeQuestIds: newActiveQuests,
    );
    await _persist();
  }

  Future<void> acceptQuest(String questId) async {
    if (state.activeQuestIds.contains(questId) || state.completedQuestIds.contains(questId)) {
      return;
    }
    state = state.copyWith(activeQuestIds: [...state.activeQuestIds, questId]);
    await _persist();
  }

  Future<void> completeQuest(
    String questId, {
    int rewardGold = 0,
    String? rewardItemId,
    String? nextQuestId,
  }) async {
    final newActive = state.activeQuestIds.where((id) => id != questId).toList();
    final newCompleted = <String>{...state.completedQuestIds, questId}.toList();
    final newInventory = [...state.inventoryItemIds];
    if (rewardItemId != null && rewardItemId.isNotEmpty) {
      newInventory.add(rewardItemId);
    }
    var newUnlockedQuests = state.unlockedQuestIds;
    if (nextQuestId != null &&
        nextQuestId.isNotEmpty &&
        !newUnlockedQuests.contains(nextQuestId)) {
      newUnlockedQuests = [...newUnlockedQuests, nextQuestId];
    }
    state = state.copyWith(
      gold: state.gold + rewardGold,
      activeQuestIds: newActive,
      completedQuestIds: newCompleted,
      inventoryItemIds: newInventory,
      unlockedQuestIds: newUnlockedQuests,
    );
    await _persist();
  }

  Future<void> buyItem(String itemId, int cost) async {
    if (state.gold < cost) return;
    state = state.copyWith(
      gold: state.gold - cost,
      inventoryItemIds: [...state.inventoryItemIds, itemId],
    );
    await _persist();
  }

  /// Equips [itemId]. When [slot] is given, any other equipped item sharing
  /// that slot (per [items], a map of itemId -> item record) is unequipped
  /// first, so only one item per slot is ever equipped at once.
  Future<void> equipItem(
    String itemId, {
    String? slot,
    Map<String, dynamic>? items,
  }) async {
    if (state.equippedItemIds.contains(itemId)) return;
    var newEquipped = state.equippedItemIds;
    if (slot != null && slot.isNotEmpty && items != null) {
      newEquipped = state.equippedItemIds.where((id) {
        final other = items[id] as Map<String, dynamic>?;
        return (other?['equipSlot']?.toString() ?? '') != slot;
      }).toList();
    }
    state = state.copyWith(equippedItemIds: [...newEquipped, itemId]);
    await _persist();
  }

  Future<void> unequipItem(String itemId) async {
    if (!state.equippedItemIds.contains(itemId)) return;
    state = state.copyWith(
      equippedItemIds: state.equippedItemIds.where((id) => id != itemId).toList(),
    );
    await _persist();
  }

  /// Marks a shop/quest/enemy as discovered through story progression, so it
  /// becomes accessible in the Play tab. Empty/null ids are ignored.
  Future<void> unlockContent({String? shopId, String? questId, String? enemyId}) async {
    var newShops = state.unlockedShopIds;
    var newQuests = state.unlockedQuestIds;
    var newEnemies = state.unlockedEnemyIds;
    if (shopId != null && shopId.isNotEmpty && !newShops.contains(shopId)) {
      newShops = [...newShops, shopId];
    }
    if (questId != null && questId.isNotEmpty && !newQuests.contains(questId)) {
      newQuests = [...newQuests, questId];
    }
    if (enemyId != null && enemyId.isNotEmpty && !newEnemies.contains(enemyId)) {
      newEnemies = [...newEnemies, enemyId];
    }
    if (identical(newShops, state.unlockedShopIds) &&
        identical(newQuests, state.unlockedQuestIds) &&
        identical(newEnemies, state.unlockedEnemyIds)) {
      return;
    }
    state = state.copyWith(
      unlockedShopIds: newShops,
      unlockedQuestIds: newQuests,
      unlockedEnemyIds: newEnemies,
    );
    await _persist();
  }

  Future<void> assignSkillToDiceFace(String diceId, int faceIndex, String skillId) async {
    final updated = <String, Map<String, String>>{
      for (final entry in state.diceSkillAssignments.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
    final faceMap = Map<String, String>.from(updated[diceId] ?? const {});
    faceMap[faceIndex.toString()] = skillId;
    updated[diceId] = faceMap;
    state = state.copyWith(diceSkillAssignments: updated);
    await _persist();
  }

  Future<void> clearDiceFaceSkill(String diceId, int faceIndex) async {
    final faceMap = state.diceSkillAssignments[diceId];
    if (faceMap == null || !faceMap.containsKey(faceIndex.toString())) return;
    final updated = <String, Map<String, String>>{
      for (final entry in state.diceSkillAssignments.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
    updated[diceId]!.remove(faceIndex.toString());
    state = state.copyWith(diceSkillAssignments: updated);
    await _persist();
  }

  Future<void> unlockSkill(String skillId) async {
    if (state.skillPoints <= 0 || state.unlockedSkillIds.contains(skillId)) return;
    state = state.copyWith(
      skillPoints: state.skillPoints - 1,
      unlockedSkillIds: [...state.unlockedSkillIds, skillId],
    );
    await _persist();
  }

  Future<void> spendStatPoint({required String stat}) async {
    if (state.statPoints <= 0) return;
    var newBaseDamage = state.baseDamage;
    var newBaseArmor = state.baseArmor;
    var newMaxHealth = state.maxHealth;
    var newCurrentHealth = state.currentHealth;
    switch (stat) {
      case 'damage':
        newBaseDamage += 1;
        break;
      case 'armor':
        newBaseArmor += 1;
        break;
      case 'health':
        newMaxHealth += 10;
        newCurrentHealth += 10;
        break;
      default:
        break;
    }
    state = state.copyWith(
      statPoints: state.statPoints - 1,
      baseDamage: newBaseDamage,
      baseArmor: newBaseArmor,
      maxHealth: newMaxHealth,
      currentHealth: newCurrentHealth,
    );
    await _persist();
  }

  Future<void> consumePotion() async {
    if (state.potionCount <= 0) return;
    state = state.copyWith(potionCount: state.potionCount - 1);
    await _persist();
  }

  Future<void> applyCombatResult({
    required int hpAfter,
    int goldGain = 0,
    int xpGain = 0,
    List<String> itemsGained = const [],
  }) async {
    var newLevel = state.level;
    var newXp = state.currentXP + xpGain;
    var newMaxHealth = state.maxHealth;
    var newStatPoints = state.statPoints;
    var newSkillPoints = state.skillPoints;
    var leveledUp = false;

    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel += 1;
      newStatPoints += 5;
      newSkillPoints += 1;
      newMaxHealth += 20;
      leveledUp = true;
    }

    final clampedHp = hpAfter < 0
        ? 0
        : (hpAfter > newMaxHealth ? newMaxHealth : hpAfter);
    final newHealth = leveledUp ? newMaxHealth : clampedHp;

    state = state.copyWith(
      level: newLevel,
      currentXP: newXp,
      maxHealth: newMaxHealth,
      currentHealth: newHealth,
      statPoints: newStatPoints,
      skillPoints: newSkillPoints,
      gold: state.gold + goldGain,
      inventoryItemIds: [...state.inventoryItemIds, ...itemsGained],
    );
    await _persist();
  }
}

final playerSessionProvider =
    StateNotifierProvider<PlayerSessionNotifier, PlayerSession>((ref) {
  return PlayerSessionNotifier();
});

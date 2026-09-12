import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _playerSessionPrefsKey = 'player_session';
const String _newGameDefaultsAssetPath = 'assets/gamedata/game_config.json';
const String _newGameDefaultsPrefsKey = 'gamedb_game_config';

/// The starter die's face indexes reserved for the player's profession and
/// race standard skills (see assets/gamedata/dice.json's starter_die).
const String _starterDiceId = 'starter_die';
const int _starterDieProfessionFaceIndex = 4;
const int _starterDieRaceFaceIndex = 5;

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
    required this.ownedDiceIds,
    required this.equippedDiceId,
    this.xpEarnedThisRun = 0,
    this.shopPurchaseCounts = const {},
    this.characterName = '',
    this.shopUnlockNodeIds = const {},
    this.seenShopIds = const [],
    this.seenQuestIds = const [],
    this.seenEnemyIds = const [],
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

  /// Dice are equipment: dice the player owns (found, bought or granted),
  /// and which one is currently equipped for combat.
  final List<String> ownedDiceIds;
  final String? equippedDiceId;

  /// XP gained since the last new game / permadeath reset — a recap metric
  /// only, not a gameplay stat; doesn't affect level or anything else.
  final int xpEarnedThisRun;

  /// How many units of each item a shop has sold so far, keyed by
  /// "shopID::itemID". Shops have a fixed stock (see [DbSchema] shops'
  /// stockQuantities field) that doesn't replenish, so this persists across
  /// sessions and survives permadeath (losing an item doesn't restock it).
  final Map<String, int> shopPurchaseCounts;

  /// The player-chosen name for this character, set once during creation
  /// (see RaceProfessionScreen's lock-in dialog) and fixed for the rest of
  /// the run.
  final String characterName;

  /// shopId -> the story node whose choice unlocked it. A shop is only
  /// browsable in the Play tab while the player is currently on that node;
  /// leaving it hides the shop again (it reappears if the player returns).
  /// Unlike [unlockedShopIds], entries here are never removed, so
  /// historical stats (e.g. the playthrough simulator) still see every shop
  /// ever discovered.
  final Map<String, String> shopUnlockNodeIds;

  /// Ids the player has already viewed in the Play tab, used to compute the
  /// "newly unlocked" badge counts shown on the Quests/Shops/Bestiary
  /// section headers.
  final List<String> seenShopIds;
  final List<String> seenQuestIds;
  final List<String> seenEnemyIds;

  int get xpToNextLevel => level * 100;

  String get alignmentLabel {
    if (alignmentScore >= 20) return 'Good';
    if (alignmentScore <= -20) return 'Evil';
    return 'Neutral';
  }

  bool meetsRequirements({
    int reqGold = 0,
    int? reqAlignmentScore,
    int? reqAlignmentMax,
    List<String> reqFlags = const [],
  }) {
    if (gold < reqGold) return false;
    if (reqAlignmentScore != null && alignmentScore < reqAlignmentScore) return false;
    if (reqAlignmentMax != null && alignmentScore > reqAlignmentMax) return false;
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
    List<String>? ownedDiceIds,
    String? equippedDiceId,
    int? xpEarnedThisRun,
    Map<String, int>? shopPurchaseCounts,
    String? characterName,
    Map<String, String>? shopUnlockNodeIds,
    List<String>? seenShopIds,
    List<String>? seenQuestIds,
    List<String>? seenEnemyIds,
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
      ownedDiceIds: ownedDiceIds ?? this.ownedDiceIds,
      equippedDiceId: equippedDiceId ?? this.equippedDiceId,
      xpEarnedThisRun: xpEarnedThisRun ?? this.xpEarnedThisRun,
      shopPurchaseCounts: shopPurchaseCounts ?? this.shopPurchaseCounts,
      characterName: characterName ?? this.characterName,
      shopUnlockNodeIds: shopUnlockNodeIds ?? this.shopUnlockNodeIds,
      seenShopIds: seenShopIds ?? this.seenShopIds,
      seenQuestIds: seenQuestIds ?? this.seenQuestIds,
      seenEnemyIds: seenEnemyIds ?? this.seenEnemyIds,
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
        'ownedDiceIds': ownedDiceIds,
        'equippedDiceId': equippedDiceId,
        'xpEarnedThisRun': xpEarnedThisRun,
        'shopPurchaseCounts': shopPurchaseCounts,
        'characterName': characterName,
        'shopUnlockNodeIds': shopUnlockNodeIds,
        'seenShopIds': seenShopIds,
        'seenQuestIds': seenQuestIds,
        'seenEnemyIds': seenEnemyIds,
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
      ownedDiceIds:
          (json['ownedDiceIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      equippedDiceId: json['equippedDiceId'] as String?,
      xpEarnedThisRun: (json['xpEarnedThisRun'] as num?)?.toInt() ?? 0,
      shopPurchaseCounts: (json['shopPurchaseCounts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          const {},
      characterName: json['characterName'] as String? ?? '',
      shopUnlockNodeIds: (json['shopUnlockNodeIds'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const {},
      seenShopIds: (json['seenShopIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      seenQuestIds:
          (json['seenQuestIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      seenEnemyIds:
          (json['seenEnemyIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
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
          ownedDiceIds: [],
          equippedDiceId: null,
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
      ownedDiceIds: const [],
      equippedDiceId: null,
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

    final professionSkillId = profession['standardSkillID']?.toString() ?? '';
    final raceSkillId = race['standardSkillID']?.toString() ?? '';
    final starterAssignments = <String, String>{
      if (professionSkillId.isNotEmpty)
        _starterDieProfessionFaceIndex.toString(): professionSkillId,
      if (raceSkillId.isNotEmpty) _starterDieRaceFaceIndex.toString(): raceSkillId,
    };
    // Race/profession signature skills default to isUnlocked: false in the
    // skills db (most skills are locked until earned) but are wired
    // directly into the starter die's Heritage/Profession Technique faces
    // from the moment a character exists — so they need to be unlocked
    // here too, or those faces would just fizzle on the very first roll.
    final starterUnlockedSkills = <String>[
      if (professionSkillId.isNotEmpty) professionSkillId,
      if (raceSkillId.isNotEmpty) raceSkillId,
    ];

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
      unlockedSkillIds: starterUnlockedSkills,
      unlockedShopIds: const [],
      unlockedQuestIds: const [],
      unlockedEnemyIds: const [],
      diceSkillAssignments: {
        if (starterAssignments.isNotEmpty) _starterDiceId: starterAssignments,
      },
      raceId: raceId,
      professionId: professionId,
      ownedDiceIds: const [_starterDiceId],
      equippedDiceId: _starterDiceId,
    );
    await _persist();
  }

  /// Sets the character's name — called once from the lock-in dialog right
  /// after character creation (see RaceProfessionScreen), before the
  /// origin-story prompts run.
  Future<void> setCharacterName(String name) async {
    state = state.copyWith(characterName: name.trim());
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

  /// Directly replaces the live session with [session] — used to restore a
  /// manually saved checkpoint (see save_game_provider.dart). Persists
  /// immediately like every other mutator here.
  Future<void> loadSession(PlayerSession session) async {
    state = session;
    await _persist();
  }

  Future<void> applyChoiceEffects({
    int goldMod = 0,
    int alignmentMod = 0,
    int healAmount = 0,
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
    final newHealthRaw = state.currentHealth + healAmount;
    state = state.copyWith(
      gold: newGoldRaw < 0 ? 0 : newGoldRaw,
      alignmentScore: state.alignmentScore + alignmentMod,
      currentHealth: newHealthRaw > state.maxHealth ? state.maxHealth : newHealthRaw,
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
    String? rewardDiceId,
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
    var newOwnedDice = state.ownedDiceIds;
    if (rewardDiceId != null &&
        rewardDiceId.isNotEmpty &&
        !newOwnedDice.contains(rewardDiceId)) {
      newOwnedDice = [...newOwnedDice, rewardDiceId];
    }
    state = state.copyWith(
      gold: state.gold + rewardGold,
      activeQuestIds: newActive,
      completedQuestIds: newCompleted,
      inventoryItemIds: newInventory,
      unlockedQuestIds: newUnlockedQuests,
      ownedDiceIds: newOwnedDice,
    );
    await _persist();
  }

  Future<void> buyDice(String diceId, int cost) async {
    if (state.gold < cost || state.ownedDiceIds.contains(diceId)) return;
    state = state.copyWith(
      gold: state.gold - cost,
      ownedDiceIds: [...state.ownedDiceIds, diceId],
    );
    await _persist();
  }

  Future<void> equipDice(String diceId) async {
    if (!state.ownedDiceIds.contains(diceId) || state.equippedDiceId == diceId) return;
    state = state.copyWith(equippedDiceId: diceId);
    await _persist();
  }

  /// Buys [itemId] from [shopId]. Shops have a fixed stock per item
  /// ([stockLimit], from the shop's stockQuantities data) that this tracks
  /// via [PlayerSession.shopPurchaseCounts] and never replenishes.
  Future<void> buyItem(String shopId, String itemId, int cost, int stockLimit) async {
    final key = '$shopId::$itemId';
    final purchased = state.shopPurchaseCounts[key] ?? 0;
    if (state.gold < cost || purchased >= stockLimit) return;
    state = state.copyWith(
      gold: state.gold - cost,
      inventoryItemIds: [...state.inventoryItemIds, itemId],
      shopPurchaseCounts: {...state.shopPurchaseCounts, key: purchased + 1},
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
  ///
  /// [shopUnlockNodeId] records which story node's choice unlocked the shop
  /// (usually the node the player is leaving when the choice fires) — shops
  /// are only browsable while the player is currently on that node.
  Future<void> unlockContent({
    String? shopId,
    String? questId,
    String? enemyId,
    String? shopUnlockNodeId,
  }) async {
    var newShops = state.unlockedShopIds;
    var newQuests = state.unlockedQuestIds;
    var newEnemies = state.unlockedEnemyIds;
    var newShopUnlockNodeIds = state.shopUnlockNodeIds;
    var newSeenShopIds = state.seenShopIds;
    var newSeenQuestIds = state.seenQuestIds;
    var newSeenEnemyIds = state.seenEnemyIds;
    if (shopId != null && shopId.isNotEmpty) {
      if (!newShops.contains(shopId)) {
        newShops = [...newShops, shopId];
      }
      if (shopUnlockNodeId != null && shopUnlockNodeId.isNotEmpty) {
        newShopUnlockNodeIds = {...newShopUnlockNodeIds, shopId: shopUnlockNodeId};
      }
      if (newSeenShopIds.contains(shopId)) {
        newSeenShopIds = newSeenShopIds.where((id) => id != shopId).toList();
      }
    }
    if (questId != null && questId.isNotEmpty) {
      if (!newQuests.contains(questId)) {
        newQuests = [...newQuests, questId];
      }
      if (newSeenQuestIds.contains(questId)) {
        newSeenQuestIds = newSeenQuestIds.where((id) => id != questId).toList();
      }
    }
    if (enemyId != null && enemyId.isNotEmpty) {
      if (!newEnemies.contains(enemyId)) {
        newEnemies = [...newEnemies, enemyId];
      }
      if (newSeenEnemyIds.contains(enemyId)) {
        newSeenEnemyIds = newSeenEnemyIds.where((id) => id != enemyId).toList();
      }
    }
    if (identical(newShops, state.unlockedShopIds) &&
        identical(newQuests, state.unlockedQuestIds) &&
        identical(newEnemies, state.unlockedEnemyIds) &&
        identical(newShopUnlockNodeIds, state.shopUnlockNodeIds) &&
        identical(newSeenShopIds, state.seenShopIds) &&
        identical(newSeenQuestIds, state.seenQuestIds) &&
        identical(newSeenEnemyIds, state.seenEnemyIds)) {
      return;
    }
    state = state.copyWith(
      unlockedShopIds: newShops,
      unlockedQuestIds: newQuests,
      unlockedEnemyIds: newEnemies,
      shopUnlockNodeIds: newShopUnlockNodeIds,
      seenShopIds: newSeenShopIds,
      seenQuestIds: newSeenQuestIds,
      seenEnemyIds: newSeenEnemyIds,
    );
    await _persist();
  }

  /// Marks a shop/quest/enemy id as viewed in the Play tab, clearing its
  /// "newly unlocked" badge contribution.
  Future<void> markSeen({String? shopId, String? questId, String? enemyId}) async {
    var newSeenShopIds = state.seenShopIds;
    var newSeenQuestIds = state.seenQuestIds;
    var newSeenEnemyIds = state.seenEnemyIds;
    if (shopId != null && shopId.isNotEmpty && !newSeenShopIds.contains(shopId)) {
      newSeenShopIds = [...newSeenShopIds, shopId];
    }
    if (questId != null && questId.isNotEmpty && !newSeenQuestIds.contains(questId)) {
      newSeenQuestIds = [...newSeenQuestIds, questId];
    }
    if (enemyId != null && enemyId.isNotEmpty && !newSeenEnemyIds.contains(enemyId)) {
      newSeenEnemyIds = [...newSeenEnemyIds, enemyId];
    }
    if (identical(newSeenShopIds, state.seenShopIds) &&
        identical(newSeenQuestIds, state.seenQuestIds) &&
        identical(newSeenEnemyIds, state.seenEnemyIds)) {
      return;
    }
    state = state.copyWith(
      seenShopIds: newSeenShopIds,
      seenQuestIds: newSeenQuestIds,
      seenEnemyIds: newSeenEnemyIds,
    );
    await _persist();
  }

  /// Marks every currently-unlocked shop/quest/enemy id as seen at once —
  /// used when a Play-tab section is expanded, clearing its whole badge.
  Future<void> markAllSeenInCategory({bool shops = false, bool quests = false, bool enemies = false}) async {
    state = state.copyWith(
      seenShopIds: shops ? state.unlockedShopIds : state.seenShopIds,
      seenQuestIds: quests ? state.unlockedQuestIds : state.seenQuestIds,
      seenEnemyIds: enemies ? state.unlockedEnemyIds : state.seenEnemyIds,
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

  /// Directly overwrites any subset of the player's stats — bypassing all
  /// normal game rules (gold/level requirements, max-health clamping,
  /// etc). Only intended for the Edit-mode stat editor, so QA/authoring
  /// can jump straight to a specific game state to test a node or fight
  /// without replaying to reach it.
  Future<void> debugSetStats({
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
  }) async {
    state = state.copyWith(
      level: level,
      currentXP: currentXP,
      gold: gold,
      alignmentScore: alignmentScore,
      maxHealth: maxHealth,
      currentHealth: currentHealth,
      baseDamage: baseDamage,
      baseArmor: baseArmor,
      potionCount: potionCount,
      statPoints: statPoints,
      skillPoints: skillPoints,
    );
    await _persist();
  }

  Future<void> consumePotion() async {
    if (state.potionCount <= 0) return;
    state = state.copyWith(potionCount: state.potionCount - 1);
    await _persist();
  }

  /// Applies a fight's outcome to the player's stats. Returns true if the
  /// XP gain pushed the player up one or more levels, so the caller can
  /// show a level-up celebration.
  Future<bool> applyCombatResult({
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
      xpEarnedThisRun: state.xpEarnedThisRun + xpGain,
    );
    await _persist();
    return leveledUp;
  }

  /// Permadeath: clears the player's inventory and equipped items but keeps
  /// level, XP, gold, stats, skills, dice and story flags/quests intact.
  /// Returns a summary of the run for a death-screen recap.
  Future<PermadeathResult> applyPermadeath() async {
    final result = PermadeathResult(
      lostItemIds: [...state.inventoryItemIds],
      xpEarnedThisRun: state.xpEarnedThisRun,
    );
    state = state.copyWith(
      currentHealth: state.maxHealth,
      inventoryItemIds: const [],
      equippedItemIds: const [],
      xpEarnedThisRun: 0,
    );
    await _persist();
    return result;
  }
}

/// Summary of a run that ended in permadeath, for the death screen.
class PermadeathResult {
  const PermadeathResult({required this.lostItemIds, required this.xpEarnedThisRun});

  final List<String> lostItemIds;
  final int xpEarnedThisRun;
}

final playerSessionProvider =
    StateNotifierProvider<PlayerSessionNotifier, PlayerSession>((ref) {
  return PlayerSessionNotifier();
});

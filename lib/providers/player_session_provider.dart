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
    required this.gold,
    required this.alignmentScore,
    required this.flags,
    required this.activeQuestIds,
    required this.completedQuestIds,
    required this.inventoryItemIds,
  });

  final int level;
  final int gold;
  final int alignmentScore;
  final List<String> flags;
  final List<String> activeQuestIds;
  final List<String> completedQuestIds;
  final List<String> inventoryItemIds;

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
    int? gold,
    int? alignmentScore,
    List<String>? flags,
    List<String>? activeQuestIds,
    List<String>? completedQuestIds,
    List<String>? inventoryItemIds,
  }) {
    return PlayerSession(
      level: level ?? this.level,
      gold: gold ?? this.gold,
      alignmentScore: alignmentScore ?? this.alignmentScore,
      flags: flags ?? this.flags,
      activeQuestIds: activeQuestIds ?? this.activeQuestIds,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'gold': gold,
        'alignmentScore': alignmentScore,
        'flags': flags,
        'activeQuestIds': activeQuestIds,
        'completedQuestIds': completedQuestIds,
        'inventoryItemIds': inventoryItemIds,
      };

  factory PlayerSession.fromJson(Map<String, dynamic> json) {
    return PlayerSession(
      level: (json['level'] as num?)?.toInt() ?? 1,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      alignmentScore: (json['alignmentScore'] as num?)?.toInt() ?? 0,
      flags: (json['flags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      activeQuestIds:
          (json['activeQuestIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      completedQuestIds:
          (json['completedQuestIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      inventoryItemIds:
          (json['inventoryItemIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class PlayerSessionNotifier extends StateNotifier<PlayerSession> {
  PlayerSessionNotifier()
      : super(const PlayerSession(
          level: 1,
          gold: 0,
          alignmentScore: 0,
          flags: [],
          activeQuestIds: [],
          completedQuestIds: [],
          inventoryItemIds: [],
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
    state = PlayerSession(
      level: (defaults['playerLevel'] as num?)?.toInt() ?? 1,
      gold: (defaults['gold'] as num?)?.toInt() ?? 0,
      alignmentScore: 0,
      flags: const [],
      activeQuestIds: const [],
      completedQuestIds: const [],
      inventoryItemIds: const [],
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
  }) async {
    final newActive = state.activeQuestIds.where((id) => id != questId).toList();
    final newCompleted = <String>{...state.completedQuestIds, questId}.toList();
    final newInventory = [...state.inventoryItemIds];
    if (rewardItemId != null && rewardItemId.isNotEmpty) {
      newInventory.add(rewardItemId);
    }
    state = state.copyWith(
      gold: state.gold + rewardGold,
      activeQuestIds: newActive,
      completedQuestIds: newCompleted,
      inventoryItemIds: newInventory,
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
}

final playerSessionProvider =
    StateNotifierProvider<PlayerSessionNotifier, PlayerSession>((ref) {
  return PlayerSessionNotifier();
});

import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/story_repository.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

/// True when there is a story to continue: a character made, or a step
/// taken past the first scene.
bool hasGameInProgress(PlayerSession session, StoryPlayState story) =>
    session.raceId.isNotEmpty ||
    story.history.isNotEmpty ||
    story.currentNodeId != StoryRepository.startNodeId;

/// The manual save slots the Play tab offers.
const int saveSlotCount = 3;

// The single save of earlier versions: read once into slot 1.
const String _legacySessionPrefsKey = 'saved_game_session';
const String _legacyStoryPrefsKey = 'saved_game_story';

String _slotPrefsKey(int slot) => 'saved_game_slot_$slot';

/// What a slot shows before it is loaded: who, how far, and when.
class SaveSlotSummary {
  const SaveSlotSummary({
    required this.slot,
    required this.characterName,
    required this.raceId,
    required this.professionId,
    required this.level,
    required this.cycle,
    required this.nodeId,
    required this.savedAt,
  });

  final int slot;
  final String characterName;
  final String raceId;
  final String professionId;
  final int level;

  /// The New Game+ cycle the save belongs to (0 for a first run).
  final int cycle;
  final String nodeId;

  /// Null for a save carried over from before slots existed.
  final DateTime? savedAt;
}

/// A saved game read back from a slot.
class SavedGame {
  const SavedGame({
    required this.session,
    required this.currentNodeId,
    required this.history,
  });

  final PlayerSession session;
  final String currentNodeId;
  final List<String> history;
}

/// Manual checkpoints the player saves to and loads from at will, on top
/// of the continuous autosave -- [saveSlotCount] slots, each shown with
/// its character, level, cycle, story node and time. The state holds each
/// slot's summary (null when empty). A slot that cannot be read is shown
/// as empty but never deleted, so a later version can still read it.
class SavedGamesNotifier extends StateNotifier<List<SaveSlotSummary?>> {
  SavedGamesNotifier() : super(List.filled(saveSlotCount, null)) {
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacySave(prefs);
    state = [
      for (var slot = 1; slot <= saveSlotCount; slot++)
        _summaryOf(slot, prefs.getString(_slotPrefsKey(slot))),
    ];
  }

  /// Earlier versions kept one save under two keys: it becomes slot 1.
  Future<void> _migrateLegacySave(SharedPreferences prefs) async {
    final session = prefs.getString(_legacySessionPrefsKey);
    final story = prefs.getString(_legacyStoryPrefsKey);
    if (session == null || story == null) return;
    if (prefs.getString(_slotPrefsKey(1)) == null) {
      final storyMap = json.decode(story) as Map<String, dynamic>;
      await prefs.setString(
        _slotPrefsKey(1),
        json.encode({
          'session': json.decode(session),
          'currentNodeId': storyMap['currentNodeId'],
          'history': storyMap['history'] ?? const [],
        }),
      );
    }
    await prefs.remove(_legacySessionPrefsKey);
    await prefs.remove(_legacyStoryPrefsKey);
  }

  static SaveSlotSummary? _summaryOf(int slot, String? raw) {
    if (raw == null) return null;
    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      final session = data['session'] as Map<String, dynamic>;
      final savedAt = data['savedAt']?.toString();
      return SaveSlotSummary(
        slot: slot,
        characterName: session['characterName']?.toString() ?? '',
        raceId: session['raceId']?.toString() ?? '',
        professionId: session['professionId']?.toString() ?? '',
        level: (session['level'] as num?)?.toInt() ?? 1,
        cycle: (session['newGamePlusCycle'] as num?)?.toInt() ?? 0,
        nodeId: data['currentNodeId']?.toString() ?? '',
        savedAt: savedAt == null ? null : DateTime.tryParse(savedAt),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required int slot,
    required PlayerSession session,
    required String currentNodeId,
    required List<String> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _slotPrefsKey(slot),
      json.encode({
        'session': session.toJson(),
        'currentNodeId': currentNodeId,
        'history': history,
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );
    await _refresh();
  }

  /// The game in [slot], or null when the slot is empty or unreadable.
  Future<SavedGame?> load(int slot) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_slotPrefsKey(slot));
    if (raw == null) return null;
    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      return SavedGame(
        session:
            PlayerSession.fromJson(data['session'] as Map<String, dynamic>),
        currentNodeId: data['currentNodeId'] as String,
        history:
            (data['history'] as List?)?.map((e) => e.toString()).toList() ??
                const <String>[],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(int slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_slotPrefsKey(slot));
    await _refresh();
  }

  /// Ironman: a permadeath death takes every checkpoint with it, so
  /// turning permadeath off afterwards brings nothing back.
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (var slot = 1; slot <= saveSlotCount; slot++) {
      await prefs.remove(_slotPrefsKey(slot));
    }
    await prefs.remove(_legacySessionPrefsKey);
    await prefs.remove(_legacyStoryPrefsKey);
    await _refresh();
  }
}

final savedGamesProvider =
    StateNotifierProvider<SavedGamesNotifier, List<SaveSlotSummary?>>(
        (ref) => SavedGamesNotifier());

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player_session_provider.dart';

const String _savedSessionPrefsKey = 'saved_game_session';
const String _savedStoryPrefsKey = 'saved_game_story';

/// A manual checkpoint the player can save to and load from at will, on top
/// of the continuous auto-persisted live session — e.g. to check-point
/// before a risky choice, or before testing a reset in edit mode. The bool
/// state tracks whether a save currently exists, so the Load action can be
/// disabled until there's something to load.
class SavedGameNotifier extends StateNotifier<bool> {
  SavedGameNotifier() : super(false) {
    _checkExists();
  }

  Future<void> _checkExists() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.containsKey(_savedSessionPrefsKey);
  }

  Future<void> save({
    required PlayerSession session,
    required String currentNodeId,
    required List<String> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedSessionPrefsKey, json.encode(session.toJson()));
    await prefs.setString(
      _savedStoryPrefsKey,
      json.encode({'currentNodeId': currentNodeId, 'history': history}),
    );
    state = true;
  }

  /// Returns the saved session and story position, or null if there's no
  /// save yet.
  Future<(PlayerSession, String, List<String>)?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_savedSessionPrefsKey);
    final storyJson = prefs.getString(_savedStoryPrefsKey);
    if (sessionJson == null || storyJson == null) return null;
    final session = PlayerSession.fromJson(
        json.decode(sessionJson) as Map<String, dynamic>);
    final storyMap = json.decode(storyJson) as Map<String, dynamic>;
    final currentNodeId = storyMap['currentNodeId'] as String;
    final history =
        (storyMap['history'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    return (session, currentNodeId, history);
  }
}

final savedGameExistsProvider = StateNotifierProvider<SavedGameNotifier, bool>(
    (ref) => SavedGameNotifier());

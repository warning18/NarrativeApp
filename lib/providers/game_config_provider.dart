import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _gameConfigAssetPath = 'assets/gamedata/game_config.json';

/// Mirrors player_session_provider.dart's own private
/// `_newGameDefaultsPrefsKey` — kept in sync manually since that constant
/// isn't exported. Whichever source `startNewGame` would currently draw
/// from (an edit-mode override saved here, else the bundled asset) is what
/// this provider returns too, so a recruited ally's derived base stats
/// (see [deriveAllyBaseStats]) reflect the same defaults a brand new player
/// character would get right now.
const String _gameConfigPrefsKey = 'gamedb_game_config';

/// The New Game Defaults singleton (assets/gamedata/game_config.json) — a
/// flat stat-defaults object, not a keyed collection, so unlike every other
/// data table it doesn't fit the `gameDbProvider`/`DbSchema` pattern. Read
/// access only.
final gameConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_gameConfigPrefsKey);
  if (saved != null) {
    return json.decode(saved) as Map<String, dynamic>;
  }
  final raw = await rootBundle.loadString(_gameConfigAssetPath);
  return json.decode(raw) as Map<String, dynamic>;
});

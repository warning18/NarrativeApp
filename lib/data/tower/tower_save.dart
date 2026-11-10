// The Tower's own save (v1.845, docs/proposals/tower-mechanics.md §8): two
// keys of its own, apart from the story's saved_game_slot_N. Deleting the
// story saves never touches them, and nothing here touches the story's.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'tower_progress.dart';
import 'tower_run.dart';

/// The run in progress (a TowerRun's JSON), absent when there is none.
const String towerRunPrefsKey = 'tower_run_v1';

/// The marks, unlocks and counts (a TowerProgress's JSON).
const String towerMarksPrefsKey = 'tower_marks_v1';

/// Reads and writes the Tower's two keys.
class TowerSave {
  const TowerSave(this.prefs);

  final SharedPreferences prefs;

  static Future<TowerSave> open() async =>
      TowerSave(await SharedPreferences.getInstance());

  /// The run in progress, or null (none, or a save that can't be read).
  TowerRun? loadRun() {
    final raw = prefs.getString(towerRunPrefsKey);
    if (raw == null) return null;
    try {
      return TowerRun.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Saves [run]; an ended run clears the key (bank its marks first, see
  /// [endRun]).
  Future<void> saveRun(TowerRun run) => run.isOver
      ? prefs.remove(towerRunPrefsKey)
      : prefs.setString(towerRunPrefsKey, jsonEncode(run.toJson()));

  TowerProgress loadProgress() {
    final raw = prefs.getString(towerMarksPrefsKey);
    if (raw == null) return const TowerProgress();
    try {
      return TowerProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TowerProgress();
    }
  }

  Future<void> saveProgress(TowerProgress progress) =>
      prefs.setString(towerMarksPrefsKey, jsonEncode(progress.toJson()));

  /// An ended [run]: its marks banked, then the run cleared. Returns the
  /// record with them.
  Future<TowerProgress> endRun(TowerRun run) async {
    final progress = loadProgress().afterRun(run);
    await saveProgress(progress);
    await prefs.remove(towerRunPrefsKey);
    return progress;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tremblePrefsKey = 'combat_tremble_enabled';

class TrembleNotifier extends StateNotifier<bool> {
  TrembleNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_tremblePrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tremblePrefsKey, enabled);
  }
}

/// Whether the screen should briefly shake when the player takes damage
/// in combat. Defaults to on; persisted via [SharedPreferences].
final trembleEnabledProvider =
    StateNotifierProvider<TrembleNotifier, bool>((ref) => TrembleNotifier());

const String _chestAutoOpenPrefsKey = 'combat_chest_auto_open';

class ChestAutoOpenNotifier extends StateNotifier<bool> {
  ChestAutoOpenNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_chestAutoOpenPrefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chestAutoOpenPrefsKey, enabled);
  }
}

/// Whether the post-fight spoils chest opens itself with every slot
/// already revealed, instead of waiting for the player's tap. Defaults to
/// off (the tap is the point); persisted via [SharedPreferences].
final chestAutoOpenProvider =
    StateNotifierProvider<ChestAutoOpenNotifier, bool>(
        (ref) => ChestAutoOpenNotifier());

const String _alignmentHuntersPrefsKey = 'alignment_hunters_enabled';

class AlignmentHuntersNotifier extends StateNotifier<bool> {
  AlignmentHuntersNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_alignmentHuntersPrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alignmentHuntersPrefsKey, enabled);
  }
}

/// Whether alignment has consequences on the road: angels hunting an
/// Evil character, demons hunting a Good one, and temptations courting a
/// Neutral one (see alignment_events.dart). Defaults to on; persisted via
/// [SharedPreferences].
final alignmentHuntersEnabledProvider =
    StateNotifierProvider<AlignmentHuntersNotifier, bool>(
        (ref) => AlignmentHuntersNotifier());

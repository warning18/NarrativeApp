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

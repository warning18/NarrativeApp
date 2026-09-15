import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _permadeathPrefsKey = 'permadeath_enabled';

class PermadeathNotifier extends StateNotifier<bool> {
  PermadeathNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_permadeathPrefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permadeathPrefsKey, enabled);
  }
}

/// Whether losing a fight resets the player to the start of the story
/// (keeping level/stats/skills, losing items). Off by default; persisted
/// via [SharedPreferences].
final permadeathEnabledProvider =
    StateNotifierProvider<PermadeathNotifier, bool>(
        (ref) => PermadeathNotifier());

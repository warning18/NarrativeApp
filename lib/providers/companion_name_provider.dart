import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _companionNamePrefsKey = 'companion_name';

class CompanionNameNotifier extends StateNotifier<String> {
  CompanionNameNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_companionNamePrefsKey) ?? '';
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    state = trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_companionNamePrefsKey);
    } else {
      await prefs.setString(_companionNamePrefsKey, trimmed);
    }
  }
}

/// The player-chosen name for their walking companion. Empty means unnamed
/// (generic "your companion" phrasing is used instead). Persisted via
/// [SharedPreferences].
final companionNameProvider =
    StateNotifierProvider<CompanionNameNotifier, String>((ref) => CompanionNameNotifier());

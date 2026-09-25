import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _walkCompanionPrefsKey = 'walk_companion_enabled';

class WalkCompanionNotifier extends StateNotifier<bool> {
  WalkCompanionNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_walkCompanionPrefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_walkCompanionPrefsKey, enabled);
  }
}

/// Whether the companion dog walks across the story page whenever the
/// story advances to a new node. On by default (it is also the guide of
/// the tutorials); Settings turns it off. Persisted via
/// [SharedPreferences].
final walkCompanionEnabledProvider =
    StateNotifierProvider<WalkCompanionNotifier, bool>(
        (ref) => WalkCompanionNotifier());

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _walkCompanionPrefsKey = 'walk_companion_enabled';

class WalkCompanionNotifier extends StateNotifier<bool> {
  WalkCompanionNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_walkCompanionPrefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_walkCompanionPrefsKey, enabled);
  }
}

/// Whether a small pet silhouette walks across the bottom edge of the
/// screen whenever the story advances to a new node. Off by default
/// (purely cosmetic); persisted via [SharedPreferences].
final walkCompanionEnabledProvider =
    StateNotifierProvider<WalkCompanionNotifier, bool>((ref) => WalkCompanionNotifier());

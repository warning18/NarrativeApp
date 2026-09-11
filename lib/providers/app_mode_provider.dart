import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _appModePrefsKey = 'app_mode';

/// Edit mode is the full authoring app (Story/Play/Map/Generate/Data,
/// node editing, GitHub sync, dev tools). In-Game mode is an enclosed,
/// player-only experience — just Story and Play, with every authoring
/// affordance hidden — for handing the app to someone who should only play
/// it, not edit it.
enum AppMode { edit, inGame }

class AppModeNotifier extends StateNotifier<AppMode> {
  AppModeNotifier() : super(AppMode.edit) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_appModePrefsKey);
    if (saved == AppMode.inGame.name) {
      state = AppMode.inGame;
    }
  }

  Future<void> setMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appModePrefsKey, mode.name);
    state = mode;
  }
}

final appModeProvider = StateNotifierProvider<AppModeNotifier, AppMode>((ref) => AppModeNotifier());

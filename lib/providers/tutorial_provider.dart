import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tutorialEnabledPrefsKey = 'tutorial_enabled';
const String _tutorialSeenPrefsKey = 'tutorial_seen';

class TutorialSettings {
  const TutorialSettings({required this.enabled, required this.seen});

  /// Whether the guided tour should show automatically the first time
  /// In-Game mode is entered. Opt-in in spirit — on by default so new
  /// players see it once, but can be turned off in Settings.
  final bool enabled;

  /// Whether the tour has already been shown (so it doesn't repeat every
  /// time In-Game mode is entered). Reset from Settings to replay it.
  final bool seen;

  TutorialSettings copyWith({bool? enabled, bool? seen}) =>
      TutorialSettings(enabled: enabled ?? this.enabled, seen: seen ?? this.seen);
}

class TutorialNotifier extends StateNotifier<TutorialSettings> {
  TutorialNotifier() : super(const TutorialSettings(enabled: true, seen: false)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = TutorialSettings(
      enabled: prefs.getBool(_tutorialEnabledPrefsKey) ?? true,
      seen: prefs.getBool(_tutorialSeenPrefsKey) ?? false,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialEnabledPrefsKey, enabled);
  }

  Future<void> markSeen() async {
    state = state.copyWith(seen: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenPrefsKey, true);
  }

  /// Clears the seen flag so the guided tour shows again next time (or
  /// immediately, if the caller also opens it) — used by Settings' "Replay
  /// tutorial" action.
  Future<void> reset() async {
    state = state.copyWith(seen: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenPrefsKey, false);
  }
}

final tutorialProvider =
    StateNotifierProvider<TutorialNotifier, TutorialSettings>((ref) => TutorialNotifier());

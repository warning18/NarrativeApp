import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _seenModeNudgePrefsKey = 'seen_mode_nudge';

/// Whether the one-time "you're in Edit Mode" nudge (see [PlayScreen]) has
/// already been dismissed. `AppModeNotifier` defaults every fresh install to
/// [AppMode.edit] — the full authoring app, not just the game — since that's
/// what this project's own day-to-day development relies on; flipping that
/// default would work against the developer's own workflow. This nudge is
/// the safer alternative: point a genuine first-time player at the Settings
/// toggle once, without ever changing the default itself.
class ModeNudgeNotifier extends StateNotifier<bool> {
  ModeNudgeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_seenModeNudgePrefsKey) ?? false;
  }

  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenModeNudgePrefsKey, true);
    state = true;
  }
}

final hasSeenModeNudgeProvider =
    StateNotifierProvider<ModeNudgeNotifier, bool>((ref) => ModeNudgeNotifier());

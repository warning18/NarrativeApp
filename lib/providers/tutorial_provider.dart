import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tutorial/tutorial_topics.dart';

const String _tutorialEnabledPrefsKey = 'tutorial_enabled';
// The single guided tour this replaced: a player who saw it has seen the
// Story tab's tour.
const String _legacySeenPrefsKey = 'tutorial_seen';
const String _seenTopicsPrefsKey = 'tutorial_seen_topics';
const String _voicePrefsKey = 'tutorial_voice';

class TutorialSettings {
  const TutorialSettings({
    required this.enabled,
    required this.seen,
    this.voice = false,
    this.loaded = false,
  });

  /// Whether a feature's tour shows by itself the first time the player
  /// reaches it. On by default; Settings turns it off. Tours can always be
  /// replayed from the Other tab.
  final bool enabled;

  /// The tours already shown, by [TutorialTopic.name].
  final Set<String> seen;

  /// Whether the guide reads its lines aloud.
  final bool voice;

  /// Whether the saved values have been read yet: nothing shows before.
  final bool loaded;

  bool hasSeen(TutorialTopic topic) => seen.contains(topic.name);

  TutorialSettings copyWith(
          {bool? enabled, Set<String>? seen, bool? voice, bool? loaded}) =>
      TutorialSettings(
        enabled: enabled ?? this.enabled,
        seen: seen ?? this.seen,
        voice: voice ?? this.voice,
        loaded: loaded ?? this.loaded,
      );
}

class TutorialNotifier extends StateNotifier<TutorialSettings> {
  TutorialNotifier() : super(const TutorialSettings(enabled: true, seen: {})) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = {...?prefs.getStringList(_seenTopicsPrefsKey)};
    if (prefs.getBool(_legacySeenPrefsKey) ?? false) {
      seen.add(TutorialTopic.story.name);
    }
    state = TutorialSettings(
      enabled: prefs.getBool(_tutorialEnabledPrefsKey) ?? true,
      seen: seen,
      voice: prefs.getBool(_voicePrefsKey) ?? false,
      loaded: true,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialEnabledPrefsKey, enabled);
  }

  Future<void> setVoice(bool voice) async {
    state = state.copyWith(voice: voice);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voicePrefsKey, voice);
  }

  Future<void> markSeen(TutorialTopic topic) async {
    if (state.hasSeen(topic)) return;
    state = state.copyWith(seen: {...state.seen, topic.name});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_seenTopicsPrefsKey, state.seen.toList());
  }

  /// Forgets every tour shown, so each plays again the next time its
  /// feature is reached (Settings' "Replay tutorials").
  Future<void> reset() async {
    state = state.copyWith(seen: {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_seenTopicsPrefsKey, const []);
    await prefs.setBool(_legacySeenPrefsKey, false);
  }
}

final tutorialProvider =
    StateNotifierProvider<TutorialNotifier, TutorialSettings>(
        (ref) => TutorialNotifier());

/// Whether tours start by themselves when a feature is first reached. Off
/// under `flutter test`, where a tour would cover what a test taps; tests
/// of the tours themselves override it.
final tutorialAutoShowProvider = Provider<bool>(
    (ref) => kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'));

/// A tour asked for from the Tutorials list: the screen it belongs to plays
/// it once it is showing, then clears this.
final pendingTourProvider = StateProvider<TutorialTopic?>((ref) => null);

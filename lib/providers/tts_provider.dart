import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_locale.dart';

/// Wraps a single shared [FlutterTts] instance for the story reader's
/// read-aloud button. The bool state tracks whether speech is currently
/// playing, so the UI can show a play/stop toggle.
class TtsNotifier extends StateNotifier<bool> {
  TtsNotifier() : super(false) {
    _tts.setCompletionHandler(() => state = false);
    _tts.setCancelHandler(() => state = false);
    _tts.setErrorHandler((message) => state = false);
  }

  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, AppLanguage language) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage(language == AppLanguage.fr ? 'fr-FR' : 'en-US');
    state = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = false;
  }
}

final ttsProvider =
    StateNotifierProvider<TtsNotifier, bool>((ref) => TtsNotifier());

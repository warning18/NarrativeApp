import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
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
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS silences an app's speech with the Ring/Silent switch unless the
      // app says it plays audio on purpose: read-aloud does, like a
      // podcast, lowering other apps' sound while it speaks.
      _tts.setSharedInstance(true);
      _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        const [IosTextToSpeechAudioCategoryOptions.duckOthers],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    }
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _geminiVoiceEnabledPrefsKey = 'gemini_voice_enabled';
const String _geminiVoiceNamePrefsKey = 'gemini_voice_name';
const String _autoReadAloudPrefsKey = 'auto_read_aloud_enabled';

/// Default prebuilt Gemini voice, used until the player picks another one.
const String defaultGeminiVoiceName = 'Kore';

/// A short, curated subset of Gemini's 30 prebuilt TTS voices to offer in
/// Settings, spanning a range of tones.
const List<String> geminiVoiceChoices = [
  'Kore',
  'Puck',
  'Charon',
  'Aoede',
  'Fenrir',
  'Leda',
  'Zephyr',
  'Autonoe',
];

class GeminiVoiceSettings {
  const GeminiVoiceSettings({required this.enabled, required this.voiceName});

  final bool enabled;
  final String voiceName;

  GeminiVoiceSettings copyWith({bool? enabled, String? voiceName}) => GeminiVoiceSettings(
        enabled: enabled ?? this.enabled,
        voiceName: voiceName ?? this.voiceName,
      );
}

class GeminiVoiceSettingsNotifier extends StateNotifier<GeminiVoiceSettings> {
  GeminiVoiceSettingsNotifier()
      : super(const GeminiVoiceSettings(enabled: false, voiceName: defaultGeminiVoiceName)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = GeminiVoiceSettings(
      enabled: prefs.getBool(_geminiVoiceEnabledPrefsKey) ?? false,
      voiceName: prefs.getString(_geminiVoiceNamePrefsKey) ?? defaultGeminiVoiceName,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_geminiVoiceEnabledPrefsKey, enabled);
  }

  Future<void> setVoiceName(String voiceName) async {
    state = state.copyWith(voiceName: voiceName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiVoiceNamePrefsKey, voiceName);
  }
}

/// Whether the story reader's read-aloud button uses Gemini's higher-quality
/// prebuilt voices (via the same API key as the AI generator) instead of the
/// device's on-device text-to-speech engine, and which voice to use. Off by
/// default since it requires an API key and network access; persisted via
/// [SharedPreferences].
final geminiVoiceSettingsProvider =
    StateNotifierProvider<GeminiVoiceSettingsNotifier, GeminiVoiceSettings>(
  (ref) => GeminiVoiceSettingsNotifier(),
);

class AutoReadAloudNotifier extends StateNotifier<bool> {
  AutoReadAloudNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_autoReadAloudPrefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoReadAloudPrefsKey, enabled);
  }
}

/// Whether each new story scene is read aloud automatically as soon as it
/// appears, instead of requiring a tap on the read-aloud button every time.
/// Always uses the device's on-device voice (never Gemini's) — that voice
/// is already installed and speaks instantly, whereas Gemini needs a
/// network round-trip per scene, which auto-triggering on every single node
/// would make painfully slow. Off by default; persisted via
/// [SharedPreferences].
final autoReadAloudProvider =
    StateNotifierProvider<AutoReadAloudNotifier, bool>((ref) => AutoReadAloudNotifier());

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _elevenLabsEnabledPrefsKey = 'elevenlabs_voice_enabled';
const String _elevenLabsApiKeyPrefsKey = 'elevenlabs_api_key';
const String _elevenLabsVoiceIdPrefsKey = 'elevenlabs_voice_id';
const String _autoReadAloudPrefsKey = 'auto_read_aloud_enabled';

/// The narrator's ElevenLabs voice, used until the player enters another
/// (https://elevenlabs.io/voices/8TMmdpPgqHKvDOGYP2lN).
const String defaultElevenLabsVoiceId = '8TMmdpPgqHKvDOGYP2lN';

/// ElevenLabs' multilingual model: it speaks both the English and the
/// French story, detecting the language from the text.
const String elevenLabsModelId = 'eleven_multilingual_v2';

class ElevenLabsVoiceSettings {
  const ElevenLabsVoiceSettings({
    required this.enabled,
    required this.voiceId,
    this.apiKey,
  });

  final bool enabled;
  final String voiceId;

  /// Kept on this device only (SharedPreferences), never in the story
  /// data or anything the app pushes; recorded clips play without it.
  final String? apiKey;

  bool get hasApiKey => apiKey?.isNotEmpty ?? false;

  ElevenLabsVoiceSettings copyWith({
    bool? enabled,
    String? voiceId,
    String? apiKey,
    bool clearApiKey = false,
  }) =>
      ElevenLabsVoiceSettings(
        enabled: enabled ?? this.enabled,
        voiceId: voiceId ?? this.voiceId,
        apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      );
}

class ElevenLabsVoiceSettingsNotifier
    extends StateNotifier<ElevenLabsVoiceSettings> {
  ElevenLabsVoiceSettingsNotifier()
      : super(const ElevenLabsVoiceSettings(
            enabled: false, voiceId: defaultElevenLabsVoiceId)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final voiceId = prefs.getString(_elevenLabsVoiceIdPrefsKey);
    state = ElevenLabsVoiceSettings(
      enabled: prefs.getBool(_elevenLabsEnabledPrefsKey) ?? false,
      voiceId:
          (voiceId?.isNotEmpty ?? false) ? voiceId! : defaultElevenLabsVoiceId,
      apiKey: prefs.getString(_elevenLabsApiKeyPrefsKey),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_elevenLabsEnabledPrefsKey, enabled);
  }

  /// An empty [voiceId] goes back to [defaultElevenLabsVoiceId].
  Future<void> setVoiceId(String voiceId) async {
    final trimmed = voiceId.trim();
    state = state.copyWith(
        voiceId: trimmed.isEmpty ? defaultElevenLabsVoiceId : trimmed);
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_elevenLabsVoiceIdPrefsKey);
    } else {
      await prefs.setString(_elevenLabsVoiceIdPrefsKey, trimmed);
    }
  }

  Future<void> setApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return clearApiKey();
    state = state.copyWith(apiKey: trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_elevenLabsApiKeyPrefsKey, trimmed);
  }

  Future<void> clearApiKey() async {
    state = state.copyWith(clearApiKey: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_elevenLabsApiKeyPrefsKey);
  }
}

/// Whether the story is read aloud in a recorded ElevenLabs voice instead
/// of the device's on-device text-to-speech engine, which voice, and the
/// ElevenLabs API key that records it. Each paragraph is recorded once and
/// stored on the device (see `elevenLabsTtsProvider`), so after that it
/// plays offline. Off by default; persisted via [SharedPreferences].
final elevenLabsVoiceSettingsProvider = StateNotifierProvider<
    ElevenLabsVoiceSettingsNotifier, ElevenLabsVoiceSettings>(
  (ref) => ElevenLabsVoiceSettingsNotifier(),
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
/// Uses the ElevenLabs voice when it is on and the scene can be heard in
/// it, the device's own voice otherwise. Off by default; persisted via
/// [SharedPreferences].
final autoReadAloudProvider =
    StateNotifierProvider<AutoReadAloudNotifier, bool>(
        (ref) => AutoReadAloudNotifier());

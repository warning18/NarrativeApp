import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../l10n/app_locale.dart';

/// Preview TTS model — see https://ai.google.dev/gemini-api/docs/speech-generation.
const String _geminiTtsModel = 'gemini-2.5-flash-preview-tts';

/// How many recently-fetched clips to keep in memory so revisiting a node
/// (or one preloaded ahead of time) plays back instantly instead of
/// re-fetching. Bounded so a long play session doesn't grow unbounded.
const int _maxCacheEntries = 6;

/// Thrown when a Gemini TTS request fails; [message] is safe to show the
/// player (the API key itself never ends up in it).
class GeminiTtsException implements Exception {
  GeminiTtsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// [GeminiTtsNotifier]'s state: idle (nothing to show), loading (a request
/// is in flight — not yet audible), or playing (audio is actually
/// sounding). Split from a single bool so the read-aloud button can show a
/// spinner during the network round-trip instead of jumping straight to a
/// "stop" icon before there's anything to stop.
enum GeminiTtsPlaybackState { idle, loading, playing }

/// Speaks story text aloud using one of Gemini's prebuilt voices instead of
/// the device's on-device TTS engine. Wraps a single shared [AudioPlayer].
class GeminiTtsNotifier extends StateNotifier<GeminiTtsPlaybackState> {
  GeminiTtsNotifier() : super(GeminiTtsPlaybackState.idle);

  /// Created on first use: a reader who never turns the Gemini voice on
  /// never opens a native audio player (every scene change calls [stop]).
  AudioPlayer? _audio;
  AudioPlayer get _player => _audio ??= AudioPlayer()
    ..onPlayerComplete.listen((_) => state = GeminiTtsPlaybackState.idle);

  /// Clip cache, keyed by voice+language+text — insertion-ordered so the
  /// oldest entry is evicted first once [_maxCacheEntries] is exceeded.
  final Map<String, Uint8List> _cache = {};

  /// Cache keys currently being fetched by [preload], so a node displayed
  /// across a couple of rebuilds doesn't fire off duplicate requests for
  /// the same clip before the first one lands.
  final Set<String> _pendingPreloads = {};

  String _cacheKey(String text, String voiceName, AppLanguage language) =>
      '$voiceName|${language.name}|$text';

  void _cacheClip(String key, Uint8List bytes) {
    _cache.remove(key);
    _cache[key] = bytes;
    if (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Fetches a node's audio ahead of time, without playing it, so that
  /// tapping read-aloud later plays back instantly from cache instead of
  /// waiting on a network round-trip. Silently gives up on failure — a
  /// preload is purely opportunistic, and any real problem (bad key, no
  /// network) still surfaces normally the moment the player taps play.
  Future<void> preload({
    required String text,
    required String apiKey,
    required String voiceName,
    required AppLanguage language,
  }) async {
    if (text.trim().isEmpty) return;
    final key = _cacheKey(text, voiceName, language);
    if (_cache.containsKey(key) || _pendingPreloads.contains(key)) return;
    _pendingPreloads.add(key);
    try {
      final wavBytes = await _fetchWav(
        text: text,
        apiKey: apiKey,
        voiceName: voiceName,
        language: language,
      );
      _cacheClip(key, wavBytes);
    } catch (_) {
      // Opportunistic — see doc comment above.
    } finally {
      _pendingPreloads.remove(key);
    }
  }

  Future<void> speak({
    required String text,
    required String apiKey,
    required String voiceName,
    required AppLanguage language,
  }) async {
    if (text.trim().isEmpty) return;
    await _player.stop();
    final key = _cacheKey(text, voiceName, language);
    final cached = _cache[key];
    state = GeminiTtsPlaybackState.loading;
    try {
      final wavBytes = cached ??
          await _fetchWav(
              text: text,
              apiKey: apiKey,
              voiceName: voiceName,
              language: language);
      if (cached == null) _cacheClip(key, wavBytes);
      // stop() may have been called while the request was in flight —
      // don't play stale audio for a request nobody wants anymore.
      if (state != GeminiTtsPlaybackState.loading) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gemini_tts_output.wav');
      await file.writeAsBytes(wavBytes, flush: true);
      if (state != GeminiTtsPlaybackState.loading) return;
      state = GeminiTtsPlaybackState.playing;
      await _player.play(DeviceFileSource(file.path));
    } catch (_) {
      state = GeminiTtsPlaybackState.idle;
      rethrow;
    }
  }

  Future<void> stop() async {
    await _audio?.stop();
    state = GeminiTtsPlaybackState.idle;
  }

  Future<Uint8List> _fetchWav({
    required String text,
    required String apiKey,
    required String voiceName,
    required AppLanguage language,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_geminiTtsModel:generateContent?key=$apiKey',
    );
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': text},
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['AUDIO'],
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': voiceName},
          },
          'languageCode': language == AppLanguage.fr ? 'fr-FR' : 'en-US',
        },
      },
    });
    final response = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'}, body: requestBody)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw GeminiTtsException(
          _apiErrorMessage(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    final content = candidates?.isNotEmpty ?? false
        ? (candidates!.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?
        : null;
    final parts = content?['parts'] as List<dynamic>?;
    final inlineData = parts?.isNotEmpty ?? false
        ? (parts!.first as Map<String, dynamic>)['inlineData']
            as Map<String, dynamic>?
        : null;
    final base64Audio = inlineData?['data'] as String?;
    if (base64Audio == null || base64Audio.isEmpty) {
      throw GeminiTtsException('Gemini returned no audio.');
    }

    final mimeType = inlineData?['mimeType'] as String? ?? '';
    return _wrapPcmAsWav(base64Decode(base64Audio),
        sampleRate: _sampleRateFrom(mimeType));
  }

  int _sampleRateFrom(String mimeType) {
    final match = RegExp(r'rate=(\d+)').firstMatch(mimeType);
    return match != null ? int.parse(match.group(1)!) : 24000;
  }

  String _apiErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message =
          (decoded['error'] as Map<String, dynamic>?)?['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      // Body wasn't the expected JSON shape — fall through to the generic
      // message below rather than surfacing a parse error.
    }
    return 'Gemini API request failed (HTTP $statusCode).';
  }

  /// Gemini returns raw headerless 16-bit PCM; wrap it in a standard WAV
  /// container so audioplayers (and the OS media backends underneath it)
  /// know the sample rate, bit depth and channel count before playing it.
  Uint8List _wrapPcmAsWav(
    Uint8List pcm, {
    required int sampleRate,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final header = BytesBuilder()
      ..add(ascii.encode('RIFF'))
      ..add(_uint32le(36 + pcm.length))
      ..add(ascii.encode('WAVE'))
      ..add(ascii.encode('fmt '))
      ..add(_uint32le(16))
      ..add(_uint16le(1)) // PCM
      ..add(_uint16le(channels))
      ..add(_uint32le(sampleRate))
      ..add(_uint32le(byteRate))
      ..add(_uint16le(blockAlign))
      ..add(_uint16le(bitsPerSample))
      ..add(ascii.encode('data'))
      ..add(_uint32le(pcm.length));
    return Uint8List.fromList([...header.toBytes(), ...pcm]);
  }

  List<int> _uint32le(int v) =>
      [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];

  List<int> _uint16le(int v) => [v & 0xff, (v >> 8) & 0xff];

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }
}

final geminiTtsProvider =
    StateNotifierProvider<GeminiTtsNotifier, GeminiTtsPlaybackState>(
  (ref) => GeminiTtsNotifier(),
);

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

/// Thrown when a Gemini TTS request fails; [message] is safe to show the
/// player (the API key itself never ends up in it).
class GeminiTtsException implements Exception {
  GeminiTtsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Speaks story text aloud using one of Gemini's prebuilt voices instead of
/// the device's on-device TTS engine. Wraps a single shared [AudioPlayer];
/// the bool state tracks whether a request is in flight or audio is
/// currently playing, so the UI can show the same play/stop toggle the
/// on-device engine uses.
class GeminiTtsNotifier extends StateNotifier<bool> {
  GeminiTtsNotifier() : super(false) {
    _player.onPlayerComplete.listen((_) => state = false);
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> speak({
    required String text,
    required String apiKey,
    required String voiceName,
    required AppLanguage language,
  }) async {
    if (text.trim().isEmpty) return;
    await _player.stop();
    state = true;
    try {
      final wavBytes = await _fetchWav(
        text: text,
        apiKey: apiKey,
        voiceName: voiceName,
        language: language,
      );
      // speak() may have been cancelled via stop() while the request was
      // in flight — don't play stale audio for a request nobody wants.
      if (!state) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/gemini_tts_output.wav');
      await file.writeAsBytes(wavBytes, flush: true);
      if (!state) return;
      await _player.play(DeviceFileSource(file.path));
    } catch (_) {
      state = false;
      rethrow;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = false;
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
        .post(uri, headers: {'Content-Type': 'application/json'}, body: requestBody)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw GeminiTtsException(_apiErrorMessage(response.body, response.statusCode));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    final content = candidates?.isNotEmpty ?? false
        ? (candidates!.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?
        : null;
    final parts = content?['parts'] as List<dynamic>?;
    final inlineData = parts?.isNotEmpty ?? false
        ? (parts!.first as Map<String, dynamic>)['inlineData'] as Map<String, dynamic>?
        : null;
    final base64Audio = inlineData?['data'] as String?;
    if (base64Audio == null || base64Audio.isEmpty) {
      throw GeminiTtsException('Gemini returned no audio.');
    }

    final mimeType = inlineData?['mimeType'] as String? ?? '';
    return _wrapPcmAsWav(base64Decode(base64Audio), sampleRate: _sampleRateFrom(mimeType));
  }

  int _sampleRateFrom(String mimeType) {
    final match = RegExp(r'rate=(\d+)').firstMatch(mimeType);
    return match != null ? int.parse(match.group(1)!) : 24000;
  }

  String _apiErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message = (decoded['error'] as Map<String, dynamic>?)?['message'] as String?;
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
    _player.dispose();
    super.dispose();
  }
}

final geminiTtsProvider =
    StateNotifierProvider<GeminiTtsNotifier, bool>((ref) => GeminiTtsNotifier());

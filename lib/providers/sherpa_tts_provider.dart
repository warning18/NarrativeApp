import 'dart:io';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// Offline French neural voice — a k2-fsa sherpa-onnx conversion of Meta's
/// MMS-TTS French model (VITS architecture). Bundled as a one-time
/// ~model-sized download instead of a build asset, so the repo and APK
/// don't carry the binary; the app's documents directory caches it after
/// the first fetch. French only for now — sherpa-onnx offers plenty of
/// other languages, but this app only reads French narration aloud with it.
const String _frenchModelUrl =
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-mms-fra.tar.bz2';
const String _modelDirName = 'sherpa_tts_fr';

/// Thrown when the offline voice can't be prepared or used; [message] is
/// safe to show the player.
class SherpaTtsException implements Exception {
  SherpaTtsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// [SherpaTtsNotifier]'s state: idle, fetching the (one-time) model archive,
/// generating audio for the current request, or actually playing it back —
/// split out so the read-aloud button can show what's actually happening
/// on a slow connection instead of a generic spinner throughout.
enum SherpaTtsPlaybackState { idle, downloading, generating, playing }

/// Speaks French text aloud entirely on-device via sherpa-onnx, once the
/// (one-time, cached) model has been fetched — no network round-trip per
/// line the way the Gemini voice needs, and no dependence on whatever (or
/// however poor) text-to-speech engine happens to be installed on the
/// device the way the OS voice does.
class SherpaTtsNotifier extends StateNotifier<SherpaTtsPlaybackState> {
  SherpaTtsNotifier() : super(SherpaTtsPlaybackState.idle) {
    _player.onPlayerComplete.listen((_) {
      if (state == SherpaTtsPlaybackState.playing) state = SherpaTtsPlaybackState.idle;
    });
  }

  final AudioPlayer _player = AudioPlayer();
  sherpa_onnx.OfflineTts? _tts;
  bool _bindingsInitialized = false;

  /// Guards concurrent callers from downloading/initializing twice.
  Future<void>? _readyFuture;

  Future<Directory> _modelDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_modelDirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Looks for already-extracted model files by extension/name rather than
  /// a hardcoded folder layout, since the archive's internal structure
  /// isn't guaranteed across releases.
  Future<(File, File)?> _findModelFiles(Directory dir) async {
    File? modelFile;
    File? tokensFile;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.endsWith('.onnx')) modelFile = entity;
      if (name == 'tokens.txt') tokensFile = entity;
    }
    if (modelFile != null && tokensFile != null) return (modelFile, tokensFile);
    return null;
  }

  Future<void> _ensureReady() async {
    try {
      await (_readyFuture ??= _prepareEngine());
    } catch (e) {
      // Don't let a failed attempt (e.g. no network) permanently poison
      // future retries — clear the cache so the next speak() tries again.
      _readyFuture = null;
      rethrow;
    }
  }

  Future<void> _prepareEngine() async {
    final dir = await _modelDir();
    var found = await _findModelFiles(dir);
    if (found == null) {
      state = SherpaTtsPlaybackState.downloading;
      try {
        final response = await http
            .get(Uri.parse(_frenchModelUrl))
            .timeout(const Duration(minutes: 5));
        if (response.statusCode != 200) {
          throw SherpaTtsException(
            'French voice download failed (HTTP ${response.statusCode}).',
          );
        }
        final tarBytes = BZip2Decoder().decodeBytes(response.bodyBytes);
        final archive = TarDecoder().decodeBytes(tarBytes);
        for (final file in archive.files) {
          if (!file.isFile) continue;
          final name = file.name.split('/').last;
          if (!name.endsWith('.onnx') && name != 'tokens.txt') continue;
          final content = file.content as List<int>;
          await File('${dir.path}/$name').writeAsBytes(content, flush: true);
        }
      } catch (e) {
        state = SherpaTtsPlaybackState.idle;
        throw SherpaTtsException('Could not download the French voice: $e');
      }
      found = await _findModelFiles(dir);
      if (found == null) {
        state = SherpaTtsPlaybackState.idle;
        throw SherpaTtsException('French voice download did not contain a usable model.');
      }
    }

    if (!_bindingsInitialized) {
      sherpa_onnx.initBindings();
      _bindingsInitialized = true;
    }
    final (modelFile, tokensFile) = found;
    _tts = sherpa_onnx.OfflineTts(
      sherpa_onnx.OfflineTtsConfig(
        model: sherpa_onnx.OfflineTtsModelConfig(
          vits: sherpa_onnx.OfflineTtsVitsModelConfig(
            model: modelFile.path,
            tokens: tokensFile.path,
          ),
          numThreads: 2,
          debug: false,
        ),
      ),
    );
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _player.stop();
    try {
      await _ensureReady();
      state = SherpaTtsPlaybackState.generating;
      final tts = _tts;
      if (tts == null) throw SherpaTtsException('French voice failed to load.');
      final audio = tts.generate(text: text);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sherpa_tts_output.wav');
      sherpa_onnx.writeWave(
        filename: file.path,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      if (state != SherpaTtsPlaybackState.generating) return;
      state = SherpaTtsPlaybackState.playing;
      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      state = SherpaTtsPlaybackState.idle;
      if (e is SherpaTtsException) rethrow;
      throw SherpaTtsException('French voice error: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = SherpaTtsPlaybackState.idle;
  }

  @override
  void dispose() {
    _tts?.free();
    _player.dispose();
    super.dispose();
  }
}

final sherpaTtsProvider =
    StateNotifierProvider<SherpaTtsNotifier, SherpaTtsPlaybackState>(
  (ref) => SherpaTtsNotifier(),
);

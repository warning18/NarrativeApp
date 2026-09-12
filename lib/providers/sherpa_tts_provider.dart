import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show compute;
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

/// Unpacks a downloaded tar.bz2 model archive into filename -> bytes for
/// just the files the engine needs (model + tokens). Run via [compute]
/// (a throwaway background isolate) since bzip2/tar decoding is CPU-bound
/// and would otherwise freeze the UI for however long it takes — a one-time
/// cost, but still enough to be felt on the first read-aloud.
Map<String, Uint8List> _extractModelArchive(Uint8List archiveBytes) {
  final tarBytes = BZip2Decoder().decodeBytes(archiveBytes);
  final archive = TarDecoder().decodeBytes(tarBytes);
  final result = <String, Uint8List>{};
  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name.split('/').last;
    if (!name.endsWith('.onnx') && name != 'tokens.txt') continue;
    final content = file.content;
    result[name] = content is Uint8List ? content : Uint8List.fromList(content as List<int>);
  }
  return result;
}

/// Runs entirely in a dedicated background isolate for the lifetime of the
/// app: loads the sherpa-onnx model once and keeps it resident in that
/// isolate, generating audio for each request without re-loading. Model
/// construction and neural-network inference (`OfflineTts.generate`) are
/// both synchronous, CPU-heavy native calls — running them on the main
/// isolate is exactly what was freezing the UI, since auto-read fires one
/// on every single scene. Communicates over plain Maps of primitives plus
/// a SendPort, which cross the isolate boundary directly.
///
/// sherpa-onnx's FFI binding state is per-isolate — every isolate that
/// calls a sherpa-onnx API must call `initBindings()` itself first. That
/// includes `writeWave()`, so the WAV file is written here too (given a
/// path computed on the main isolate, since `path_provider` needs platform
/// channels this isolate doesn't have) rather than back on the main
/// isolate, which previously threw "Please initialize sherpa-onnx first".
void _sherpaIsolateEntry(SendPort mainSendPort) {
  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  sherpa_onnx.OfflineTts? tts;
  var bindingsInitialized = false;

  commandPort.listen((dynamic message) {
    final request = message as Map<String, dynamic>;
    final replyPort = request['replyPort'] as SendPort;
    try {
      if (!bindingsInitialized) {
        sherpa_onnx.initBindings();
        bindingsInitialized = true;
      }
      tts ??= sherpa_onnx.OfflineTts(
        sherpa_onnx.OfflineTtsConfig(
          model: sherpa_onnx.OfflineTtsModelConfig(
            vits: sherpa_onnx.OfflineTtsVitsModelConfig(
              model: request['modelPath'] as String,
              tokens: request['tokensPath'] as String,
            ),
            numThreads: 2,
            debug: false,
          ),
        ),
      );
      final audio = tts!.generate(text: request['text'] as String);
      final outputPath = request['outputPath'] as String;
      sherpa_onnx.writeWave(
        filename: outputPath,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      replyPort.send({'outputPath': outputPath});
    } catch (e) {
      replyPort.send({'error': e.toString()});
    }
  });
}

/// Speaks French text aloud entirely on-device via sherpa-onnx, once the
/// (one-time, cached) model has been fetched — no network round-trip per
/// line the way the Gemini voice needs, and no dependence on whatever (or
/// however poor) text-to-speech engine happens to be installed on the
/// device the way the OS voice does. All CPU-heavy work (model load,
/// inference, archive extraction) runs off the UI isolate.
class SherpaTtsNotifier extends StateNotifier<SherpaTtsPlaybackState> {
  SherpaTtsNotifier() : super(SherpaTtsPlaybackState.idle) {
    _player.onPlayerComplete.listen((_) {
      if (state == SherpaTtsPlaybackState.playing) state = SherpaTtsPlaybackState.idle;
    });
  }

  final AudioPlayer _player = AudioPlayer();

  Isolate? _workerIsolate;
  Future<SendPort>? _workerPortFuture;

  String? _modelPath;
  String? _tokensPath;
  Future<void>? _modelReadyFuture;

  Future<Directory> _modelDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_modelDirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Looks for already-extracted model files by extension/name rather than
  /// a hardcoded folder layout, since the archive's internal structure
  /// isn't guaranteed across releases.
  Future<(String, String)?> _findModelPaths(Directory dir) async {
    String? modelPath;
    String? tokensPath;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.endsWith('.onnx')) modelPath = entity.path;
      if (name == 'tokens.txt') tokensPath = entity.path;
    }
    if (modelPath != null && tokensPath != null) return (modelPath, tokensPath);
    return null;
  }

  Future<void> _ensureModelDownloaded() async {
    try {
      await (_modelReadyFuture ??= _downloadAndExtractModel());
    } catch (e) {
      // Don't let a failed attempt (e.g. no network) permanently poison
      // future retries — clear the cache so the next speak() tries again.
      _modelReadyFuture = null;
      rethrow;
    }
  }

  Future<void> _downloadAndExtractModel() async {
    final dir = await _modelDir();
    final existing = await _findModelPaths(dir);
    if (existing != null) {
      final (modelPath, tokensPath) = existing;
      _modelPath = modelPath;
      _tokensPath = tokensPath;
      return;
    }

    state = SherpaTtsPlaybackState.downloading;
    final http.Response response;
    try {
      response =
          await http.get(Uri.parse(_frenchModelUrl)).timeout(const Duration(minutes: 5));
    } catch (e) {
      state = SherpaTtsPlaybackState.idle;
      throw SherpaTtsException('Could not download the French voice: $e');
    }
    if (response.statusCode != 200) {
      state = SherpaTtsPlaybackState.idle;
      throw SherpaTtsException('French voice download failed (HTTP ${response.statusCode}).');
    }

    final files = await compute(_extractModelArchive, response.bodyBytes);
    for (final entry in files.entries) {
      await File('${dir.path}/${entry.key}').writeAsBytes(entry.value, flush: true);
    }

    final found = await _findModelPaths(dir);
    if (found == null) {
      state = SherpaTtsPlaybackState.idle;
      throw SherpaTtsException('French voice download did not contain a usable model.');
    }
    final (modelPath, tokensPath) = found;
    _modelPath = modelPath;
    _tokensPath = tokensPath;
  }

  Future<SendPort> _ensureWorkerPort() async {
    try {
      return await (_workerPortFuture ??= _spawnWorker());
    } catch (e) {
      _workerPortFuture = null;
      rethrow;
    }
  }

  Future<SendPort> _spawnWorker() async {
    final readyPort = ReceivePort();
    _workerIsolate = await Isolate.spawn(_sherpaIsolateEntry, readyPort.sendPort);
    return await readyPort.first as SendPort;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _player.stop();
    try {
      await _ensureModelDownloaded();
      state = SherpaTtsPlaybackState.generating;

      // Computed here (not in the worker isolate) because path_provider
      // needs platform-channel access a plain Isolate.spawn'd isolate
      // doesn't have.
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/sherpa_tts_output.wav';

      final workerPort = await _ensureWorkerPort();
      final replyPort = ReceivePort();
      workerPort.send({
        'text': text,
        'modelPath': _modelPath,
        'tokensPath': _tokensPath,
        'outputPath': outputPath,
        'replyPort': replyPort.sendPort,
      });
      final response = await replyPort.first as Map<dynamic, dynamic>;
      replyPort.close();
      if (response.containsKey('error')) {
        throw SherpaTtsException('French voice error: ${response['error']}');
      }

      if (state != SherpaTtsPlaybackState.generating) return;
      state = SherpaTtsPlaybackState.playing;
      await _player.play(DeviceFileSource(response['outputPath'] as String));
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
    _workerIsolate?.kill(priority: Isolate.immediate);
    _player.dispose();
    super.dispose();
  }
}

final sherpaTtsProvider =
    StateNotifierProvider<SherpaTtsNotifier, SherpaTtsPlaybackState>(
  (ref) => SherpaTtsNotifier(),
);

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/narration_clips.dart';
import '../l10n/app_locale.dart';
import 'voice_settings_provider.dart';

/// Thrown when a paragraph can't be voiced: ElevenLabs refused the request,
/// or it isn't recorded yet and there is no API key to record it with.
/// [message] is safe to show the player (the API key never ends up in it).
class ElevenLabsException implements Exception {
  ElevenLabsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns [text] into MP3 bytes in the voice [voiceId].
typedef ElevenLabsSynthesize = Future<Uint8List> Function({
  required String text,
  required String apiKey,
  required String voiceId,
});

/// Calls ElevenLabs' text-to-speech endpoint
/// (https://elevenlabs.io/docs/api-reference/text-to-speech/convert).
Future<Uint8List> synthesizeWithElevenLabs({
  required String text,
  required String apiKey,
  required String voiceId,
}) async {
  final uri = Uri.https(
    'api.elevenlabs.io',
    '/v1/text-to-speech/${Uri.encodeComponent(voiceId)}',
    {'output_format': elevenLabsOutputFormat},
  );
  final response = await http
      .post(
        uri,
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body: jsonEncode({'text': text, 'model_id': elevenLabsModelId}),
      )
      .timeout(const Duration(seconds: 60));
  if (response.statusCode != 200) {
    throw ElevenLabsException(
        elevenLabsErrorMessage(response.body, response.statusCode));
  }
  if (response.bodyBytes.isEmpty) {
    throw ElevenLabsException('ElevenLabs returned no audio.');
  }
  return response.bodyBytes;
}

/// The readable reason in an ElevenLabs error body (`detail` is either a
/// string or a `{status, message}` object), or a generic line.
String elevenLabsErrorMessage(String body, int statusCode) {
  try {
    final detail = (jsonDecode(body) as Map<String, dynamic>)['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is Map && detail['message'] is String) {
      return detail['message'] as String;
    }
  } catch (_) {
    // Not the expected JSON shape -- fall through to the generic message.
  }
  if (statusCode == 401) return 'The ElevenLabs API key was refused.';
  return 'ElevenLabs request failed (HTTP $statusCode).';
}

/// ElevenLabs' MP3 at 64 kbit/s: clear for a speaking voice, and half
/// the size of their default, which matters once recordings ship inside
/// the app (see [bundledNarrationPath]).
const String elevenLabsOutputFormat = 'mp3_44100_64';

/// Where a recording is kept in the repository, and so inside the app
/// once it is pushed (see `pushNarrationToGitHub`): the clip id already
/// names the voice and the model, so every voice shares one folder per
/// language.
String bundledNarrationPath(String clipId, AppLanguage language) =>
    'assets/narration/${language.name}/$clipId.mp3';

/// One recording kept on this device (see [NarrationRecordings.localClips]).
class LocalNarrationClip {
  const LocalNarrationClip(
      {required this.clipId, required this.language, required this.mp3});

  final String clipId;
  final AppLanguage language;
  final File mp3;

  /// The words it speaks, kept beside it.
  File get text => File(mp3.path.replaceFirst(RegExp(r'\.mp3$'), '.txt'));
}

Future<Set<String>> _loadBundledNarration() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest
      .listAssets()
      .where((path) => path.startsWith('assets/narration/'))
      .toSet();
}

/// Where recorded narration lives: recorded on this device, one MP3 per
/// paragraph under `narration/<voice id>/<en|fr>/<clip id>.mp3` in the
/// app's documents folder, each with a `.txt` beside it holding the words
/// it speaks; or shipped inside the app, once pushed to the repository
/// (see [bundledNarrationPath]).
class NarrationRecordings {
  NarrationRecordings({
    Future<Directory> Function()? root,
    Future<Set<String>> Function()? bundledAssets,
  })  : _root = root ?? getApplicationDocumentsDirectory,
        _loadBundled = bundledAssets ?? _loadBundledNarration;

  final Future<Directory> Function() _root;
  final Future<Set<String>> Function() _loadBundled;
  Future<Set<String>>? _bundled;

  /// The web build has no file system to keep recordings in.
  static bool get supported => !kIsWeb;

  /// The recordings shipped inside the app, read once. An app without any
  /// (or a test host without an asset manifest) has none.
  Future<Set<String>> bundled() => _bundled ??= () async {
        try {
          return await _loadBundled();
        } catch (_) {
          return <String>{};
        }
      }();

  String clipIdFor(String text, {required String voiceId}) =>
      narrationClipId(text: text, voiceId: voiceId, modelId: elevenLabsModelId);

  Future<Directory> _voiceDir(String voiceId) async =>
      Directory('${(await _root()).path}/narration/$voiceId');

  Future<Directory> _dir(String voiceId, AppLanguage language) async =>
      Directory('${(await _voiceDir(voiceId)).path}/${language.name}');

  /// Where [text] is (or would be) recorded on this device.
  Future<File> fileFor(String text,
      {required String voiceId, required AppLanguage language}) async {
    final id = clipIdFor(text, voiceId: voiceId);
    return File('${(await _dir(voiceId, language)).path}/$id.mp3');
  }

  /// Whether [text] ships inside the app in [voiceId].
  Future<bool> isBundled(String text,
          {required String voiceId, required AppLanguage language}) async =>
      (await bundled()).contains(
          bundledNarrationPath(clipIdFor(text, voiceId: voiceId), language));

  /// What plays [text] without recording it: this device's recording, or
  /// the one shipped inside the app; null when there is neither.
  Future<Source?> sourceFor(String text,
      {required String voiceId, required AppLanguage language}) async {
    final file = await fileFor(text, voiceId: voiceId, language: language);
    if (await file.exists()) return DeviceFileSource(file.path);
    final asset =
        bundledNarrationPath(clipIdFor(text, voiceId: voiceId), language);
    if ((await bundled()).contains(asset)) {
      // AssetSource paths are relative to the assets/ folder.
      return AssetSource(asset.substring('assets/'.length));
    }
    return null;
  }

  Future<bool> has(String text,
          {required String voiceId, required AppLanguage language}) async =>
      await sourceFor(text, voiceId: voiceId, language: language) != null;

  Future<File> save(String text, Uint8List mp3,
      {required String voiceId, required AppLanguage language}) async {
    final file = await fileFor(text, voiceId: voiceId, language: language);
    await file.parent.create(recursive: true);
    // Written under a temporary name first, so a recording cut short (the
    // app closed mid-write) is never mistaken for a finished one.
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(mp3, flush: true);
    await File(file.path.replaceFirst(RegExp(r'\.mp3$'), '.txt'))
        .writeAsString(text, flush: true);
    return partial.rename(file.path);
  }

  /// How many paragraphs are recorded on this device in [voiceId] and
  /// [language].
  Future<int> count(
      {required String voiceId, required AppLanguage language}) async {
    final dir = await _dir(voiceId, language);
    if (!await dir.exists()) return 0;
    return dir.list().where((entry) => entry.path.endsWith('.mp3')).length;
  }

  /// The folder holding [voiceId]'s recordings in [language].
  Future<String> folderPath(
          {required String voiceId, required AppLanguage language}) async =>
      (await _dir(voiceId, language)).path;

  /// How many recordings ship inside the app in [language], every voice
  /// together.
  Future<int> bundledCount(AppLanguage language) async => (await bundled())
      .where((path) =>
          path.startsWith('assets/narration/${language.name}/') &&
          path.endsWith('.mp3'))
      .length;

  /// Every recording made on this device in [voiceId], both languages.
  Future<List<LocalNarrationClip>> localClips(String voiceId) async {
    final clips = <LocalNarrationClip>[];
    for (final language in AppLanguage.values) {
      final dir = await _dir(voiceId, language);
      if (!await dir.exists()) continue;
      await for (final entry in dir.list()) {
        if (entry is! File || !entry.path.endsWith('.mp3')) continue;
        final name = entry.uri.pathSegments.last;
        clips.add(LocalNarrationClip(
          clipId: name.substring(0, name.length - '.mp3'.length),
          language: language,
          mp3: entry,
        ));
      }
    }
    clips.sort((a, b) => a.mp3.path.compareTo(b.mp3.path));
    return clips;
  }

  /// Deletes every recording made on this device in [voiceId], both
  /// languages (the ones shipped inside the app stay).
  Future<void> deleteVoice(String voiceId) async {
    final dir = await _voiceDir(voiceId);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

/// [ElevenLabsTtsNotifier]'s state: idle, loading (recording a paragraph
/// that isn't on the device yet -- nothing audible), or playing.
enum VoicePlaybackState { idle, loading, playing }

/// Reads story text aloud in a recorded ElevenLabs voice. Each paragraph
/// is recorded once (see [NarrationRecordings]) and played from the device
/// from then on; paragraphs play one after another, the next one recorded
/// while the current one is heard.
class ElevenLabsTtsNotifier extends StateNotifier<VoicePlaybackState> {
  ElevenLabsTtsNotifier({
    NarrationRecordings? recordings,
    ElevenLabsSynthesize? synthesize,
  })  : recordings = recordings ?? NarrationRecordings(),
        _synthesize = synthesize ?? synthesizeWithElevenLabs,
        super(VoicePlaybackState.idle);

  final NarrationRecordings recordings;
  final ElevenLabsSynthesize _synthesize;

  /// Created on first use: a reader who never turns the voice on never
  /// opens a native audio player (every scene change calls [stop]).
  AudioPlayer? _audio;
  AudioPlayer get _player => _audio ??= AudioPlayer();

  /// Bumped by every [speak] and [stop], so a reading that was stopped (or
  /// replaced by another) notices and goes no further.
  int _run = 0;

  /// Completed by [stop] to cut short the clip currently playing.
  Completer<void>? _interrupt;

  /// Recordings under way, by file path: a paragraph asked for again while
  /// it is still being recorded (a reading stopped and started again, the
  /// whole story recording alongside one) waits for that recording rather
  /// than paying ElevenLabs for it twice.
  final Map<String, Future<File>> _recording = {};

  /// What plays [text]: its recording on this device or inside the app,
  /// recording it first when there is neither.
  Future<Source> clipFor(String text,
      {required ElevenLabsVoiceSettings settings,
      required AppLanguage language}) async {
    if (!NarrationRecordings.supported) {
      throw ElevenLabsException(
          'Recorded voices are not available in the web version.');
    }
    final file = await recordings.fileFor(text,
        voiceId: settings.voiceId, language: language);
    if (!_recording.containsKey(file.path)) {
      final existing = await recordings.sourceFor(text,
          voiceId: settings.voiceId, language: language);
      if (existing != null && !_recording.containsKey(file.path)) {
        return existing;
      }
    }
    // Checked after the last await, so no other request can slip in
    // between this check and the recording being registered below.
    final pending = _recording[file.path];
    if (pending != null) return DeviceFileSource((await pending).path);
    if (!settings.hasApiKey) {
      throw ElevenLabsException(
          'This scene is not recorded yet and no ElevenLabs API key is set.');
    }
    final recording = () async {
      final mp3 = await _synthesize(
          text: text, apiKey: settings.apiKey!, voiceId: settings.voiceId);
      return recordings.save(text, mp3,
          voiceId: settings.voiceId, language: language);
    }();
    _recording[file.path] = recording;
    try {
      return DeviceFileSource((await recording).path);
    } finally {
      _recording.remove(file.path);
    }
  }

  /// Whether every one of [paragraphs] is already recorded, so reading
  /// them needs neither the network nor any ElevenLabs credits.
  Future<bool> isRecorded(List<String> paragraphs,
      {required ElevenLabsVoiceSettings settings,
      required AppLanguage language}) async {
    if (!NarrationRecordings.supported) return false;
    for (final paragraph in paragraphs) {
      if (!await recordings.has(paragraph,
          voiceId: settings.voiceId, language: language)) {
        return false;
      }
    }
    return true;
  }

  Future<void> speak(List<String> paragraphs,
      {required ElevenLabsVoiceSettings settings,
      required AppLanguage language}) async {
    await stop();
    if (paragraphs.isEmpty) return;
    final run = ++_run;
    state = VoicePlaybackState.loading;
    Future<Source>? next;
    try {
      next = clipFor(paragraphs.first, settings: settings, language: language);
      for (var i = 0; i < paragraphs.length; i++) {
        final clip = await next!;
        next = null;
        if (run != _run) return;
        if (i + 1 < paragraphs.length) {
          next = clipFor(paragraphs[i + 1],
              settings: settings, language: language);
        }
        state = VoicePlaybackState.playing;
        await _playToEnd(clip);
        if (run != _run) return;
        if (next != null) state = VoicePlaybackState.loading;
      }
    } finally {
      // A reading that stopped early leaves the next clip recording: it is
      // kept for later, but its failure, if any, is nobody's to report.
      next?.ignore();
      if (run == _run) state = VoicePlaybackState.idle;
    }
  }

  Future<void> _playToEnd(Source clip) async {
    final interrupt = _interrupt = Completer<void>();
    final finished = _player.onPlayerComplete.first;
    await _player.play(clip);
    await Future.any([finished, interrupt.future]);
  }

  Future<void> stop() async {
    _run++;
    final interrupt = _interrupt;
    if (interrupt != null && !interrupt.isCompleted) interrupt.complete();
    await _audio?.stop();
    state = VoicePlaybackState.idle;
  }

  /// Records every one of [paragraphs] not yet on the device, one at a
  /// time, reporting progress as `(done, total)` and stopping early when
  /// [cancelled] says so. Returns how many new clips were recorded; the
  /// first refusal from ElevenLabs (a bad key, credits run out) is thrown,
  /// and everything recorded before it is kept.
  Future<int> recordAll(
    List<String> paragraphs, {
    required ElevenLabsVoiceSettings settings,
    required AppLanguage language,
    void Function(int done, int total)? onProgress,
    bool Function()? cancelled,
  }) async {
    var recorded = 0;
    for (var i = 0; i < paragraphs.length; i++) {
      if (cancelled?.call() ?? false) break;
      final text = paragraphs[i];
      if (!await recordings.has(text,
          voiceId: settings.voiceId, language: language)) {
        await clipFor(text, settings: settings, language: language);
        recorded++;
      }
      onProgress?.call(i + 1, paragraphs.length);
    }
    return recorded;
  }

  /// The paragraphs of [paragraphs] not recorded yet, and how many
  /// characters recording them would send to ElevenLabs.
  Future<({List<String> missing, int characters})> missingFrom(
      List<String> paragraphs,
      {required ElevenLabsVoiceSettings settings,
      required AppLanguage language}) async {
    final missing = <String>[];
    var characters = 0;
    for (final text in paragraphs) {
      if (!await recordings.has(text,
          voiceId: settings.voiceId, language: language)) {
        missing.add(text);
        characters += text.length;
      }
    }
    return (missing: missing, characters: characters);
  }

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }
}

final elevenLabsTtsProvider =
    StateNotifierProvider<ElevenLabsTtsNotifier, VoicePlaybackState>(
  (ref) => ElevenLabsTtsNotifier(),
);

/// Bumped when the recording tools make or delete recordings, so the
/// "recorded" marks and counts they show read the folder again.
final narrationRecordingsVersionProvider = StateProvider<int>((ref) => 0);

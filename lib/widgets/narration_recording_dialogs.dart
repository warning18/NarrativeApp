import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/elevenlabs_tts_provider.dart';
import '../providers/github_push_provider.dart';
import '../providers/voice_settings_provider.dart';

/// The recording tools' shared steps: recording a set of paragraphs with a
/// confirmation of what it costs and a progress dialog, and pushing the
/// recordings made on this device to the repository.

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Runs [work] behind a progress dialog titled [title], [total] steps long
/// (or open-ended when [total] is 0). With [cancellable], Cancel (and
/// back) ask [work] to stop through its `isCancelled`; the dialog closes
/// once [work] returns. Returns [work]'s result, or rethrows its error.
Future<T> runWithProgress<T>(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required int total,
  bool cancellable = true,
  required Future<T> Function(
          void Function(int done) onProgress, bool Function() isCancelled)
      work,
}) async {
  final progress = ValueNotifier<int>(0);
  var cancelled = false;
  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        if (cancellable) cancelled = true;
      },
      child: AlertDialog(
        title: Text(title),
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (context, done, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: total == 0 ? null : done / total),
              if (total > 0) ...[
                const SizedBox(height: 12),
                Text(tr(ref, 'elevenlabs_progress')
                    .replaceAll('{done}', '$done')
                    .replaceAll('{total}', '$total')),
              ],
            ],
          ),
        ),
        actions: [
          if (cancellable)
            TextButton(
              onPressed: () => cancelled = true,
              child: Text(tr(ref, 'cancel')),
            ),
        ],
      ),
    ),
  );
  try {
    return await work((done) => progress.value = done, () => cancelled);
  } finally {
    navigator.pop();
    progress.dispose();
  }
}

/// Records whatever of [script] (paragraphs by language) is not recorded
/// yet, after showing how many ElevenLabs characters that costs when
/// [confirm] is set. Reports the outcome in a snack bar and returns how
/// many paragraphs were recorded.
Future<int> recordNarration(
  BuildContext context,
  WidgetRef ref,
  Map<AppLanguage, List<String>> script, {
  bool confirm = true,
}) async {
  final voice = ref.read(elevenLabsVoiceSettingsProvider);
  final notifier = ref.read(elevenLabsTtsProvider.notifier);
  if (!voice.hasApiKey) {
    _snack(context, tr(ref, 'elevenlabs_needs_key'));
    return 0;
  }
  final missing = <AppLanguage, List<String>>{};
  var characters = 0;
  for (final entry in script.entries) {
    final pending = await notifier.missingFrom(entry.value,
        settings: voice, language: entry.key);
    if (pending.missing.isNotEmpty) missing[entry.key] = pending.missing;
    characters += pending.characters;
  }
  if (!context.mounted) return 0;
  final total = missing.values.fold<int>(0, (sum, list) => sum + list.length);
  if (total == 0) {
    _snack(context, tr(ref, 'elevenlabs_record_nothing'));
    return 0;
  }
  if (confirm) {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(ref, 'elevenlabs_record_button')),
        content: Text(tr(ref, 'elevenlabs_record_confirm_body')
            .replaceAll('{count}', '$total')
            .replaceAll('{chars}', '$characters')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(ref, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(ref, 'elevenlabs_record_button')),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return 0;
  }

  var recorded = 0;
  Object? error;
  try {
    await runWithProgress<void>(
      context,
      ref,
      title: tr(ref, 'elevenlabs_recording_title'),
      total: total,
      work: (onProgress, isCancelled) async {
        var before = 0;
        for (final entry in missing.entries) {
          if (isCancelled()) break;
          recorded += await notifier.recordAll(
            entry.value,
            settings: voice,
            language: entry.key,
            onProgress: (done, _) => onProgress(before + done),
            cancelled: isCancelled,
          );
          before += entry.value.length;
        }
      },
    );
  } catch (e) {
    error = e;
  }
  ref.read(narrationRecordingsVersionProvider.notifier).state++;
  if (!context.mounted) return recorded;
  _snack(
    context,
    error != null
        ? '${tr(ref, 'voice_error_prefix')}: $error'
        : tr(ref, 'elevenlabs_record_done').replaceAll('{count}', '$recorded'),
  );
  return recorded;
}

/// Pushes the recordings made on this device (the current voice, both
/// languages) that the repository doesn't hold yet to a new branch, as
/// `assets/narration/<lang>/<clip id>.mp3` with each clip's words beside
/// it, so a pull request from that branch ships them inside the app.
Future<void> pushNarrationRecordings(
    BuildContext context, WidgetRef ref) async {
  final token = ref.read(githubTokenProvider);
  if (token == null || token.isEmpty) {
    _snack(context, tr(ref, 'elevenlabs_push_needs_token'));
    return;
  }
  final voice = ref.read(elevenLabsVoiceSettingsProvider);
  final recordings = ref.read(elevenLabsTtsProvider.notifier).recordings;

  final List<GitBinaryFile> files;
  try {
    files = await runWithProgress(
      context,
      ref,
      title: tr(ref, 'elevenlabs_push_checking'),
      total: 0,
      cancellable: false,
      work: (_, __) async {
        final inRepo = await repositoryPathsUnder(
            token: token, prefix: 'assets/narration/');
        final clips = await recordings.localClips(voice.voiceId);
        return [
          for (final clip in clips)
            if (!inRepo.contains(
                bundledNarrationPath(clip.clipId, clip.language))) ...[
              GitBinaryFile(
                path: bundledNarrationPath(clip.clipId, clip.language),
                read: clip.mp3.readAsBytes,
              ),
              if (clip.text.existsSync())
                GitBinaryFile(
                  path: bundledNarrationPath(clip.clipId, clip.language)
                      .replaceFirst(RegExp(r'\.mp3$'), '.txt'),
                  read: clip.text.readAsBytes,
                ),
            ],
        ];
      },
    );
  } catch (e) {
    if (context.mounted) {
      _snack(context, '${tr(ref, 'push_failed_prefix')}: $e');
    }
    return;
  }
  if (!context.mounted) return;
  final clipCount = files.where((f) => f.path.endsWith('.mp3')).length;
  if (clipCount == 0) {
    _snack(context, tr(ref, 'elevenlabs_push_nothing'));
    return;
  }

  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final branchName = 'narration-${now.year}${two(now.month)}${two(now.day)}-'
      '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr(ref, 'elevenlabs_push_button')),
      content: Text(tr(ref, 'elevenlabs_push_confirm_body')
          .replaceAll('{count}', '$clipCount')
          .replaceAll('{branch}', branchName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr(ref, 'cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr(ref, 'push_button')),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return;

  final GitPushResult result;
  try {
    result = await runWithProgress(
      context,
      ref,
      title: tr(ref, 'elevenlabs_pushing_title'),
      total: files.length,
      cancellable: false,
      work: (onProgress, _) => pushFilesToGitHub(
        token: token,
        branchName: branchName,
        message: 'Add $clipCount recorded narration clips '
            '(ElevenLabs voice ${voice.voiceId})',
        files: files,
        onProgress: (done, _) => onProgress(done),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      _snack(context, '${tr(ref, 'push_failed_prefix')}: $e');
    }
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr(ref, 'push_success_title')),
      content: SelectableText(
          '${tr(ref, 'elevenlabs_push_success_body')}\n\n${result.compareUrl}'),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: result.compareUrl));
            if (!dialogContext.mounted) return;
            _snack(dialogContext, tr(ref, 'link_copied_message'));
          },
          child: Text(tr(ref, 'copy_link_button')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(tr(ref, 'close_button')),
        ),
      ],
    ),
  );
}

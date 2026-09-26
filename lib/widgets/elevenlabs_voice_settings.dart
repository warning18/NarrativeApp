import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/narration_clips.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/elevenlabs_tts_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../providers/voice_settings_provider.dart';

/// The Settings controls for the recorded ElevenLabs voice: on/off, the
/// API key (kept on this device only), the voice id, how much of the story
/// is recorded, recording the whole story at once, and deleting the
/// recordings.
class ElevenLabsVoiceSettingsSection extends ConsumerStatefulWidget {
  const ElevenLabsVoiceSettingsSection({super.key});

  @override
  ConsumerState<ElevenLabsVoiceSettingsSection> createState() =>
      _ElevenLabsVoiceSettingsSectionState();
}

class _ElevenLabsVoiceSettingsSectionState
    extends ConsumerState<ElevenLabsVoiceSettingsSection> {
  final _keyController = TextEditingController();
  late final TextEditingController _voiceController;
  bool _obscure = true;

  /// Bumped to re-read the recorded count after recording or deleting.
  int _countVersion = 0;

  /// The recorded count and folder, read once per [_countVersion], voice
  /// and language rather than on every rebuild.
  String? _statusKey;
  Future<(int, String)>? _status;

  Future<(int, String)> _statusFor(String voiceId, AppLanguage language) {
    final key = '$_countVersion|$voiceId|${language.name}';
    if (key != _statusKey || _status == null) {
      _statusKey = key;
      final recordings = ref.read(elevenLabsTtsProvider.notifier).recordings;
      Future<(int, String)> read() async => (
            await recordings.count(voiceId: voiceId, language: language),
            await recordings.folderPath(voiceId: voiceId, language: language),
          );
      _status = read();
    }
    return _status!;
  }

  @override
  void initState() {
    super.initState();
    _voiceController = TextEditingController(
        text: ref.read(elevenLabsVoiceSettingsProvider).voiceId);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Every paragraph of the story, in the app's language, as this player
  /// would hear it.
  Future<List<String>> _script(AppLanguage language) async {
    final story = await ref.read(storyDataProvider.future);
    final session = ref.read(playerSessionProvider);
    final french = language == AppLanguage.fr;
    return narrationScript(
      story.nodes.values,
      french: french,
      personalize: (text) => personalizeFor(session, text, french: french),
    );
  }

  Future<void> _recordWholeStory() async {
    final language = ref.read(appLanguageProvider);
    final voice = ref.read(elevenLabsVoiceSettingsProvider);
    final notifier = ref.read(elevenLabsTtsProvider.notifier);
    final pending = await notifier.missingFrom(await _script(language),
        settings: voice, language: language);
    if (!mounted) return;
    if (pending.missing.isEmpty) {
      _snack(tr(ref, 'elevenlabs_record_nothing'));
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(ref, 'elevenlabs_record_all_button')),
        content: Text(tr(ref, 'elevenlabs_record_confirm_body')
            .replaceAll('{count}', '${pending.missing.length}')
            .replaceAll('{chars}', '${pending.characters}')),
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
    if (go != true || !mounted) return;

    final progress = ValueNotifier<int>(0);
    var cancelled = false;
    final total = pending.missing.length;
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // Back works as Cancel: the dialog closes itself once the clip being
      // recorded is saved.
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) => cancelled = true,
        child: AlertDialog(
          title: Text(tr(ref, 'elevenlabs_recording_title')),
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (context, done, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                    value: total == 0 ? null : done / total),
                const SizedBox(height: 12),
                Text(tr(ref, 'elevenlabs_recording_progress')
                    .replaceAll('{done}', '$done')
                    .replaceAll('{total}', '$total')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => cancelled = true,
              child: Text(tr(ref, 'cancel')),
            ),
          ],
        ),
      ),
    );
    int? recorded;
    Object? error;
    try {
      recorded = await notifier.recordAll(
        pending.missing,
        settings: voice,
        language: language,
        onProgress: (done, _) => progress.value = done,
        cancelled: () => cancelled,
      );
    } catch (e) {
      error = e;
    }
    navigator.pop();
    progress.dispose();
    if (!mounted) return;
    setState(() => _countVersion++);
    _snack(error != null
        ? '${tr(ref, 'voice_error_prefix')}: $error'
        : tr(ref, 'elevenlabs_record_done').replaceAll('{count}', '$recorded'));
  }

  Future<void> _deleteRecordings() async {
    final voice = ref.read(elevenLabsVoiceSettingsProvider);
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(tr(ref, 'elevenlabs_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(ref, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(ref, 'elevenlabs_delete_button')),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final notifier = ref.read(elevenLabsTtsProvider.notifier);
    await notifier.stop();
    await notifier.recordings.deleteVoice(voice.voiceId);
    if (!mounted) return;
    setState(() => _countVersion++);
    _snack(tr(ref, 'elevenlabs_deleted'));
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(elevenLabsVoiceSettingsProvider);
    final language = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr(ref, 'elevenlabs_voice_setting_title')),
          subtitle: Text(tr(ref, 'elevenlabs_voice_setting_desc')),
          value: voice.enabled,
          onChanged: (value) => ref
              .read(elevenLabsVoiceSettingsProvider.notifier)
              .setEnabled(value),
        ),
        if (voice.enabled && !NarrationRecordings.supported)
          Text(
            tr(ref, 'elevenlabs_web_unsupported'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        if (voice.enabled && NarrationRecordings.supported) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _keyController,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: tr(ref, 'elevenlabs_api_key_label'),
              helperText: voice.hasApiKey
                  ? tr(ref, 'elevenlabs_api_key_saved_hint')
                  : tr(ref, 'elevenlabs_api_key_missing_hint'),
              helperMaxLines: 3,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                tooltip: _obscure
                    ? tr(ref, 'show_api_key_tooltip')
                    : tr(ref, 'hide_api_key_tooltip'),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final key = _keyController.text.trim();
                    if (key.isEmpty) return;
                    await ref
                        .read(elevenLabsVoiceSettingsProvider.notifier)
                        .setApiKey(key);
                    _keyController.clear();
                    if (!mounted) return;
                    _snack(tr(ref, 'api_key_saved'));
                  },
                  child: Text(tr(ref, 'save')),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: voice.hasApiKey
                    ? () async {
                        _keyController.clear();
                        await ref
                            .read(elevenLabsVoiceSettingsProvider.notifier)
                            .clearApiKey();
                        if (!mounted) return;
                        _snack(tr(ref, 'api_key_removed'));
                      }
                    : null,
                child: Text(tr(ref, 'clear_button')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _voiceController,
            autocorrect: false,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: tr(ref, 'elevenlabs_voice_id_label'),
              helperText: tr(ref, 'elevenlabs_voice_id_hint')
                  .replaceAll('{id}', defaultElevenLabsVoiceId),
              helperMaxLines: 3,
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                tooltip: tr(ref, 'save'),
                onPressed: () async {
                  await ref
                      .read(elevenLabsVoiceSettingsProvider.notifier)
                      .setVoiceId(_voiceController.text);
                  _voiceController.text =
                      ref.read(elevenLabsVoiceSettingsProvider).voiceId;
                  if (!mounted) return;
                  setState(() => _countVersion++);
                },
              ),
            ),
            onSubmitted: (value) async {
              await ref
                  .read(elevenLabsVoiceSettingsProvider.notifier)
                  .setVoiceId(value);
              if (!mounted) return;
              setState(() => _countVersion++);
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<(int, String)>(
            future: _statusFor(voice.voiceId, language),
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(ref, 'elevenlabs_recorded_count')
                      .replaceAll('{count}', '${data.$1}')),
                  SelectableText(data.$2, style: theme.textTheme.bodySmall),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: voice.hasApiKey ? _recordWholeStory : null,
            icon: const Icon(Icons.mic_none),
            label: Text(tr(ref, 'elevenlabs_record_all_button')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _deleteRecordings,
            icon: const Icon(Icons.delete_outline),
            label: Text(tr(ref, 'elevenlabs_delete_button')),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/narration_clips.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/elevenlabs_tts_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../providers/voice_settings_provider.dart';
import '../widgets/narration_recording_dialogs.dart';

/// Edit Mode's recording page: the story's scenes sorted by kind (main
/// story, places, side scenes, endings) and chapter, each showing how much
/// of it is recorded, to record the ones picked in one go -- and to push
/// everything recorded on this device to the repository, so it ships
/// inside the app.
class NarrationRecordingScreen extends ConsumerStatefulWidget {
  const NarrationRecordingScreen({super.key});

  @override
  ConsumerState<NarrationRecordingScreen> createState() =>
      _NarrationRecordingScreenState();
}

/// One scene's recorded share, per language asked for.
typedef _Coverage = ({int recorded, int total});

class _NarrationRecordingScreenState
    extends ConsumerState<NarrationRecordingScreen> {
  final Set<NarrationCategory> _categories = {...NarrationCategory.values};
  final Set<int> _chapters = {0, 1, 2, 3, 4, 5, 6};
  late final Set<AppLanguage> _languages = {ref.read(appLanguageProvider)};
  bool _variations = true;
  final Set<String> _selected = {};

  /// Per node id: its paragraphs recorded out of all of them, in the
  /// languages picked. Read again when the filters or recordings change.
  Future<Map<String, _Coverage>>? _coverage;
  String? _coverageKey;

  String Function(String) _personalizer(bool french) {
    final session = ref.read(playerSessionProvider);
    return (text) => personalizeFor(session, text, french: french);
  }

  Map<AppLanguage, List<String>> _scriptFor(Iterable<StoryNode> nodes) => {
        for (final language in _languages)
          language: narrationScript(
            nodes,
            french: language == AppLanguage.fr,
            personalize: _personalizer(language == AppLanguage.fr),
            variations: _variations,
          ),
      };

  Future<Map<String, _Coverage>> _coverageFor(
      List<StoryNode> nodes, int version) {
    final voice = ref.read(elevenLabsVoiceSettingsProvider);
    final key = '$version|${voice.voiceId}|$_variations|'
        '${_languages.map((l) => l.name).join(',')}';
    if (key != _coverageKey || _coverage == null) {
      _coverageKey = key;
      final recordings = ref.read(elevenLabsTtsProvider.notifier).recordings;
      Future<Map<String, _Coverage>> read() async {
        final coverage = <String, _Coverage>{};
        for (final node in nodes) {
          var recorded = 0;
          var total = 0;
          for (final paragraphs in _scriptFor([node]).entries) {
            for (final text in paragraphs.value) {
              total++;
              if (await recordings.has(text,
                  voiceId: voice.voiceId, language: paragraphs.key)) {
                recorded++;
              }
            }
          }
          coverage[node.id] = (recorded: recorded, total: total);
        }
        return coverage;
      }

      _coverage = read();
    }
    return _coverage!;
  }

  bool _shown(StoryNode node) =>
      _categories.contains(narrationCategoryOf(node)) &&
      _chapters.contains(narrationChapterOf(node));

  String _categoryLabel(NarrationCategory category) => tr(
      ref,
      switch (category) {
        NarrationCategory.mainStory => 'narration_category_main',
        NarrationCategory.places => 'narration_category_places',
        NarrationCategory.sideScenes => 'narration_category_side',
        NarrationCategory.endings => 'narration_category_endings',
      });

  String _chapterLabel(int chapter) => chapter == 0
      ? tr(ref, 'narration_chapter_prologue')
      : tr(ref, 'narration_chapter_n').replaceAll('{n}', '$chapter');

  Widget _chips<T>(Iterable<T> values, Set<T> picked, String Function(T) label,
      {bool keepOne = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(label(value)),
            selected: picked.contains(value),
            onSelected: (on) => setState(() {
              if (on) {
                picked.add(value);
              } else if (!keepOne || picked.length > 1) {
                picked.remove(value);
              }
            }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyDataProvider);
    final version = ref.watch(narrationRecordingsVersionProvider);
    final voice = ref.watch(elevenLabsVoiceSettingsProvider);
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'narration_recording_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: tr(ref, 'elevenlabs_push_button'),
            onPressed: () => pushNarrationRecordings(context, ref),
          ),
        ],
      ),
      body: storyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (story) {
          final nodes = story.nodes.values.toList();
          final shown = nodes.where(_shown).toList();
          final picked = nodes.where((n) => _selected.contains(n.id)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FutureBuilder<Map<String, _Coverage>>(
                  future: _coverageFor(nodes, version),
                  builder: (context, snapshot) {
                    final coverage = snapshot.data ?? const {};
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(tr(ref, 'narration_recording_desc'),
                            style: theme.textTheme.bodySmall),
                        if (!voice.hasApiKey) ...[
                          const SizedBox(height: 8),
                          Text(tr(ref, 'elevenlabs_needs_key'),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.error)),
                        ],
                        const SizedBox(height: 12),
                        Text(tr(ref, 'narration_filter_kind'),
                            style: theme.textTheme.labelLarge),
                        _chips(NarrationCategory.values, _categories,
                            _categoryLabel),
                        const SizedBox(height: 8),
                        Text(tr(ref, 'narration_filter_chapter'),
                            style: theme.textTheme.labelLarge),
                        _chips([0, 1, 2, 3, 4, 5, 6], _chapters, _chapterLabel),
                        const SizedBox(height: 8),
                        Text(tr(ref, 'narration_filter_language'),
                            style: theme.textTheme.labelLarge),
                        _chips(AppLanguage.values, _languages,
                            (l) => tr(ref, 'narration_language_${l.name}'),
                            keepOne: true),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tr(ref, 'narration_variations_title')),
                          subtitle: Text(tr(ref, 'narration_variations_desc')),
                          value: _variations,
                          onChanged: (on) => setState(() => _variations = on),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr(ref, 'narration_scenes_shown')
                                    .replaceAll('{count}', '${shown.length}'),
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() =>
                                  _selected.addAll(shown.map((n) => n.id))),
                              child: Text(tr(ref, 'narration_select_all')),
                            ),
                            TextButton(
                              onPressed: () => setState(() =>
                                  _selected.removeAll(shown.map((n) => n.id))),
                              child: Text(tr(ref, 'narration_select_none')),
                            ),
                          ],
                        ),
                        for (final node in shown)
                          _NodeTile(
                            node: node,
                            french: french,
                            chapter: _chapterLabel(narrationChapterOf(node)),
                            category: _categoryLabel(narrationCategoryOf(node)),
                            coverage: coverage[node.id],
                            selected: _selected.contains(node.id),
                            onChanged: (on) => setState(() => on
                                ? _selected.add(node.id)
                                : _selected.remove(node.id)),
                          ),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    onPressed: picked.isEmpty || !voice.hasApiKey
                        ? null
                        : () =>
                            recordNarration(context, ref, _scriptFor(picked)),
                    icon: const Icon(Icons.mic_none),
                    label: Text(tr(ref, 'narration_record_selected')
                        .replaceAll('{count}', '${picked.length}')),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.french,
    required this.chapter,
    required this.category,
    required this.coverage,
    required this.selected,
    required this.onChanged,
  });

  final StoryNode node;
  final bool french;
  final String chapter;
  final String category;
  final _Coverage? coverage;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = storyBodyFor(node.descriptionFor(french));
    final header = storyHeaderFor(node.descriptionFor(french));
    final done = coverage != null &&
        coverage!.total > 0 &&
        coverage!.recorded == coverage!.total;
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: selected,
      onChanged: (on) => onChanged(on ?? false),
      title: Text(
        '${node.id}${header != null ? ' · $header' : ''}',
        style: theme.textTheme.labelLarge,
      ),
      subtitle: Text(
        '$chapter · $category\n$body',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      secondary: coverage == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(done ? Icons.mic : Icons.mic_none,
                    color: done ? theme.colorScheme.primary : null),
                Text('${coverage!.recorded}/${coverage!.total}',
                    style: theme.textTheme.labelSmall),
              ],
            ),
    );
  }
}

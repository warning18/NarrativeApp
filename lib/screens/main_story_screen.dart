import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_spine.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/story_providers.dart';
import 'story_node_editor_screen.dart';

/// The main quest line: each chapter's fixed story beats, pulled live from
/// the narrative data. Tap a node id to edit its text and choices directly;
/// changes are saved as a local override on top of the bundled story.
class MainStoryScreen extends ConsumerWidget {
  const MainStoryScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final language = ref.read(appLanguageProvider);
    String t(String key) => trFor(language, key);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('reset_story')),
        content: Text(t('reset_story_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('reset')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await resetStoryToDefaults(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDataProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'main_story_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: tr(ref, 'reset_story'),
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: storyAsync.when(
        data: (story) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final spine in chapterSpines) ...[
              Text(
                '${tr(ref, 'chapter_label')} ${spine.chapter}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < spine.beats.length; i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(child: Text('${i + 1}')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: spine.beats[i].map((id) {
                                  final node = story.nodeFor(id);
                                  return ActionChip(
                                    avatar: const Icon(Icons.edit, size: 16),
                                    label: Text(id),
                                    onPressed: node == null
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => StoryNodeEditorScreen(node: node),
                                              ),
                                            );
                                          },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                spine.beats[i]
                                    .map((id) =>
                                        story.nodeFor(id)?.description ?? tr(ref, 'missing_node_label'))
                                    .join('\n'),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${tr(ref, 'failed_to_load_story')}: $error')),
      ),
    );
  }
}

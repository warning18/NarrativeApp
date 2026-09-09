import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_spine.dart';
import '../providers/story_providers.dart';

/// Read-only view of the main quest line: each chapter's fixed story beats,
/// pulled live from the narrative data. The beats themselves are authored
/// in the Story / AI Generator tabs; this just surfaces the spine as data,
/// consistent with the rest of the Data tab.
class MainStoryScreen extends ConsumerWidget {
  const MainStoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Main Story')),
      body: storyAsync.when(
        data: (story) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final spine in chapterSpines) ...[
              Text('Chapter ${spine.chapter}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (var i = 0; i < spine.beats.length; i++)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(spine.beats[i].join(' / ')),
                    subtitle: Text(
                      spine.beats[i]
                          .map((id) => story.nodeFor(id)?.description ?? '(missing node)')
                          .join('\n'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load story: $error')),
      ),
    );
  }
}

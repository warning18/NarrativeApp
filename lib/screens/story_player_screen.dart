import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/story_repository.dart';
import '../providers/story_providers.dart';

class StoryPlayerScreen extends ConsumerWidget {
  const StoryPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDataProvider);

    return storyAsync.when(
      data: (story) => _StoryView(story: story),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load story: $error'),
        ),
      ),
    );
  }
}

class _StoryView extends ConsumerWidget {
  const _StoryView({required this.story});

  final StoryData story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playState = ref.watch(storyPlayProvider);
    final notifier = ref.read(storyPlayProvider.notifier);
    final node = story.nodeFor(playState.currentNodeId);

    if (node == null) {
      return _EndingView(
        title: 'The trail goes cold',
        message: 'This path leads nowhere in the current story data.',
        onRestart: () => notifier.restart(StoryRepository.startNodeId),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (playState.history.isNotEmpty)
                  TextButton.icon(
                    onPressed: notifier.goBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                const Spacer(),
                Text(
                  'Node ${node.id}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  node.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (node.choices.isEmpty)
              _EndingView(
                title: 'The End',
                message: 'You have reached the end of this branch.',
                onRestart: () => notifier.restart(StoryRepository.startNodeId),
              )
            else
              ...node.choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      if (choice.isEnding) {
                        notifier.restart(StoryRepository.startNodeId);
                      } else {
                        notifier.choose(choice.nextId);
                      }
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(choice.text),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EndingView extends StatelessWidget {
  const _EndingView({
    required this.title,
    required this.message,
    required this.onRestart,
  });

  final String title;
  final String message;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRestart,
              child: const Text('Restart Story'),
            ),
          ],
        ),
      ),
    );
  }
}

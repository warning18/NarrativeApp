import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

import '../data/story_repository.dart';
import '../providers/story_providers.dart';

class StoryGraphScreen extends ConsumerWidget {
  const StoryGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDataProvider);

    return storyAsync.when(
      data: (story) => _GraphView(story: story),
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

class _GraphView extends ConsumerWidget {
  const _GraphView({required this.story});

  final StoryData story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = Graph()..isTree = false;
    final nodesById = <String, Node>{
      for (final id in story.nodes.keys) id: Node.Id(id),
    };

    for (final entry in story.nodes.entries) {
      final fromNode = nodesById[entry.key]!;
      for (final choice in entry.value.choices) {
        if (choice.isEnding) continue;
        final toNode = nodesById[choice.nextId];
        if (toNode != null) {
          graph.addEdge(fromNode, toNode);
        }
      }
    }

    if (graph.nodes.isEmpty) {
      for (final node in nodesById.values) {
        graph.addNode(node);
      }
    }

    final configuration = SugiyamaConfiguration()
      ..nodeSeparation = 24
      ..levelSeparation = 48
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;

    final playState = ref.watch(storyPlayProvider);
    final notifier = ref.read(storyPlayProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.1,
      maxScale: 3,
      child: GraphView(
        graph: graph,
        algorithm: SugiyamaAlgorithm(configuration),
        paint: Paint()
          ..color = colorScheme.outline
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final id = node.key!.value as String;
          final isCurrent = id == playState.currentNodeId;
          return GestureDetector(
            onTap: () => notifier.jumpTo(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Text(
                id,
                style: TextStyle(
                  color: isCurrent ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

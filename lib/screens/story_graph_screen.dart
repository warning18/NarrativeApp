import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

import '../data/chapter_spine.dart';
import '../data/story_repository.dart';
import '../models/story_node.dart';
import '../providers/story_providers.dart';

enum _NodeKind { characterCreation, combat, shop, quest, generic }

class _NodeStyle {
  const _NodeStyle({required this.color, required this.icon, required this.label, required this.radius});
  final Color color;
  final IconData icon;
  final String label;
  final double radius;
}

_NodeKind _classify(StoryNode node) {
  if (node.choices.any((c) => c.opensCharacterCreation)) return _NodeKind.characterCreation;
  if (node.choices.any((c) => c.triggersCombat)) return _NodeKind.combat;
  if (node.choices.any((c) => (c.unlockShopId ?? '').isNotEmpty)) return _NodeKind.shop;
  if (node.choices.any((c) => (c.unlockQuestId ?? '').isNotEmpty)) return _NodeKind.quest;
  return _NodeKind.generic;
}

Map<_NodeKind, _NodeStyle> _styles(ColorScheme colorScheme) => {
      _NodeKind.characterCreation: _NodeStyle(
        color: Colors.purple.shade300,
        icon: Icons.person,
        label: 'Character Creation',
        radius: 8,
      ),
      _NodeKind.combat: _NodeStyle(
        color: Colors.red.shade300,
        icon: Icons.sports_martial_arts,
        label: 'Combat',
        radius: 2,
      ),
      _NodeKind.shop: _NodeStyle(
        color: Colors.green.shade300,
        icon: Icons.storefront,
        label: 'Shop',
        radius: 20,
      ),
      _NodeKind.quest: _NodeStyle(
        color: Colors.amber.shade300,
        icon: Icons.assignment,
        label: 'Quest',
        radius: 8,
      ),
      _NodeKind.generic: _NodeStyle(
        color: colorScheme.surfaceContainerHighest,
        icon: Icons.circle_outlined,
        label: 'Generic',
        radius: 8,
      ),
    };

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
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

    final playState = ref.watch(storyPlayProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final styles = _styles(colorScheme);

    return Stack(
      children: [
        InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.1,
          maxScale: 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 200),
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
                final storyNode = story.nodeFor(id);
                final kind = storyNode != null ? _classify(storyNode) : _NodeKind.generic;
                final style = styles[kind]!;
                final isMainBeat = isMainBeatNode(id);

                return GestureDetector(
                  onTap: () {
                    if (storyNode != null) {
                      _showNodeInfo(context, ref, storyNode, style);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? colorScheme.primary : style.color,
                      borderRadius: BorderRadius.circular(style.radius),
                      border: Border.all(
                        color: isMainBeat ? colorScheme.primary : colorScheme.outline,
                        width: isMainBeat ? 3 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: 14,
                          color: isCurrent ? colorScheme.onPrimary : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          id,
                          style: TextStyle(
                            color: isCurrent ? colorScheme.onPrimary : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: _Legend(styles: styles, colorScheme: colorScheme),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.styles, required this.colorScheme});

  final Map<_NodeKind, _NodeStyle> styles;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Legend', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            ...styles.values.map(
              (style) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: style.color,
                        borderRadius: BorderRadius.circular(style.radius / 2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(style.label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.primary, width: 3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text('Main Story Beat', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showNodeInfo(
  BuildContext context,
  WidgetRef ref,
  StoryNode node,
  _NodeStyle style,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (innerContext, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    Icon(style.icon, size: 18),
                    const SizedBox(width: 6),
                    Text('Node ${node.id}', style: Theme.of(innerContext).textTheme.titleLarge),
                    const SizedBox(width: 8),
                    if (isMainBeatNode(node.id))
                      const Chip(label: Text('Main Beat'), visualDensity: VisualDensity.compact),
                  ],
                ),
                if (node.hasRequirements) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Requires: '
                    '${node.reqGold > 0 ? "${node.reqGold}g " : ""}'
                    '${node.reqAlignmentScore != null ? "align>=${node.reqAlignmentScore} " : ""}'
                    '${node.reqFlags.isNotEmpty ? node.reqFlags.join(", ") : ""}',
                    style: Theme.of(innerContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Text(node.description),
                const SizedBox(height: 16),
                Text('Choices', style: Theme.of(innerContext).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (node.choices.isEmpty)
                  const Text('(none — this is an ending)')
                else
                  ...node.choices.map(
                    (choice) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${choice.text} → ${choice.isEnding ? "End" : choice.nextId}',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(storyPlayProvider.notifier).jumpTo(node.id);
                    Navigator.of(sheetContext).pop();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Jump to this node'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

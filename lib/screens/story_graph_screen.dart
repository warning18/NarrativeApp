import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

import '../data/chapter_spine.dart';
import '../data/story_repository.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/story_providers.dart';

enum _NodeKind { characterCreation, combat, shop, quest, generic }

class _NodeStyle {
  const _NodeStyle({required this.color, required this.icon, required this.radius});
  final Color color;
  final IconData icon;
  final double radius;
}

_NodeKind _classify(StoryNode node) {
  if (node.choices.any((c) => c.opensCharacterCreation)) return _NodeKind.characterCreation;
  if (node.choices.any((c) => c.triggersCombat)) return _NodeKind.combat;
  if (node.choices.any((c) => (c.unlockShopId ?? '').isNotEmpty)) return _NodeKind.shop;
  if (node.choices.any((c) => (c.unlockQuestId ?? '').isNotEmpty)) return _NodeKind.quest;
  return _NodeKind.generic;
}

String _nodeKindLabelKey(_NodeKind kind) {
  switch (kind) {
    case _NodeKind.characterCreation:
      return 'node_kind_character_creation';
    case _NodeKind.combat:
      return 'node_kind_combat';
    case _NodeKind.shop:
      return 'node_kind_shop';
    case _NodeKind.quest:
      return 'node_kind_quest';
    case _NodeKind.generic:
      return 'node_kind_generic';
  }
}

Map<_NodeKind, _NodeStyle> _styles(ColorScheme colorScheme) => {
      _NodeKind.characterCreation: _NodeStyle(
        color: Colors.purple.shade300,
        icon: Icons.person,
        radius: 8,
      ),
      _NodeKind.combat: _NodeStyle(
        color: Colors.red.shade300,
        icon: Icons.sports_martial_arts,
        radius: 2,
      ),
      _NodeKind.shop: _NodeStyle(
        color: Colors.green.shade300,
        icon: Icons.storefront,
        radius: 20,
      ),
      _NodeKind.quest: _NodeStyle(
        color: Colors.amber.shade300,
        icon: Icons.assignment,
        radius: 8,
      ),
      _NodeKind.generic: _NodeStyle(
        color: colorScheme.surfaceContainerHighest,
        icon: Icons.circle_outlined,
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

class _GraphView extends ConsumerStatefulWidget {
  const _GraphView({required this.story});

  final StoryData story;

  @override
  ConsumerState<_GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends ConsumerState<_GraphView> {
  final TransformationController _transformationController = TransformationController();
  static const double _panStep = 140;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _pan(double dx, double dy) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final matrix = _transformationController.value.clone()..translate(dx / scale, dy / scale);
    _transformationController.value = matrix;
  }

  void _panUp() => _pan(0, _panStep);

  void _panDown() => _pan(0, -_panStep);

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
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
          transformationController: _transformationController,
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
          child: _Legend(styles: styles),
        ),
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PanButton(icon: Icons.keyboard_arrow_up, tooltip: tr(ref, 'pan_up'), onStep: _panUp),
              const SizedBox(height: 10),
              _PanButton(
                icon: Icons.keyboard_arrow_down,
                tooltip: tr(ref, 'pan_down'),
                onStep: _panDown,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanButton extends StatefulWidget {
  const _PanButton({required this.icon, required this.tooltip, required this.onStep});

  final IconData icon;
  final String tooltip;
  final VoidCallback onStep;

  @override
  State<_PanButton> createState() => _PanButtonState();
}

class _PanButtonState extends State<_PanButton> {
  Timer? _repeatTimer;

  void _start() {
    widget.onStep();
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 90), (_) => widget.onStep());
  }

  void _stop() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: const CircleBorder(),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(widget.icon),
          ),
        ),
      ),
    );
  }
}

class _Legend extends ConsumerWidget {
  const _Legend({required this.styles});

  final Map<_NodeKind, _NodeStyle> styles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(ref, 'legend_title'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            ...styles.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: entry.value.color,
                        borderRadius: BorderRadius.circular(entry.value.radius / 2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr(ref, _nodeKindLabelKey(entry.key)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                Text(tr(ref, 'main_story_beat'), style: Theme.of(context).textTheme.bodySmall),
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
  final language = ref.read(appLanguageProvider);
  final french = language == AppLanguage.fr;
  String t(String key) => trFor(language, key);

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
                    Text(
                      '${t('node')} ${node.id}',
                      style: Theme.of(innerContext).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    if (isMainBeatNode(node.id))
                      Chip(label: Text(t('main_beat_chip')), visualDensity: VisualDensity.compact),
                  ],
                ),
                if (node.hasRequirements) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${t('requires_label')} '
                    '${node.reqGold > 0 ? "${node.reqGold}g " : ""}'
                    '${node.reqAlignmentScore != null ? "align>=${node.reqAlignmentScore} " : ""}'
                    '${node.reqFlags.isNotEmpty ? node.reqFlags.join(", ") : ""}',
                    style: Theme.of(innerContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Text(node.descriptionFor(french)),
                const SizedBox(height: 16),
                Text(t('choices_label'), style: Theme.of(innerContext).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (node.choices.isEmpty)
                  Text(t('no_choices_ending'))
                else
                  ...node.choices.map(
                    (choice) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${choice.textFor(french)} → '
                        '${choice.isEnding ? t('end_label') : choice.nextId}',
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
                  label: Text(t('jump_to_node')),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

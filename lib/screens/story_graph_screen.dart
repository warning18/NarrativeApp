import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

import '../data/autoplay_engine.dart';
import '../data/chapter_grid_layout.dart';
import '../data/chapter_spine.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/app_mode_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/home_tab_provider.dart';
import '../providers/story_providers.dart';
import '../utils/export_utils.dart';
import '../utils/story_export.dart';
import 'story_node_editor_screen.dart';

/// A node box's fixed width — capped and ellipsized (see the node
/// `builder` below) rather than left to grow with the id's length, so a
/// long id (e.g. "2015_dockside") can never spill past its column and
/// overlap the next one. Kept comfortably under [ChapterGridAlgorithm]'s
/// own `columnWidth` so there's always a visible gap for edges to route
/// through between columns.
const double _nodeBoxWidth = 150;

enum _NodeKind {
  characterCreation,
  combat,
  shop,
  quest,
  companionQuest,
  generic
}

class _NodeStyle {
  const _NodeStyle(
      {required this.color, required this.icon, required this.radius});
  final Color color;
  final IconData icon;
  final double radius;

  /// A readable text/icon color for this node, computed from [color]'s
  /// actual brightness rather than assumed — [color] is a fixed light
  /// pastel for most kinds, but the generic kind uses a theme-adaptive
  /// surface color that turns dark in dark mode, where a hardcoded dark
  /// text color would be unreadable.
  Color get onColor =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black87;
}

/// [quests] is the loaded `quests.json` table, keyed by quest id — used only
/// to tell a companion-recruit quest (one with a non-empty `rewardAllyId`)
/// apart from every other quest, so it gets its own legend entry.
_NodeKind _classify(StoryNode node, Map<String, dynamic> quests) {
  if (node.choices.any((c) => c.opensCharacterCreation)) {
    return _NodeKind.characterCreation;
  }
  if (node.choices.any((c) => c.triggersCombat)) return _NodeKind.combat;
  if (node.choices.any((c) => (c.unlockShopId ?? '').isNotEmpty)) {
    return _NodeKind.shop;
  }
  if (node.choices.any((c) {
    final questId = c.unlockQuestId ?? '';
    if (questId.isEmpty) return false;
    final quest = quests[questId] as Map<String, dynamic>?;
    return (quest?['rewardAllyId']?.toString() ?? '').isNotEmpty;
  })) {
    return _NodeKind.companionQuest;
  }
  if (node.choices.any((c) => (c.unlockQuestId ?? '').isNotEmpty)) {
    return _NodeKind.quest;
  }
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
    case _NodeKind.companionQuest:
      return 'node_kind_companion_quest';
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
      _NodeKind.companionQuest: _NodeStyle(
        color: Colors.teal.shade300,
        icon: Icons.groups,
        radius: 8,
      ),
      _NodeKind.generic: _NodeStyle(
        color: colorScheme.surfaceContainerHighest,
        icon: Icons.circle_outlined,
        radius: 8,
      ),
    };

/// Places every node on the fixed grid [slots]/[bandLayout] already
/// computed, instead of letting an automatic layered-graph algorithm
/// (Sugiyama, force-directed, …) decide positions — this is what actually
/// enforces "5 nodes per column, chapters as separate bands," a constraint
/// no general-purpose layout algorithm takes as an input.
class ChapterGridAlgorithm extends Algorithm {
  ChapterGridAlgorithm({
    required this.slots,
    required this.bandLayout,
    this.columnWidth = 190,
    this.rowHeight = 72,
  });

  final Map<String, GridSlot> slots;
  final ChapterBandLayout bandLayout;
  final double columnWidth;
  final double rowHeight;

  // ArrowEdgeRenderer, not null — some GraphView internals call through
  // this unconditionally, and SugiyamaAlgorithm (what this replaces)
  // always had one set. `Algorithm.renderer` is a getter/setter pair, not
  // a plain field, so this overrides both rather than shadowing it.
  EdgeRenderer? _renderer = ArrowEdgeRenderer();

  @override
  EdgeRenderer? get renderer => _renderer;

  @override
  set renderer(EdgeRenderer? value) => _renderer = value;

  @override
  void init(Graph? graph) {}

  @override
  void setDimensions(double width, double height) {}

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null) return Size.zero;
    for (final node in graph.nodes) {
      final id = node.key!.value as String;
      final slot = slots[id];
      if (slot == null) continue;
      node.position = Offset(
        shiftX + slot.column * columnWidth,
        shiftY +
            (bandLayout.bandStartY[slot.chapter] ?? 0) +
            slot.row * rowHeight,
      );
    }
    return Size(
      shiftX + (bandLayout.maxColumn + 1) * columnWidth,
      shiftY + bandLayout.totalHeight,
    );
  }
}

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
  final Set<_NodeKind> _hiddenKinds = {};
  bool _legendVisible = true;

  void _toggleKind(_NodeKind kind) {
    setState(() {
      if (!_hiddenKinds.remove(kind)) _hiddenKinds.add(kind);
    });
  }

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

    // Each chapter lays out as its own small map — a grid capped at 5
    // nodes per column (column = hops from that chapter's opening beat),
    // stacked in vertical bands so no chapter's branching crowds another's.
    final slots = computeChapterGridSlots(story);
    // rowHeight here must match ChapterGridAlgorithm's own rowHeight below
    // -- it's what the band start-Y offsets are measured in, and a mismatch
    // would leave later chapters' bands overlapping the ones before them.
    final bandLayout = computeChapterBandLayout(slots, rowHeight: 72);

    final playState = ref.watch(storyPlayProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final styles = _styles(colorScheme);
    final quests = ref.watch(localizedDbProvider(questsSchema)).value ??
        const <String, dynamic>{};
    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;

    return Stack(
      children: [
        InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.1,
          maxScale: 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 200),
            child: Stack(
              children: [
                GraphView(
                  graph: graph,
                  algorithm: ChapterGridAlgorithm(
                      slots: slots, bandLayout: bandLayout),
                  paint: Paint()
                    ..color = colorScheme.outline
                    ..strokeWidth = 1.5
                    ..style = PaintingStyle.stroke,
                  builder: (Node node) {
                    final id = node.key!.value as String;
                    final isCurrent = id == playState.currentNodeId;
                    final storyNode = story.nodeFor(id);
                    final kind = storyNode != null
                        ? _classify(storyNode, quests)
                        : _NodeKind.generic;
                    final style = styles[kind]!;
                    final isMainBeat = isMainBeatNode(id);
                    final hidden = _hiddenKinds.contains(kind);

                    // Fog of war: outside Edit Mode, a node the player
                    // hasn't actually reached yet is shown as an
                    // unrevealed shadow -- position and connections stay
                    // visible (so the map still reads as a map), but its
                    // kind, id and description stay hidden rather than
                    // spoiling what's ahead. Edit Mode always sees
                    // everything, same as every other authoring feature
                    // gated to it.
                    final isShadowed = !isEditMode &&
                        !isCurrent &&
                        !playState.visitedNodeIds.contains(id);
                    if (isShadowed) {
                      return _NodeTapArea(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(tr(ref, 'node_not_yet_discovered')))),
                        onDoubleTap: null,
                        child: Container(
                          width: _nodeBoxWidth,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: colorScheme.outlineVariant, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.nights_stay_outlined,
                                size: 14,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '?????',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final container = Container(
                      width: _nodeBoxWidth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? colorScheme.primary : style.color,
                        borderRadius: BorderRadius.circular(style.radius),
                        border: Border.all(
                          color: isMainBeat
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: isMainBeat ? 3 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            style.icon,
                            size: 14,
                            color: isCurrent
                                ? colorScheme.onPrimary
                                : style.onColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              id,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: isCurrent
                                    ? colorScheme.onPrimary
                                    : style.onColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    // Positioned inside the node's own bounds (not
                    // overflowing via a negative offset) so this can't
                    // interfere with GraphView's own size measurement of
                    // each node.
                    final withCommentBadge = (storyNode?.hasComment ?? false)
                        ? Stack(
                            children: [
                              container,
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Icon(
                                  Icons.comment,
                                  size: 12,
                                  color: isCurrent
                                      ? colorScheme.onPrimary
                                      : style.onColor,
                                ),
                              ),
                            ],
                          )
                        : container;

                    if (hidden) {
                      return Opacity(
                          opacity: 0.18,
                          child: IgnorePointer(child: withCommentBadge));
                    }

                    // A plain GestureDetector's tap recognizer competes with
                    // InteractiveViewer's pan/scale recognizer in the gesture
                    // arena, which can eat one-finger drags that start on a
                    // node. Listener never joins the arena, so panning always
                    // wins immediately; tap is detected manually instead.
                    return _NodeTapArea(
                      onTap: () {
                        if (storyNode != null) {
                          _showNodeInfo(context, ref, storyNode, style);
                        }
                      },
                      onDoubleTap: (!isEditMode || storyNode == null)
                          ? null
                          : () {
                              ref
                                  .read(storyPlayProvider.notifier)
                                  .jumpTo(storyNode.id);
                              final messenger = ScaffoldMessenger.of(context);
                              _leaveMap(context, ref);
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text(tr(ref, 'node_activated'))),
                              );
                            },
                      child: withCommentBadge,
                    );
                  },
                ),
                for (final entry in bandLayout.bandStartY.entries)
                  Positioned(
                    left: 4,
                    top: entry.value + 4,
                    child: Text(
                      entry.key == 0
                          ? tr(ref, 'chapter_band_prologue')
                          : '${tr(ref, 'chapter_band_prefix')} ${entry.key}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: _legendVisible
              ? _Legend(
                  styles: styles,
                  hiddenKinds: _hiddenKinds,
                  onToggle: _toggleKind,
                  onClose: () => setState(() => _legendVisible = false),
                  showUndiscovered: !isEditMode,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendReopenButton(
                      onTap: () => setState(() => _legendVisible = true),
                    ),
                    if (isEditMode) ...[
                      const SizedBox(width: 12),
                      const _ExportNodesButton(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// `gameDbProvider` is a [StateNotifierProvider] (not a `FutureProvider`),
/// so it has no `.future` to await like `storyDataProvider` does — its
/// [GameDbNotifier] loads asynchronously in the background right from its
/// own construction. Polls the current [AsyncValue] until it settles,
/// rather than adding a Future-returning method to that shared provider
/// just for this one caller.
Future<Map<String, dynamic>> _awaitGameDb(
    WidgetRef ref, DbSchema schema) async {
  for (var i = 0; i < 150; i++) {
    final value = ref.read(localizedDbProvider(schema)).value;
    if (value != null) return value;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  return const {};
}

/// Runs [autoplayToNode] toward [targetNodeId], showing a busy dialog while
/// it works and a result summary once it's done.
Future<void> _runAutoplay(
  BuildContext context,
  WidgetRef ref, {
  required String targetNodeId,
}) async {
  final lang = ref.read(appLanguageProvider);
  String t(String key) => trFor(lang, key);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(t('autoplay_running')),
            ],
          ),
        ),
      ),
    ),
  );

  final story = await ref.read(storyDataProvider.future);
  final dice = await _awaitGameDb(ref, diceSchema);
  final skills = await _awaitGameDb(ref, skillsSchema);
  final items = await _awaitGameDb(ref, itemsSchema);
  final enemies = await _awaitGameDb(ref, enemiesSchema);
  final races = await _awaitGameDb(ref, racesSchema);
  final professions = await _awaitGameDb(ref, professionsSchema);
  final zones = await _awaitGameDb(ref, zonesSchema);

  final result = await autoplayToNode(
    ref,
    story: story,
    targetNodeId: targetNodeId,
    dice: dice,
    skills: skills,
    items: items,
    enemies: enemies,
    races: races,
    professions: professions,
    zones: zones,
  );

  if (!context.mounted) return;
  Navigator.of(context).pop();

  final message = switch (result.status) {
    AutoplayStatus.alreadyThere => t('autoplay_already_there'),
    AutoplayStatus.noPathFound => t('autoplay_no_path'),
    AutoplayStatus.stuckInCombat => '${t('autoplay_stuck_prefix')} '
        '${result.stuckEnemyName} (${result.stepsApplied} ${t('autoplay_steps_suffix')})',
    AutoplayStatus.reachedTarget =>
      '${t('autoplay_reached_prefix')} (${result.stepsApplied} ${t('autoplay_steps_suffix')})',
    // autoplayToNode (the only engine this function drives) never actually
    // produces this status -- only autoplayToChapter's open-ended branching
    // walk can run out of steps -- but the switch must stay exhaustive
    // against the shared AutoplayStatus enum.
    AutoplayStatus.stepCapReached => t('autoplay_step_cap_reached'),
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  if (result.stepsApplied > 0) _leaveMap(context, ref);
}

/// The story map as its own page, opened from the game's header.
class StoryMapPage extends ConsumerWidget {
  const StoryMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'title_map'))),
      body: const StoryGraphScreen(),
    );
  }
}

/// Back to the story after a jump or an autoplay from the map: the Story
/// tab, and the map page closed when the map is one.
void _leaveMap(BuildContext context, WidgetRef ref) {
  ref.read(homeTabIndexProvider.notifier).state = 0;
  if (context.findAncestorWidgetOfExactType<StoryMapPage>() != null) {
    Navigator.of(context).pop();
  }
}

/// Detects a tap (and optionally a double-tap) using raw pointer events
/// instead of a [GestureDetector], so it never competes with the enclosing
/// [InteractiveViewer] for the gesture arena — one-finger drag-to-pan
/// always starts immediately, even when the drag begins on top of a node.
class _NodeTapArea extends StatefulWidget {
  const _NodeTapArea(
      {required this.onTap, this.onDoubleTap, required this.child});

  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final Widget child;

  @override
  State<_NodeTapArea> createState() => _NodeTapAreaState();
}

class _NodeTapAreaState extends State<_NodeTapArea> {
  static const double _tapSlop = 12;
  static const Duration _tapTimeout = Duration(milliseconds: 400);
  static const Duration _doubleTapWindow = Duration(milliseconds: 300);

  Offset? _downPosition;
  DateTime? _downTime;
  Offset? _pendingTapPosition;
  Timer? _singleTapTimer;

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _downPosition = event.position;
        _downTime = DateTime.now();
      },
      onPointerUp: (event) {
        final downPosition = _downPosition;
        final downTime = _downTime;
        if (downPosition == null || downTime == null) return;
        final movedFar = (event.position - downPosition).distance > _tapSlop;
        final tookTooLong = DateTime.now().difference(downTime) > _tapTimeout;
        if (movedFar || tookTooLong) return;

        final onDoubleTap = widget.onDoubleTap;
        if (onDoubleTap == null) {
          widget.onTap();
          return;
        }

        final pending = _pendingTapPosition;
        if (pending != null &&
            (event.position - pending).distance <= _tapSlop) {
          _singleTapTimer?.cancel();
          _singleTapTimer = null;
          _pendingTapPosition = null;
          onDoubleTap();
          return;
        }

        _pendingTapPosition = event.position;
        _singleTapTimer?.cancel();
        _singleTapTimer = Timer(_doubleTapWindow, () {
          _pendingTapPosition = null;
          widget.onTap();
        });
      },
      child: widget.child,
    );
  }
}

class _LegendReopenButton extends ConsumerWidget {
  const _LegendReopenButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: tr(ref, 'show_legend'),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 3,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.info_outline),
          ),
        ),
      ),
    );
  }
}

/// Edit Mode: exports every story node, light (id, chapter, text and
/// choices, for reading or review) or full (every field in both
/// languages, in the story file's format), copied or saved to a file.
class _ExportNodesButton extends ConsumerWidget {
  const _ExportNodesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: tr(ref, 'export_nodes_title'),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 3,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _showExportSheet(context, ref),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.ios_share_outlined),
          ),
        ),
      ),
    );
  }

  Future<void> _showExportSheet(BuildContext context, WidgetRef ref) async {
    final story = await ref.read(storyDataProvider.future);
    if (!context.mounted) return;
    final french = ref.read(appLanguageProvider) == AppLanguage.fr;

    Future<String> build(bool full) async => full
        ? storyFullExport(await ref.read(storyRepositoryProvider).loadRaw())
        : storyLightExport(story, french: french);

    Future<void> copy(bool full) async {
      final text = await build(full);
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'export_nodes_copied'))),
      );
    }

    Future<void> save(bool full) async {
      final text = await build(full);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await exportTextToFile(context, ref, text,
          full ? 'story_nodes_full.json' : 'story_nodes_light.json');
    }

    Widget option(bool full) => ListTile(
          leading: Icon(full ? Icons.data_object : Icons.notes),
          title:
              Text(tr(ref, full ? 'export_nodes_full' : 'export_nodes_light')),
          subtitle: Text(tr(ref,
              full ? 'export_nodes_full_desc' : 'export_nodes_light_desc')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: tr(ref, 'copy_button'),
                onPressed: () => copy(full),
              ),
              IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: tr(ref, 'export_button'),
                onPressed: () => save(full),
              ),
            ],
          ),
        );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${tr(ref, 'export_nodes_title')} · ${story.nodes.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              option(false),
              option(true),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends ConsumerWidget {
  const _Legend({
    required this.styles,
    required this.hiddenKinds,
    required this.onToggle,
    required this.onClose,
    required this.showUndiscovered,
  });

  final Map<_NodeKind, _NodeStyle> styles;
  final Set<_NodeKind> hiddenKinds;
  final ValueChanged<_NodeKind> onToggle;
  final VoidCallback onClose;

  /// Whether the map is currently shadowing unvisited nodes (i.e. not in
  /// Edit Mode) -- shows an explanatory legend row for that shadow style
  /// only when it can actually appear on the map right now.
  final bool showUndiscovered;

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
            Row(
              children: [
                Text(tr(ref, 'legend_title'),
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(width: 12),
                InkWell(
                  onTap: onClose,
                  child: Tooltip(
                    message: tr(ref, 'close_legend'),
                    child:
                        Icon(Icons.close, size: 16, color: colorScheme.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...styles.entries.map((entry) {
              final hidden = hiddenKinds.contains(entry.key);
              return InkWell(
                onTap: () => onToggle(entry.key),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Opacity(
                    opacity: hidden ? 0.4 : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: entry.value.color,
                            borderRadius:
                                BorderRadius.circular(entry.value.radius / 2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr(ref, _nodeKindLabelKey(entry.key)),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                decoration:
                                    hidden ? TextDecoration.lineThrough : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
                Text(tr(ref, 'main_story_beat'),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (showUndiscovered) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Icon(Icons.nights_stay_outlined,
                        size: 10, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 6),
                  Text(tr(ref, 'undiscovered_node_legend'),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              tr(ref, 'tap_to_filter'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.outline),
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
  final isEditMode = ref.read(appModeProvider) == AppMode.edit;
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
                      Chip(
                          label: Text(t('main_beat_chip')),
                          visualDensity: VisualDensity.compact),
                  ],
                ),
                if (node.hasRequirements) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${t('requires_label')} '
                    '${node.reqGold > 0 ? "${node.reqGold}g " : ""}'
                    '${node.reqAlignmentScore != null ? "${t('alignment_label')}≥${node.reqAlignmentScore} " : ""}'
                    '${node.reqAlignmentMax != null ? "${t('alignment_label')}≤${node.reqAlignmentMax} " : ""}'
                    '${node.reqCharisma > 0 ? "${t('charisma_label')}≥${node.reqCharisma} " : ""}'
                    '${node.reqFlags.isNotEmpty ? node.reqFlags.join(", ") : ""}',
                    style: Theme.of(innerContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Text(node.descriptionFor(french)),
                if (node.hasComment) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(innerContext)
                          .colorScheme
                          .tertiaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.comment_outlined, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(node.authoringComment!)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(t('choices_label'),
                    style: Theme.of(innerContext).textTheme.titleMedium),
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
                if (isEditMode) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(storyPlayProvider.notifier).jumpTo(node.id);
                      Navigator.of(sheetContext).pop();
                      _leaveMap(context, ref);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(t('jump_to_node')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _runAutoplay(context, ref, targetNodeId: node.id);
                    },
                    icon: const Icon(Icons.fast_forward),
                    label: Text(t('autoplay_to_node')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoryNodeEditorScreen(node: node),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(t('edit_node')),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

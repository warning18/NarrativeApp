import 'dart:async';

import 'package:flutter/material.dart';
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
  if (node.choices.any((c) => c.opensCharacterCreation))
    return _NodeKind.characterCreation;
  if (node.choices.any((c) => c.triggersCombat)) return _NodeKind.combat;
  if (node.choices.any((c) => (c.unlockShopId ?? '').isNotEmpty))
    return _NodeKind.shop;
  if (node.choices.any((c) {
    final questId = c.unlockQuestId ?? '';
    if (questId.isEmpty) return false;
    final quest = quests[questId] as Map<String, dynamic>?;
    return (quest?['rewardAllyId']?.toString() ?? '').isNotEmpty;
  })) {
    return _NodeKind.companionQuest;
  }
  if (node.choices.any((c) => (c.unlockQuestId ?? '').isNotEmpty))
    return _NodeKind.quest;
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
    final quests = ref.watch(gameDbProvider(questsSchema)).value ??
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

                    if (hidden) {
                      return Opacity(
                          opacity: 0.18,
                          child: IgnorePointer(child: container));
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
                              ref.read(homeTabIndexProvider.notifier).state = 0;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(tr(ref, 'node_activated'))),
                              );
                            },
                      child: container,
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
          top: 12,
          child: _legendVisible
              ? _Legend(
                  styles: styles,
                  hiddenKinds: _hiddenKinds,
                  onToggle: _toggleKind,
                  onClose: () => setState(() => _legendVisible = false),
                )
              : _LegendReopenButton(
                  onTap: () => setState(() => _legendVisible = true),
                ),
        ),
        if (isEditMode)
          Positioned(
            right: 12,
            top: 12,
            child: _ChapterJumpBar(
              onJump: (nodeId) {
                ref.read(storyPlayProvider.notifier).jumpTo(nodeId);
                ref.read(homeTabIndexProvider.notifier).state = 0;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr(ref, 'node_activated'))),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// The target a chapter-jump chip lands on — jumping ahead this way is
/// inherently approximate about which branch state you'd actually have
/// earned by then (see [firstNodeIdForChapter]).
String? _firstNodeIdForChapter(int chapter) =>
    firstNodeIdForChapter(chapter, prologueNodeId: StoryRepository.startNodeId);

/// A small "jump ahead" panel for testing/browsing: one chip per chapter,
/// each landing on that chapter's opening beat via the same
/// [StoryPlayNotifier.jumpTo] the map's per-node double-tap already uses.
/// Complements that (undiscoverable, one node at a time) gesture with a
/// visible, chapter-granularity shortcut.
class _ChapterJumpBar extends ConsumerWidget {
  const _ChapterJumpBar({required this.onJump});

  final ValueChanged<String> onJump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxChapter = chapterSpines.isEmpty
        ? 0
        : chapterSpines.map((s) => s.chapter).reduce((a, b) => a > b ? a : b);
    final chapterEntries = <MapEntry<int, String>>[
      for (var chapter = 0; chapter <= maxChapter; chapter++)
        if (_firstNodeIdForChapter(chapter) != null)
          MapEntry(chapter, _firstNodeIdForChapter(chapter)!),
    ];
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(ref, 'jump_to_chapter_title'),
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in chapterEntries)
                  ActionChip(
                    label: Text(entry.key == 0
                        ? tr(ref, 'chapter_band_prologue')
                        : '${entry.key}'),
                    onPressed: () => onJump(entry.value),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () =>
                  _showAutoplayChapterPicker(context, ref, chapterEntries),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              icon: const Icon(Icons.fast_forward, size: 16),
              label: Text(tr(ref, 'autoplay_to_chapter_button')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the player pick a chapter to [_runAutoplay] toward — a real-state
/// counterpart to the quick preview jump chips above, which just move the
/// displayed node without earning anything along the way.
Future<void> _showAutoplayChapterPicker(
  BuildContext context,
  WidgetRef ref,
  List<MapEntry<int, String>> chapterEntries,
) async {
  final lang = ref.read(appLanguageProvider);
  String t(String key) => trFor(lang, key);
  final target = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t('autoplay_to_chapter_title')),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in chapterEntries)
              ListTile(
                title: Text(
                  entry.key == 0
                      ? t('chapter_band_prologue')
                      : '${t('chapter_band_prefix')} ${entry.key}',
                ),
                onTap: () => Navigator.of(dialogContext).pop(entry.value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(t('close_button')),
        ),
      ],
    ),
  );
  if (target == null || !context.mounted) return;
  await _runAutoplay(context, ref, targetNodeId: target);
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
    final value = ref.read(gameDbProvider(schema)).value;
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

  final result = await autoplayToNode(
    ref,
    story: story,
    targetNodeId: targetNodeId,
    dice: dice,
    skills: skills,
    items: items,
    enemies: enemies,
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
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

class _Legend extends ConsumerWidget {
  const _Legend({
    required this.styles,
    required this.hiddenKinds,
    required this.onToggle,
    required this.onClose,
  });

  final Map<_NodeKind, _NodeStyle> styles;
  final Set<_NodeKind> hiddenKinds;
  final ValueChanged<_NodeKind> onToggle;
  final VoidCallback onClose;

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
                    '${node.reqFlags.isNotEmpty ? node.reqFlags.join(", ") : ""}',
                    style: Theme.of(innerContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Text(node.descriptionFor(french)),
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
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

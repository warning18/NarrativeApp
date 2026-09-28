import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/encounter_text.dart';
import '../data/journey_map.dart';
import '../data/map_charts.dart' show ChartPalette;
import '../data/narration_tokens.dart';
import '../data/story_repository.dart';
import '../data/world_map.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/aftermath_provider.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';
import '../widgets/player_stats_bar.dart';
import 'journal_screen.dart';
import 'story_player_screen.dart'
    show composeNarration, isStoryChoiceLocked, takeStoryChoice;

/// The Journey tab's index among the play-mode tabs (after Story,
/// Character, Camp and Other, so theirs stay as they were).
const int journeyTabIndex = 4;

/// The Journey tab: the story and the map in one. The scene the story is
/// on reads at the top; under it a chart of the road, with the places
/// already passed below, the party where it stands, and each way on
/// ahead as a step on the map. Tapping a step says what it holds; Go (or
/// a second tap) takes it, exactly as its choice under the story would.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(storyDataProvider).when(
          data: (story) => _JourneyView(story: story),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${tr(ref, 'failed_to_load_story')}: $error'),
            ),
          ),
        );
  }
}

/// One way on from the scene, as the map shows it.
class _Step {
  const _Step({
    required this.choice,
    required this.kind,
    required this.slot,
    required this.label,
    required this.locked,
    required this.leadsTo,
    required this.onward,
  });

  final StoryChoice choice;
  final JourneyStepKind kind;
  final JourneySlot slot;

  /// The choice's text, or why it is shut while it is.
  final String label;
  final bool locked;

  /// The place the step reaches, when it is not where the party stands.
  final String? leadsTo;

  /// How many ways on the step's own scene has (drawn as faint forks).
  final int onward;
}

class _JourneyView extends ConsumerStatefulWidget {
  const _JourneyView({required this.story});

  final StoryData story;

  @override
  ConsumerState<_JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends ConsumerState<_JourneyView> {
  /// The scene the selection belongs to; a new scene clears it.
  String? _sceneKey;
  int? _selected;
  bool _busy = false;

  /// The scene folded to its first lines (kept from scene to scene).
  bool _sceneFolded = false;

  Future<void> _take(_Step step) async {
    if (_busy || step.locked) return;
    setState(() => _busy = true);
    try {
      await takeStoryChoice(context, ref, step.choice);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tap(int index, _Step step) {
    if (_selected == index && !step.locked) {
      _take(step);
      return;
    }
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final play = ref.watch(storyPlayProvider);
    final session = ref.watch(playerSessionProvider);
    final language = ref.watch(appLanguageProvider);
    final french = language == AppLanguage.fr;
    final palette = ChartPalette.of(ref.watch(mapLookProvider));
    final look = ref.watch(mapLookProvider);
    final node = play.activeExcursionNode ?? story.nodeFor(play.currentNodeId);

    final sceneKey = '${node?.id}_${play.isInExcursion}_${play.history.length}';
    if (sceneKey != _sceneKey) {
      _sceneKey = sceneKey;
      _selected = null;
    }

    final tools = [
      IconButton(
        icon: const Icon(Icons.menu_book_outlined, size: 20),
        tooltip: tr(ref, 'journal_title'),
        visualDensity: VisualDensity.compact,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JournalScreen()),
        ),
      ),
    ];

    if (node == null) {
      return _EndedPanel(
        title: tr(ref, 'trail_cold_title'),
        message: tr(ref, 'trail_cold_message'),
      );
    }

    // Where the party stands, and the places passed on the way here.
    final hereLandmark =
        play.isInExcursion ? null : landmarkOfScene(play.currentNodeId);
    final standing =
        currentLandmark(play.currentNodeId, play.history) ?? hereLandmark;
    final hereName = play.isInExcursion
        ? tr(ref, 'detour')
        : node.settlement?.nameFor(french) ?? standing?.name(language) ?? '';
    var passed = journeyOf(play.history, play.currentNodeId);
    if (passed.isNotEmpty &&
        hereLandmark != null &&
        passed.last.id == hereLandmark.id) {
      passed = passed.sublist(0, passed.length - 1);
    }
    final trail = [
      for (final landmark in passed.reversed.take(2)) landmark.name(language),
    ];

    final choices =
        node.choices.where((c) => !c.isHiddenFor(session.flags)).toList();
    final ended = choices.isEmpty || isStoryEnding(node);
    final mainQuestOpen =
        ref.watch(chapterProgressProvider)?.mainQuestOpen ?? true;
    final slots = journeySlots(choices.length);
    final steps = [
      for (var i = 0; i < choices.length; i++)
        () {
          final choice = choices[i];
          final shut =
              choice.mainQuest && !play.isInExcursion && !mainQuestOpen;
          final locked = shut ||
              (!play.isInExcursion &&
                  isStoryChoiceLocked(choice, story, session));
          final lockedText = shut
              ? tr(ref, 'main_quest_shut_lock')
              : locked
                  ? choice.lockedTextFor(french)
                  : null;
          final target = play.isInExcursion || choice.isEnding
              ? null
              : landmarkOfScene(choice.nextId);
          return _Step(
            choice: choice,
            kind: journeyStepKindOf(choice),
            slot: slots[i],
            label: (lockedText?.isNotEmpty ?? false)
                ? lockedText!
                : choice.textFor(french),
            locked: locked,
            leadsTo: target != null && target.id != standing?.id
                ? target.name(language)
                : null,
            onward: play.isInExcursion || choice.isEnding
                ? 0
                : story.nodeFor(choice.nextId)?.choices.length ?? 0,
          );
        }(),
    ];
    final selected = _selected != null && _selected! < steps.length
        ? steps[_selected!]
        : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlayerStatsBar(trailing: tools),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(builder: (context, area) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: math.max(96, area.maxHeight * 0.32)),
                      child: _ScenePanel(
                        key: ValueKey('journey_scene_$sceneKey'),
                        node: node,
                        french: french,
                        folded: _sceneFolded,
                        onFold: (folded) =>
                            setState(() => _sceneFolded = folded),
                        detour: !play.isInExcursion
                            ? null
                            : [
                                switch (play.excursionOriginFor(french)) {
                                  null => tr(ref, 'detour'),
                                  final origin =>
                                    '${tr(ref, 'detour_on_the_way')} “$origin”',
                                },
                                if (node.contextNoteFor(french)
                                    case final note?)
                                  note,
                              ].join(' '),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ended
                          ? _EndedPanel(
                              title: tr(ref, 'the_end'),
                              message: tr(ref, 'journey_ended'),
                            )
                          : _JourneyChart(
                              key: ValueKey('journey_chart_$sceneKey'),
                              steps: steps,
                              selected: _selected,
                              hereName: hereName,
                              youAreHere: tr(ref, 'journey_you_are_here'),
                              leadsTo: tr(ref, 'journey_leads_to'),
                              trail: trail,
                              palette: palette,
                              ink: look == MapLook.parchment
                                  ? InkColors.light
                                  : InkColors.dark,
                              greyed: look == MapLook.shroud,
                              onTap: _tap,
                            ),
                    ),
                    if (!ended) ...[
                      const SizedBox(height: 10),
                      _StepDetail(
                        step: selected,
                        busy: _busy,
                        french: french,
                        isExcursion: play.isInExcursion,
                        onGo: selected == null ? null : () => _take(selected),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scene the story is on, as the Story tab tells it: what the last
/// fight or roll left behind, who speaks, and the scene itself.
class _ScenePanel extends ConsumerWidget {
  const _ScenePanel({
    super.key,
    required this.node,
    required this.french,
    required this.folded,
    required this.onFold,
    this.detour,
  });

  final StoryNode node;
  final bool french;

  /// Folded to its first lines, to leave the map the room.
  final bool folded;
  final ValueChanged<bool> onFold;

  /// On a detour: what it is met on the way to, and why.
  final String? detour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final session = ref.watch(playerSessionProvider);
    final aftermath = ref.watch(pendingAftermathProvider);
    final outcome = ref.watch(pendingCheckOutcomeProvider);
    final speaker = speakerLabelFor(node.speaker, french: french);
    final text = composeNarration(node, session, french: french);
    final prose = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: InkFonts.prose,
      fontSize: 15,
      height: 1.45,
    );
    final aside = prose?.copyWith(
      fontStyle: FontStyle.italic,
      color: ink.ash,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          if (folded)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onFold(false),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 80, 12),
                child: Text(
                  [
                    if (detour != null && detour!.isNotEmpty) detour!,
                    text,
                  ].join(' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: prose,
                ),
              ),
            )
          else
            Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 40, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detour != null && detour!.isNotEmpty) ...[
                      Text(detour!, style: aside),
                      const SizedBox(height: 8),
                    ],
                    if (aftermath != null && aftermath.isNotEmpty) ...[
                      Text(aftermath, style: aside),
                      const SizedBox(height: 8),
                    ],
                    if (outcome != null && outcome.isNotEmpty) ...[
                      Text(outcome, style: aside),
                      const SizedBox(height: 8),
                    ],
                    if (speaker != null) ...[
                      Text(
                        speaker.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: InkFonts.system,
                          letterSpacing: 1.2,
                          color: ink.gold,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(text, style: prose),
                  ],
                ),
              ),
            ),
          // The whole scene, with its read-aloud and the companion, is a
          // tap away in the Story tab.
          Positioned(
            top: 2,
            right: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (folded)
                  IconButton(
                    key: const ValueKey('journey_scene_unfold'),
                    icon: const Icon(Icons.expand_more, size: 20),
                    tooltip: tr(ref, 'hub_story_unfold'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onFold(false),
                  ),
                IconButton(
                  icon: const Icon(Icons.chrome_reader_mode_outlined, size: 18),
                  tooltip: tr(ref, 'journey_read_in_story'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      ref.read(homeTabIndexProvider.notifier).state = 0,
                ),
              ],
            ),
          ),
          if (!folded)
            Positioned(
              bottom: 2,
              right: 2,
              child: IconButton(
                key: const ValueKey('journey_scene_fold'),
                icon: const Icon(Icons.expand_less, size: 20),
                tooltip: tr(ref, 'hub_story_fold'),
                visualDensity: VisualDensity.compact,
                onPressed: () => onFold(true),
              ),
            ),
        ],
      ),
    );
  }
}

/// No way on from here on the map: the Story tab has the ending, New
/// Game+ and the way back to the beginning.
class _EndedPanel extends ConsumerWidget {
  const _EndedPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontFamily: InkFonts.display)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () =>
                  ref.read(homeTabIndexProvider.notifier).state = 0,
              icon: const Icon(Icons.menu_book),
              label: Text(tr(ref, 'journey_open_story')),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(JourneyStepKind kind) => switch (kind) {
      JourneyStepKind.ending => Icons.auto_stories_outlined,
      JourneyStepKind.mainQuest => Icons.flag_outlined,
      JourneyStepKind.expedition => Icons.explore_outlined,
      JourneyStepKind.fight => Icons.sports_martial_arts,
      JourneyStepKind.challenge => Icons.casino,
      JourneyStepKind.check => Icons.casino_outlined,
      JourneyStepKind.shop => Icons.storefront_outlined,
      JourneyStepKind.quest => Icons.chat_bubble_outline,
      JourneyStepKind.travel => Icons.sailing_outlined,
      JourneyStepKind.rest => Icons.bedtime_outlined,
      JourneyStepKind.road => Icons.signpost_outlined,
    };

String _kindKey(JourneyStepKind kind) => 'journey_kind_${kind.name}';

/// The colour a step of [kind] is drawn in: danger in blood and ember,
/// rolls and voyages in tide, what a place offers in gold. The Shroud
/// look keeps colour for the Void alone, and the main quest's mark.
Color _colorFor(JourneyStepKind kind, InkColors ink, ChartPalette palette,
    {required bool greyed}) {
  if (greyed) {
    return switch (kind) {
      JourneyStepKind.ending => palette.voidColor,
      JourneyStepKind.mainQuest => palette.mark,
      _ => palette.place,
    };
  }
  return switch (kind) {
    JourneyStepKind.ending => ink.voidColor,
    JourneyStepKind.mainQuest => palette.mark,
    JourneyStepKind.expedition => ink.ember,
    JourneyStepKind.fight => ink.blood,
    JourneyStepKind.challenge || JourneyStepKind.check => ink.tide,
    JourneyStepKind.shop || JourneyStepKind.quest => ink.gold,
    JourneyStepKind.travel => ink.tide,
    JourneyStepKind.rest => ink.heal,
    JourneyStepKind.road => palette.place,
  };
}

/// The chart: the road ahead fanning out from where the party stands, one
/// step per way on. Many ways on (a town) stack in rows up the map, which
/// scrolls; it opens on the party.
class _JourneyChart extends StatelessWidget {
  const _JourneyChart({
    super.key,
    required this.steps,
    required this.selected,
    required this.hereName,
    required this.youAreHere,
    required this.leadsTo,
    required this.trail,
    required this.palette,
    required this.ink,
    required this.greyed,
    required this.onTap,
  });

  final List<_Step> steps;
  final int? selected;
  final String hereName;

  /// "You are here", over [hereName].
  final String youAreHere;

  /// "To {place}", under a step that leads somewhere else.
  final String leadsTo;

  /// The places passed, the latest first.
  final List<String> trail;
  final ChartPalette palette;
  final InkColors ink;
  final bool greyed;
  final void Function(int index, _Step step) onTap;

  static const double _stepRadius = 22;
  static const double _hereRadius = 26;
  static const double _top = 40;
  static const double _rowMin = 136;
  static const double _rowMax = 190;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: palette.land,
        child: LayoutBuilder(builder: (context, box) {
          final width = box.maxWidth;
          final rowSizes = journeyRowSizes(steps.length);
          final rows = rowSizes.length;
          final trailHeight = 20.0 + trail.length * 30.0;
          final needed = _top + rows * _rowMin + _hereRadius * 2 + trailHeight;
          final height = math.max(box.maxHeight, needed);
          final hereY = height - trailHeight - _hereRadius;
          final here = Offset(width / 2, hereY);
          final rowGap = rows == 0
              ? 0.0
              : ((hereY - _top - _stepRadius) / rows).clamp(_rowMin, _rowMax);
          Offset centreOf(_Step step) =>
              Offset(step.slot.x * width, hereY - rowGap * (step.slot.row + 1));
          double labelWidth(_Step step) {
            final n = rowSizes[step.slot.row];
            return n == 1
                ? math.min(width * 0.7, 240)
                : math.min(width / (n + 1) - 6, 180);
          }

          final placeStyle = TextStyle(
            fontFamily: InkFonts.prose,
            fontSize: 12.5,
            height: 1.25,
            color: palette.place,
          );
          final noteStyle = TextStyle(
            fontFamily: InkFonts.system,
            fontSize: 11,
            height: 1.2,
            color: palette.label,
          );

          return SingleChildScrollView(
            reverse: true,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _JourneyPainter(
                        palette: palette,
                        here: here,
                        hereRadius: _hereRadius,
                        stepRadius: _stepRadius,
                        steps: [
                          for (var i = 0; i < steps.length; i++)
                            (
                              centre: centreOf(steps[i]),
                              row: steps[i].slot.row,
                              locked: steps[i].locked,
                              selected: selected == i,
                              onward: steps[i].onward,
                            ),
                        ],
                        trail: trail.length,
                      ),
                    ),
                  ),
                  // The party, where the story stands.
                  Positioned(
                    left: here.dx - _hereRadius,
                    top: here.dy - _hereRadius,
                    child: Container(
                      width: _hereRadius * 2,
                      height: _hereRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.mark,
                        border: Border.all(color: palette.land, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: palette.mark.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child:
                          Icon(Icons.person_pin, color: palette.land, size: 26),
                    ),
                  ),
                  Positioned(
                    left: here.dx + _hereRadius + 10,
                    width: math.max(0, width / 2 - _hereRadius - 16),
                    top: here.dy - 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          youAreHere.toUpperCase(),
                          style: noteStyle.copyWith(
                              fontSize: 10, letterSpacing: 1.2),
                        ),
                        Text(
                          hereName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InkFonts.display,
                            fontSize: 16,
                            height: 1.1,
                            color: palette.place,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The places passed, down the road behind.
                  for (var i = 0; i < trail.length; i++)
                    Positioned(
                      left: width / 2 + 14,
                      top: hereY + _hereRadius + 12 + i * 30,
                      width: math.max(0, width / 2 - 20),
                      child: Text(
                        trail[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: noteStyle.copyWith(
                            color: palette.place
                                .withValues(alpha: i == 0 ? 0.75 : 0.5)),
                      ),
                    ),
                  // The ways on.
                  for (var i = 0; i < steps.length; i++)
                    () {
                      final step = steps[i];
                      final centre = centreOf(step);
                      final w = labelWidth(step);
                      final left = (centre.dx - w / 2)
                          .clamp(4.0, math.max(4.0, width - w - 4))
                          .toDouble();
                      final colour = step.locked
                          ? palette.label
                          : _colorFor(step.kind, ink, palette, greyed: greyed);
                      final isSelected = selected == i;
                      return Positioned(
                        left: left,
                        top: centre.dy - _stepRadius,
                        width: w,
                        child: Semantics(
                          button: true,
                          selected: isSelected,
                          label: step.label,
                          child: GestureDetector(
                            key: ValueKey('journey_step_$i'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(i, step),
                            child: Column(
                              children: [
                                Transform.translate(
                                  offset: Offset(centre.dx - left - w / 2, 0),
                                  child: AnimatedScale(
                                    scale: isSelected ? 1.15 : 1,
                                    duration: const Duration(milliseconds: 160),
                                    child: Container(
                                      width: _stepRadius * 2,
                                      height: _stepRadius * 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            isSelected ? colour : palette.land,
                                        border: Border.all(
                                          color: colour,
                                          width: isSelected ? 3 : 2,
                                        ),
                                      ),
                                      child: Icon(
                                        step.locked
                                            ? Icons.lock_outline
                                            : _iconFor(step.kind),
                                        size: 20,
                                        color:
                                            isSelected ? palette.land : colour,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // A plaque under the words: the roads to
                                // the far steps pass beneath it.
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: palette.land.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3, vertical: 1),
                                    child: Column(
                                      children: [
                                        Text(
                                          step.label,
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: placeStyle.copyWith(
                                            color: palette.place.withValues(
                                                alpha: step.locked ? 0.55 : 1),
                                            fontWeight: isSelected
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                          ),
                                        ),
                                        if (step.leadsTo != null)
                                          Text(
                                            leadsTo.replaceAll(
                                                '{place}', step.leadsTo!),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: noteStyle,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }(),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The chart under the steps: a faint grid, the fog over what is not
/// known yet, the road walked coming up from below, and the ways on.
class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.palette,
    required this.here,
    required this.hereRadius,
    required this.stepRadius,
    required this.steps,
    required this.trail,
  });

  final ChartPalette palette;
  final Offset here;
  final double hereRadius;
  final double stepRadius;
  final List<
      ({
        Offset centre,
        int row,
        bool locked,
        bool selected,
        int onward,
      })> steps;
  final int trail;

  @override
  void paint(Canvas canvas, Size size) {
    // The chart's grid.
    final grid = Paint()..color = palette.seaLine.withValues(alpha: 0.55);
    for (var y = 12.0; y < size.height; y += 24) {
      for (var x = 12.0; x < size.width; x += 24) {
        canvas.drawCircle(Offset(x, y), 0.9, grid);
      }
    }
    // Fog over the far side of the map.
    final fogRect = Rect.fromLTWH(0, 0, size.width, 90);
    canvas.drawRect(
      fogRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.fog, palette.fog.withValues(alpha: 0)],
        ).createShader(fogRect),
    );

    // The road walked, from off the bottom of the map to the party.
    final walked = Paint()
      ..color = palette.road.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final below = Path()
      ..moveTo(here.dx, here.dy)
      ..cubicTo(here.dx + 16, here.dy + 40, here.dx - 16, size.height - 30,
          here.dx, size.height + 4);
    canvas.drawPath(below, walked);
    for (var i = 0; i < trail; i++) {
      final y = here.dy + hereRadius + 20 + i * 30;
      canvas.drawCircle(
        Offset(here.dx + (i.isEven ? 2 : -2), y),
        i == 0 ? 5 : 4,
        Paint()..color = palette.road.withValues(alpha: i == 0 ? 0.9 : 0.6),
      );
    }

    // The ways on: dashed, the chosen one drawn in full. Each leaves the
    // party's mark on the side it heads for, and the roads to the far
    // rows fade, so a town's many ways read as a fan rather than a knot.
    for (final step in steps) {
      final lean = ((step.centre.dx - here.dx) / size.width * 1.6)
          .clamp(-math.pi / 3, math.pi / 3);
      final start = here +
          Offset(math.sin(lean) * hereRadius, -math.cos(lean) * hereRadius);
      final end = step.centre.translate(0, stepRadius);
      final dy = (start.dy - end.dy).abs();
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, start.dy - dy * 0.45, end.dx, end.dy + dy * 0.45,
            end.dx, end.dy);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = step.selected ? 3 : 2
        ..color = step.selected
            ? palette.mark
            : step.locked
                ? palette.label.withValues(alpha: 0.4)
                : palette.ahead
                    .withValues(alpha: step.row == 0 ? 1 : 0.75 / step.row);
      if (step.selected) {
        canvas.drawPath(path, paint);
      } else {
        _dashed(canvas, path, paint, dash: 6, gap: 6);
      }
      // What lies past the step: a dot for each way on from it, at the
      // edge of the fog.
      if (!step.locked && step.onward > 0) {
        final forks = math.min(step.onward, 3);
        final fog = Paint()..color = palette.label.withValues(alpha: 0.6);
        for (var f = 0; f < forks; f++) {
          final angle =
              forks == 1 ? 0.0 : (f / (forks - 1) - 0.5) * (math.pi / 2.2);
          canvas.drawCircle(
            step.centre +
                Offset(math.sin(angle) * (stepRadius + 9),
                    -math.cos(angle) * (stepRadius + 9)),
            2,
            fog,
          );
        }
      }
    }
  }

  static void _dashed(Canvas canvas, Path path, Paint paint,
      {required double dash, required double gap}) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_JourneyPainter old) =>
      old.palette != palette ||
      old.here != here ||
      old.trail != trail ||
      old.steps.length != steps.length ||
      [
        for (var i = 0; i < steps.length; i++) old.steps[i] != steps[i],
      ].any((changed) => changed);
}

/// Under the map: the step picked, what it holds and costs, and Go.
/// Nothing picked yet says how to pick.
class _StepDetail extends ConsumerWidget {
  const _StepDetail({
    required this.step,
    required this.busy,
    required this.french,
    required this.isExcursion,
    required this.onGo,
  });

  final _Step? step;
  final bool busy;
  final bool french;
  final bool isExcursion;
  final VoidCallback? onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final step = this.step;
    if (step == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          tr(ref, 'journey_pick_hint'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
        ),
      );
    }
    final choice = step.choice;
    String signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';
    final enemies = choice.triggersCombat
        ? ref.watch(localizedDbProvider(enemiesSchema)).value
        : null;
    final ids = choice.allTriggerEnemyIds;
    final roster = isExcursion ||
            enemies == null ||
            ids.isEmpty ||
            ids.any((id) => id.startsWith('@'))
        ? null
        : enemyRoster(ids, enemies);
    final colour = step.locked
        ? ink.ash
        : _colorFor(step.kind, ink, ChartPalette.of(ref.watch(mapLookProvider)),
            greyed: false);
    final tags = [
      if (choice.hasAbilityCheck)
        InkTag(
          label: '${tr(ref, '${choice.checkAbility}_label')} '
              'DC ${choice.checkDC ?? 10}',
          color: ink.tide,
        ),
      if (choice.goldMod != 0)
        InkTag(
          label: '${signed(choice.goldMod)} ${tr(ref, 'gold_label')}',
          color: ink.gold,
        ),
      if (choice.healAmount != 0)
        InkTag(
          label: '${signed(choice.healAmount)} ${tr(ref, 'hp_label')}',
          color: choice.healAmount > 0 ? ink.heal : ink.blood,
        ),
      if (choice.alignmentMod != 0)
        InkTag(
          label: '${tr(ref, 'alignment_label')} ${signed(choice.alignmentMod)}',
          color: ink.voidColor,
        ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(ref, _kindKey(step.kind)).toUpperCase(),
                    style: TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: colour,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: InkFonts.prose,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  if (roster != null && !step.locked)
                    Text(
                      tr(ref, 'choice_fight_roster')
                          .replaceAll('{roster}', roster),
                      style: theme.textTheme.labelSmall,
                    ),
                  if (step.leadsTo != null)
                    Text(
                      tr(ref, 'journey_leads_to')
                          .replaceAll('{place}', step.leadsTo!),
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash),
                    ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: step.locked ? 0.45 : 1,
                      child: Wrap(spacing: 6, runSpacing: 4, children: tags),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              key: const ValueKey('journey_go'),
              onPressed: step.locked || busy ? null : onGo,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(tr(ref, 'journey_go')),
            ),
          ],
        ),
      ),
    );
  }
}

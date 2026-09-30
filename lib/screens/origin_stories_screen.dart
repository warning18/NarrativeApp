import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/origin_stories.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// The formative memories, on their own page once the character is named:
/// six moments from the age of six to sixteen (origin_stories.dart), one
/// at a time on a timeline of ages. A later memory can open with a line
/// recalling an earlier answer. Each answer shows what it teaches; once
/// picked, the page tells what came of it before moving on. A summary of
/// every answer, what they taught and the alignment they add up to closes
/// the page.
///
/// Back always steps back (from what came of an answer to its answers, to
/// the previous memory, from the summary to the last one) and never skips
/// a memory; Back on the first memory leaves the page. Nothing is applied
/// here: the page pops with the [OriginResult], or null when the player
/// backs out, and the caller applies it once.
class OriginStoriesScreen extends ConsumerStatefulWidget {
  const OriginStoriesScreen(
      {super.key, this.raceId, this.professionId, this.random});

  /// Picks the race's own second memory.
  final String? raceId;

  /// Picks the profession's own fourth memory.
  final String? professionId;

  /// Shuffles the answers; tests pass a seeded one.
  final Random? random;

  @override
  ConsumerState<OriginStoriesScreen> createState() =>
      _OriginStoriesScreenState();
}

class _OriginStoriesScreenState extends ConsumerState<OriginStoriesScreen> {
  late final List<OriginMemory> _memories = originMemoriesFor(
      raceId: widget.raceId, professionId: widget.professionId);

  // Shuffled once, so going back to a memory shows its answers in the same
  // order as before.
  late final List<List<OriginAnswer>> _answerOrder = () {
    final random = widget.random ?? Random();
    return [
      for (final memory in _memories) [...memory.answers]..shuffle(random),
    ];
  }();

  late final List<OriginAnswer?> _answers =
      List<OriginAnswer?>.filled(_memories.length, null);

  /// The memory on screen; [_memories].length means the summary.
  int _index = 0;

  /// Set once the memory on screen is answered: what came of it shows
  /// until the player moves on (or chooses again).
  bool _showingOutcome = false;

  /// Set while a memory is reopened from the summary: moving on from it
  /// (or Back) returns straight to the summary.
  bool _editingFromSummary = false;

  bool get _onSummary => _index >= _memories.length;

  bool get _canLeave => _index == 0 && !_showingOutcome && !_editingFromSummary;

  bool get _french => ref.read(appLanguageProvider) == AppLanguage.fr;

  void _answer(OriginAnswer answer) {
    setState(() {
      _answers[_index] = answer;
      _showingOutcome = true;
    });
  }

  void _moveOn() {
    setState(() {
      _showingOutcome = false;
      if (_editingFromSummary) {
        _editingFromSummary = false;
        _index = _memories.length;
      } else {
        _index++;
      }
    });
  }

  void _back() {
    setState(() {
      if (_showingOutcome) {
        _showingOutcome = false;
      } else if (_editingFromSummary) {
        _editingFromSummary = false;
        _index = _memories.length;
      } else if (_index > 0) {
        _index--;
      }
    });
  }

  void _reopen(int index) {
    setState(() {
      _editingFromSummary = true;
      _showingOutcome = false;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appLanguageProvider);
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'origin_stories_section_title'))),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: KeyedSubtree(
              key: ValueKey('$_index/$_showingOutcome'),
              child:
                  _onSummary ? _buildSummary(context) : _buildMemory(context),
            ),
          ),
        ),
      ),
    );
  }

  String _stageLabel(OriginMemory memory) =>
      '${tr(ref, 'origin_age_label').replaceAll('{n}', '${memory.age}')} · '
      '${tr(ref, memory.isChildhood ? 'origin_stage_childhood' : 'origin_stage_youth')}';

  String _lessonLabel(OriginAnswer answer) => tr(ref, 'origin_teaches')
      .replaceAll('{ability}', tr(ref, '${answer.ability}_label'));

  String _leanLabel(OriginAnswer answer) {
    final n = answer.alignmentMod.abs();
    final key = answer.alignmentMod > 0
        ? 'origin_lean_good'
        : answer.alignmentMod < 0
            ? 'origin_lean_evil'
            : 'origin_lean_neutral';
    return tr(ref, key).replaceAll('{n}', '$n');
  }

  Widget _buildMemory(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final french = _french;
    final memory = _memories[_index];
    final chosen = _answers[_index];
    final before = originResultOf(
        _memories.sublist(0, _index), _answers.sublist(0, _index));
    final recall = memory.recallFor(before.flags.toSet(), before.alignment);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (_index == 0 && !_editingFromSummary && !_showingOutcome) ...[
          Text(
            tr(ref, 'origin_stories_intro'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
        ],
        _AgeTimeline(
          ages: [for (final m in _memories) m.age],
          current: _index,
          answered: [for (final a in _answers) a != null],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                _stageLabel(memory).toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              tr(ref, 'origin_memory_progress')
                  .replaceAll('{n}', '${_index + 1}')
                  .replaceAll('{total}', '${_memories.length}'),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(memory.titleFor(french), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (recall != null) ...[
          Row(
            key: const ValueKey('origin_recall'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.history_edu_outlined,
                    size: 18, color: colors.tertiary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recall.textFor(french),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Text(
            memory.sceneFor(french),
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_showingOutcome && chosen != null)
          _Outcome(
            answer: chosen.textFor(french),
            outcome: chosen.outcomeFor(french),
            lesson: _lessonLabel(chosen),
            lean: _leanLabel(chosen),
            alignmentMod: chosen.alignmentMod,
            nextLabel: tr(
                ref,
                _editingFromSummary || _index == _memories.length - 1
                    ? 'origin_to_summary'
                    : 'origin_next_memory'),
            chooseAgainLabel: tr(ref, 'origin_choose_again'),
            onNext: _moveOn,
            onChooseAgain: _back,
          )
        else
          for (final answer in _answerOrder[_index])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnswerButton(
                label: answer.textFor(french),
                lesson: _lessonLabel(answer),
                selected: identical(answer, chosen),
                onPressed: () => _answer(answer),
              ),
            ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final french = _french;
    final session = ref.watch(playerSessionProvider);
    final result = originResultOf(_memories, _answers);
    final starting = session.copyWith(
        alignmentScore: session.alignmentScore + result.alignment);
    final name = session.characterName.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(tr(ref, 'origin_summary_title'),
            style: theme.textTheme.headlineSmall),
        if (name.isNotEmpty)
          Text(name,
              style:
                  theme.textTheme.titleMedium?.copyWith(color: colors.primary)),
        const SizedBox(height: 10),
        Text(
          tr(ref, 'origin_portrait_${originPortraitOf(_answers)}'),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 19,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < _memories.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SummaryRow(
              age: _memories[i].age,
              title: _memories[i].titleFor(french),
              answer: _answers[i]?.textFor(french) ?? '—',
              lesson: _answers[i] == null ? null : _lessonLabel(_answers[i]!),
              alignmentMod: _answers[i]?.alignmentMod ?? 0,
              onTap: () => _reopen(i),
            ),
          ),
        Text(
          tr(ref, 'origin_summary_change_hint'),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text(tr(ref, 'origin_summary_lessons'),
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in result.abilities.entries)
              Chip(
                avatar:
                    Icon(Icons.auto_awesome, size: 16, color: colors.primary),
                label: Text('${tr(ref, '${entry.key}_label')} +${entry.value}'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.balance_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr(ref, 'origin_starting_alignment'),
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              '${trAlignmentLabel(ref, starting.alignmentLabel)} '
              '(${starting.alignmentScore})',
              style:
                  theme.textTheme.titleSmall?.copyWith(color: colors.primary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _AlignmentGauge(score: starting.alignmentScore),
        const SizedBox(height: 18),
        Text(
          tr(ref, 'origin_summary_intro'),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _answers.contains(null)
              ? null
              : () => Navigator.of(context).pop(result),
          child: Text(tr(ref, 'begin_story_button')),
        ),
      ],
    );
  }
}

/// The ages, one dot each: the memory on screen is ringed, answered ones
/// are filled.
class _AgeTimeline extends StatelessWidget {
  const _AgeTimeline(
      {required this.ages, required this.current, required this.answered});

  final List<int> ages;
  final int current;
  final List<bool> answered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        for (var i = 0; i < ages.length; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: answered[i - 1]
                    ? colors.primary.withValues(alpha: 0.5)
                    : colors.outlineVariant,
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == current ? 16 : 12,
                height: i == current ? 16 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: answered[i] ? colors.primary : colors.surface,
                  border: Border.all(
                    color: i == current || answered[i]
                        ? colors.primary
                        : colors.outline,
                    width: i == current ? 3 : 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ages[i]}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      i == current ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: i == current ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// What came of the answer, what it taught and how it leans, with the way
/// on (or back to the answers).
class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.answer,
    required this.outcome,
    required this.lesson,
    required this.lean,
    required this.alignmentMod,
    required this.nextLabel,
    required this.chooseAgainLabel,
    required this.onNext,
    required this.onChooseAgain,
  });

  final String answer;
  final String outcome;
  final String lesson;
  final String lean;
  final int alignmentMod;
  final String nextLabel;
  final String chooseAgainLabel;
  final VoidCallback onNext;
  final VoidCallback onChooseAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: Column(
        key: const ValueKey('origin_outcome'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: colors.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“$answer”',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  outcome,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Tag(
                        icon: Icons.auto_awesome,
                        label: lesson,
                        color: colors.primary),
                    _Tag(
                      icon: Icons.balance_outlined,
                      label: lean,
                      color: alignmentMod > 0
                          ? colors.tertiary
                          : alignmentMod < 0
                              ? colors.error
                              : colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: Text(nextLabel),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
                onPressed: onChooseAgain, child: Text(chooseAgainLabel)),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.lesson,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String lesson;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final child = Column(
      children: [
        Text(label, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          lesson,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
    return selected
        ? FilledButton.tonal(
            style: FilledButton.styleFrom(padding: padding),
            onPressed: onPressed,
            child: child,
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(padding: padding),
            onPressed: onPressed,
            child: child,
          );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.age,
    required this.title,
    required this.answer,
    required this.lesson,
    required this.alignmentMod,
    required this.onTap,
  });

  final int age;
  final String title;
  final String answer;
  final String? lesson;
  final int alignmentMod;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lean = alignmentMod > 0
        ? colors.tertiary
        : alignmentMod < 0
            ? colors.error
            : colors.outline;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: lean, width: 2),
                ),
                child: Text('$age',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: colors.primary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      answer,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    if (lesson != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        lesson!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.edit_outlined,
                  size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where [score] sits between Evil and Good, with the Neutral band
/// (±20, see PlayerSession.alignmentLabel) marked.
class _AlignmentGauge extends StatelessWidget {
  const _AlignmentGauge({required this.score});

  final int score;

  static const double _range = 30;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final at = ((score.clamp(-_range, _range) + _range) / (2 * _range));
    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          double x(double v) => (v + _range) / (2 * _range) * w;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 7,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(colors: [
                      colors.error,
                      colors.outlineVariant,
                      colors.tertiary,
                    ]),
                  ),
                ),
              ),
              for (final v in const [-20.0, 20.0])
                Positioned(
                  left: x(v) - 1,
                  top: 3,
                  width: 2,
                  height: 12,
                  child: ColoredBox(color: colors.outline),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: at * w - 7,
                top: 2,
                width: 14,
                height: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(color: colors.primary, width: 3),
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/origin_stories.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// The formative memories, on their own page once the character is named:
/// one memory at a time with its answers in a shuffled order, then a summary
/// of every answer and the alignment they add up to.
///
/// Back always steps to the previous memory (or from the summary to the
/// last one) and never skips a memory; Back on the first memory leaves the
/// page. Nothing is applied here: the page pops with the chosen answers, one
/// per memory in order, or null when the player backs out, and the caller
/// applies their alignment once.
class OriginStoriesScreen extends ConsumerStatefulWidget {
  const OriginStoriesScreen({super.key, this.professionId, this.random});

  /// Picks the profession's own variant of the beggar memory.
  final String? professionId;

  /// Shuffles the answers; tests pass a seeded one.
  final Random? random;

  @override
  ConsumerState<OriginStoriesScreen> createState() =>
      _OriginStoriesScreenState();
}

class _OriginStoriesScreenState extends ConsumerState<OriginStoriesScreen> {
  late final List<OriginPrompt> _prompts = [
    for (var i = 0; i < originStoryPrompts.length; i++)
      originPromptForSlot(i, widget.professionId),
  ];

  // Shuffled once, so going back to a memory shows its answers in the same
  // order as before.
  late final List<List<OriginChoice>> _choiceOrder = () {
    final random = widget.random ?? Random();
    return [
      for (final prompt in _prompts) [...prompt.choices]..shuffle(random),
    ];
  }();

  late final List<OriginChoice?> _answers =
      List<OriginChoice?>.filled(_prompts.length, null);

  /// The memory on screen; [_prompts].length means the summary.
  int _index = 0;

  /// Set while a memory is reopened from the summary: answering it (or
  /// Back) returns straight to the summary.
  bool _editingFromSummary = false;

  bool get _onSummary => _index >= _prompts.length;

  bool get _canLeave => _index == 0 && !_editingFromSummary;

  void _answer(OriginChoice choice) {
    setState(() {
      _answers[_index] = choice;
      if (_editingFromSummary) {
        _editingFromSummary = false;
        _index = _prompts.length;
      } else {
        _index++;
      }
    });
  }

  void _back() {
    setState(() {
      if (_editingFromSummary) {
        _editingFromSummary = false;
        _index = _prompts.length;
      } else if (_index > 0) {
        _index--;
      }
    });
  }

  void _reopen(int index) {
    setState(() {
      _editingFromSummary = true;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => tr(ref, key);
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(t('origin_stories_section_title'))),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child:
                  _onSummary ? _buildSummary(context) : _buildMemory(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemory(BuildContext context) {
    String t(String key) => tr(ref, key);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final prompt = _prompts[_index];
    final chosen = _answers[_index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (_index == 0 && !_editingFromSummary) ...[
          Text(
            t('origin_stories_intro'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
        ],
        _Progress(current: _index, answers: _answers),
        const SizedBox(height: 6),
        Text(
          t('origin_memory_progress')
              .replaceAll('{n}', '${_index + 1}')
              .replaceAll('{total}', '${_prompts.length}'),
          style: theme.textTheme.labelMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Text(t(prompt.titleKey), style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Text(
            t(prompt.descriptionKey),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'serif',
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (final choice in _choiceOrder[_index])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AnswerButton(
              label: t(choice.textKey),
              selected: identical(choice, chosen),
              onPressed: () => _answer(choice),
            ),
          ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    String t(String key) => tr(ref, key);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = ref.watch(playerSessionProvider);
    final total = originAlignmentTotal(_answers.whereType<OriginChoice>());
    final starting =
        session.copyWith(alignmentScore: session.alignmentScore + total);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(t('origin_summary_title'), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          t('origin_summary_intro'),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < _prompts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _reopen(i),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t(_prompts[i].titleKey),
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: colors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _answers[i] == null
                                  ? '—'
                                  : t(_answers[i]!.textKey),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontFamily: 'serif', height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined,
                          size: 18, color: colors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 2),
        Text(
          t('origin_summary_change_hint'),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(Icons.balance_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('origin_starting_alignment'),
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
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _answers.contains(null)
              ? null
              : () => Navigator.of(context)
                  .pop(List<OriginChoice>.unmodifiable(_answers)),
          child: Text(t('begin_story_button')),
        ),
      ],
    );
  }
}

/// The alignment a set of memory answers adds up to.
int originAlignmentTotal(Iterable<OriginChoice> answers) =>
    answers.fold(0, (sum, choice) => sum + choice.alignmentMod);

/// One segment per memory: answered and current ones are lit.
class _Progress extends StatelessWidget {
  const _Progress({required this.current, required this.answers});

  final int current;
  final List<OriginChoice?> answers;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < answers.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i == current
                    ? colors.primary
                    : answers[i] != null
                        ? colors.primary.withValues(alpha: 0.45)
                        : colors.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    final text = Text(label, textAlign: TextAlign.center);
    return selected
        ? FilledButton.tonal(
            style: FilledButton.styleFrom(padding: padding),
            onPressed: onPressed,
            child: text,
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(padding: padding),
            onPressed: onPressed,
            child: text,
          );
  }
}

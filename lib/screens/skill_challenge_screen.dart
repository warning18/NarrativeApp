import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ability_check.dart';
import '../data/skill_challenge.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';

/// A multi-round "push your luck" contest: reach [successesNeeded]
/// successful ability checks before [maxFailures] failed ones. Distinct
/// from a single ability check (one roll settles it) and from combat
/// (health, dice faces, an enemy) — this is closer to a tabletop "skill
/// challenge": tension builds round by round, and an early bad roll doesn't
/// end the attempt, it just narrows the margin left for error.
///
/// Resolves the whole sequence once on entry, via the pure
/// [resolveSkillChallenge], so the outcome is fixed and independently
/// testable — then reveals it round by round for pacing. Pops `true` on
/// success, `false` on failure, mirroring how the combat screen reports a
/// win.
class SkillChallengeScreen extends ConsumerStatefulWidget {
  const SkillChallengeScreen({
    super.key,
    required this.promptText,
    required this.ability,
    required this.dc,
    required this.successesNeeded,
    required this.maxFailures,
  });

  final String promptText;
  final String ability;
  final int dc;
  final int successesNeeded;
  final int maxFailures;

  @override
  ConsumerState<SkillChallengeScreen> createState() =>
      _SkillChallengeScreenState();
}

class _SkillChallengeScreenState extends ConsumerState<SkillChallengeScreen> {
  late final SkillChallengeResult _result;
  int _revealed = 0;
  bool _started = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(playerSessionProvider);
    _result = resolveSkillChallenge(
      ability: widget.ability,
      dc: widget.dc,
      successesNeeded: widget.successesNeeded,
      maxFailures: widget.maxFailures,
      session: session,
    );
  }

  Future<void> _begin() async {
    setState(() => _started = true);
    for (var i = 0; i < _result.rounds.length; i++) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => _revealed = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ink = InkColors.of(context);
    final abilityLabel = tr(ref, '${widget.ability}_label');
    final revealedRounds = _result.rounds.take(_revealed).toList();
    final successesSoFar = revealedRounds.where((r) => r.success).length;
    final failuresSoFar = revealedRounds.length - successesSoFar;
    final latest = revealedRounds.isEmpty ? null : revealedRounds.last;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'skill_challenge_title'))),
      body: TutorialTrigger(
        topic: TutorialTopic.skillChallenge,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  abilityLabel.toUpperCase(),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: ink.ember, letterSpacing: 1.5),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.promptText,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 16),
                TutorialTarget(
                  id: 'challenge.track',
                  child: Row(
                    children: [
                      Expanded(
                        child: _PipRow(
                          label: tr(ref, 'skill_challenge_successes_label'),
                          filled: successesSoFar,
                          total: widget.successesNeeded,
                          color: ink.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PipRow(
                          label: tr(ref, 'skill_challenge_failures_label'),
                          filled: failuresSoFar,
                          total: widget.maxFailures,
                          color: ink.blood,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TutorialTarget(
                  id: 'challenge.die',
                  child: _D20(
                    roll: latest?.check.roll,
                    success: latest?.success,
                    // Smaller on a short screen, so the rounds keep room.
                    size: (MediaQuery.sizeOf(context).height * 0.18)
                        .clamp(84.0, 150.0),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  latest == null
                      ? '$abilityLabel ${tr(ref, 'check_label')} '
                          '${tr(ref, 'vs_dc_label')} ${widget.dc}'
                      : '${latest.check.roll} + $abilityLabel ${latest.check.modifier}'
                          ' = ${latest.check.total}  ·  ${tr(ref, 'vs_dc_label')} ${widget.dc}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _revealed,
                    itemBuilder: (context, index) {
                      final round = _result.rounds[index];
                      return _RoundTile(
                        roundNumber: index + 1,
                        roundLabel: tr(ref, 'skill_challenge_round_label'),
                        result: round.check,
                        success: round.success,
                      );
                    },
                  ),
                ),
                if (!_started)
                  FilledButton(
                    onPressed: _begin,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: Text(tr(ref, 'skill_challenge_begin')),
                  )
                else if (_finished)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                                color: _result.success
                                    ? ink.gold
                                    : colorScheme.error),
                          ),
                          child: Text(
                            (_result.success
                                    ? tr(ref, 'skill_challenge_success_banner')
                                    : tr(ref, 'skill_challenge_fail_banner'))
                                .toUpperCase(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              letterSpacing: 2,
                              color: _result.success
                                  ? ink.gold
                                  : colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_result.success),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52)),
                        child: Text(tr(ref, 'skill_challenge_continue')),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The d20: a hexagon face with the latest roll on it, gold for a
/// success, the error colour for a failure, plain before the first roll.
class _D20 extends StatelessWidget {
  const _D20({this.roll, this.success, this.size = 150});

  final int? roll;
  final bool? success;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final edge = success == null
        ? ink.seam
        : success!
            ? ink.gold
            : theme.colorScheme.error;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _D20Painter(
              edge: edge,
              face: theme.colorScheme.surfaceContainer,
              facet: ink.seam),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: size * 0.09),
              child: Text(
                roll?.toString() ?? '20',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: size * 0.24,
                  fontFamily: InkFonts.system,
                  fontWeight: FontWeight.w600,
                  color: roll == null ? ink.ash : edge,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _D20Painter extends CustomPainter {
  const _D20Painter(
      {required this.edge, required this.face, required this.facet});

  final Color edge;
  final Color face;
  final Color facet;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset p(double x, double y) => Offset(x * w / 170, y * h / 170);
    final hex = Path()
      ..moveTo(p(85, 6).dx, p(85, 6).dy)
      ..lineTo(p(158, 48).dx, p(158, 48).dy)
      ..lineTo(p(158, 122).dx, p(158, 122).dy)
      ..lineTo(p(85, 164).dx, p(85, 164).dy)
      ..lineTo(p(12, 122).dx, p(12, 122).dy)
      ..lineTo(p(12, 48).dx, p(12, 48).dy)
      ..close();
    canvas.drawPath(hex, Paint()..color = face);
    final facetPaint = Paint()
      ..color = facet
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final tri = Path()
      ..moveTo(p(85, 34).dx, p(85, 34).dy)
      ..lineTo(p(134, 112).dx, p(134, 112).dy)
      ..lineTo(p(36, 112).dx, p(36, 112).dy)
      ..close();
    canvas.drawPath(tri, facetPaint);
    for (final (a, b) in [
      ((85.0, 6.0), (85.0, 34.0)),
      ((158.0, 48.0), (134.0, 112.0)),
      ((12.0, 48.0), (36.0, 112.0)),
      ((85.0, 164.0), (36.0, 112.0)),
      ((85.0, 164.0), (134.0, 112.0)),
      ((158.0, 122.0), (134.0, 112.0)),
      ((12.0, 122.0), (36.0, 112.0)),
      ((12.0, 48.0), (85.0, 34.0)),
      ((158.0, 48.0), (85.0, 34.0)),
    ]) {
      canvas.drawLine(p(a.$1, a.$2), p(b.$1, b.$2), facetPaint);
    }
    canvas.drawPath(
        hex,
        Paint()
          ..color = edge
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_D20Painter old) =>
      old.edge != edge || old.face != face || old.facet != facet;
}

class _PipRow extends StatelessWidget {
  const _PipRow({
    required this.label,
    required this.filled,
    required this.total,
    required this.color,
  });

  final String label;
  final int filled;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${label.toUpperCase()} · $filled / $total',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < total; i++)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: i < filled ? color : null,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                        color:
                            i < filled ? color : color.withValues(alpha: 0.5),
                        width: 1.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundTile extends StatelessWidget {
  const _RoundTile({
    required this.roundNumber,
    required this.roundLabel,
    required this.result,
    required this.success,
  });

  final int roundNumber;
  final String roundLabel;
  final AbilityCheckResult result;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final color = success ? ink.gold : theme.colorScheme.error;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(success ? Icons.check : Icons.close, color: color),
      title:
          Text('$roundLabel $roundNumber', style: theme.textTheme.labelLarge),
      trailing: Text(
        '${result.roll} + ${result.modifier} = ${result.total}',
        style: theme.textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

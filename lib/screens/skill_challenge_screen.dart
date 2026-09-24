import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ability_check.dart';
import '../data/skill_challenge.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final abilityLabel = tr(ref, '${widget.ability}_label');
    final revealedRounds = _result.rounds.take(_revealed).toList();
    final successesSoFar = revealedRounds.where((r) => r.success).length;
    final failuresSoFar = revealedRounds.length - successesSoFar;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'skill_challenge_title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.promptText,
                style: const TextStyle(
                    fontFamily: 'serif', fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                '$abilityLabel ${tr(ref, 'check_label')} '
                '${tr(ref, 'vs_dc_label')} ${widget.dc}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PipRow(
                    label: tr(ref, 'skill_challenge_successes_label'),
                    filled: successesSoFar,
                    total: widget.successesNeeded,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 32),
                  _PipRow(
                    label: tr(ref, 'skill_challenge_failures_label'),
                    filled: failuresSoFar,
                    total: widget.maxFailures,
                    color: colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                  child: Text(tr(ref, 'skill_challenge_begin')),
                )
              else if (_finished)
                Column(
                  children: [
                    Text(
                      _result.success
                          ? tr(ref, 'skill_challenge_success_banner')
                          : tr(ref, 'skill_challenge_fail_banner'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            _result.success ? Colors.green : colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_result.success),
                      child: Text(tr(ref, 'skill_challenge_continue')),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
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
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  i < filled ? Icons.circle : Icons.circle_outlined,
                  size: 14,
                  color: i < filled ? color : color.withValues(alpha: 0.35),
                ),
              ),
          ],
        ),
      ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(
        success ? Icons.check_circle : Icons.cancel,
        color: success ? Colors.green : colorScheme.error,
      ),
      title: Text('$roundLabel $roundNumber'),
      trailing: Text(
        '${result.roll} + ${result.modifier} = ${result.total}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

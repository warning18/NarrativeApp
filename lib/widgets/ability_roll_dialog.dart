// A single ability check, rolled on screen (v1.309): the d20 tumbles over a
// dimmed scene with no panel behind it, lands on the roll, and the sum
// against the DC comes up under it -- then it goes by itself, or on a tap.
// The same die as the Skill Challenge's (see d20_roll.dart).
import 'package:flutter/material.dart';

import '../data/ability_check.dart';
import '../theme/stitched_ink.dart';
import 'd20_roll.dart';

/// Shows [result] being rolled; [message] is the line that comes up when the
/// die has landed ("Strength check: 12 + 2 = 14 vs DC 12 — success").
Future<void> showAbilityRoll(
  BuildContext context, {
  required AbilityCheckResult result,
  required String message,
  Duration linger = const Duration(milliseconds: 1700),
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: message,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _AbilityRoll(result: result, message: message, linger: linger),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _AbilityRoll extends StatefulWidget {
  const _AbilityRoll(
      {required this.result, required this.message, required this.linger});

  final AbilityCheckResult result;
  final String message;
  final Duration linger;

  @override
  State<_AbilityRoll> createState() => _AbilityRollState();
}

class _AbilityRollState extends State<_AbilityRoll> {
  bool _landed = false;

  void _onLanded() {
    if (!mounted || _landed) return;
    setState(() => _landed = true);
    Future.delayed(widget.linger, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final edge = widget.result.success ? ink.gold : theme.colorScheme.error;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              D20Roll(
                key: const Key('ability_roll_die'),
                roll: widget.result.roll,
                success: widget.result.success,
                size: 150,
                onLanded: _onLanded,
              ),
              const SizedBox(height: 14),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _landed ? 1 : 0,
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: edge,
                    height: 1.4,
                    shadows: const [
                      Shadow(blurRadius: 6, color: Colors.black87),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

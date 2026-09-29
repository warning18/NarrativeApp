import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// The clock over a timed scene's choices (see StoryNode.timeLimit): a
/// bar that empties over [seconds], reddening in its last third, with the
/// seconds left. Runs only while [active] (the scene's tab on screen, no
/// page over it); when it runs out, [onTimeout] is called once.
class TimedChoiceBar extends StatefulWidget {
  const TimedChoiceBar({
    super.key,
    required this.seconds,
    required this.active,
    required this.onTimeout,
    required this.label,
  });

  final int seconds;
  final bool active;
  final VoidCallback onTimeout;

  /// What the clock is for ("Choose before time runs out").
  final String label;

  @override
  State<TimedChoiceBar> createState() => _TimedChoiceBarState();
}

class _TimedChoiceBarState extends State<TimedChoiceBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: Duration(seconds: math.max(1, widget.seconds)),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_fired) {
          _fired = true;
          widget.onTimeout();
        }
      });
    if (widget.active) _clock.forward();
  }

  @override
  void didUpdateWidget(TimedChoiceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    if (widget.active) {
      _clock.forward();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final left = 1 - _clock.value;
        final seconds = (left * widget.seconds).ceil();
        final colour = left < 1 / 3 ? theme.colorScheme.error : ink.gold;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.hourglass_bottom, size: 14, color: colour),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colour, letterSpacing: 0.4),
                    ),
                  ),
                  Text(
                    '${seconds}s',
                    key: const ValueKey('timed_choice_seconds'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colour,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: left,
                  minHeight: 5,
                  color: colour,
                  backgroundColor: colour.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

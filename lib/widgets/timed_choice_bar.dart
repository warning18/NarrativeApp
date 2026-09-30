import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/timed_clock_provider.dart';
import '../theme/stitched_ink.dart';

/// The clock over a timed scene's choices (see StoryNode.timeLimit): a
/// bar that empties over [seconds], reddening in its last third, with the
/// seconds left. Runs only while [active] (the scene's tab on screen, no
/// page over it); when it runs out, [onTimeout] is called once. The time
/// run is the [scene]'s, shared by every bar showing it (see
/// timedSceneClockProvider): switching tabs or reading the scene full
/// screen goes on from where the clock stood.
class TimedChoiceBar extends ConsumerStatefulWidget {
  const TimedChoiceBar({
    super.key,
    required this.scene,
    required this.seconds,
    required this.active,
    required this.onTimeout,
    required this.label,
  });

  /// The scene the clock is for: its node and how far the story has come
  /// (see timedSceneKey).
  final String scene;
  final int seconds;
  final bool active;
  final VoidCallback onTimeout;

  /// What the clock is for ("Choose before time runs out").
  final String label;

  @override
  ConsumerState<TimedChoiceBar> createState() => _TimedChoiceBarState();
}

/// The scene a timed clock belongs to (see TimedChoiceBar.scene): node
/// [nodeId] with the story [historyLength] scenes along.
String timedSceneKey(String nodeId, int historyLength) =>
    '${nodeId}_$historyLength';

class _TimedChoiceBarState extends ConsumerState<TimedChoiceBar>
    with SingleTickerProviderStateMixin {
  late final TimedSceneClock _shared = ref.read(timedSceneClockProvider);
  late final Duration _limit = Duration(seconds: math.max(1, widget.seconds));
  late final AnimationController _clock;

  /// How much of the clock the scene has used, as the shared clock has it.
  double get _spent => math.min(1,
      _shared.elapsedOn(widget.scene).inMicroseconds / _limit.inMicroseconds);

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: _limit, value: _spent)
      ..addListener(() => _shared.run(widget.scene, _limit * _clock.value))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            !_shared.ranOutOn(widget.scene)) {
          _shared.runOut(widget.scene);
          widget.onTimeout();
        }
      });
    if (widget.active) _run();
  }

  /// Runs on from the shared clock, unless it has run out already.
  void _run() {
    if (_shared.ranOutOn(widget.scene)) return;
    _clock.value = _spent;
    _clock.forward();
  }

  @override
  void didUpdateWidget(TimedChoiceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    if (widget.active) {
      _run();
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

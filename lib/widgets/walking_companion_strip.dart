import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/companion_sprites.dart';
import '../providers/combat_active_provider.dart';

final List<String> _walkFrames = companionFrames('Walking/east', 8);
final List<String> _fightFrames = companionFrames('Fight_-_Attack/animations/Bark/east', 6);
const String _idleSprite = '$companionAssetsRoot/Sitting_down/rotations/east.png';

const double _companionSpriteSize = 120;

/// A companion dog that idles (sitting) at the left edge of the story
/// screen, walks west to east across it each time [trigger] changes (i.e.
/// each time the player advances the story), then returns to idling at the
/// left — and switches to a fighting stance instead of idling whenever
/// [combatActiveProvider] is true.
class WalkingCompanionStrip extends ConsumerStatefulWidget {
  const WalkingCompanionStrip({
    super.key,
    required this.trigger,
    this.height = _companionSpriteSize,
  });

  final Object trigger;
  final double height;

  @override
  ConsumerState<WalkingCompanionStrip> createState() => _WalkingCompanionStripState();
}

class _WalkingCompanionStripState extends ConsumerState<WalkingCompanionStrip>
    with TickerProviderStateMixin {
  late final AnimationController _walkController;
  late final AnimationController _poseController;

  @override
  void initState() {
    super.initState();
    _walkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    // Drives frame cycling for the (currently only) multi-frame pose:
    // fighting. Only runs while actually fighting (see build's ref.listen)
    // so idling doesn't repaint every frame for no reason.
    _poseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void didUpdateWidget(covariant WalkingCompanionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _walkController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _walkController.dispose();
    _poseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(combatActiveProvider, (previous, next) {
      if (next) {
        _poseController.repeat();
      } else {
        _poseController.stop();
      }
    });
    final fighting = ref.watch(combatActiveProvider);
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_walkController, _poseController]),
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final walking = !fighting && _walkController.isAnimating;

              final String framePath;
              double x = 0;
              if (fighting) {
                final frame =
                    (_poseController.value * _fightFrames.length).floor() % _fightFrames.length;
                framePath = _fightFrames[frame];
              } else if (walking) {
                final t = Curves.linear.transform(_walkController.value);
                x = -_companionSpriteSize + (constraints.maxWidth + _companionSpriteSize) * t;
                // A handful of walk cycles across the crossing.
                final frame = (t * _walkFrames.length * 4).floor() % _walkFrames.length;
                framePath = _walkFrames[frame];
              } else {
                framePath = _idleSprite;
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: x,
                    bottom: 0,
                    child: Image.asset(
                      framePath,
                      width: _companionSpriteSize,
                      height: _companionSpriteSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

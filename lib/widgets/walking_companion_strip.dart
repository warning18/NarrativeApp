import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/companion_sprites.dart';
import '../providers/combat_active_provider.dart';
import '../providers/companion_name_provider.dart';
import '../providers/player_session_provider.dart';

final List<String> _neutralWalkFrames = companionFrames('Walking/east', 8);
final List<String> _fightFrames = companionFrames('Fight_-_Attack/animations/Bark/south', 6);
const String _neutralIdleSprite = '$companionAssetsRoot/Sitting_down/rotations/south.png';

// A Good/Evil character's companion swaps its neutral dog look for an
// angelic/demonic one (a single directional pose each, not an animated
// cycle) instead of the plain walking/sitting sprites.
const String _angelWalkSprite = '$companionAssetsRoot/Make_it_with_angel_w/rotations/east.png';
const String _demonWalkSprite = '$companionAssetsRoot/Make_it_with_demon_w/rotations/east.png';
const String _angelIdleSprite = '$companionAssetsRoot/Make_it_with_angel_w/rotations/south.png';
const String _demonIdleSprite = '$companionAssetsRoot/Make_it_with_demon_w/rotations/south.png';

// The walking frames' source canvas is 88x88px; the sitting/fighting
// frames' is 64x64px. Rendering both into the same fixed box would stretch
// the smaller canvas's padding along with it, making the sitting dog look
// like a different size than the walking one. Scaling each pose by the
// same factor relative to its own native canvas keeps the dog itself a
// consistent size across poses.
const double _walkNativeSize = 88;
const double _restNativeSize = 64;
const double _walkDisplaySize = 120;
const double _restDisplaySize = _restNativeSize * (_walkDisplaySize / _walkNativeSize);

/// A companion dog that idles (sitting, facing the player) at the left edge
/// of the story screen, and each time [trigger] changes (i.e. each time the
/// player advances the story) walks off across the screen to the right,
/// then walks back in from the left and sits back down — rather than
/// popping between positions. Switches to a fighting stance instead of
/// idling whenever [combatActiveProvider] is true (an actual fight is on
/// screen) or [fightAvailable] is true (the current node offers a choice
/// that would start one, even before the player picks it).
class WalkingCompanionStrip extends ConsumerStatefulWidget {
  const WalkingCompanionStrip({
    super.key,
    required this.trigger,
    this.fightAvailable = false,
    this.height = _walkDisplaySize,
  });

  final Object trigger;
  final bool fightAvailable;
  final double height;

  @override
  ConsumerState<WalkingCompanionStrip> createState() => _WalkingCompanionStripState();
}

class _WalkingCompanionStripState extends ConsumerState<WalkingCompanionStrip>
    with TickerProviderStateMixin {
  late final AnimationController _walkOutController;
  late final AnimationController _walkInController;
  late final AnimationController _poseController;

  @override
  void initState() {
    super.initState();
    _walkOutController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _walkInController.forward(from: 0);
        }
      });
    _walkInController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    // Drives frame cycling for the fighting stance. Only runs while
    // actually fighting (see build's isAnimating guard) so idling doesn't
    // repaint every frame for no reason.
    _poseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    // Walk in and sit down on first appearance too, instead of popping in.
    _walkInController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant WalkingCompanionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _walkOutController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _walkOutController.dispose();
    _walkInController.dispose();
    _poseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fighting = ref.watch(combatActiveProvider) || widget.fightAvailable;
    // Guarded by isAnimating so this is a no-op (not a restart-from-frame-0)
    // on rebuilds where `fighting` hasn't actually changed.
    if (fighting && !_poseController.isAnimating) {
      _poseController.repeat();
    } else if (!fighting && _poseController.isAnimating) {
      _poseController.stop();
    }
    final name = ref.watch(companionNameProvider);
    final alignment = ref.watch(playerSessionProvider).alignmentLabel;
    final walkFrames = switch (alignment) {
      'Good' => const [_angelWalkSprite],
      'Evil' => const [_demonWalkSprite],
      _ => _neutralWalkFrames,
    };
    final idleSprite = switch (alignment) {
      'Good' => _angelIdleSprite,
      'Evil' => _demonIdleSprite,
      _ => _neutralIdleSprite,
    };

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_walkOutController, _walkInController, _poseController]),
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final walkingOut = !fighting && _walkOutController.isAnimating;
              final walkingIn = !fighting && !walkingOut && _walkInController.isAnimating;
              final stationary = !fighting && !walkingOut && !walkingIn;

              final String framePath;
              double x = 0;
              double size;
              if (fighting) {
                final frame =
                    (_poseController.value * _fightFrames.length).floor() % _fightFrames.length;
                framePath = _fightFrames[frame];
                size = _restDisplaySize;
              } else if (walkingOut) {
                final t = Curves.linear.transform(_walkOutController.value);
                x = (constraints.maxWidth + _walkDisplaySize) * t;
                final frame = (t * walkFrames.length * 4).floor() % walkFrames.length;
                framePath = walkFrames[frame];
                size = _walkDisplaySize;
              } else if (walkingIn) {
                final t = Curves.linear.transform(_walkInController.value);
                x = -_walkDisplaySize + _walkDisplaySize * t;
                final frame = (t * walkFrames.length).floor() % walkFrames.length;
                framePath = walkFrames[frame];
                size = _walkDisplaySize;
              } else {
                framePath = idleSprite;
                size = _restDisplaySize;
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (stationary && name.isNotEmpty)
                    Positioned(
                      left: 0,
                      bottom: _restDisplaySize + 2,
                      width: _restDisplaySize,
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Positioned(
                    left: x,
                    bottom: 0,
                    child: Image.asset(
                      framePath,
                      width: size,
                      height: size,
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

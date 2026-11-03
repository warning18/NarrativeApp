// From the finished character into the Blind Beggar (after-opening option 3):
// the character's screen no longer cuts to the story's first scene, it
// cross-fades into it over about a second and a half, the opening's sigil
// at its highest in the middle of the fade, a whisper. The story page
// beneath stays alive, so a tap on it plays its text at once. With reduced
// motion the cut stays a cut and the sigil does not show.
import 'package:flutter/material.dart';

import 'prologue_opening.dart' show prologueSigilAsset;

/// How much of the sigil shows at the middle of the fade (the whisper's
/// highest, 8-15 %).
const double creationSigilPeak = 0.15;

/// How long the character's screen takes to fade away when it closes.
const Duration creationFadeOut = Duration(milliseconds: 1500);

/// A route to [builder] that fades in quickly and, when popped, fades out
/// over [creationFadeOut] with the sigil rising and falling behind it.
Route<T> creationToStoryRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    opaque: false,
    barrierColor: null,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: creationFadeOut,
    pageBuilder: (context, _, __) => builder(context),
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final leaving = animation.status == AnimationStatus.reverse;
          // 0 at the start of the leave, 1 at its end; the sigil is highest
          // in the middle.
          final t = (1 - animation.value).clamp(0.0, 1.0);
          final sigil =
              leaving ? creationSigilPeak * (1 - (2 * t - 1).abs()) : 0.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(opacity: animation, child: child),
              if (sigil > 0)
                IgnorePointer(
                  child: Center(
                    child: Opacity(
                      key: const Key('creation_sigil'),
                      opacity: sigil,
                      child: Image.asset(
                        prologueSigilAsset,
                        width: 220,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

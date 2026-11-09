// "Remove animations": the platform's own setting (Android's, iOS's Reduce
// Motion), read through MediaQuery so a test can set it. Most of the app's
// loops and tweens already honour it where they start; these are the few
// that start in initState or on a change, where the context is not asked.
import 'package:flutter/widgets.dart';

/// Whether the platform asks for no animations. Reads MediaQuery without
/// depending on it, so it may be called from initState.
bool stillMotion(BuildContext context) =>
    context
        .getInheritedWidgetOfExactType<MediaQuery>()
        ?.data
        .disableAnimations ??
    WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

extension StillAnimation on AnimationController {
  /// Plays to the end, or lands there at once when motion is off.
  void forwardOrJump(BuildContext context, {double? from}) {
    if (stillMotion(context)) {
      value = upperBound;
    } else {
      forward(from: from);
    }
  }
}

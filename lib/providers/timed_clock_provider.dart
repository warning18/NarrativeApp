import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A timed scene's clock (see TimedChoiceBar), kept outside the bars that
/// show it: the Story and Journey tabs each have one, and reading the
/// scene full screen takes the bar off screen, yet the scene has one
/// clock. It holds the scene the story stands on (its node and how far
/// the story has come, so the same scene met again starts afresh), how
/// long its clock has run and whether it ran out.
class TimedSceneClock {
  String? _scene;
  Duration _elapsed = Duration.zero;
  bool _ranOut = false;

  /// How long [scene]'s clock has run; a scene not seen yet, none.
  Duration elapsedOn(String scene) =>
      scene == _scene ? _elapsed : Duration.zero;

  /// Whether [scene]'s clock has run out (its way taken for the party).
  bool ranOutOn(String scene) => scene == _scene && _ranOut;

  /// [scene]'s clock has run [elapsed].
  void run(String scene, Duration elapsed) {
    _begin(scene);
    _elapsed = elapsed;
  }

  /// [scene]'s clock has run out: it runs out once.
  void runOut(String scene) {
    _begin(scene);
    _ranOut = true;
  }

  void _begin(String scene) {
    if (scene == _scene) return;
    _scene = scene;
    _elapsed = Duration.zero;
    _ranOut = false;
  }
}

/// The one clock of the timed scene the story is on (see TimedSceneClock).
final timedSceneClockProvider =
    Provider<TimedSceneClock>((ref) => TimedSceneClock());

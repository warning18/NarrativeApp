// Every test file starts here. The story text writes itself out in play (the
// choices wait for it); the tests read a scene at once, and the ones about
// the typewriter turn it back on (test/story_text_test.dart). The first-launch
// intro stays off the same way (test/intro_screen_test.dart plays it). A move over
// the world chart takes a third of its time, so the waits stay short.
import 'dart:async';

import 'package:narrative_data_app/screens/intro_screen.dart'
    show introOnNewGame;
import 'package:narrative_data_app/widgets/journey_world_map.dart'
    show worldMoveTimeScale;
import 'package:narrative_data_app/widgets/story_text.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  storyTypewriterOn = false;
  introOnNewGame = false;
  worldMoveTimeScale = 0.3;
  await testMain();
}

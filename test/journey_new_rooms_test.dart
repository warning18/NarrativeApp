// The Journey inside the buildings Core added (wave 14): the prison, the
// library and the forge open their own rooms, from the scene's own location.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/room_plan.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/room_plan_painter.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

void main() {
  testWidgets(
      'a scene in a new building opens its room: prison, library, forge',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);

    // Core's wave-14 data (building_interiors_test.dart): the scene's own
    // location is the building; nothing else maps a scene to a room.
    for (final (scene, kind) in [
      ('800', RoomKind.prison),
      ('3020', RoomKind.library),
      ('3100_house_anvil_deaf', RoomKind.forge),
    ]) {
      play.jumpTo(scene);
      await settleApp(tester);
      for (var i = 0; i < 3; i++) {
        Navigator.of(
                tester.element(find.byType(JourneyScreen, skipOffstage: false)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byKey(const ValueKey('journey_room')), findsOneWidget,
          reason: 'scene $scene');
      expect(find.byKey(const ValueKey('journey_streets')), findsNothing,
          reason: 'scene $scene');
      final plan = (tester
              .widget<CustomPaint>(find.byKey(const ValueKey('journey_room')))
              .painter as RoomPlanPainter)
          .plan;
      expect(plan.kind, kind, reason: 'scene $scene');
      expect(tester.takeException(), isNull, reason: 'scene $scene');
    }
  });
}

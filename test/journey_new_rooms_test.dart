// The Journey inside the buildings Core added (wave 14): the prison, the
// library and the forge open their own rooms, from the scene's own location.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/room_plan.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/room_plan_painter.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
      'a scene in a new building opens its room: prison, library, forge',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await _settle(tester);

    // Core's wave-14 data (building_interiors_test.dart): the scene's own
    // location is the building; nothing else maps a scene to a room.
    for (final (scene, kind) in [
      ('800', RoomKind.prison),
      ('3020', RoomKind.library),
      ('3100_house_anvil_deaf', RoomKind.forge),
    ]) {
      play.jumpTo(scene);
      await _settle(tester);
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

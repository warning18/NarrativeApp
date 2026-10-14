// The Journey inside a building (v1.207): the story opens at the Blind
// Beggar's tables, so the map shows the room, with every way at its spot
// in it and none out on the streets; a look out shows the streets round
// the building with the ways kept inside, and the + button (or a pinch
// out) goes back in; a way that leaves the building sits at its door.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/room_plan.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'package:narrative_data_app/widgets/room_plan_painter.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the Blind Beggar is drawn from inside, its ways at their spots',
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
    // The geography knows the Blind Beggar as a den in the Lower Town.
    final geography = container.read(geographyProvider);
    final beggar = geography.place('blind_beggar')!;
    expect(beggar.isBuilding, isTrue);
    expect(beggar.kind, 'den');
    expect(geography.locationOf('blind_beggar')!.id, 'alster');

    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('100');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);

    // The room, not the streets, with the three ways in it.
    expect(find.byKey(const ValueKey('journey_room')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_streets')), findsNothing);
    final painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('journey_room')))
        .painter as RoomPlanPainter;
    final plan = painter.plan;
    expect(plan.kind, RoomKind.den);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('journey_step_$i')), findsOneWidget,
          reason: 'step $i');
    }
    // The ways sit over the building: each step's centre falls within
    // the plan's walls on the map.
    final roomRect = tester.getRect(find.byKey(const ValueKey('journey_room')));
    Rect onMap(Rect r) => Rect.fromLTRB(
        roomRect.left + painter.origin.dx + r.left * painter.scale,
        roomRect.top + painter.origin.dy + r.top * painter.scale,
        roomRect.left + painter.origin.dx + r.right * painter.scale,
        roomRect.top + painter.origin.dy + r.bottom * painter.scale);
    final walls = onMap(plan.frame);
    for (var i = 0; i < 3; i++) {
      final c = tester.getCenter(find.byKey(ValueKey('journey_step_$i')));
      expect(walls.contains(c), isTrue, reason: 'step $i at $c in $walls');
    }

    // A look out: the streets round the building, the ways kept inside,
    // and the + brings the room back.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('journey_streets')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_room')), findsNothing);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    expect(find.byKey(const Key('journey_go_inside')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_go_inside')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('journey_room')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);

    // Out again and further: the land.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('journey_streets')), findsNothing);
    expect(find.byKey(const ValueKey('journey_world_map')), findsOneWidget);

    // Back in from the land: the streets round the building first.
    await tester.tap(find.byKey(const Key('journey_recentre')));
    await tester.pump();
    await tester.tapAt(tester.getRect(find.byType(JourneyWorldMap)).center);
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);
    expect(find.byKey(const ValueKey('journey_streets')), findsOneWidget);
    expect(find.byKey(const Key('journey_go_inside')), findsOneWidget);

    // After the fight, the way out the back sits at the back door, inside.
    play.jumpTo('106');
    await _settle(tester);
    if (find.byKey(const ValueKey('journey_continue')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('journey_continue')));
      await _settle(tester);
    }
    expect(find.byKey(const ValueKey('journey_room')), findsOneWidget);
    final painter2 = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('journey_room')))
        .painter as RoomPlanPainter;
    final roomRect2 =
        tester.getRect(find.byKey(const ValueKey('journey_room')));
    final back = Offset(
        roomRect2.left +
            painter2.origin.dx +
            painter2.plan.anchorOf('back').dx * painter2.scale,
        roomRect2.top +
            painter2.origin.dy +
            painter2.plan.anchorOf('back').dy * painter2.scale);
    // The ways the flags hide are gone: the way out is the last step shown.
    final shown = [
      for (var i = 0; i < 4; i++)
        if (find.byKey(ValueKey('journey_step_$i')).evaluate().isNotEmpty) i,
    ];
    expect(shown, isNotEmpty);
    final exit =
        tester.getCenter(find.byKey(ValueKey('journey_step_${shown.last}')));
    expect((exit - back).distance, lessThan(40),
        reason: 'exit $exit back $back');
    // And on the street after it, the streets again, with no way back in.
    play.jumpTo('250');
    await _settle(tester);
    if (find.byKey(const ValueKey('journey_continue')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('journey_continue')));
      await _settle(tester);
    }
    expect(find.byKey(const ValueKey('journey_streets')), findsOneWidget);
    expect(find.byKey(const Key('journey_go_inside')), findsNothing);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}

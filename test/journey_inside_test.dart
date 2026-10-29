// The Journey inside a building (v1.207): the story opens at the Blind
// Beggar's tables, so the map shows the room, with every way at its spot
// in it and none out on the streets; a look out shows the streets round
// the building with the ways kept inside, and the + button (or a pinch
// out) goes back in; a way that leaves the building sits at its door.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/room_plan.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'package:narrative_data_app/widgets/room_plan_painter.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

void main() {
  testWidgets('the Blind Beggar is drawn from inside, its ways at their spots',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester);
    // The geography knows the Blind Beggar as a den in the Lower Town.
    final geography = container.read(geographyProvider);
    final beggar = geography.place('blind_beggar')!;
    expect(beggar.isBuilding, isTrue);
    expect(beggar.kind, 'den');
    expect(geography.locationOf('blind_beggar')!.id, 'alster');

    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('100');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);

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

    // A look out: the streets round the building (Alster's stored chart,
    // board 15), and the + brings the room back.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await settleApp(tester);
    // The doorway is told in words, both ways (v1.537).
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('journey_transit_caption')))
            .data,
        'You step back out into the streets\u2026');
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_room')), findsNothing);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);
    expect(find.byKey(const Key('journey_go_inside')), findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_go_inside')));
    await settleApp(tester);
    expect(find.text('You step inside the Blind Beggar\u2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_room')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsOneWidget);

    // Out again and further: the land.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await settleApp(tester);
    // The streets round the building, then the town, then the land.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await settleApp(tester);
    expect(find.byKey(const ValueKey('journey_city_chart')), findsNothing);
    expect(find.byKey(const ValueKey('journey_world_map')), findsOneWidget);

    // Back in from the land: the streets round the building first.
    await tester.tap(find.byKey(const Key('journey_recentre')));
    await tester.pump();
    await tester.tapAt(tester.getRect(find.byType(JourneyWorldMap)).center);
    await tester.pump(const Duration(milliseconds: 300));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(find.byKey(const Key('journey_go_inside')), findsOneWidget);

    // After the fight, the way out the back sits at the back door, inside.
    play.jumpTo('106');
    await settleApp(tester);
    if (find.byKey(const ValueKey('journey_continue')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('journey_continue')));
      await settleApp(tester);
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
    // And on the street after it, Alster's own plan (city_plans.json), with
    // no way back in.
    play.jumpTo('250');
    await settleApp(tester);
    if (find.byKey(const ValueKey('journey_continue')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('journey_continue')));
      await settleApp(tester);
    }
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(find.byKey(const Key('journey_go_inside')), findsNothing);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}

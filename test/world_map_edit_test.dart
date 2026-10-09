// The world chart in Edit Mode (v1.209): a second map button in the
// header opens the chart whole, with no fog, every place and every
// chapter's road.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/world_map_screen.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('edit mode opens the whole world from the header',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);

    // Beside the scene graph, the chart.
    expect(find.byKey(const Key('home_world_map')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_world_map')));
    await _settle(tester);
    expect(find.byType(WorldMapPage), findsOneWidget);
    final painter = tester
        .widgetList<CustomPaint>(find.descendant(
            of: find.byType(WorldMapPage), matching: find.byType(CustomPaint)))
        .map((w) => w.painter)
        .whereType<ChartMapPainter>()
        .first;
    // The world whole: no fog, every place, every chapter's road.
    expect(painter.fog, ChartFog.none);
    expect(painter.discovered.length, worldMapLandmarks.length);
    expect(painter.legs.length, greaterThan(worldMapLandmarks.length ~/ 2));
    expect(painter.ahead, isNull);
    expect(tester.takeException(), isNull);
  });
}

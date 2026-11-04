// A way to another district of the town is walked on the city chart
// (v1.823): from the Lower Town (250) the way to the Stone Bridge is a mark
// on Alster's chart, the party's mark walks the streets to it (the walk can
// be skipped by a tap) and the bridge's scene opens.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart'
    show CityChartView;
import 'support/open_game.dart';
import 'support/pump.dart';

void main() {
  /// The game open on the Journey at scene [nodeId].
  Future<ProviderContainer> openAt(WidgetTester tester, String nodeId,
      {bool motion = true}) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));
    if (!motion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    final container = await openGame(tester);
    container.read(storyPlayProvider.notifier).jumpTo(nodeId);
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    return container;
  }

  Future<void> closeOverlays(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('a way to another district is walked on the city chart',
      (tester) async {
    final container = await openAt(tester, '250');
    await closeOverlays(tester);
    // The Lower Town's one way on, to the Stone Bridge, is a mark on the
    // city chart (a move, not a step in place): the page gives way to the
    // map, and the way is picked on the chart.
    final back = find.byKey(const ValueKey('journey_continue'));
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back);
      await tester.pump(const Duration(milliseconds: 600));
    }
    final view = tester.widget<CityChartView>(
        find.byKey(const ValueKey('journey_city_chart')));
    expect(view.chart.ways, hasLength(1));
    view.onPick!(view.chart.ways.single);
    await tester.pump(const Duration(milliseconds: 400));
    final go = find.byKey(const ValueKey('journey_go'));
    await tester.ensureVisible(go);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(go);
    // The party's mark walks the streets (the walk can be skipped by a tap),
    // then the scene at the bridge opens.
    var walking = false;
    for (var i = 0; i < 20 && !walking; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      walking = find
          .byKey(const ValueKey('journey_city_walk_skip'))
          .evaluate()
          .isNotEmpty;
    }
    expect(walking, isTrue, reason: 'the move is walked on the city chart');
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settleApp(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '260');
    expect(tester.takeException(), isNull);
  });
}

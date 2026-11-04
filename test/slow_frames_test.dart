// The slow-frames counter (v1.765): the meter counts per screen and only while
// started, the screen is named from the routes and the tab, and the Settings
// switch (off by default) starts and stops it, copies the report and clears it.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/combat_active_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/slow_frames_provider.dart';
import 'package:narrative_data_app/screens/settings_screen.dart';
import 'package:narrative_data_app/utils/slow_frames.dart';
import 'support/pump.dart';

/// One frame of [totalMs], half of it build.
ui.FrameTiming _frame(double totalMs) {
  final us = (totalMs * 1000).round();
  return ui.FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: us ~/ 2,
    rasterStart: us ~/ 2,
    rasterFinish: us,
    rasterFinishWallTime: us,
  );
}

/// Delivers [timings] the way the engine does.
void _deliver(WidgetTester tester, List<ui.FrameTiming> timings) =>
    tester.binding.platformDispatcher.onReportTimings!(timings);

void main() {
  test('frames are counted per screen; the slow ones and the worst are kept',
      () {
    final meter = SlowFrameMeter(screen: () => 'x');
    meter.addFrame('Fight', totalMs: 10, buildMs: 5, rasterMs: 5);
    meter.addFrame('Fight', totalMs: 17, buildMs: 8, rasterMs: 9);
    meter.addFrame('Fight', totalMs: 48.4, buildMs: 30, rasterMs: 18.4);
    meter.addFrame('Camp', totalMs: 21, buildMs: 11, rasterMs: 10);
    expect(meter.stats['Fight']!.frames, 3);
    expect(meter.stats['Fight']!.slow, 1, reason: '17 ms is not over 17');
    expect(meter.stats['Fight']!.worstMs, 48.4);
    expect(meter.stats['Camp']!.slow, 1);
    expect([for (final f in meter.worst) f.totalMs], [48.4, 21]);

    final report = meter.report(device: 'v1.x · test');
    expect(report, contains('v1.x · test'));
    expect(report, contains('Fight: 1 / 3, worst 48 ms'));
    expect(report, contains('Camp: 1 / 1, worst 21 ms'));
    expect(report, contains('48.4 total = 30.0 build + 18.4 raster, Fight'));

    meter.reset();
    expect(meter.stats, isEmpty);
    expect(meter.worst, isEmpty);
    expect(meter.report(device: 'd'), contains('Nothing counted yet.'));
  });

  test('only the five worst frames are listed', () {
    final meter = SlowFrameMeter(screen: () => 'x');
    for (var i = 0; i < 9; i++) {
      meter.addFrame('A', totalMs: 20.0 + i, buildMs: 1, rasterMs: 1);
    }
    expect(meter.worst.length, worstFramesListed);
    expect(meter.worst.first.totalMs, 28);
    expect(meter.worst.last.totalMs, 24);
  });

  testWidgets('the meter counts only between start and stop', (tester) async {
    var screen = 'A';
    final meter = SlowFrameMeter(screen: () => screen);
    addTearDown(meter.stop);
    expect(meter.running, isFalse);
    _deliver(tester, [_frame(40)]);
    expect(meter.stats, isEmpty, reason: 'not started: nothing counted');

    meter.start();
    meter.start();
    expect(meter.running, isTrue);
    _deliver(tester, [_frame(40), _frame(5)]);
    expect(meter.stats['A']!.frames, 2);
    expect(meter.stats['A']!.slow, 1);
    expect(meter.stats['A']!.worstMs, closeTo(40, 0.01));
    screen = 'B';
    _deliver(tester, [_frame(30)]);
    expect(meter.stats['B']!.slow, 1);

    // The counter on screen is told of the change, not on every frame.
    final before = meter.changes.value;
    await tester.pump(const Duration(milliseconds: 600));
    expect(meter.changes.value, greaterThan(before));
    final settled = meter.changes.value;
    await tester.pump(const Duration(milliseconds: 600));
    expect(meter.changes.value, settled, reason: 'nothing changed: no update');

    meter.stop();
    expect(meter.running, isFalse);
    _deliver(tester, [_frame(90)]);
    expect(meter.stats['B']!.frames, 1, reason: 'stopped: nothing counted');
    expect(meter.stats['A']!.worstMs, closeTo(40, 0.01));
  });

  test(
      'the screen is named from the fight, the routes, the tab and the Journey',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    addTearDown(() => slowFrameHint = null);
    final routes = container.read(slowFrameRoutesProvider);
    final meter = container.read(slowFrameMeterProvider);
    Route<void> route(String? name) => MaterialPageRoute<void>(
        settings: RouteSettings(name: name), builder: (_) => const SizedBox());

    routes.didPush(route('/'), null);
    expect(meter.screen(), 'Main menu');
    routes.didPush(route(gameRouteName), null);
    await container.read(appModeProvider.notifier).setMode(AppMode.edit);
    container.read(homeTabIndexProvider.notifier).state = 1;
    expect(meter.screen(), 'Play', reason: 'in Edit Mode tab 1 is Play');
    await container.read(appModeProvider.notifier).setMode(AppMode.inGame);
    expect(meter.screen(), 'Character');
    container.read(homeTabIndexProvider.notifier).state = 2;
    expect(meter.screen(), 'Camp or ship');
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    expect(meter.screen(), 'Journey');
    slowFrameHint = 'reading page';
    expect(meter.screen(), 'Journey, reading page');
    slowFrameHint = 'map';
    expect(meter.screen(), 'Journey, map');

    final shop = route(null);
    routes.didPush(shop, null);
    expect(meter.screen(), 'Another screen');
    routes.didPop(shop, null);
    expect(meter.screen(), 'Journey, map');

    container.read(combatActiveProvider.notifier).state = true;
    expect(meter.screen(), 'Fight');
  });

  testWidgets(
      'off by default; the Settings switch turns it on, the report is copied, '
      'reset clears it, and off stops it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    usePhone(tester, const Size(800, 1280));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(milliseconds: 300));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    final meter = container.read(slowFrameMeterProvider);
    expect(container.read(slowFramesProvider), isFalse,
        reason: 'off by default');
    expect(meter.running, isFalse);
    expect(find.byKey(const Key('slow_frames_chip')), findsNothing);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    final tile = find.byKey(const Key('slow_frames_setting'));
    await tester.scrollUntilVisible(tile, 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('slow_frames_copy')), findsNothing,
        reason: 'the buttons come with the switch');

    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(slowFramesProvider), isTrue);
    expect(meter.running, isTrue);
    expect(find.byKey(const Key('slow_frames_chip')), findsOneWidget);

    _deliver(tester, [_frame(40), _frame(8)]);
    await tester.pump(const Duration(milliseconds: 600));
    expect(
        find.descendant(
            of: find.byKey(const Key('slow_frames_chip')),
            matching: find.text('slow 1 / 2 · worst 40 ms')),
        findsOneWidget,
        reason: 'the counter of the screen being played (the page on top)');

    await tester.ensureVisible(find.byKey(const Key('slow_frames_copy')));
    await tester.tap(find.byKey(const Key('slow_frames_copy')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(copied, hasLength(1));
    expect(copied.single, contains('Slow frames (over 17 ms)'));
    expect(copied.single, contains('Another screen: 1 / 2, worst 40 ms'));
    expect(find.text('Report copied'), findsOneWidget);

    await tester.tap(find.byKey(const Key('slow_frames_reset')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(meter.stats, isEmpty);

    // The "Report copied" snackbar leaves before the switch is tapped again.
    await tester.pump(const Duration(seconds: 5));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(slowFramesProvider), isFalse);
    expect(meter.running, isFalse);
    expect(find.byKey(const Key('slow_frames_chip')), findsNothing);
    expect(find.byKey(const Key('slow_frames_copy')), findsNothing);
    _deliver(tester, [_frame(90)]);
    expect(meter.stats, isEmpty, reason: 'off: nothing is counted');
  });

  testWidgets('saved as on, the counter is there from the start',
      (tester) async {
    SharedPreferences.setMockInitialValues({'slow_frames_enabled': true});
    usePhone(tester, const Size(360, 740));
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 300));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    expect(container.read(slowFramesProvider), isTrue);
    expect(container.read(slowFrameMeterProvider).running, isTrue);
    expect(find.byKey(const Key('slow_frames_chip')), findsOneWidget);
  });
}

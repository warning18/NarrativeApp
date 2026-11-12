// QA guard (Maps release 1, v1.930): on the REAL Journey screen, the world tab
// is the sphere and it draws the player's here-marker and a ruled town's halo.
//
// The Journey is opened in Emberwick (scene 3100, a town the Cinder Compact
// rules), the world tab is tapped, and the chart's painter is taken from the
// widget tree: it must be told where the party stands (`here`) and which
// towns are ruled (`townTints`, with Emberwick's colours), and painting it
// must draw the traveller's pin and the ruled town's halo (a recording canvas
// counts the draw calls). It is a phone size (360 x 740), English.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/theme/palette.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';

import 'qa_smoke_harness.dart';

/// A canvas that keeps what is drawn on it, to read after the paint.
class _Rec implements ui.Canvas {
  final circles = <(double, ui.Paint)>[];
  final paths = <ui.Paint>[];

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) =>
      circles.add((radius, paint));

  @override
  void drawPath(ui.Path path, ui.Paint paint) => paths.add(paint);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _settle(WidgetTester tester, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  testWidgets('the Journey world tab draws the here-marker and a ruled halo',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = smokeSizes.first;

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    container.read(storyPlayProvider.notifier).jumpTo('3100');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester, 10);
    for (var i = 0; i < 3; i++) {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
    await _settle(tester);
    await tester.ensureVisible(find.byKey(const Key('journey_tab_world')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('journey_tab_world')));
    await _settle(tester, 15);

    final painters = [
      for (final e in find.byType(CustomPaint).evaluate())
        if ((e.widget as CustomPaint).painter case final ChartMapPainter p) p,
    ];
    expect(find.byKey(const ValueKey('journey_globe_canvas')), findsOneWidget,
        reason: 'the Journey world tab is not the sphere');
    expect(painters, hasLength(1), reason: 'no chart painter on the world tab');
    final p = painters.single;

    // Told where the party stands, and which towns are ruled.
    expect(p.here?.id, 'emberwick',
        reason: 'the sphere is not told where the party stands');
    final tint = p.townTints['emberwick'];
    expect(tint, isNotNull, reason: 'Emberwick (ruled) has no tint');

    // Painting it draws them.
    final rec = _Rec();
    p.paint(rec, const Size(360, 560));
    int argb(Color c) => c.toARGB32();
    // The same colour: a Paint keeps alpha as a whole byte, a Color rounds.
    bool same(Color a, Color b) =>
        (argb(a) & 0xFFFFFF) == (argb(b) & 0xFFFFFF) &&
        ((argb(a) >> 24) - (argb(b) >> 24)).abs() <= 1;
    // ignore: avoid_print
    expect(
        rec.circles
            .any((c) => same(c.$2.color, tint!.fill.withValues(alpha: 0.30))),
        isTrue,
        reason: 'no halo wash drawn for the ruled town Emberwick');
    expect(
        rec.circles
            .any((c) => same(c.$2.color, tint!.accent.withValues(alpha: 0.9))),
        isTrue,
        reason: 'no halo ring drawn for the ruled town Emberwick');
    expect(rec.paths.any((c) => same(c.color, Palette.ashDark)), isTrue,
        reason: 'the traveller (the party) is not drawn on the sphere');
    expect(rec.paths.any((c) => same(c.color, p.palette.mark)), isTrue,
        reason: 'the here-pin is not drawn over the traveller');
  });
}

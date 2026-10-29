// The Journey tab's map and list at the White Wells and at the High Quay of
// Alster, as the app draws them, at 320 and 412 px: before and after the
// correction of v1.607 (no text laid over the map; the list names places, not
// choices). With UX_SHOTS (a folder) and SHOT_TAG (before, after) set it saves
// the real screen as pictures:
//   UX_SHOTS=docs/ux-shots SHOT_TAG=after SHOT_SCENE=high-quay flutter test test/ux_journey_fix_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['SHOT_TAG'] ?? 'after';
  if (dir == null) {
    test('the Journey pictures are taken only with UX_SHOTS', () {});
    return;
  }

  Future<void> shoot(
      WidgetTester tester, String node, String name, double width) async {
    tester.view.physicalSize = Size(width, 860);
    tester.view.devicePixelRatio = 1;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    await tester
        .pumpWidget(ProviderScope(key: UniqueKey(), child: const MyApp()));
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settleApp(tester);
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
    await settleApp(tester);
    container.read(storyPlayProvider.notifier).jumpTo(node);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.text('Journey').last);
    // The chart and its pictures load before the map shows.
    for (var i = 0;
        i < 60 &&
            (i < 8 ||
                find.byType(CircularProgressIndicator).evaluate().isNotEmpty);
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 500));
    }
    // The district as the party stands in it, not the whole town: a tap on
    // the district's row (or the District tab) when the town is shown.
    for (final label in ['District']) {
      final tab = find.text(label);
      if (tab.evaluate().isNotEmpty) {
        await tester.tap(tab.first, warnIfMissed: false);
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 500));
        }
      }
    }
    final row = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>)
            .value
            .startsWith('journey_city_district_'));
    if (row.evaluate().isNotEmpty) {
      await tester.tap(row.first, warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 500));
      }
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(find
        .descendant(
            of: find.byType(MaterialApp),
            matching: find.byType(RepaintBoundary))
        .first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/journey-$tag-$name-${width.toInt()}.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  // One scene and width a run (SHOT_SCENE: white-wells or high-quay;
  // SHOT_WIDTH: 412 or 320): the data of a second test does not load on the
  // first one's test clock.
  final only = Platform.environment['SHOT_SCENE'];
  final onlyWidth = double.tryParse(Platform.environment['SHOT_WIDTH'] ?? '');
  for (final (node, name) in const [
    ('1200', 'white-wells'),
    ('891', 'high-quay'),
  ]) {
    if (only != null && only != name) continue;
    for (final width in const [412.0, 320.0]) {
      if (onlyWidth != null && onlyWidth != width) continue;
      testWidgets('the Journey at $name, $width px', (tester) async {
        await tester.runAsync(loadAppFonts);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await shoot(tester, node, name, width);
      });
    }
  }
}

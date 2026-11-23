// Six story nodes on the real screen (UX_SHOTS=<folder>, UX_TAG=before|after):
// Alster, Saltmouth, Greyhithe, the drowned cloister, Rimewell and Akagiri,
// dark and light, at 360 and 412 px. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/fonts.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'after';
  const nodes = {
    'alster': '891',
    'saltmouth': '2010',
    'greyhithe': '7200',
    'cloister': '5010_archivist',
    'rimewell': '6100',
    'akagiri': '3200',
  };

  testWidgets('six story nodes', skip: shots == null, (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    for (final dark in [true, false]) {
      for (final width in [360.0, 412.0]) {
        for (final entry in nodes.entries) {
          SharedPreferences.setMockInitialValues(
              {if (dark) 'app_theme_mode': 'dark'});
          usePhone(tester, Size(width, 780));
          await tester.pumpWidget(const SizedBox());
          final container = await openGame(tester);
          container.read(storyPlayProvider.notifier).jumpTo(entry.value);
          await settleApp(tester);
          // The walk there ends, then the scene is opened with Read.
          for (var i = 0; i < 60; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          final read = find.byKey(const ValueKey('journey_read'));
          if (read.evaluate().isNotEmpty) {
            (tester.widget(read.first) as dynamic).onPressed();
            await settleApp(tester);
          }
          await tester.pump(const Duration(seconds: 2));
          final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
              find.byType(RepaintBoundary));
          late List<int> bytes;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
                .buffer
                .asUint8List();
          });
          Directory(shots!).createSync(recursive: true);
          File('$shots/${entry.key}-${dark ? 'dark' : 'light'}-${width.round()}-$tag.png')
              .writeAsBytesSync(bytes);
        }
      }
    }
  });
}

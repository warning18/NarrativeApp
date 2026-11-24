// Wear and weather on the ink kit (v2.1): pictures at 360 and 320 wide, and
// frames of a snowfall piling up and being knocked (UX_SHOTS=<folder>).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_weather.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

Widget _sheet(WeatherKind kind, double fall, double w, String title) =>
    WeatherScope(
      id: 'shots-$title',
      kind: kind,
      fall: fall,
      child: Container(
        width: w,
        color: inkDeep,
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkTab(title),
          const SizedBox(height: 22),
          Row(children: [
            InkButton(
                buttonKey: const ValueKey('go'),
                label: 'Fight',
                primary: true,
                onPressed: () {}),
            const SizedBox(width: 18),
            InkButton(
                buttonKey: const ValueKey('flee'),
                label: 'Flee',
                onPressed: () {}),
          ]),
          const SizedBox(height: 26),
          InkPaperPanel(
              title: 'Floor 12',
              child: const Text('A cold hall. The door opens on its own.',
                  style: TextStyle(fontFamily: InkFonts.prose, fontSize: 14))),
        ]),
      ),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  Future<void> shoot(WidgetTester t, GlobalKey key, String name) async {
    await t.runAsync(() async {
      final render =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> pumpSheet(WidgetTester t, GlobalKey key, Widget sheet,
      {bool reduce = false}) async {
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: InkFonts.prose),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Material(
            color: inkDeep,
            child: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(key: key, child: sheet))),
      ),
    ));
  }

  testWidgets('wear and weather on the ink kit', skip: shots == null,
      (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(360, 520);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    for (final w in [360.0, 320.0]) {
      final n = w.toInt();
      for (final (name, kind, fall, secs)
          in <(String, WeatherKind, double, int)>[
        ('clear', WeatherKind.clear, 0.0, 0),
        ('snow-band1', WeatherKind.snow, 0.4, 40),
        ('snow-band2', WeatherKind.snow, 0.7, 40),
        ('snow-band3', WeatherKind.snow, 1.0, 40),
        ('sand', WeatherKind.dust, 0.8, 40),
        ('ash', WeatherKind.ash, 0.8, 40),
        ('rain', WeatherKind.rain, 0.8, 40),
        ('fog', WeatherKind.fog, 0.8, 1),
      ]) {
        InkWeatherStore.reset();
        await pumpSheet(t, key, _sheet(kind, fall, w, name));
        await t.pump(Duration(seconds: secs));
        await shoot(t, key, '$name-$n');
        await t.pumpWidget(const SizedBox());
      }
      InkWeatherStore.reset();
      await pumpSheet(t, key, _sheet(WeatherKind.snow, 1, w, 'reduced'),
          reduce: true);
      await t.pump();
      await shoot(t, key, 'snow-reduced-$n');
      await t.pumpWidget(const SizedBox());
    }
    // The frames of a fall: 0 s to 30 s, then a tap, in four steps.
    InkWeatherStore.reset();
    await pumpSheet(t, key, _sheet(WeatherKind.snow, 1, 360, 'Snowfall'));
    var f = 0;
    String fr() => 'frame-${(f++).toString().padLeft(2, '0')}';
    await shoot(t, key, fr());
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 5));
      await shoot(t, key, fr());
    }
    await t.tapAt(t.getCenter(find.text('Fight')));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 110));
      await shoot(t, key, fr());
    }
    await t.pump(const Duration(seconds: 3));
    await shoot(t, key, fr());
    await t.pumpWidget(const SizedBox());
  });
}

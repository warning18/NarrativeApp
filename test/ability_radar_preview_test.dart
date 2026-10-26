// A pick on the ability radar (v1.549): the shape as it stands, and the shape
// a pick would give drawn over it in a second colour, the changed corners
// showing the new value (highlighted) and the gain. The shape grows from the
// current one; with reduced motion it is there at once.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'package:narrative_data_app/widgets/ability_radar.dart';
import 'package:narrative_data_app/widgets/radar_chart.dart';

const _values = {
  'strength': 8,
  'dexterity': 10,
  'constitution': 6,
  'intelligence': 7,
  'wisdom': 9,
  'perception': 11,
  'luck': 5,
  'charisma': 7,
};

Widget _radar({Map<String, int>? preview, bool reduced = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: Center(
            child: AbilityRadar(
              size: 230,
              t: (key) => key,
              values: _values,
              preview: preview,
            ),
          ),
        ),
      ),
    );

List<RadarLayer> _layers(WidgetTester tester) =>
    tester.widget<RadarChart>(find.byType(RadarChart)).layers;

void main() {
  testWidgets('without a pick the radar is as it was', (tester) async {
    await tester.pumpWidget(_radar());
    expect(_layers(tester), hasLength(1));
    expect(
        tester
            .widget<RadarChart>(find.byType(RadarChart))
            .axes
            .every((a) => a.sub == null && a.valueColor == null),
        isTrue);
  });

  testWidgets('a pick is a second shape round the first, its corners lit',
      (tester) async {
    await tester.pumpWidget(_radar(preview: {..._values, 'constitution': 7}));
    // Grown by the end of its short animation.
    await tester.pump(const Duration(milliseconds: 400));
    final layers = _layers(tester);
    expect(layers, hasLength(2));
    // The last is the current shape, as today, whole over the other.
    expect(layers[1].color, radarGold);
    expect(layers[1].values[2], 6);
    // The first is the pick's, in the second colour, with +1 at CON.
    expect(layers[0].color, radarMore);
    expect(layers[0].values[2], closeTo(7, 1e-6));
    expect(layers[0].values[0], 8);
    final axes = tester.widget<RadarChart>(find.byType(RadarChart)).axes;
    final con = axes[abilityRadarOrder.indexOf('constitution')];
    expect(con.value, '7');
    expect(con.sub, '+1');
    expect(con.valueColor, radarMore);
    // The other corners keep their value and say nothing.
    final str = axes[abilityRadarOrder.indexOf('strength')];
    expect(str.value, '8');
    expect(str.sub, isNull);
    expect(str.valueColor, isNull);
  });

  testWidgets(
      'the shape grows from the current one, and not with reduced '
      'motion', (tester) async {
    await tester.pumpWidget(_radar(preview: {..._values, 'luck': 8}));
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _layers(tester)[0].values[6];
    expect(mid, greaterThan(5));
    expect(mid, lessThan(8));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_layers(tester)[0].values[6], closeTo(8, 1e-6));

    await tester
        .pumpWidget(_radar(preview: {..._values, 'luck': 8}, reduced: true));
    expect(_layers(tester)[0].values[6], 8);
  });

  testWidgets('the radar\'s scale takes the pick in', (tester) async {
    await tester.pumpWidget(_radar(preview: {..._values, 'strength': 20}));
    await tester.pump(const Duration(milliseconds: 500));
    final chart = tester.widget<RadarChart>(find.byType(RadarChart));
    expect(chart.max, greaterThanOrEqualTo(20));
  });

  testWidgets('pictures of a pick on the radar (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    for (final (family, files) in const [
      (
        'PixelifySans',
        ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
      ),
      ('Spectral', ['Spectral-Regular.ttf', 'Spectral-Medium.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(Future.value(ByteData.view(
            Uint8List.fromList(File('assets/fonts/$f').readAsBytesSync())
                .buffer)));
      }
      await loader.load();
    }
    tester.view.physicalSize = const Size(1500, 760);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    Widget radar(String title, Map<String, int>? preview) => Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title),
            const SizedBox(height: 8),
            AbilityRadar(
                size: 230,
                t: (k) =>
                    k == 'str_abbrev' ? 'STR' : k.substring(0, 3).toUpperCase(),
                values: _values,
                preview: preview),
          ]),
        );
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFF17151B),
            child: Row(children: [
              radar('No pick selected', null),
              radar('Constitution +1', {..._values, 'constitution': 7}),
              radar('A rare pick: Perception +2, Luck +2',
                  {..._values, 'perception': 13, 'luck': 7}),
            ]),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/level-up-pick-radar.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

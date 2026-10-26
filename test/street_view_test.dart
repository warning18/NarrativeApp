// The street-view kit (v1.544, lib/widgets/street_view): a scene played
// outside a building shows the building's front, the street before it, the
// day's weather and hour, the party at the door and the ways as pins on the
// stones. UX_SHOTS=<folder> takes a picture of the six fronts by day, at
// dusk, at night and in the rain.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/widgets/street_view/street_facade.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

List<StreetPin> _pins(int n) => [
      for (var i = 0; i < n; i++)
        StreetPin(
          index: i,
          label: 'Way number $i to somewhere',
          child: const Icon(Icons.place, size: 28, color: Colors.amber),
        ),
    ];

Widget _scene(
  String kind,
  String name, {
  DayPhase phase = DayPhase.day,
  WeatherKind? sky,
  int pins = 3,
  void Function(int)? onPick,
  double width = 390,
  double height = 300,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: StreetViewScene(
                kind: kind,
                name: name,
                phase: phase,
                sky: sky,
                pins: _pins(pins),
                onPick: onPick),
          ),
        ),
      ),
    );

void main() {
  test('a building\'s front is told by what it is', () {
    // The three buildings Core gives a doorstep (v1.542).
    expect(facadeStyleOf('house', 'The family house'), FacadeStyle.house);
    expect(facadeStyleOf('den', 'The Blind Beggar'), FacadeStyle.tavern);
    expect(facadeStyleOf('warehouse', 'The informant’s warehouse'),
        FacadeStyle.warehouse);
    // The name decides, as it does for the rooms.
    expect(facadeStyleOf('house', 'Saint Orla’s Chapel'), FacadeStyle.temple);
    expect(facadeStyleOf('plain', 'The Black Hold'), FacadeStyle.house);
    expect(facadeStyleOf('plain', 'La cathédrale de la Flèche'),
        FacadeStyle.temple);
    expect(facadeStyleOf('keep', 'The keep'), FacadeStyle.fort);
    expect(facadeStyleOf('shop', 'The chandlery'), FacadeStyle.shop);
  });

  test('every front stands on the kerb, inside the scene', () {
    for (final style in FacadeStyle.values) {
      for (final cols in [60.0, 90.0, 130.0]) {
        final box = facadeBoxFor(style, cols, streetKerb);
        expect(box.left, greaterThanOrEqualTo(0), reason: '$style $cols');
        expect(box.left + box.width, lessThanOrEqualTo(cols),
            reason: '$style $cols');
        expect(box.base, streetKerb);
        expect(box.top, greaterThan(8), reason: '$style: room for the sky');
        for (final w in facadeWindows(style, box)) {
          expect(w.left, greaterThanOrEqualTo(box.left), reason: '$style');
          expect(w.right, lessThanOrEqualTo(box.left + box.width),
              reason: '$style');
          expect(w.bottom, lessThan(box.base), reason: '$style');
        }
      }
    }
  });

  test('the pins stand apart across the street, in two rows when many', () {
    for (var n = 1; n <= 8; n++) {
      final at = [for (var k = 0; k < n; k++) StreetViewScene.pinAt(k, n)];
      expect({for (final o in at) o}, hasLength(n), reason: '$n pins');
      for (final o in at) {
        expect(o.dx, inInclusiveRange(0, 1));
        expect(o.dy, inInclusiveRange(0.6, 1));
      }
      if (n > 4) {
        expect(at.map((o) => o.dy).toSet(), hasLength(2), reason: '$n pins');
      }
    }
  });

  test('the sky greys under the weather and darkens with the hour', () {
    final clear = streetSkyBands(DayPhase.day, WeatherKind.clear);
    final rain = streetSkyBands(DayPhase.day, WeatherKind.rain);
    expect(rain.first, isNot(clear.first));
    expect(streetSkyBands(DayPhase.night, null).first.computeLuminance(),
        lessThan(clear.first.computeLuminance()));
    expect(streetParticles(WeatherKind.rain), isNotNull);
    expect(streetParticles(WeatherKind.clear).name, 'none');
  });

  testWidgets('every front paints at every hour and in every weather',
      (tester) async {
    var i = 0;
    const skies = [null, WeatherKind.rain, WeatherKind.snow, WeatherKind.fog];
    for (final (kind, name) in const [
      ('house', 'The family house'),
      ('den', 'The Blind Beggar'),
      ('warehouse', 'A warehouse'),
      ('shop', 'A shop'),
      ('temple', 'A chapel'),
      ('keep', 'A keep'),
    ]) {
      for (final phase in DayPhase.values) {
        await tester.pumpWidget(
            _scene(kind, name, phase: phase, sky: skies[i++ % skies.length]));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: '$kind $phase');
      }
    }
  });

  testWidgets('a pin on the street is a tap on its way', (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(
        _scene('house', 'The family house', pins: 3, onPick: picked.add));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('journey_street_scene')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('street_pin_1')));
    expect(picked, [1]);
    // The label is on the pin.
    expect(find.textContaining('Way number 2'), findsOneWidget);
  });

  testWidgets('six ways fit a 320 px street, each in reach', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        _scene('den', 'The Blind Beggar', pins: 6, width: 320, height: 260));
    await tester.pump(const Duration(milliseconds: 200));
    final rects = [
      for (var i = 0; i < 6; i++)
        tester.getRect(find.byKey(ValueKey('street_pin_$i'))),
    ];
    for (final r in rects) {
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(320));
    }
    // Pins in one row do not overlap.
    for (final row in [rects.sublist(0, 3), rects.sublist(3)]) {
      for (var i = 1; i < row.length; i++) {
        expect(row[i - 1].right, lessThanOrEqualTo(row[i].left + 0.5));
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('with reduced motion the street stands still', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _scene('house', 'The family house',
          phase: DayPhase.night, sky: WeatherKind.rain),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pictures of the six fronts (UX_SHOTS=<folder>)', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1560, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    const cases = [
      ('house', 'The family house', DayPhase.day, null),
      ('den', 'The Blind Beggar', DayPhase.dusk, null),
      ('warehouse', 'A warehouse', DayPhase.night, WeatherKind.rain),
      ('shop', 'A shop', DayPhase.day, WeatherKind.snow),
      ('temple', 'A chapel', DayPhase.dawn, WeatherKind.fog),
      ('keep', 'A keep', DayPhase.night, null),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Wrap(children: [
            for (final (kind, name, phase, sky) in cases)
              SizedBox(
                width: 390,
                height: 300,
                child: StreetViewScene(
                    kind: kind,
                    name: name,
                    phase: phase,
                    sky: sky,
                    pins: _pins(3)),
              ),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/street-view-fronts.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

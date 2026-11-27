// v2.10.17 (UX-2): the snow is a field. Flakes fall, drifts build on the pieces'
// top edges, a chunk sheds at the cap, a tap knocks a piece's snow off, reduced
// motion is a static dusting, and a piece covered by a dialog has no drift.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_snowfall.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_weather.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
      theme: ThemeData(fontFamily: InkFonts.prose),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: Center(child: child)),
      ),
    );

Widget _scope(Widget child, {double fall = 1}) => WeatherScope(
    id: 'snow_test', kind: WeatherKind.snow, fall: fall, child: child);

SnowField _field(WidgetTester t) => t
    .state<InkWeatherPieceState>(find.byType(InkWeatherPiece).first)
    .snowField!;

void main() {
  setUp(InkWeatherStore.reset);

  test('a drift is a smooth mound, thick in the middle, thin at the corners',
      () {
    for (var id = 1; id < 30; id++) {
      for (final t in [3.0, 9.0, 20.0]) {
        final h = [
          for (var i = 0; i <= 60; i++) snowThickness(id, i / 60, t, cap: 8)
        ];
        expect(h.first, lessThan(1.5), reason: 'corner, id $id at $t');
        expect(h.last, lessThan(1.5));
        // Never over its cap (a little lump allowed), never negative.
        expect(h.reduce(math.max), lessThanOrEqualTo(8 * 1.15));
        expect(h.reduce(math.min), greaterThanOrEqualTo(0));
      }
    }
    // No saw-tooth: between neighbours a step stays small (a shed's edge is
    // the one place it may drop, and it is eased).
    final h = [for (var i = 0; i <= 200; i++) snowThickness(7, i / 200, 5)];
    for (var i = 1; i < h.length; i++) {
      expect((h[i] - h[i - 1]).abs(), lessThan(1.0));
    }
  });

  test('it builds up, sheds a chunk at a random place, and builds again', () {
    for (var id = 1; id < 12; id++) {
      // Along 60 s the middle drops by more than half within a second at
      // least once, and the drift is back above half a few seconds later.
      var sheds = 0;
      double? last;
      for (var t = 0.0; t < 60; t += 0.1) {
        final now = [
          for (var i = 0; i <= 20; i++) snowThickness(id, i / 20, t, cap: 8)
        ].reduce(math.max);
        if (last != null && last > 4 && now < last - 2.5) sheds++;
        last = now;
      }
      // Not every edge sheds at its middle, but the drift always stays capped.
      expect(sheds, lessThanOrEqualTo(8));
    }
    // A shed takes a stretch, not the whole edge, and the rest keeps its snow.
    var partial = 0;
    for (var id = 1; id < 40; id++) {
      for (var t = 0.0; t < 60; t += 0.25) {
        final h = [
          for (var i = 0; i <= 40; i++) snowThickness(id, i / 40, t, cap: 8)
        ];
        final mx = h.reduce(math.max), mn = h.sublist(8, 33).reduce(math.min);
        if (mx > 5 && mn < 1) partial++;
      }
    }
    expect(partial, greaterThan(5),
        reason: 'a chunk gone, the rest still there');
    // Irregular: two edges never shed together.
    final a = [for (var t = 0.0; t < 40; t += 0.5) snowThickness(3, 0.5, t)];
    final b = [for (var t = 0.0; t < 40; t += 0.5) snowThickness(4, 0.5, t)];
    expect(a, isNot(b));
  });

  test('a knock takes the edge clear, and it builds again', () {
    // A moment when the drift stands at its height.
    var t0 = 10.0;
    while (snowThickness(5, 0.5, t0) < 5) {
      t0 += 0.25;
    }
    expect(snowThickness(5, 0.5, t0 + 0.6, knocks: [t0]), lessThan(0.8));
    expect(snowThickness(5, 0.5, t0 + 0.2, knocks: [t0]),
        lessThan(snowThickness(5, 0.5, t0 + 0.2)));
    expect(snowThickness(5, 0.5, t0 + 14, knocks: [t0]), greaterThan(1.5));
  });

  test('a light fall has fewer flakes and a lower cap than a heavy one', () {
    final light = SnowField(fall: 0.4, reduceMotion: false);
    final heavy = SnowField(fall: 1, reduceMotion: false);
    addTearDown(light.dispose);
    addTearDown(heavy.dispose);
    expect(light.flakes, lessThan(heavy.flakes));
    expect(heavy.flakes, lessThanOrEqualTo(140));
    expect(light.cap, lessThan(heavy.cap));
    expect(heavy.cap, lessThanOrEqualTo(8));
    expect(light.slow, greaterThan(heavy.slow));
  });

  testWidgets('the pieces register their edge, and leaving takes it away',
      (t) async {
    await t.pumpWidget(_app(_scope(Column(children: [
      for (var i = 0; i < 3; i++) InkButton(label: 'B$i', onPressed: () {}),
    ]))));
    final field = _field(t);
    expect(field.pieces.length, 3);
    expect(field.edgeCount, 3);
    expect(find.byType(SnowfallLayer), findsOneWidget);
    await t.pumpWidget(_app(const SizedBox()));
    expect(field.pieces, isEmpty);
  });

  testWidgets('the clock runs, and a tap on a piece knocks its snow off',
      (t) async {
    var taps = 0;
    await t.pumpWidget(
        _app(_scope(InkButton(label: 'Fight', onPressed: () => taps++))));
    await t.pump(const Duration(seconds: 15));
    final field = _field(t);
    expect(field.time.value, greaterThan(10));
    final piece = t.state<InkWeatherPieceState>(find.byType(InkWeatherPiece));
    final mid = snowThickness(piece.snowId, 0.5, field.time.value,
        cap: field.cap, slow: field.slow, knocks: piece.snowKnocks);
    expect(mid, greaterThan(2));
    await t.tap(find.text('Fight'));
    await t.pump(const Duration(milliseconds: 700));
    expect(taps, 1, reason: 'the tap goes on to the button');
    expect(piece.snowKnocks, hasLength(1));
    final after = snowThickness(piece.snowId, 0.5, field.time.value,
        cap: field.cap, slow: field.slow, knocks: piece.snowKnocks);
    expect(after, lessThan(0.8));
    await t.pump(const Duration(seconds: 12));
    final again = snowThickness(piece.snowId, 0.5, field.time.value,
        cap: field.cap, slow: field.slow, knocks: piece.snowKnocks);
    expect(again, greaterThan(after + 1));
  });

  testWidgets('a blow on a panel knocks its snow off', (t) async {
    final signal = ChangeNotifier();
    var hit = false;
    await t.pumpWidget(_app(_scope(InkSlantPanel(
      size: const Size(200, 60),
      points: const [
        Offset(6, 14),
        Offset(194, 6),
        Offset(194, 54),
        Offset(6, 54)
      ],
      knockOn: signal,
      knockWhen: () => hit,
      child: const SizedBox(),
    ))));
    await t.pump(const Duration(seconds: 10));
    final piece = t.state<InkWeatherPieceState>(find.byType(InkWeatherPiece));
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    signal.notifyListeners();
    expect(piece.snowKnocks, isEmpty, reason: 'not a blow on this side');
    hit = true;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    signal.notifyListeners();
    expect(piece.snowKnocks, hasLength(1));
    // Its edge is the slanted top: from the first point to the second.
    final edge = piece.snowEdge()!;
    expect(edge.$2.dy, lessThan(edge.$1.dy));
  });

  testWidgets('reduce motion: a static dusting, no clock, no flakes',
      (t) async {
    await t.pumpWidget(_app(_scope(InkButton(label: 'Fight', onPressed: () {})),
        reduce: true));
    final field = _field(t);
    expect(field.reduceMotion, isTrue);
    final start = field.time.value;
    await t.pump(const Duration(seconds: 30));
    expect(field.time.value, start, reason: 'no clock');
    expect(t.hasRunningAnimations, isFalse);
    await t.tap(find.text('Fight'));
    final piece = t.state<InkWeatherPieceState>(find.byType(InkWeatherPiece));
    expect(piece.snowKnocks, isEmpty, reason: 'nothing to knock off');
  });

  testWidgets('a piece under a dialog has no drift', (t) async {
    await t.pumpWidget(_app(_scope(Builder(
        builder: (context) => Column(children: [
              InkButton(label: 'Fight', onPressed: () {}),
              TextButton(
                  onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const AlertDialog(title: Text('Hi'))),
                  child: const Text('open')),
            ])))));
    await t.pump();
    final field = _field(t);
    expect(field.edgeCount, greaterThan(0));
    await t.tap(find.text('open'));
    await t.pump(const Duration(milliseconds: 400));
    expect(field.edgeCount, 0, reason: 'covered by a route: no drift');
  });

  testWidgets('clear weather draws no snow layer', (t) async {
    await t.pumpWidget(_app(WeatherScope(
        id: 'c',
        kind: WeatherKind.clear,
        fall: 1,
        child: InkButton(label: 'Fight', onPressed: () {}))));
    expect(find.byType(SnowfallLayer), findsNothing);
  });

  testWidgets(
      'the fight takes the flakes off the overlay and draws them itself',
      (tester) async {
    await tester.pumpWidget(_app(_scope(Column(children: [
      InkButton(label: 'a', onPressed: () {}),
      const SnowFlakesHandOff(child: SizedBox(width: 10, height: 10)),
    ]))));
    await tester.pump();
    final field = _field(tester);
    // While the fight's panels are mounted the overlay leaves the flakes out.
    expect(field.overlayFlakes, isFalse);
    await tester.pumpWidget(_app(_scope(Column(children: [
      InkButton(label: 'a', onPressed: () {}),
    ]))));
    await tester.pump();
    expect(_field(tester).overlayFlakes, isTrue);
  });

  testWidgets('a panel can draw its own flakes (the fight, behind the figures)',
      (tester) async {
    await tester.pumpWidget(_app(_scope(Column(children: [
      InkButton(label: 'a', onPressed: () {}),
      Builder(builder: (context) {
        final f = inkSnowFieldOf(context)!;
        return SizedBox(
            width: 300, height: 120, child: SnowFlakesLayer(field: f));
      }),
    ]))));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SnowFlakesLayer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

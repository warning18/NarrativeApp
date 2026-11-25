// v2.1 (UX-2): seeded wear and weather on the ink pieces.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_seed.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_weather.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
      theme: ThemeData(fontFamily: InkFonts.prose),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: Center(child: child)),
      ),
    );

// The caps are the weathers' other than snow (snow is a field, see
// ux_snowfall_test.dart).
Widget _scope(Widget child,
        {WeatherKind kind = WeatherKind.ash, double fall = 1}) =>
    WeatherScope(id: 't', kind: kind, fall: fall, child: child);

InkWeatherPieceState _piece(WidgetTester t) =>
    t.state<InkWeatherPieceState>(find.byType(InkWeatherPiece).first);

void main() {
  setUp(InkWeatherStore.reset);

  test('the same seed gives the same look, others differ', () {
    final a = InkSeed.of('fight'), b = InkSeed.of('fight');
    expect(a, b);
    expect([a.red, a.paper, a.tilt, a.fold, a.burn, a.pin, a.chip],
        [b.red, b.paper, b.tilt, b.fold, b.burn, b.pin, b.chip]);
    final looks = {for (var i = 0; i < 40; i++) InkSeed.of('b$i').red};
    expect(looks.length, greaterThan(2));
    for (var i = 0; i < 200; i++) {
      final s = InkSeed.of('x$i');
      expect(s.tilt.abs(), inInclusiveRange(0.017, 0.053));
    }
  });

  test('the label stays AA on every tint', () {
    for (final r in inkReds) {
      expect(inkContrast(inkPaper, r), greaterThanOrEqualTo(4.5), reason: '$r');
    }
    for (final p in inkPapers) {
      expect(inkContrast(inkOnPaper, p), greaterThanOrEqualTo(4.5),
          reason: '$p');
    }
  });

  testWidgets('a cap never reaches the label box', (t) async {
    for (var lv = 0.0; lv <= 1.0; lv += 0.25) {
      final r = InkSkyPainter.capBounds(const Size(120, 40), lv);
      expect(r.bottom, lessThanOrEqualTo(2));
      expect(r.top, greaterThanOrEqualTo(-inkCapMaxHeight - 6));
    }
    await t.pumpWidget(_app(
        _scope(InkButton(label: 'Fight', onPressed: () {}, primary: true))));
    await t.pump(const Duration(seconds: 40));
    final box = t.getRect(find.byType(FilledButton));
    final label = t.getRect(find.text('Fight'));
    expect(box.contains(label.center), isTrue);
    // The cap lies above the box's top edge plus its 2 px of overlap.
    expect(box.top + 2, lessThan(label.top));
    expect(_piece(t).level, greaterThan(0.9));
  });

  testWidgets('reduce motion: a static medium cap, no clock', (t) async {
    final live = InkWeatherClock.live;
    await t.pumpWidget(_app(_scope(InkButton(label: 'Fight', onPressed: () {})),
        reduce: true));
    expect(_piece(t).level, inkMediumLevel);
    await t.pump(const Duration(seconds: 30));
    expect(_piece(t).level, inkMediumLevel);
    expect(InkWeatherClock.live, live + 1);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('a tap clears the level, and it builds again', (t) async {
    var taps = 0;
    await t.pumpWidget(
        _app(_scope(InkButton(label: 'Fight', onPressed: () => taps++))));
    await t.pump(const Duration(seconds: 20));
    final before = _piece(t).level;
    expect(before, greaterThan(0.5));
    await t.tap(find.text('Fight'));
    await t.pump();
    expect(taps, 1);
    expect(_piece(t).knocking, isTrue);
    await t.pump(const Duration(milliseconds: 600));
    expect(_piece(t).knocking, isFalse);
    expect(_piece(t).level, lessThan(0.1));
    await t.pump(const Duration(seconds: 10));
    expect(_piece(t).level, greaterThan(0.1));
  });

  testWidgets('one clock per screen, however many pieces', (t) async {
    final live = InkWeatherClock.live;
    await t.pumpWidget(_app(_scope(Column(children: [
      for (var i = 0; i < 5; i++) InkButton(label: 'B$i', onPressed: () {}),
      const InkTab('Tab'),
    ]))));
    expect(InkWeatherClock.live, live + 1);
    await t.pumpWidget(_app(const SizedBox()));
    expect(InkWeatherClock.live, live);
  });

  testWidgets('the level survives a rebuild and leaving', (t) async {
    await t
        .pumpWidget(_app(_scope(InkButton(label: 'Fight', onPressed: () {}))));
    await t.pump(const Duration(seconds: 15));
    await t.pumpWidget(_app(const SizedBox()));
    final kept = InkWeatherStore.restore('t', 1);
    expect(kept, greaterThan(10));
    await t
        .pumpWidget(_app(_scope(InkButton(label: 'Fight', onPressed: () {}))));
    expect(_piece(t).level, greaterThan(0.3));
  });

  testWidgets('clear weather and no scope draw nothing', (t) async {
    await t.pumpWidget(_app(_scope(InkButton(label: 'Fight', onPressed: () {}),
        kind: WeatherKind.clear)));
    expect(find.byType(InkWeatherPiece), findsOneWidget);
    expect(_piece(t).level, 0);
    await t.pumpWidget(_app(InkButton(label: 'Fight', onPressed: () {})));
    expect(_piece(t).level, 0);
  });
}

// Second round of the power sign (UX mock): the user found bars more visible
// than chevrons and the chevrons too big, so: smaller bars, and other ways,
// each shown the same way for comparison: one clan at the four tiers at the
// ring's size (34 px), the six clans mixed at 34 px, the four tiers at the
// standard's size (64 px) and one at the offer's full size (128 px). The
// standing sign (round disc, top corner) is on every banner, as it will be.
// Power is the clan card's four tiers (clan_power.dart's powerTierFor).
// UX_SHOTS=<folder> takes docs/ux-shots/power-bars-mock.png.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'ux_standing_sign_mock_test.dart' show StandingSign;

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    ('Spectral', ['Spectral-Regular.ttf', 'Spectral-Medium.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.view(
          Uint8List.fromList(File('assets/fonts/$f').readAsBytesSync())
              .buffer)));
    }
    await loader.load();
  }
}

const _bg = Color(0xFF17151B);
const _ash = Color(0xFF9A93A6);
const _gold = Color(0xFFE2B890);
const _metal = Color(0xFFF2C14E);
const _dim = Color(0xFF3A3642);

TextStyle _t(double size, {Color? c, bool bold = false}) => TextStyle(
    fontFamily: 'Spectral',
    fontSize: size,
    height: 1.25,
    color: c ?? const Color(0xFFEDE6DC),
    fontWeight: bold ? FontWeight.w600 : FontWeight.w400);

/// How a variant marks the power tier on a banner [h] tall and [w] wide.
enum _Way { bars, slimBars, steps, frame }

const _names = {
  _Way.bars: 'A. Bars (round 1)',
  _Way.slimBars: 'B. Slim bars: thinner, shorter',
  _Way.steps: 'C. Rising steps (signal bars)',
  _Way.frame: 'D. A rim round the banner',
};

const _notes = {
  _Way.bars: 'four 4 px bars under the hem',
  _Way.slimBars: 'four 2 px bars, 80% of the width',
  _Way.steps: 'four bars of rising height, centred under the hem',
  _Way.frame: 'none / bronze / silver / gold (double) rim, no extra room',
};

/// The marks under or around the banner, as a stack child list.
List<Widget> _marks(_Way way, PowerTier tier, double w, double h) {
  final lit = tier.index + 1;
  final u = math.max(1.0, h / 34);
  switch (way) {
    case _Way.bars:
      return [
        Positioned(
          left: 0,
          top: h + 3,
          width: w,
          child: Row(children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 4 * u.clamp(1, 1.6),
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  color: i < lit ? _metal : _dim,
                ),
              ),
          ]),
        ),
      ];
    case _Way.slimBars:
      final bw = w * 0.8;
      return [
        Positioned(
          left: (w - bw) / 2,
          top: h + 2.5,
          width: bw,
          child: Row(children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 2 * u.clamp(1, 1.5),
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  color: i < lit ? _metal : _dim,
                ),
              ),
          ]),
        ),
      ];
    case _Way.steps:
      final bar = math.max(2.0, 2.4 * u);
      final total = 4 * bar + 3 * 1.0;
      return [
        Positioned(
          left: (w - total) / 2,
          top: h + 2,
          child: SizedBox(
            width: total,
            height: bar * 2.6,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 1),
                Container(
                  width: bar,
                  height: bar * (0.9 + 0.55 * i),
                  color: i < lit ? _metal : _dim,
                ),
              ],
            ]),
          ),
        ),
      ];
    case _Way.frame:
      final colours = [
        const Color(0xFF4B4655),
        const Color(0xFFB0763F),
        const Color(0xFFC9CED6),
        _metal,
      ];
      final c = colours[tier.index];
      final t = math.max(1.0, 1.2 * u);
      return [
        Positioned(
          left: -t,
          top: -t,
          width: w + 2 * t,
          height: h + 2 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: c, width: t),
            ),
          ),
        ),
        if (tier == PowerTier.ascendant)
          Positioned(
            left: -3 * t,
            top: -3 * t,
            width: w + 6 * t,
            height: h + 6 * t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                    color: _metal.withValues(alpha: 0.6), width: t * 0.8),
              ),
            ),
          ),
      ];
  }
}

Widget _banner(String id, StandingTier standing, PowerTier tier, _Way way,
    {required double h, required double sign}) {
  final w = h / 2;
  return Padding(
    padding: EdgeInsets.only(
        right: sign * 0.45 + 4,
        bottom: way == _Way.frame ? 0 : 8 * math.max(1.0, h / 34)),
    child: SizedBox(
      width: w,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: 0, top: 0, child: ClanFlag(factionId: id, height: h)),
        ..._marks(way, tier, w, h),
        Positioned(
            right: -sign * 0.45,
            top: -sign * 0.15,
            child: StandingSign(standing, size: sign)),
      ]),
    ),
  );
}

const _mock = <(String, int, int)>[
  ('vigil', 14, 55),
  ('compact', 32, 82),
  ('mire', 2, 30),
  ('penitents', -8, 10),
  ('dominion', -40, 60),
  ('crows', 70, 20),
];

String _tierWord(PowerTier t) => switch (t) {
      PowerTier.minor => 'Minor',
      PowerTier.rising => 'Rising',
      PowerTier.dominant => 'Dominant',
      PowerTier.ascendant => 'Ascendant',
    };

Widget _row(_Way way) {
  Widget group(String label, List<Widget> kids) => Padding(
        padding: const EdgeInsets.only(right: 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: _t(10.5, c: _ash)),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: kids),
        ]),
      );
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_names[way]!, style: _t(14, c: _gold, bold: true)),
        const SizedBox(width: 10),
        Text(_notes[way]!, style: _t(11.5, c: _ash)),
      ]),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        group('34 px: minor · rising · dominant · ascendant', [
          for (final t in PowerTier.values)
            _banner('mire', StandingTier.unknown, t, way, h: 34, sign: 16),
        ]),
        group('34 px: the six clans mixed', [
          for (final (id, s, p) in _mock)
            _banner(id, standingTierFor(s), powerTierFor(p), way,
                h: 34, sign: 16),
        ]),
        group('64 px: the four tiers', [
          for (final t in PowerTier.values)
            _banner('vigil', StandingTier.friend, t, way, h: 64, sign: 20),
        ]),
        group('128 px: Dominant', [
          _banner('vigil', StandingTier.friend, PowerTier.dominant, way,
              h: 128, sign: 28),
        ]),
      ]),
    ]),
  );
}

Widget _board() => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Power on the banner: smaller bars, and other ways',
            style: _t(18)),
        const SizedBox(height: 4),
        Text(
            'Tiers: Minor (below 25) · Rising (25–49) · Dominant (50–74) · Ascendant (75 and up). '
            'Gold = lit. The standing disc stays top-right on every banner.',
            style: _t(11.5, c: _ash)),
        const SizedBox(height: 14),
        for (final way in _Way.values) _row(way),
      ]),
    );

void main() {
  setUpAll(_loadFonts);

  test('four tiers, four marks', () {
    expect(PowerTier.values.length, 4);
    expect(_Way.values.length, 4);
    expect(powerTierFor(risingPower), PowerTier.rising);
  });

  testWidgets('a picture of the power marks (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1260, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          child: RepaintBoundary(
              key: key, child: ColoredBox(color: _bg, child: _board())),
        ),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/power-bars-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

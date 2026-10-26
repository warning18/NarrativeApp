// Third round of the power sign (UX mock): the user chose the rising steps
// (way C of power-bars-mock) and wants the bars to change colour as the tier
// grows too. Four colour ramps are shown the same way, for comparison: one
// clan at the four tiers at the ring's size (34 px), the six clans mixed at
// 34 px, the four tiers at the standard's size (64 px) and one at the offer's
// full size (128 px). The standing sign (round disc, top corner; green, grey,
// red) is on every banner. Power is the clan card's four tiers.
// Every ramp gets lighter with the tier, so the tier also reads by lightness
// (not by hue alone). UX_SHOTS=<folder> takes docs/ux-shots/power-colour-mock.png.
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

/// A colour ramp for the four tiers. [perBar] colours each bar by its own
/// position (a lit bar always wears its own colour); otherwise every lit bar
/// wears the tier's colour.
class _Ramp {
  const _Ramp(this.name, this.note, this.colours, {this.perBar = false});
  final String name;
  final String note;
  final List<Color> colours;
  final bool perBar;
}

const _ramps = [
  _Ramp(
    'P1. Metals, the tier\u2019s colour on every lit bar',
    'bronze · silver · gold · white-gold (a glow at Ascendant)',
    [
      Color(0xFFB0763F),
      Color(0xFFA9B1BD),
      Color(0xFFF2C14E),
      Color(0xFFFFF1B8)
    ],
  ),
  _Ramp(
    'P2. Cool to warm, the tier\u2019s colour on every lit bar',
    'steel blue · violet · amber · gold (no green, no red: those are standing\u2019s)',
    [
      Color(0xFF4F73BE),
      Color(0xFFB594F0),
      Color(0xFFF0A23A),
      Color(0xFFFFD84D)
    ],
  ),
  _Ramp(
    'P3. One gold that brightens',
    'dim bronze-gold · gold · bright gold · pale gold',
    [
      Color(0xFF9A7432),
      Color(0xFFCB9B3A),
      Color(0xFFF2C14E),
      Color(0xFFFFE9A0)
    ],
  ),
  _Ramp(
    'P4. Each bar wears its own colour (a gradient that grows)',
    'bar 1 bronze, 2 silver, 3 gold, 4 white-gold: a lit bar never changes',
    [
      Color(0xFFB0763F),
      Color(0xFFA9B1BD),
      Color(0xFFF2C14E),
      Color(0xFFFFF1B8)
    ],
    perBar: true,
  ),
];

const _dimBar = Color(0xFF3A3642);

/// The rising steps, centred under the hem, lit and coloured by [ramp].
Widget _steps(_Ramp ramp, PowerTier tier, double w, double h) {
  final lit = tier.index + 1;
  final u = math.max(1.0, h / 34);
  final bar = math.max(2.0, 2.4 * u);
  final total = 4 * bar + 3 * 1.0;
  return Positioned(
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
            decoration: BoxDecoration(
              color: i < lit
                  ? (ramp.perBar ? ramp.colours[i] : ramp.colours[tier.index])
                  : _dimBar,
              boxShadow: tier == PowerTier.ascendant && i < lit
                  ? [
                      BoxShadow(
                          color: ramp.colours[3].withValues(alpha: 0.55),
                          blurRadius: 3 * u.clamp(1, 2))
                    ]
                  : null,
            ),
          ),
        ],
      ]),
    ),
  );
}

Widget _banner(String id, StandingTier standing, PowerTier tier, _Ramp ramp,
    {required double h, required double sign}) {
  final w = h / 2;
  return Padding(
    padding: EdgeInsets.only(
        right: sign * 0.45 + 4, bottom: 8 * math.max(1.0, h / 34)),
    child: SizedBox(
      width: w,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: 0, top: 0, child: ClanFlag(factionId: id, height: h)),
        _steps(ramp, tier, w, h),
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

Widget _row(_Ramp ramp) {
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
        Text(ramp.name, style: _t(14, c: _gold, bold: true)),
        const SizedBox(width: 10),
        // The ramp's four swatches.
        for (final c in ramp.colours)
          Container(
              width: 14,
              height: 8,
              margin: const EdgeInsets.only(right: 2),
              color: c),
        const SizedBox(width: 8),
        Text(ramp.note, style: _t(11.5, c: _ash)),
      ]),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        group('34 px: minor · rising · dominant · ascendant', [
          for (final t in PowerTier.values)
            _banner('mire', StandingTier.unknown, t, ramp, h: 34, sign: 16),
        ]),
        group('34 px: the six clans mixed', [
          for (final (id, s, p) in _mock)
            _banner(id, standingTierFor(s), powerTierFor(p), ramp,
                h: 34, sign: 16),
        ]),
        group('64 px: the four tiers', [
          for (final t in PowerTier.values)
            _banner('vigil', StandingTier.friend, t, ramp, h: 64, sign: 20),
        ]),
        group('128 px: Dominant', [
          _banner('vigil', StandingTier.friend, PowerTier.dominant, ramp,
              h: 128, sign: 28),
        ]),
      ]),
    ]),
  );
}

Widget _board() => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Power as rising steps whose colour grows with the tier',
            style: _t(18)),
        const SizedBox(height: 4),
        Text(
            'Tiers: Minor (below 25) · Rising (25–49) · Dominant (50–74) · Ascendant (75 and up). '
            'Unlit steps stay dark. The standing disc stays top-right on every banner.',
            style: _t(11.5, c: _ash)),
        const SizedBox(height: 14),
        for (final ramp in _ramps) _row(ramp),
      ]),
    );

void main() {
  setUpAll(_loadFonts);

  test('every ramp gets lighter with the tier, so it reads without hue', () {
    for (final ramp in _ramps) {
      for (var i = 1; i < 4; i++) {
        expect(ramp.colours[i].computeLuminance(),
            greaterThan(ramp.colours[i - 1].computeLuminance()),
            reason: '${ramp.name} step $i');
      }
    }
    expect(PowerTier.values.length, 4);
    expect(powerTierFor(risingPower), PowerTier.rising);
  });

  testWidgets('a picture of the power colours (UX_SHOTS=<folder>)',
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
      File('$dir/power-colour-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

// The power sign, redrawn (UX mock): the user rejected the rising bars, so
// three genuinely different ways to read how strong a clan is, at a glance,
// on its banner and at its point on the ring. Nothing about relationship is
// on it (no green, no red, no heart): only the clan card's four power tiers
// (clan_power.dart: Minor below 25, Rising 25, Dominant 50, Ascendant 75).
//   A. A rank numeral (I to IV) on a small plate at the banner's foot.
//   B. The banner's cloth fills with its colour from the foot, a quarter for
//      each tier; the rest of the cloth stays a dark silhouette.
//   C. Size and aura: on the ring the crest itself grows with its tier; on a
//      banner a gold aura grows round it.
// Each is shown at the offer's size (128 px), the Throne room's (64 px), the
// ring's crests (34 px) and on the ring itself.
// UX_SHOTS=<folder> takes docs/ux-shots/power-ways-mock.png.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
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

TextStyle _t(double size, {Color? c, bool bold = false, bool italic = false}) =>
    TextStyle(
        fontFamily: 'Spectral',
        fontSize: size,
        height: 1.25,
        color: c ?? const Color(0xFFEDE6DC),
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal);

enum _Way { numeral, fill, aura }

const _numerals = ['I', 'II', 'III', 'IV'];

/// The cloth shows only from the foot up to [frac] of its height.
class _FromFoot extends CustomClipper<Rect> {
  _FromFoot(this.frac);
  final double frac;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(
      0, size.height * (1 - frac), size.width, size.height * frac);
  @override
  bool shouldReclip(_FromFoot old) => old.frac != frac;
}

/// A banner marked with its power tier by way [way].
Widget _banner(String id, PowerTier tier, _Way way, {required double h}) {
  final w = h / 2;
  final u = math.max(1.0, h / 34);
  switch (way) {
    case _Way.numeral:
      final plateW = math.max(13.0, w * 0.5);
      final plateH = math.max(13.0, h * 0.14);
      final top = tier == PowerTier.ascendant;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(clipBehavior: Clip.none, children: [
          ClanFlag(factionId: id, height: h),
          Positioned(
            left: (w - plateW) / 2,
            top: h - plateH - h * 0.06,
            child: Container(
              width: plateW,
              height: plateH,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: top ? _metal : const Color(0xFF14121A),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                    color: top ? const Color(0xFF8A6B1E) : _metal, width: 1),
              ),
              child: Text(_numerals[tier.index],
                  style: TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: math.max(8.0, plateH * 0.66),
                      height: 1,
                      color: top ? const Color(0xFF14121A) : _metal)),
            ),
          ),
        ]),
      );
    case _Way.fill:
      final frac = (tier.index + 1) / 4;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(clipBehavior: Clip.none, children: [
          // The empty cloth: a dark silhouette.
          ClanFlag(factionId: id, height: h, found: false),
          // The filled part: the banner's own colours, from the foot up.
          ClipRect(
              clipper: _FromFoot(frac),
              child: ClanFlag(factionId: id, height: h)),
          // A hairline at the fill's edge, so the level reads at 34 px.
          if (frac < 1)
            Positioned(
              left: 0,
              right: 0,
              top: h * (1 - frac),
              child: Container(height: math.max(1, u * 0.8), color: _metal),
            ),
        ]),
      );
    case _Way.aura:
      final a = [0.0, 0.22, 0.45, 0.8][tier.index];
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          boxShadow: a == 0
              ? null
              : [
                  BoxShadow(
                      color: _metal.withValues(alpha: a),
                      blurRadius: (4 + tier.index * 3) * u.clamp(1, 2.2),
                      spreadRadius: tier.index * 0.8 * u.clamp(1, 2)),
                ],
        ),
        child: ClanFlag(factionId: id, height: h),
      );
  }
}

const _tiers = [
  ('penitents', PowerTier.minor),
  ('mire', PowerTier.rising),
  ('vigil', PowerTier.dominant),
  ('compact', PowerTier.ascendant),
];

const _six = [
  ('vigil', PowerTier.dominant),
  ('compact', PowerTier.ascendant),
  ('mire', PowerTier.rising),
  ('penitents', PowerTier.minor),
  ('dominion', PowerTier.dominant),
  ('crows', PowerTier.minor),
];

String _word(PowerTier t) => switch (t) {
      PowerTier.minor => 'Minor',
      PowerTier.rising => 'Rising',
      PowerTier.dominant => 'Dominant',
      PowerTier.ascendant => 'Ascendant',
    };

/// The ring: six crests round a circle; way C grows each crest with its tier.
Widget _ring(_Way way) {
  const w = 330.0;
  final points = [
    for (var i = 0; i < _six.length; i++)
      Offset(
          w / 2 +
              math.cos(-math.pi / 2 + i * 2 * math.pi / _six.length) * w * 0.34,
          w / 2 +
              math.sin(-math.pi / 2 + i * 2 * math.pi / _six.length) *
                  w *
                  0.34),
  ];
  const scales = [0.78, 0.95, 1.12, 1.3];
  return SizedBox(
    width: w,
    height: w,
    child: Stack(children: [
      CustomPaint(size: const Size(w, w), painter: _RingLine()),
      for (var i = 0; i < _six.length; i++)
        Positioned(
          left: points[i].dx - 30,
          top: points[i].dy - 36,
          child: SizedBox(
            width: 60,
            height: 72,
            child: Center(
              child: Transform.scale(
                scale: way == _Way.aura ? scales[_six[i].$2.index] : 1,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1B22),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF3A3642)),
                  ),
                  child: _banner(_six[i].$1, _six[i].$2, way, h: 34),
                ),
              ),
            ),
          ),
        ),
    ]),
  );
}

class _RingLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
      size.center(Offset.zero),
      size.width * 0.34,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF3A3642));

  @override
  bool shouldRepaint(_RingLine old) => false;
}

Widget _column(_Way way, String name, String line, String verdict) {
  Widget label(String s) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(s, style: _t(11.5, c: _ash)),
      );
  return SizedBox(
    width: 430,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: _t(16, c: _gold, bold: true)),
      const SizedBox(height: 2),
      Text(line, style: _t(12, c: _ash)),
      label(
          'The offer’s banners (128 px): Minor · Rising · Dominant · Ascendant'),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final (id, t) in _tiers)
          Padding(
            padding: const EdgeInsets.only(right: 26),
            child: Column(children: [
              _banner(id, t, way, h: 128),
              const SizedBox(height: 4),
              Text(_word(t), style: _t(10.5, c: _metal)),
            ]),
          ),
      ]),
      label(
          'The Throne room’s standards (64 px), and the ring’s crests (34 px)'),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final (id, t) in _tiers)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _banner(id, t, way, h: 64),
          ),
        const SizedBox(width: 12),
        for (final (id, t) in _six)
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: _banner(id, t, way, h: 34),
          ),
      ]),
      label('The ring'),
      _ring(way),
      Text(verdict, style: _t(11.5, c: _ash, italic: true)),
    ]),
  );
}

Widget _board() => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            'How strong each clan is: three ways, no bars, nothing about relationship',
            style: _t(18)),
        const SizedBox(height: 4),
        Text(
            'Minor (below 25) · Rising (25–49) · Dominant (50–74) · Ascendant (75 and up): the clan card’s four tiers.',
            style: _t(11.5, c: _ash)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _column(
              _Way.numeral,
              'A. A rank numeral',
              'I, II, III or IV on a small plate at the foot; the plate goes gold at IV.',
              'Exact and quiet: it names the tier. Needs reading, so it is slower than the others at a glance.'),
          const SizedBox(width: 18),
          _column(
              _Way.fill,
              'B. The cloth fills',
              'The banner is a dark silhouette that fills with its colours from the foot, a quarter for each tier.',
              'The banner itself is the gauge: a strong clan looks full, a minor one empty. Costs the look of a weak clan’s banner.'),
          const SizedBox(width: 18),
          _column(
              _Way.aura,
              'C. Size and aura',
              'On the ring the crest grows with its tier; on a banner a gold glow grows round it.',
              'The loudest at a glance. On a banner it is only a glow, so the four tiers are close at 34 px.'),
        ]),
      ]),
    );

void main() {
  setUpAll(_loadFonts);

  test('four tiers, three ways', () {
    expect(PowerTier.values.length, 4);
    expect(_Way.values.length, 3);
    expect(_numerals.length, 4);
    expect(powerTierFor(ascendantPower), PowerTier.ascendant);
  });

  testWidgets('a picture of the power ways (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: RepaintBoundary(
                key: key, child: ColoredBox(color: _bg, child: _board())),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.4);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/power-ways-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

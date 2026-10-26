// A mock of the power sign (UX, for the user to approve before anything is
// built), next to the standing sign: how strong a clan is now, read at a
// glance on its banner and on the ring. Power is the clan card's four tiers
// (Minor, Rising, Dominant, Ascendant: clan_power.dart's powerTierFor), no new
// numbers. It is drawn so it can never be mistaken for the standing sign:
// standing is a round disc in the top corner in green / grey / red; power is
// rank chevrons on a flat plate at the foot, in gold, and on the ring the
// crest itself grows with the tier.
// UX_SHOTS=<folder> takes docs/ux-shots/power-sign-mock.png.
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

TextStyle _t(double size, {Color? c, bool bold = false}) => TextStyle(
    fontFamily: 'Spectral',
    fontSize: size,
    height: 1.25,
    color: c ?? const Color(0xFFEDE6DC),
    fontWeight: bold ? FontWeight.w600 : FontWeight.w400);

/// Rank chevrons on a flat plate: one to four, the rest dim; the plate's rim
/// goes gold at Ascendant.
class _RankPainter extends CustomPainter {
  _RankPainter(this.tier);
  final PowerTier tier;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final plate = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    canvas.drawRRect(plate, Paint()..color = const Color(0xFF14121A));
    final top = tier == PowerTier.ascendant;
    canvas.drawRRect(
        plate.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = top ? _metal : const Color(0xFF6B6275));
    const slots = 4;
    final lit = tier.index + 1;
    final pad = size.width * 0.14;
    final slotH = (size.height - 2 * pad) / slots;
    final stroke = math.max(1.0, slotH * 0.42);
    for (var i = 0; i < slots; i++) {
      // The highest chevron is lit first from the bottom.
      final fromBottom = slots - 1 - i;
      final on = fromBottom < lit;
      final y = pad + i * slotH + slotH * 0.5;
      final path = Path()
        ..moveTo(pad, y + slotH * 0.28)
        ..lineTo(size.width / 2, y - slotH * 0.28)
        ..lineTo(size.width - pad, y + slotH * 0.28);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.butt
            ..isAntiAlias = false
            ..color = on ? _metal : const Color(0xFF3A3642));
    }
  }

  @override
  bool shouldRepaint(_RankPainter old) => old.tier != tier;
}

class _PowerPlate extends StatelessWidget {
  const _PowerPlate(this.tier, {required this.width, required this.height});
  final PowerTier tier;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _RankPainter(tier)));
}

/// Variant B: four bars under the hem, one lit per tier.
class _PowerBars extends StatelessWidget {
  const _PowerBars(this.tier, {required this.width, required this.height});
  final PowerTier tier;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: Row(children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                color: i <= tier.index ? _metal : const Color(0xFF3A3642),
              ),
            ),
        ]),
      );
}

enum _Mark { chevrons, bars }

/// A banner with the standing sign top-right and the power mark at the foot.
Widget _banner(String id, StandingTier standing, PowerTier power,
    {required double height,
    required double sign,
    _Mark mark = _Mark.chevrons,
    bool withStanding = true}) {
  final w = height / 2;
  final plateW = math.max(14.0, w * 0.62);
  final plateH = math.max(13.0, height * 0.20);
  return SizedBox(
    width: w + sign * 0.4,
    height: height + (mark == _Mark.bars ? 7 : 0),
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned(
          left: 0, top: 0, child: ClanFlag(factionId: id, height: height)),
      if (withStanding)
        Positioned(
            right: 0,
            top: -sign * 0.15,
            child: StandingSign(standing, size: sign)),
      if (mark == _Mark.chevrons)
        Positioned(
          left: (w - plateW) / 2,
          top: height - plateH - height * 0.07,
          child: _PowerPlate(power, width: plateW, height: plateH),
        )
      else
        Positioned(
          left: 0,
          top: height + 3,
          child: _PowerBars(power, width: w, height: 4),
        ),
    ]),
  );
}

const _mock = <(String, String, int, int)>[
  // id, name, standing, power
  ('vigil', 'Vigil', 14, 55),
  ('compact', 'Compact', 32, 82),
  ('mire', 'Mire', 2, 30),
  ('penitents', 'Penitents', -8, 10),
  ('dominion', 'Dominion', -40, 60),
  ('crows', 'Crows', 70, 20),
];

String _tierWord(PowerTier t) => switch (t) {
      PowerTier.minor => 'Minor',
      PowerTier.rising => 'Rising',
      PowerTier.dominant => 'Dominant',
      PowerTier.ascendant => 'Ascendant',
    };

Widget _title(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(s, style: _t(14, c: _gold, bold: true)),
    );

Widget _offer() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(
          'On the offer’s banners (full size): standing top-right, power at the foot'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (id, name, standing, power) in [
          _mock[3],
          _mock[2],
          _mock[0],
          _mock[1]
        ])
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(children: [
              _banner(id, standingTierFor(standing), powerTierFor(power),
                  height: 128, sign: 28),
              const SizedBox(height: 6),
              Text(name, style: _t(12.5)),
              Text(_tierWord(powerTierFor(power)), style: _t(11, c: _metal)),
            ]),
          ),
        const SizedBox(width: 18),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Option B: four bars under the hem', style: _t(11.5, c: _ash)),
          const SizedBox(height: 6),
          Row(children: [
            for (final (id, _, standing, power) in [_mock[2], _mock[1]])
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _banner(
                    id, standingTierFor(standing), powerTierFor(power),
                    height: 96, sign: 24, mark: _Mark.bars),
              ),
          ]),
        ]),
      ]),
    ]);

Widget _small() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(
          'Smallest sizes: the ring’s crests and the Throne room’s standards'),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final (id, _, standing, power) in _mock)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _banner(id, standingTierFor(standing), powerTierFor(power),
                height: 34, sign: 16),
          ),
        const SizedBox(width: 10),
        for (final (id, _, standing, power) in _mock.sublist(0, 3))
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _banner(id, standingTierFor(standing), powerTierFor(power),
                height: 64, sign: 20),
          ),
      ]),
      const SizedBox(height: 6),
      Text(
          'Power marks keep at least 14 × 13 px; the chevrons still count at 34 px.',
          style: _t(11.5, c: _ash)),
    ]);

class _RingPainter extends CustomPainter {
  _RingPainter(this.points);
  final List<Offset> points;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
        size.center(Offset.zero),
        size.width * 0.36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF3A3642));
    const colours = [
      Color(0xFF6BB985),
      Color(0xFFA8A194),
      Color(0xFFD9544D),
      Color(0xFFD9544D),
      Color(0xFF6BB985),
    ];
    var k = 0;
    for (var i = 1; i < points.length; i++) {
      canvas.drawLine(
          points[0],
          points[i],
          Paint()
            ..strokeWidth = 1.5
            ..color = colours[k++ % colours.length].withValues(alpha: 0.8));
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

/// The ring: with [power] the crest grows with the tier and wears the chevrons.
Widget _ring({required bool power}) {
  const w = 300.0;
  final points = [
    for (var i = 0; i < _mock.length; i++)
      Offset(
          w / 2 +
              math.cos(-math.pi / 2 + i * 2 * math.pi / _mock.length) *
                  w *
                  0.36,
          w / 2 +
              math.sin(-math.pi / 2 + i * 2 * math.pi / _mock.length) *
                  w *
                  0.36),
  ];
  const scales = {
    PowerTier.minor: 0.8,
    PowerTier.rising: 0.95,
    PowerTier.dominant: 1.1,
    PowerTier.ascendant: 1.28,
  };
  return SizedBox(
    width: w,
    height: w + 10,
    child: Stack(children: [
      CustomPaint(size: const Size(w, w), painter: _RingPainter(points)),
      for (var i = 0; i < _mock.length; i++)
        Positioned(
          left: points[i].dx - 24,
          top: points[i].dy - 30,
          child: Transform.scale(
            scale: power ? scales[powerTierFor(_mock[i].$4)]! : 1,
            child: SizedBox(
              width: 48,
              height: 60,
              child: Center(
                child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1D1B22),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: power &&
                                    powerTierFor(_mock[i].$4) ==
                                        PowerTier.ascendant
                                ? _metal
                                : const Color(0xFF3A3642))),
                    child: _banner(_mock[i].$1, standingTierFor(_mock[i].$3),
                        powerTierFor(_mock[i].$4),
                        height: 34, sign: 16, mark: _Mark.chevrons)),
              ),
            ),
          ),
        ),
      for (var i = 0; i < _mock.length; i++)
        Positioned(
          left: points[i].dx - 30,
          top: points[i].dy + 30,
          width: 60,
          child: Text(_mock[i].$2,
              textAlign: TextAlign.center, style: _t(10.5, c: _ash)),
        ),
    ]),
  );
}

Widget _legend() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(
          'The four tiers (clan_power.dart: below 25 · 25 · 50 · 75 and up)'),
      Row(children: [
        for (final t in PowerTier.values)
          Padding(
            padding: const EdgeInsets.only(right: 34),
            child: Row(children: [
              _PowerPlate(t, width: 24, height: 26),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_tierWord(t), style: _t(13, c: _metal, bold: true)),
                Text(
                    switch (t) {
                      PowerTier.minor => 'below 25',
                      PowerTier.rising => '25 to 49',
                      PowerTier.dominant => '50 to 74',
                      PowerTier.ascendant => '75 and up',
                    },
                    style: _t(11, c: _ash)),
              ]),
            ]),
          ),
      ]),
      const SizedBox(height: 14),
      _title('Two signs, never mixed up'),
      Text(
          'Standing: a round disc, top corner, green / grey / red, a heart, a dot or blades.\n'
          'Power: a flat plate at the foot, gold, one to four chevrons (the clan card’s four tiers).\n'
          'Different shape, place and colour, so each reads alone at 16 px. On the ring the crest also grows with its tier.',
          style: _t(12, c: _ash)),
    ]);

Widget _board() => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How strong each clan is now, beside how it stands with you',
            style: _t(18)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _offer(),
                const SizedBox(height: 22),
                _small(),
              ])),
          const SizedBox(width: 12),
          Column(children: [
            _title('Ring with the standing sign'),
            _ring(power: false),
          ]),
          const SizedBox(width: 8),
          Column(children: [
            _title('Ring with standing + power'),
            _ring(power: true),
          ]),
        ]),
        const SizedBox(height: 18),
        _legend(),
      ]),
    );

void main() {
  setUpAll(_loadFonts);

  test('every power tier has a mark, and the thresholds are the game’s', () {
    expect(powerTierFor(24), PowerTier.minor);
    expect(powerTierFor(risingPower), PowerTier.rising);
    expect(powerTierFor(dominantPower), PowerTier.dominant);
    expect(powerTierFor(ascendantPower), PowerTier.ascendant);
    expect(PowerTier.values.length, 4);
  });

  testWidgets('a picture of the power sign (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1340, 580);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        backgroundColor: _bg,
        body: RepaintBoundary(
            key: key, child: ColoredBox(color: _bg, child: _board())),
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
      File('$dir/power-sign-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

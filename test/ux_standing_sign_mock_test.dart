// A mock of the standing sign (UX, for the user to approve before anything is
// built): a small sign in the corner of every clan banner, and at every
// clan's point on the ring, that says how the clan stands with the player at
// a glance: the standing step the clan card already shows (standing_tier_*),
// in the game's own tier colours, so no new numbers. Green hearts and shields
// for friends, a grey dot for strangers, red blades for enemies. The banners
// are the game's own ClanFlag; the ring is drawn as the compass draws it.
// UX_SHOTS=<folder> takes docs/ux-shots/standing-sign-mock.png.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
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
}

const _bg = Color(0xFF17151B);
const _ash = Color(0xFF9A93A6);
const _gold = Color(0xFFE2B890);

TextStyle _t(double size, {Color? c, bool bold = false}) => TextStyle(
    fontFamily: 'Spectral',
    fontSize: size,
    height: 1.25,
    color: c ?? const Color(0xFFEDE6DC),
    fontWeight: bold ? FontWeight.w600 : FontWeight.w400);

/// A sign's shape: seven rows of seven pixels.
enum _Glyph { blades, slash, dot, ring, heart, shield, star }

const Map<_Glyph, List<String>> _bits = {
  _Glyph.blades: [
    '#.....#',
    '.#...#.',
    '..#.#..',
    '...#...',
    '..#.#..',
    '.#...#.',
    '#.....#',
  ],
  _Glyph.slash: [
    '#......',
    '##.....',
    '.##....',
    '..##...',
    '...##..',
    '....##.',
    '.....##',
  ],
  _Glyph.dot: [
    '.......',
    '.......',
    '..###..',
    '..###..',
    '..###..',
    '.......',
    '.......',
  ],
  _Glyph.ring: [
    '.......',
    '..###..',
    '.#...#.',
    '.#...#.',
    '.#...#.',
    '..###..',
    '.......',
  ],
  _Glyph.heart: [
    '.##.##.',
    '#######',
    '#######',
    '.#####.',
    '..###..',
    '...#...',
    '.......',
  ],
  _Glyph.shield: [
    '#######',
    '#######',
    '#######',
    '.#####.',
    '.#####.',
    '..###..',
    '...#...',
  ],
  _Glyph.star: [
    '...#...',
    '...#...',
    '#######',
    '.#####.',
    '..###..',
    '.##.##.',
    '.#...#.',
  ],
};

/// The sign each standing step takes. The colour is the step's own.
_Glyph glyphOf(StandingTier tier) => switch (tier) {
      StandingTier.hunted || StandingTier.hostile => _Glyph.blades,
      StandingTier.resented ||
      StandingTier.unfriendly ||
      StandingTier.wary =>
        _Glyph.slash,
      StandingTier.unknown => _Glyph.dot,
      StandingTier.known => _Glyph.ring,
      StandingTier.friendly || StandingTier.friend => _Glyph.heart,
      StandingTier.trusted => _Glyph.shield,
      StandingTier.sworn => _Glyph.star,
    };

class _SignPainter extends CustomPainter {
  _SignPainter(this.glyph, this.colour, {this.double_ = false});
  final _Glyph glyph;
  final Color colour;
  final bool double_;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF14121A));
    canvas.drawCircle(
        c,
        r - 0.75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = colour);
    if (double_) {
      canvas.drawCircle(
          c,
          r + 1.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = colour.withValues(alpha: 0.7));
    }
    // The glyph on a pixel grid inside the disc, hard edges.
    final px = (size.width * 0.58) / 7;
    final origin = c - Offset(px * 3.5, px * 3.5);
    final p = Paint()
      ..color = colour
      ..isAntiAlias = false;
    final rows = _bits[glyph]!;
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        if (rows[y][x] == '#') {
          canvas.drawRect(
              Rect.fromLTWH(origin.dx + x * px, origin.dy + y * px, px, px), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SignPainter old) => false;
}

/// The sign for [tier], [size] logical pixels across.
class StandingSign extends StatelessWidget {
  const StandingSign(this.tier, {super.key, this.size = 18});
  final StandingTier tier;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _SignPainter(glyphOf(tier), Color(tierColor(tier)),
              double_:
                  tier == StandingTier.hunted || tier == StandingTier.sworn),
        ),
      );
}

/// A banner with its sign in the top-right corner.
Widget _bannerWithSign(String id, StandingTier tier,
        {required double height, required double sign}) =>
    SizedBox(
      width: height / 2 + sign * 0.4,
      height: height,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
            left: 0, top: 0, child: ClanFlag(factionId: id, height: height)),
        Positioned(
            right: 0, top: -sign * 0.15, child: StandingSign(tier, size: sign)),
      ]),
    );

const _mock = <(String, String, int)>[
  ('vigil', 'Vigil', 14),
  ('compact', 'Compact', 32),
  ('mire', 'Mire', 2),
  ('penitents', 'Penitents', -8),
  ('dominion', 'Dominion', -40),
  ('crows', 'Crows', 70),
];

String _word(StandingTier t) => t.name[0].toUpperCase() + t.name.substring(1);

Widget _title(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(s, style: _t(14, c: _gold, bold: true)),
    );

/// The offer's banners, at the offer's size (a banner 128 tall).
Widget _offer() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('On the offer’s banners (full size)'),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (id, name, standing)
            in _mock.sublist(0, 3).followedBy([_mock[4]]))
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Column(children: [
              _bannerWithSign(id, standingTierFor(standing),
                  height: 128, sign: 28),
              const SizedBox(height: 6),
              Text(name, style: _t(12.5)),
              Text(_word(standingTierFor(standing)),
                  style:
                      _t(11, c: Color(tierColor(standingTierFor(standing))))),
            ]),
          ),
      ]),
    ]);

/// The smallest sizes: the ring's crests and the Throne room's standards.
Widget _small() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(
          'Smallest sizes: the ring’s crests and the Throne room’s standards'),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final (id, _, standing) in _mock)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _bannerWithSign(id, standingTierFor(standing),
                height: 34, sign: 16),
          ),
        const SizedBox(width: 10),
        for (final (id, _, standing) in _mock.sublist(0, 3))
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _bannerWithSign(id, standingTierFor(standing),
                height: 64, sign: 20),
          ),
      ]),
      const SizedBox(height: 6),
      Text(
          'The sign never goes under 14 px; its disc keeps it readable on any banner.',
          style: _t(11.5, c: _ash)),
    ]);

class _RingPainter extends CustomPainter {
  _RingPainter(this.points, this.focus);
  final List<Offset> points;
  final int focus;
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF3A3642);
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.36, ring);
    // The focused clan's lines to the others: friends green, enemies red.
    const colours = [
      Color(0xFF6BB985),
      Color(0xFFA8A194),
      Color(0xFFD9544D),
      Color(0xFFD9544D),
      Color(0xFF6BB985),
    ];
    var k = 0;
    for (var i = 0; i < points.length; i++) {
      if (i == focus) continue;
      canvas.drawLine(
          points[focus],
          points[i],
          Paint()
            ..strokeWidth = 1.5
            ..color = colours[k % colours.length].withValues(alpha: 0.8));
      k++;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

/// The ring: crests round a circle, lines from the focused clan, a sign at
/// every clan's point.
Widget _ring({required bool signs}) {
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
  return SizedBox(
    width: w,
    height: w,
    child: Stack(children: [
      CustomPaint(size: const Size(w, w), painter: _RingPainter(points, 0)),
      for (var i = 0; i < _mock.length; i++)
        Positioned(
          left: points[i].dx - 17,
          top: points[i].dy - 20,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: const Color(0xFF1D1B22),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF3A3642))),
            child: signs
                ? _bannerWithSign(_mock[i].$1, standingTierFor(_mock[i].$3),
                    height: 34, sign: 16)
                : ClanFlag(factionId: _mock[i].$1, height: 34),
          ),
        ),
      for (var i = 0; i < _mock.length; i++)
        Positioned(
          left: points[i].dx - 30,
          top: points[i].dy + 24,
          width: 60,
          child: Text(_mock[i].$2,
              textAlign: TextAlign.center, style: _t(10.5, c: _ash)),
        ),
    ]),
  );
}

Widget _legend() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('The signs, by step (the game’s step names and colours)'),
      Wrap(spacing: 14, runSpacing: 10, children: [
        for (final t in StandingTier.values.reversed)
          SizedBox(
            width: 128,
            child: Row(children: [
              StandingSign(t, size: 22),
              const SizedBox(width: 8),
              Text(_word(t), style: _t(12.5, c: Color(tierColor(t)))),
            ]),
          ),
      ]),
    ]);

Widget _board() => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How each clan stands with you, as a sign', style: _t(18)),
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
          const SizedBox(width: 16),
          Column(children: [
            _title('Ring today'),
            _ring(signs: false),
          ]),
          const SizedBox(width: 12),
          Column(children: [
            _title('Ring with signs'),
            _ring(signs: true),
          ]),
        ]),
        const SizedBox(height: 18),
        _legend(),
      ]),
    );

void main() {
  setUpAll(_loadFonts);

  test('every step has a sign, and colours are the game’s', () {
    for (final t in StandingTier.values) {
      expect(_bits[glyphOf(t)], isNotNull, reason: t.name);
    }
  });

  testWidgets('a picture of the standing sign (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1280, 510);
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
    // The banners' sprites load asynchronously.
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
      File('$dir/standing-sign-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

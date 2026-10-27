// The standing sign with one disc for each of the eleven standing steps (UX
// mock; the user's call on the clan glance: "keep the disc but add enough
// discs to match all levels of relations"). Each step has its own shape on a
// 7 x 7 pixel grid and the game's own colour for it (standingTiers), so the
// shape carries the level for a colour-blind player and the colour agrees
// with the clan card. The bad side is a skull, crossed blades, one blade, a
// frown and a watching eye; unknown is a dot; the good side is a ringed dot,
// a hollow heart, a heart, a shield and a crowned heart. The extremes (hunted
// and sworn) get a double rim.
// UX_SHOTS=<folder> takes docs/ux-shots/standing-discs-mock.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
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
      loader.addFont(Future.value(
          ByteData.view(File('assets/fonts/$f').readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

const _bg = Color(0xFF17151B);
const _ash = Color(0xFF9A93A6);
const _cream = Color(0xFFEDE6DC);
const _gold = Color(0xFFE2B890);

TextStyle _t(double size, {Color? c, bool px = false}) => TextStyle(
    fontFamily: px ? 'PixelifySans' : 'Spectral',
    fontSize: size,
    height: 1.25,
    color: c ?? _cream);

/// Each step's shape: seven rows of seven pixels.
const Map<StandingTier, List<String>> glyphs = {
  StandingTier.hunted: [
    '.#####.',
    '#######',
    '#.###.#',
    '#######',
    '.##.##.',
    '..#.#..',
    '..###..',
  ],
  StandingTier.hostile: [
    '##...##',
    '.##.##.',
    '..###..',
    '...#...',
    '..###..',
    '.##.##.',
    '##...##',
  ],
  StandingTier.resented: [
    '......#',
    '.....##',
    '....##.',
    '..###..',
    '.###...',
    '##.#...',
    '#.#....',
  ],
  StandingTier.unfriendly: [
    '.......',
    '.#...#.',
    '.#...#.',
    '.......',
    '..###..',
    '.#...#.',
    '#.....#',
  ],
  StandingTier.wary: [
    '.......',
    '..###..',
    '.#...#.',
    '#..#..#',
    '.#...#.',
    '..###..',
    '.......',
  ],
  StandingTier.unknown: [
    '.......',
    '.......',
    '..###..',
    '..###..',
    '..###..',
    '.......',
    '.......',
  ],
  StandingTier.known: [
    '..###..',
    '.#...#.',
    '#.....#',
    '#..#..#',
    '#.....#',
    '.#...#.',
    '..###..',
  ],
  StandingTier.friendly: [
    '.##.##.',
    '#..#..#',
    '#.....#',
    '.#...#.',
    '..#.#..',
    '...#...',
    '.......',
  ],
  StandingTier.friend: [
    '.##.##.',
    '#######',
    '#######',
    '.#####.',
    '..###..',
    '...#...',
    '.......',
  ],
  StandingTier.trusted: [
    '#######',
    '#.....#',
    '#..#..#',
    '#.###.#',
    '.#...#.',
    '..#.#..',
    '...#...',
  ],
  StandingTier.sworn: [
    '#.#.#.#',
    '#######',
    '.......',
    '.##.##.',
    '.#####.',
    '..###..',
    '...#...',
  ],
};

class _Disc extends CustomPainter {
  const _Disc(this.tier);
  final StandingTier tier;
  @override
  void paint(Canvas canvas, Size size) {
    final colour = Color(tierColor(tier));
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final rim = tier == StandingTier.hunted || tier == StandingTier.sworn;
    final rr = rim ? r - size.width * 0.07 : r;
    canvas.drawCircle(c, rr, Paint()..color = const Color(0xFF14121A));
    canvas.drawCircle(
        c,
        rr - 0.75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width < 20 ? 1.2 : 1.5
          ..color = colour);
    if (rim) {
      canvas.drawCircle(
          c,
          r - 0.6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width < 20 ? 0.9 : 1
            ..color = colour.withValues(alpha: 0.75));
    }
    final px = (size.width * 0.62) / 7;
    final origin = c - Offset(px * 3.5, px * 3.5);
    final p = Paint()
      ..color = colour
      ..isAntiAlias = false;
    final rows = glyphs[tier]!;
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
  bool shouldRepaint(_Disc old) => old.tier != tier;
}

Widget _disc(StandingTier t, double size) =>
    SizedBox(width: size, height: size, child: CustomPaint(painter: _Disc(t)));

const ColorFilter _grey = ColorFilter.matrix(<double>[
  0.33, 0.33, 0.33, 0, 0, //
  0.33, 0.33, 0.33, 0, 0,
  0.33, 0.33, 0.33, 0, 0,
  0, 0, 0, 1, 0,
]);

const _names = {
  StandingTier.hunted: 'Hunted',
  StandingTier.hostile: 'Hostile',
  StandingTier.resented: 'Resented',
  StandingTier.unfriendly: 'Unfriendly',
  StandingTier.wary: 'Wary',
  StandingTier.unknown: 'Unknown',
  StandingTier.known: 'Known',
  StandingTier.friendly: 'Friendly',
  StandingTier.friend: 'Friend',
  StandingTier.trusted: 'Trusted',
  StandingTier.sworn: 'Sworn',
};

const _shapes = {
  StandingTier.hunted: 'skull',
  StandingTier.hostile: 'crossed blades',
  StandingTier.resented: 'one blade',
  StandingTier.unfriendly: 'frown',
  StandingTier.wary: 'watching eye',
  StandingTier.unknown: 'dot',
  StandingTier.known: 'ringed dot',
  StandingTier.friendly: 'hollow heart',
  StandingTier.friend: 'heart',
  StandingTier.trusted: 'shield',
  StandingTier.sworn: 'crowned heart',
};

/// One row: every step, [build] says what is drawn for it.
Widget _row(String label, Widget Function(StandingTier) build,
        {double cell = 76}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 120, child: Text(label, style: _t(12, c: _ash))),
        for (final t in StandingTier.values)
          SizedBox(width: cell, child: Center(child: build(t))),
      ]),
    );

Widget _board() => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('The standing sign: one disc for each of the eleven steps',
            style: _t(22, px: true)),
        const SizedBox(height: 4),
        SizedBox(
          width: 930,
          child: Text(
              'Bad side: skull, crossed blades, one blade, frown, watching eye. Unknown: a dot. Good side: ringed dot, hollow heart, heart, shield, crowned heart. The colours are the game’s own (standingTiers), the same as the clan card; the shape carries the level. The extremes, hunted and sworn, wear a double rim.',
              style: _t(12.5, c: _ash)),
        ),
        const SizedBox(height: 18),
        _row('', (t) => Text(_names[t]!, style: _t(12))),
        _row('', (t) => Text(_shapes[t]!, style: _t(10.5, c: _ash))),
        _row('44 px (offer banners)', (t) => _disc(t, 44)),
        _row('28 px (standards)', (t) => _disc(t, 28)),
        _row('16 px (ring crests)', (t) => _disc(t, 16)),
        _row('in grey, 28 px',
            (t) => ColorFiltered(colorFilter: _grey, child: _disc(t, 28))),
        _row('in grey, 16 px',
            (t) => ColorFiltered(colorFilter: _grey, child: _disc(t, 16))),
        _row('on a 34 px crest', (t) {
          const h = 34.0;
          return SizedBox(
            width: h / 2 + 8,
            height: h + 4,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                  left: 0,
                  top: 4,
                  child: ClanFlag(factionId: 'vigil', height: h)),
              Positioned(right: 0, top: -2, child: _disc(t, 16)),
            ]),
          );
        }),
        _row('on a 64 px standard', (t) {
          const h = 64.0;
          return SizedBox(
            width: h / 2 + 12,
            height: h + 6,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                  left: 0,
                  top: 6,
                  child: ClanFlag(factionId: 'compact', height: h)),
              Positioned(right: 0, top: -2, child: _disc(t, 24)),
            ]),
          );
        }),
        const SizedBox(height: 6),
        Text(
            'Honest note: at 16 px each pixel of the shape is about 1.3 px. The skull, the blades, the hearts and the dot still differ by silhouette and by colour, but the three middle bad steps (one blade, frown, eye) are the closest; if the user finds the ring too small, the ring’s discs can be 18 to 20 px, which the banners have room for.',
            style: _t(11.5, c: _gold)),
      ]),
    );

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) {
    test('the discs picture is taken only with UX_SHOTS', () {});
    return;
  }
  test('every step has its own distinct shape and its own colour', () {
    final shapes = {for (final t in StandingTier.values) glyphs[t]!.join('/')};
    expect(shapes, hasLength(StandingTier.values.length));
    final colours = {for (final t in StandingTier.values) tierColor(t)};
    expect(colours, hasLength(StandingTier.values.length));
    for (final t in StandingTier.values) {
      expect(glyphs[t], hasLength(7));
      for (final row in glyphs[t]!) {
        expect(row, hasLength(7));
      }
    }
  });
  testWidgets('the eleven discs', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(1100, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: RepaintBoundary(
          key: key,
          child:
              Container(width: 1100, height: 840, color: _bg, child: _board()),
        ),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/standing-discs-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

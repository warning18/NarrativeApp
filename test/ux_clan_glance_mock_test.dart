// A clan at a glance (UX proposal, nothing built): the two things a player
// wants to know about a clan, drawn once on the same banner. How it stands
// with you (the standing sign, a small disc in the corner: heart, dot,
// crossed blades) and how strong it is (the cloth fills from the foot, a
// quarter for each of the clan card's four tiers, a gold hairline at the
// level). Both read the tiers the clan card already shows (StandingTier,
// PowerTier): no new numbers. Shown on the offer's banners (128 px), the
// Throne room's standards (64 px), the ring's crests (34 px), the ring itself
// and the Clans list's rows.
// UX_SHOTS=<folder> takes docs/ux-shots/clan-glance-mock.png.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
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

/// Core's three-way reading of a step: friendly (Friendly, Friend, Trusted,
/// Sworn), neutral (Wary, Unknown, Known), hostile (Unfriendly, Resented,
/// Hostile, Hunted).
enum Stance { friendly, neutral, hostile }

Stance stanceOf(StandingTier t) => switch (t) {
      StandingTier.friendly ||
      StandingTier.friend ||
      StandingTier.trusted ||
      StandingTier.sworn =>
        Stance.friendly,
      StandingTier.wary ||
      StandingTier.unknown ||
      StandingTier.known =>
        Stance.neutral,
      _ => Stance.hostile,
    };

_Glyph glyphOfStance(Stance s) => switch (s) {
      Stance.friendly => _Glyph.heart,
      Stance.neutral => _Glyph.dot,
      Stance.hostile => _Glyph.blades,
    };

/// The three-way sign's colours: the step colours of Friend, Unknown and
/// Hostile, so they match the clan card.
Color stanceColour(Stance s) => Color(tierColor(switch (s) {
      Stance.friendly => StandingTier.friend,
      Stance.neutral => StandingTier.unknown,
      Stance.hostile => StandingTier.hostile,
    }));

/// The sign for [tier], [size] logical pixels across: the three-way sign,
/// or with [fine] one sign per step.
class StandingSign extends StatelessWidget {
  const StandingSign(this.tier, {super.key, this.size = 18, this.fine = false});
  final StandingTier tier;
  final double size;
  final bool fine;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: fine
              ? _SignPainter(glyphOf(tier), Color(tierColor(tier)),
                  double_:
                      tier == StandingTier.hunted || tier == StandingTier.sworn)
              : _SignPainter(
                  glyphOfStance(stanceOf(tier)), stanceColour(stanceOf(tier))),
        ),
      );
}

const _metal = Color(0xFFF2C14E);

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

/// A banner with both marks: the power as how much of the cloth is in colour
/// (from the foot up, a quarter a tier, a gold hairline at the level), and the
/// standing sign at the top-right corner.
Widget _glance(String id, StandingTier standing, PowerTier power,
    {required double h, double? sign}) {
  final s = sign ?? math.max(14.0, h * 0.28);
  final u = math.max(1.0, h / 34);
  final frac = (power.index + 1) / 4;
  return SizedBox(
    width: h / 2 + s * 0.4,
    height: h,
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: 0,
        top: 0,
        width: h / 2,
        height: h,
        child: Stack(children: [
          ClanFlag(factionId: id, height: h, found: false),
          ClipRect(
              clipper: _FromFoot(frac),
              child: ClanFlag(factionId: id, height: h)),
          if (frac < 1)
            Positioned(
              left: 0,
              right: 0,
              top: h * (1 - frac),
              child: Container(height: math.max(1, u * 0.8), color: _metal),
            ),
        ]),
      ),
      Positioned(
          right: 0, top: -s * 0.15, child: StandingSign(standing, size: s)),
    ]),
  );
}

String _word(StandingTier t) => t.name[0].toUpperCase() + t.name.substring(1);
String _pword(PowerTier t) => switch (t) {
      PowerTier.minor => 'Minor',
      PowerTier.rising => 'Rising',
      PowerTier.dominant => 'Dominant',
      PowerTier.ascendant => 'Ascendant',
    };

typedef _Clan = (String, String, StandingTier, PowerTier);
const List<_Clan> _four = [
  ('vigil', 'Vigil', StandingTier.friend, PowerTier.dominant),
  ('compact', 'Compact', StandingTier.unknown, PowerTier.ascendant),
  ('mire', 'Mire', StandingTier.wary, PowerTier.rising),
  ('penitents', 'Penitents', StandingTier.hostile, PowerTier.minor),
];
const List<_Clan> _six = [
  ('vigil', 'Vigil', StandingTier.friend, PowerTier.dominant),
  ('compact', 'Compact', StandingTier.unknown, PowerTier.ascendant),
  ('mire', 'Mire', StandingTier.wary, PowerTier.rising),
  ('penitents', 'Penitents', StandingTier.hostile, PowerTier.minor),
  ('dominion', 'Dominion', StandingTier.hunted, PowerTier.dominant),
  ('crows', 'Crows', StandingTier.trusted, PowerTier.minor),
];

Widget _h(String s) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Text(s, style: _t(15, c: _gold, bold: true)));

Widget _key() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('The disc: how it stands with you', style: _t(13, bold: true)),
          const SizedBox(height: 8),
          Row(children: [
            for (final (t, w) in const [
              (StandingTier.friend, 'friendly'),
              (StandingTier.unknown, 'neutral'),
              (StandingTier.hostile, 'hostile'),
            ])
              Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: Column(children: [
                    StandingSign(t, size: 30),
                    const SizedBox(height: 4),
                    Text(w, style: _t(11, c: _ash)),
                  ])),
          ]),
          const SizedBox(height: 6),
          Text('Heart, dot, crossed blades: shape and colour both say it.',
              style: _t(11, c: _ash)),
        ]),
      ),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('The cloth: how strong it is', style: _t(13, bold: true)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final t in PowerTier.values)
              Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(children: [
                    _glance('vigil', StandingTier.unknown, t, h: 64, sign: 0.1),
                    const SizedBox(height: 4),
                    Text(_pword(t), style: _t(11, c: _ash)),
                  ])),
          ]),
          const SizedBox(height: 6),
          Text('The cloth fills from the foot, a quarter each tier.',
              style: _t(11, c: _ash)),
        ]),
      ),
    ]);

Widget _sizes() =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (h, label) in const [
        (128.0, 'offer banners · 128 px'),
        (64.0, 'Throne standards · 64 px'),
        (34.0, 'ring crests · 34 px'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            SizedBox(width: 150, child: Text(label, style: _t(11, c: _ash))),
            for (final c in _four)
              Padding(
                  padding: EdgeInsets.only(right: h > 100 ? 30 : 20),
                  child: Column(children: [
                    _glance(c.$1, c.$3, c.$4, h: h),
                    if (h > 50) ...[
                      const SizedBox(height: 4),
                      Text(c.$2, style: _t(10, c: _ash)),
                    ],
                  ])),
          ]),
        ),
    ]);

Widget _ringBoard() {
  const w = 300.0;
  final pts = [
    for (var i = 0; i < _six.length; i++)
      Offset(
          w / 2 +
              math.cos(-math.pi / 2 + i * 2 * math.pi / _six.length) * w * 0.34,
          w / 2 +
              math.sin(-math.pi / 2 + i * 2 * math.pi / _six.length) *
                  w *
                  0.34),
  ];
  return SizedBox(
    width: w,
    height: w,
    child: Stack(children: [
      CustomPaint(size: const Size(w, w), painter: _RingLine()),
      for (var i = 0; i < _six.length; i++)
        Positioned(
          left: pts[i].dx - 28,
          top: pts[i].dy - 36,
          child: SizedBox(
            width: 56,
            height: 72,
            child: Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(3, 8, 3, 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1B22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF3A3642)),
                ),
                child: _glance(_six[i].$1, _six[i].$3, _six[i].$4, h: 34),
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

Widget _list() => Container(
      width: 330,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFF1D1B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A3642))),
      child: Column(children: [
        for (final c in _six)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              _glance(c.$1, c.$3, c.$4, h: 44, sign: 16),
              const SizedBox(width: 14),
              Expanded(child: Text(c.$2, style: _t(14, bold: true))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_word(c.$3), style: _t(12)),
                Text(_pword(c.$4), style: _t(11, c: _ash)),
              ]),
            ]),
          ),
      ]),
    );

Widget _board() => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('A clan at a glance', style: _t(24, bold: true)),
        const SizedBox(height: 4),
        Text(
            'Two marks on the same banner: the disc says how it stands with you, the cloth says how strong it is. Both read the tiers the clan card already shows, so the exact words stay one tap away.',
            style: _t(12.5, c: _ash)),
        _h('How to read it'),
        _key(),
        _h('At every size the banners are drawn'),
        _sizes(),
        _h('On the ring, and in the Clans list'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ringBoard(),
          const SizedBox(width: 30),
          _list(),
        ]),
      ]),
    );

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) {
    test('the clan glance picture is taken only with UX_SHOTS', () {});
    return;
  }
  testWidgets('a clan at a glance', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(760, 1240);
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
          child: Container(
            width: 760,
            height: 1240,
            color: _bg,
            child: _board(),
          ),
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
      File('$dir/clan-glance-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

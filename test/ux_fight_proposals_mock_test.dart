// Six whole fight screens at 360 wide (UX_SHOTS=<folder>), pictures only:
// three layouts, each in today's style ("current", Art's Apollo kit) and in B
// (Art's style-1 kit, ink and one colour). The user's complaint: the ground,
// the dice, the cards and the sprites look like four games. Rules for all six:
// one pixel scale (1 art pixel = 2 dp everywhere), one outline weight, the
// dice and the ground share a material, the cards wear the panels' frame
// family, and the weakness mark (on the nameplate) and the matching-die hint
// are in every one.
//   1 One stage: the ground is one floor that runs into the dice tray, the
//     cards are cut from it;
//   2 Table: tokens on a table, the dice roll on it, the cards are a hand;
//   3 One frame kit: a strict HUD, one frame family for every panel and slot.
// Pieces: Art's combat kits (art/pixellab-combat-kits/final, in
// docs/ux-shots/fight-proposals/art), today's sprites (B: Art's hero and foe
// and stand-ins from make_b_assets.py), Art's style-1 dice. Real data: the
// foes (enemies.json), the skill cards. Mock only: the drawing code below is
// not used by the app.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/palette.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/pixel_icons/game_pixel_icons.dart';

import 'support/fonts.dart';

/// One art pixel in dp: the one pixel scale of every piece.
const double u = 2;
const String _art = 'docs/ux-shots/fight-proposals/art';
const String _bsa = 'docs/ux-shots/fight-proposals/b-assets';

// B's greys and its one accent (Art's style 1: 090A14 202E37 394A50 8B9BA0
// EBEDE9, and the gold F2C14E).
const Color _ink = Color(0xFF090A14);
const Color _g1 = Color(0xFF202E37);
const Color _g2 = Color(0xFF394A50);
const Color _g3 = Color(0xFF8B9BA0);
const Color _paper = Color(0xFFEBEDE9);
const Color _gold = Color(0xFFF2C14E);

// ------------------------------------------------------------- images ---

final Map<String, ui.Image> _im = {};
final Map<String, Rect> _bb = {};

Future<void> _load(String path) async {
  if (_im.containsKey(path)) return;
  final bytes = File(path).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  _im[path] = image;
  // The box the figure fills (the alpha channel's bounds), for tight crops.
  final data = (await image.toByteData())!;
  var x0 = image.width, y0 = image.height, x1 = 0, y1 = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (data.getUint8((y * image.width + x) * 4 + 3) > 0) {
        if (x < x0) x0 = x;
        if (x > x1) x1 = x;
        if (y < y0) y0 = y;
        if (y > y1) y1 = y;
      }
    }
  }
  _bb[path] = Rect.fromLTRB(
      x0.toDouble(), y0.toDouble(), (x1 + 1).toDouble(), (y1 + 1).toDouble());
}

/// Draws [src] of [img] at the one pixel scale.
class _SpritePainter extends CustomPainter {
  _SpritePainter(this.img, this.src);
  final ui.Image img;
  final Rect src;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
      img,
      src,
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false);
  @override
  bool shouldRepaint(_SpritePainter old) => false;
}

/// The whole picture, or [crop] of it (art pixels), at the pixel scale.
Widget _spr(String path, {Rect? crop, double scale = u}) {
  final img = _im[path]!;
  final src = crop ?? Rect.fromLTWH(0, 0, img.width * 1.0, img.height * 1.0);
  return CustomPaint(
      size: Size(src.width * scale, src.height * scale),
      painter: _SpritePainter(img, src));
}

/// A nine-slice frame: [ins] art pixels at each corner, the sides and the
/// middle stretched.
class _NinePainter extends CustomPainter {
  _NinePainter(this.img, this.ins, {this.center = true});
  final ui.Image img;
  final double ins;
  final bool center;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final c = ins * u;
    final xs = [0.0, ins, iw - ins, iw];
    final ys = [0.0, ins, ih - ins, ih];
    final dx = [0.0, c, s.width - c, s.width];
    final dy = [0.0, c, s.height - c, s.height];
    for (var j = 0; j < 3; j++) {
      for (var i = 0; i < 3; i++) {
        if (i == 1 && j == 1 && !center) continue;
        canvas.drawImageRect(
            img,
            Rect.fromLTRB(xs[i], ys[j], xs[i + 1], ys[j + 1]),
            Rect.fromLTRB(dx[i], dy[j], dx[i + 1], dy[j + 1]),
            p);
      }
    }
  }

  @override
  bool shouldRepaint(_NinePainter old) => false;
}

// -------------------------------------------------------------- looks ---

class _L {
  _L.current(BuildContext c)
      : b = false,
        kit = 'apollo',
        bg = const Color(0xFF14151E),
        text = const Color(0xFFE8E2D4),
        dim = const Color(0xFF9AA0A6),
        accent = const Color(0xFFE0A93A),
        hp = Palette.goodDeep,
        hpTrack = const Color(0xFF1B1D26),
        weak = Palette.goodDeep,
        resist = Palette.slate,
        ink = Palette.apolloOutline;
  _L.b()
      : b = true,
        kit = 'b',
        bg = _ink,
        text = _paper,
        dim = _g3,
        accent = _gold,
        hp = _gold,
        hpTrack = _g1,
        weak = _gold,
        resist = _g3,
        ink = _ink;

  final bool b;
  final String kit;
  final Color bg, text, dim, accent, hp, hpTrack, weak, resist, ink;

  String piece(String name) => '$_art/${kit}_$name.png';

  String foe(String id) {
    if (!b) return 'assets/visuals/fighters/${id}_idle_west.png';
    return id == 'inquisition_warden' ? '$_art/b_foe.png' : '$_bsa/$id.png';
  }

  String hero(String id) {
    if (!b) return 'assets/visuals/heroes/${id}_stand_east.png';
    return id == 'warrior' ? '$_art/b_hero.png' : '$_bsa/$id.png';
  }

  String get d6 =>
      b ? '$_bsa/die_d6.png' : 'assets/visuals/dice/die_d6_bone_44.png';
}

TextStyle _display(_L l, double s) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: l.text);
TextStyle _sys(_L l, double s, {Color? color}) => TextStyle(
    fontFamily: InkFonts.system,
    fontSize: s,
    height: 1.15,
    color: color ?? l.dim);
TextStyle _prose(_L l, double s, {bool italic = false, Color? color}) =>
    TextStyle(
        fontFamily: InkFonts.prose,
        fontSize: s,
        height: 1.3,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? l.text);

IconData _icon(String e) => switch (e) {
      'Fire' => Icons.local_fire_department,
      'Wind' => Icons.air,
      'Earth' => Icons.terrain,
      'Water' => Icons.water_drop,
      'Electricity' => Icons.bolt,
      'Void' => Icons.blur_on,
      'Light' => Icons.wb_sunny,
      'Ice' => Icons.ac_unit,
      _ => Icons.circle_outlined,
    };

Color _tint(_L l, String e) {
  if (l.b) return _paper; // B: the element is the mark, not a colour
  return switch (e) {
    'Fire' => const Color(0xFFE4572E),
    'Water' => const Color(0xFF3D8FD6),
    'Electricity' => const Color(0xFFF2C230),
    'Light' => const Color(0xFFF3E3A0),
    'Void' => const Color(0xFF9A6BD1),
    _ => Palette.slate,
  };
}

// ------------------------------------------------------------- frames ---

/// A piece of the kit as a frame round [child] ([kind]: panel, slot,
/// kitcard, cardframe, table).
Widget _kit(_L l, String kind, Widget child,
    {double? w, double? h, bool center = true}) {
  final ins = switch (kind) {
    'panel' => 8.0,
    'slot' => 4.0,
    'table' => 9.0,
    _ => 6.0,
  };
  return SizedBox(
    width: w,
    height: h,
    child: CustomPaint(
      painter: _NinePainter(_im[l.piece(kind)]!, ins, center: center),
      child: Padding(padding: EdgeInsets.all(ins * u), child: child),
    ),
  );
}

// ---------------------------------------------------------------- data ---

late Map<String, dynamic> _enemies;

class _Foe {
  _Foe(this.id, this.hp, this.max)
      : data = _enemies[id] as Map<String, dynamic>;
  final String id;
  final int hp, max;
  final Map<String, dynamic> data;
  String get name => data['enemyName'] as String;
  List<String> get weak => [for (final e in (data['weakTo'] as List)) '$e'];
  List<String> get resist => [for (final e in (data['resists'] as List)) '$e'];
}

class _Hero {
  const _Hero(this.name, this.sprite, this.hp, this.max);
  final String name, sprite;
  final int hp, max;
}

const _party = [
  _Hero('Edda', 'warrior', 41, 52),
  _Hero('Liora', 'cleric', 30, 36),
  _Hero('Vess', 'mage', 24, 28),
];

/// The skill cards of the hand: real skills, real rarities (0 common, 1 rare,
/// 2 epic) and their element.
const _hand = [
  ('radiant_judgment', 0, 'Light'),
  ('fireball', 1, 'Fire'),
  ('cleric_absolution', 2, 'Light'),
  ('heavy_attack', 0, ''),
];

/// The dice rolled: one per hero; the Light one matches the aimed foe.
const _dice = [('Light', 5), ('Fire', 4), ('Void', 3)];

late List<_Foe> _foes;

// -------------------------------------------------------------- pieces ---

/// A weakness / resistance mark (B of this morning): the element's icon and
/// ×3 (or ×½) in a small pixel-cornered pill, the weak one in the accent,
/// ringed when it is the one the hero's die hits.
Widget _mark(_L l, String e,
    {required bool weak, bool ring = false, double h = 15}) {
  final frame = weak ? l.weak : l.resist;
  return Container(
    height: h + (ring ? 2 : 0),
    padding: const EdgeInsets.symmetric(horizontal: 3),
    decoration: ShapeDecoration(
      color: l.bg,
      shape: PixelChipBorder(
          side: BorderSide(
              color: ring ? l.accent : frame, width: ring ? 2.5 : 1.5),
          step: 2,
          steps: 2),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon(e), size: h - 5, color: _tint(l, e)),
      const SizedBox(width: 1),
      Text(weak ? '×3' : '×½',
          style: TextStyle(
              fontFamily: InkFonts.prose,
              fontWeight: FontWeight.w700,
              fontSize: h - 6,
              height: 1,
              color: weak ? l.weak : l.dim)),
    ]),
  );
}

Widget _hpBar(_L l, int hp, int max) => SizedBox(
      height: 7,
      child: Stack(children: [
        Container(color: l.hpTrack),
        FractionallySizedBox(
            widthFactor: hp / max, child: Container(color: l.hp)),
        Container(
            decoration: BoxDecoration(
                border: Border.all(color: l.b ? _g2 : l.ink, width: 1))),
      ]),
    );

/// The nameplate: a slot of the kit, the name and (on the same line) the
/// weakness marks, the health under it. [lit]: your turn, or the aimed foe.
Widget _plate(_L l, String name, int hp, int max,
    {List<String> weak = const [],
    List<String> resist = const [],
    double width = 112,
    bool lit = false,
    bool aimedLight = false}) {
  final marks = [
    for (final e in weak)
      _mark(l, e, weak: true, h: 14, ring: aimedLight && e == 'Light'),
    for (final e in resist) _mark(l, e, weak: false, h: 14),
  ];
  Widget nameText() => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(name, maxLines: 1, style: _display(l, 11.5)));
  final Widget head;
  if (width < 140 && marks.isEmpty) {
    // A narrow plate of a hero: name and health on one line.
    final one = Row(children: [
      Expanded(child: nameText()),
      const SizedBox(width: 4),
      SizedBox(width: 30, child: _hpBar(l, hp, max)),
    ]);
    final plate = _kit(l, 'slot', one, w: width);
    if (!lit) return plate;
    return Container(
      decoration: ShapeDecoration(
        shape: PixelChipBorder(
            side: BorderSide(color: l.accent, width: 2.5), step: 3, steps: 3),
      ),
      child: plate,
    );
  }
  if (width >= 140 || marks.isEmpty) {
    // On the nameplate: the name, and on the same line the marks.
    head = Row(children: [
      Expanded(child: nameText()),
      for (final m in marks) ...[const SizedBox(width: 2), m],
    ]);
  } else {
    // A narrow plate (a slot of the kit): the marks take the line under.
    head = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Align(alignment: Alignment.centerLeft, child: nameText()),
      const SizedBox(height: 2),
      FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(children: [
            for (final m in marks) ...[m, const SizedBox(width: 2)],
          ])),
    ]);
  }
  final body = Column(mainAxisSize: MainAxisSize.min, children: [
    head,
    const SizedBox(height: 3),
    _hpBar(l, hp, max),
  ]);
  final plate = _kit(l, 'slot', body, w: width);
  if (!lit) return plate;
  return Container(
    decoration: ShapeDecoration(
      shape: PixelChipBorder(
          side: BorderSide(color: l.accent, width: 2.5), step: 3, steps: 3),
    ),
    child: plate,
  );
}

Widget _foePlate(_L l, _Foe f, {double width = 112, bool aimed = false}) =>
    _plate(l, f.name, f.hp, f.max,
        weak: f.weak,
        resist: f.resist,
        width: width,
        lit: aimed,
        aimedLight: aimed);

Widget _heroPlate(_L l, _Hero h, {double width = 104, bool turn = false}) =>
    _plate(l, h.name, h.hp, h.max, width: width, lit: turn);

Widget _shadow(_L l, double w) => Container(
      width: w,
      height: 9,
      decoration: ShapeDecoration(
        color: l.ink.withValues(alpha: 0.55),
        shape: const StadiumBorder(),
      ),
    );

/// The figure's drawn size (dp).
Size _figSize(String path) {
  final bb = _bb[path]!;
  return Size(bb.width * u, bb.height * u);
}

/// A figure, cropped to its box at the pixel scale.
Widget _fig(String path, {double? headOnly}) {
  final bb = _bb[path]!;
  final crop = headOnly == null
      ? bb
      : Rect.fromLTWH(bb.left, bb.top, bb.width, headOnly);
  return _spr(path, crop: crop);
}

/// A figure standing on its shadow (one light, from the top left: the shadow
/// falls a little to the right), centred in [minW].
Widget _stand(_L l, String path, {double minW = 0}) {
  final s = _figSize(path);
  final w = s.width > minW ? s.width : minW;
  return SizedBox(
    width: w,
    height: s.height + 4,
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned(
          left: (w - (s.width + 22)) / 2 + 5,
          bottom: 0,
          child: _shadow(l, s.width + 22)),
      Positioned(left: (w - s.width) / 2, top: 0, child: _fig(path)),
    ]),
  );
}

Widget _foeAt(_L l, _Foe f, double w, {bool aimed = false}) => SizedBox(
      width: w,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _stand(l, l.foe(f.id), minW: w),
        const SizedBox(height: 2),
        _foePlate(l, f, width: w, aimed: aimed),
      ]),
    );

Widget _heroAt(_L l, _Hero h, double w, {bool turn = false}) => SizedBox(
      width: w,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _stand(l, l.hero(h.sprite), minW: w),
        const SizedBox(height: 2),
        _heroPlate(l, h, width: w, turn: turn),
      ]),
    );

/// A die with its face: the element's mark and the number on a small plate
/// at the cube's centre; lit and tagged when it is the one that hits the
/// aimed foe for ×3.
Widget _die(_L l, String element, int face,
    {bool lit = false, double scale = 1}) {
  final size = 44 * u * scale;
  return SizedBox(
    width: size,
    height: size + 12,
    child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (lit)
            Positioned(
              top: -2,
              child: Container(
                width: size,
                height: size,
                decoration: ShapeDecoration(
                  shape: PixelChipBorder(
                      side: BorderSide(color: l.accent, width: 3),
                      step: 4,
                      steps: 3),
                ),
              ),
            ),
          Positioned(
              top: 0,
              child: SizedBox(
                  width: size,
                  height: size,
                  child: FittedBox(child: _spr(l.d6)))),
          Positioned(
            top: size * 0.30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: ShapeDecoration(
                color: l.ink.withValues(alpha: 0.88),
                shape: PixelChipBorder(
                    side: BorderSide(color: lit ? l.accent : l.dim, width: 1.5),
                    step: 2,
                    steps: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_icon(element),
                    size: 13 * scale,
                    color: l.b ? (lit ? _gold : _paper) : _tint(l, element)),
                const SizedBox(width: 2),
                Text('$face',
                    style: TextStyle(
                        fontFamily: InkFonts.display,
                        fontSize: 19 * scale,
                        height: 1,
                        color: lit
                            ? l.accent
                            : (l.b ? _paper : Palette.apolloCream))),
              ]),
            ),
          ),
          if (lit)
            Positioned(
              right: -6,
              top: -8,
              child: _mark(l, element, weak: true),
            ),
          Positioned(bottom: 0, child: Text(element, style: _sys(l, 8))),
        ]),
  );
}

/// A skill's pixel icon; in B it is folded to greys (B has one colour).
Widget _skillIcon(_L l, String id) {
  final icon = SkillPixelIcon(id, size: 32);
  if (!l.b) return icon;
  return ColorFiltered(
    colorFilter: const ColorFilter.mode(_g3, BlendMode.modulate),
    child: ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.33, 0.33, 0.33, 0, 0, //
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: icon,
    ),
  );
}

/// A skill card: the kit's card frame (the same family as the panels), the
/// icon, the name and the rarity in pips. [back] is what it is cut from.
Widget _card(_L l, (String, int, String) c,
    {String kind = 'kitcard',
    double w = 78,
    double h = 104,
    Widget? back,
    bool lit = false}) {
  final (id, rarity, element) = c;
  final rarityColor = l.b
      ? _g3
      : const [Color(0xFF9AA0A6), Color(0xFF4A90D9), Color(0xFFD98A3D)][rarity];
  final body = Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (element.isNotEmpty)
        Icon(_icon(element), size: 11, color: _tint(l, element))
      else
        const SizedBox(height: 11),
      const SizedBox(height: 1),
      _skillIcon(l, id),
      const SizedBox(height: 2),
      Column(mainAxisSize: MainAxisSize.min, children: [
        for (final word in skillDisplayName(id).split(' '))
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(word, maxLines: 1, style: _display(l, 10.5))),
      ]),
      const SizedBox(height: 3),
      Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i <= rarity; i++)
          Container(
              width: 2 * u,
              height: 2 * u,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: rarityColor),
      ]),
    ],
  );
  return SizedBox(
    width: w,
    height: h,
    child: Stack(children: [
      if (back != null) Positioned.fill(child: back),
      Positioned.fill(
          child: _kit(l, kind, Center(child: body), center: back == null)),
      if (lit)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: ShapeDecoration(
                shape: PixelChipBorder(
                    side: BorderSide(color: l.accent, width: 3),
                    step: 3,
                    steps: 3),
              ),
            ),
          ),
        ),
    ]),
  );
}

/// The turn bar: the next to act, left to right; the one acting wears the
/// accent. Each token is the figure's head, at the same pixel scale.
Widget _turnBar(_L l) {
  Widget token(String path, {bool now = false}) => Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(right: 5),
        alignment: Alignment.bottomCenter,
        decoration: ShapeDecoration(
          color: l.b ? _g1 : const Color(0xFF232634),
          shape: PixelChipBorder(
              side: BorderSide(
                  color: now ? l.accent : (l.b ? _g2 : const Color(0xFF3B4052)),
                  width: now ? 2.5 : 1.5),
              step: 3,
              steps: 3),
        ),
        child: ClipRect(
            child: Align(
                alignment: Alignment.bottomCenter,
                child: _fig(path, headOnly: 17))),
      );
  return Row(children: [
    Text('TURN', style: _sys(l, 9)),
    const SizedBox(width: 6),
    token(l.hero('warrior'), now: true),
    token(l.foe('void_sovereign')),
    token(l.hero('cleric')),
    token(l.foe('inquisition_warden')),
    token(l.hero('mage')),
    token(l.foe('white_soldier')),
  ]);
}

Widget _topBar(_L l) => Container(
      height: 52,
      color: l.bg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(children: [
        Icon(Icons.arrow_back, size: 20, color: l.dim),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fight: The Sovereign', style: _display(l, 18)),
            Text('The rift · Round 2', style: _sys(l, 9)),
          ]),
        ),
        Icon(Icons.flag_outlined, size: 18, color: l.dim),
      ]),
    );

Widget _button(_L l, String label,
        {bool primary = true, double w = 150, double fs = 14}) =>
    Container(
      width: w,
      height: 38,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: primary ? l.accent : (l.b ? _g1 : const Color(0xFF232634)),
        shape: PixelChipBorder(
            side: BorderSide(
                color: primary ? l.ink : (l.b ? _g2 : const Color(0xFF3B4052)),
                width: 2),
            step: 3,
            steps: 3),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: InkFonts.display,
              fontSize: fs,
              color: primary ? l.ink : l.text)),
    );

Widget _hint(_L l) => Row(children: [
      Icon(Icons.wb_sunny, size: 13, color: l.accent),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
            'Your Light die hits The Sovereign ×3: it is weak to Light.',
            maxLines: 2,
            style: _prose(l, 12, italic: true)),
      ),
    ]);

Widget _pos(double l, double t, Widget child) =>
    Positioned(left: l, top: t, child: child);

// ------------------------------------------------------------ layouts ---

/// Repeats the stage piece's floor rows [fromRow, toRow) over the height.
class _FloorPainter extends CustomPainter {
  _FloorPainter(this.img, this.fromRow, this.toRow);
  final ui.Image img;
  final int fromRow, toRow;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    final rows = toRow - fromRow;
    for (var y = 0.0; y < s.height; y += rows * u) {
      final h = (s.height - y) < rows * u ? s.height - y : rows * u;
      canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, fromRow.toDouble(), img.width.toDouble(), h / u),
          Rect.fromLTWH(0, y, s.width, h),
          p);
    }
  }

  @override
  bool shouldRepaint(_FloorPainter old) => false;
}

/// 1 One stage: one floor that runs into the dice tray.
Widget _stage(BuildContext c, _L l) {
  final st = _im[l.piece('stage')]!;
  const floorTop = 100.0, ledgeY = 548.0;
  Widget floorCut(double x, double y) => ClipRect(
        child: Stack(children: [
          Positioned(
              left: -x,
              top: -(y - floorTop),
              child: SizedBox(
                  width: 360,
                  height: ledgeY - floorTop,
                  child: CustomPaint(painter: _FloorPainter(st, 0, 40)))),
          Positioned.fill(
              child: Container(color: l.ink.withValues(alpha: 0.45))),
        ]),
      );
  const cardY = 676.0;
  const cardX = [14.0, 98.0, 182.0, 266.0];
  return Stack(children: [
    Positioned.fill(child: Container(color: l.bg)),
    Positioned(
        top: floorTop,
        left: 0,
        child: SizedBox(
            width: 360,
            height: ledgeY - floorTop,
            child: CustomPaint(painter: _FloorPainter(st, 0, 40)))),
    Positioned(
        top: floorTop,
        left: 0,
        child: Container(
            width: 360,
            height: ledgeY - floorTop,
            color: l.ink.withValues(alpha: 0.4))),
    // The ledge and the tray: the same ground, carried on.
    Positioned(
        top: ledgeY,
        left: 0,
        child: SizedBox(
            width: 360,
            height: 5 * u,
            child: CustomPaint(
                painter:
                    _SpritePainter(st, const Rect.fromLTWH(0, 40, 180, 5))))),
    Positioned(
        top: ledgeY + 5 * u,
        left: 0,
        child: SizedBox(
            width: 360,
            height: 55 * u,
            child: CustomPaint(
                painter:
                    _SpritePainter(st, const Rect.fromLTWH(0, 45, 180, 55))))),
    Positioned(top: 0, left: 0, right: 0, child: _topBar(l)),
    _pos(12, 54, _turnBar(l)),
    // Foes stand on the far floor, the boss at the back.
    _pos(202, 104, _foeAt(l, _foes[0], 148, aimed: true)),
    _pos(132, 282, _foeAt(l, _foes[1], 112)),
    _pos(240, 356, _foeAt(l, _foes[2], 112)),
    // Heroes stand nearer, in a line down the left.
    _pos(8, 126, _heroAt(l, _party[0], 104, turn: true)),
    _pos(24, 252, _heroAt(l, _party[1], 104)),
    _pos(8, 380, _heroAt(l, _party[2], 104)),
    // The hint, then the tray: the dice lie on it.
    _pos(
        12,
        522,
        Container(
            width: 336,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: l.ink.withValues(alpha: 0.7),
            child: _hint(l))),
    for (var i = 0; i < 3; i++)
      _pos(14.0 + i * 92, 566 + (i == 1 ? 4 : 0),
          _die(l, _dice[i].$1, _dice[i].$2, lit: i == 0, scale: 0.9)),
    _pos(290, 584, _button(l, 'Strike ×3', w: 62, fs: 11)),
    // The cards are cut from the same floor, in the kit's card frame.
    for (var i = 0; i < 4; i++)
      _pos(
          cardX[i],
          cardY,
          _card(l, _hand[i],
              kind: 'cardframe',
              w: 76,
              h: 100,
              back: floorCut(cardX[i], cardY),
              lit: i == 0)),
  ]);
}

/// 2 Table.
Widget _table(BuildContext c, _L l) {
  return Stack(children: [
    Positioned.fill(child: Container(color: l.bg)),
    Positioned(top: 0, left: 0, right: 0, child: _topBar(l)),
    _pos(12, 54, _turnBar(l)),
    // The table: one felt for the foes' tokens, the dice and the heroes'.
    _pos(8, 100, _kit(l, 'table', const SizedBox.shrink(), w: 344, h: 508)),
    // The foes along the far edge; the aimed one is in the middle.
    _pos(22, 118, _foeAt(l, _foes[1], 100)),
    _pos(118, 112, _foeAt(l, _foes[0], 124, aimed: true)),
    _pos(238, 118, _foeAt(l, _foes[2], 100)),
    // The dice roll in the middle of the same table.
    for (var i = 0; i < 3; i++)
      _pos(
          [34.0, 138.0, 240.0][i],
          [314.0, 322.0, 316.0][i],
          Transform.rotate(
              angle: [-0.08, 0.06, -0.04][i],
              child:
                  _die(l, _dice[i].$1, _dice[i].$2, lit: i == 0, scale: 0.95))),
    // The heroes along the near edge.
    for (var i = 0; i < 3; i++)
      _pos(22.0 + i * 108, 414, _heroAt(l, _party[i], 98, turn: i == 0)),
    _pos(24, 552, SizedBox(width: 196, child: _hint(l))),
    _pos(244, 552, _button(l, 'Strike ×3', w: 98)),
    // The hand: the cards fanned at the bottom, on the dark cloth.
    for (var i = 0; i < 4; i++)
      Positioned(
        left: 18.0 + i * 80,
        top: 650 + (i == 1 || i == 2 ? 0.0 : 8.0),
        child: Transform.rotate(
            angle: [-0.1, -0.035, 0.035, 0.1][i],
            child: _card(l, _hand[i],
                kind: 'cardframe', w: 80, h: 110, lit: i == 0)),
      ),
  ]);
}

/// 3 One frame kit.
Widget _hud(BuildContext c, _L l) {
  Widget slot(Widget child, {double w = 100, double h = 198}) => SizedBox(
        width: w,
        height: h,
        child: _kit(
            l, 'slot', Align(alignment: Alignment.bottomCenter, child: child)),
      );
  return Stack(children: [
    Positioned.fill(child: Container(color: l.bg)),
    Positioned(top: 0, left: 0, right: 0, child: _topBar(l)),
    _pos(12, 54, _turnBar(l)),
    // Foes: three slots of the one size in one panel.
    _pos(
        8,
        96,
        _kit(
            l,
            'panel',
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              slot(_foeAt(l, _foes[1], 84)),
              slot(_foeAt(l, _foes[0], 84, aimed: true)),
              slot(_foeAt(l, _foes[2], 84)),
            ]),
            w: 344,
            h: 230)),
    // The party: the same slots.
    _pos(
        8,
        330,
        _kit(
            l,
            'panel',
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              slot(_heroAt(l, _party[0], 84, turn: true), h: 144),
              slot(_heroAt(l, _party[1], 84), h: 144),
              slot(_heroAt(l, _party[2], 84), h: 144),
            ]),
            w: 344,
            h: 176)),
    // Dice and the hand in one panel, each die and card in a slot of the kit.
    _pos(
        8,
        510,
        _kit(
            l,
            'panel',
            Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var i = 0; i < 3; i++)
                  SizedBox(
                    width: 100,
                    height: 70,
                    child: _kit(
                        l,
                        'slot',
                        Center(
                            child: Transform.scale(
                                scale: 0.62,
                                child: _die(l, _dice[i].$1, _dice[i].$2,
                                    lit: i == 0, scale: 0.9)))),
                  ),
              ]),
              const SizedBox(height: 4),
              _hint(l),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (var i = 0; i < 4; i++)
                  _card(l, _hand[i], w: 70, h: 100, lit: i == 0),
              ]),
            ]),
            w: 344,
            h: 228)),
    _pos(
        8,
        742,
        SizedBox(
            width: 344,
            child: Row(children: [
              _button(l, 'Keep', primary: false, w: 100),
              const SizedBox(width: 8),
              _button(l, 'Reroll', primary: false, w: 100),
              const SizedBox(width: 8),
              _button(l, 'Strike ×3', w: 128),
            ]))),
  ]);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('six whole fight screens', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    _enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    _foes = [
      _Foe('void_sovereign', 86, 86),
      _Foe('inquisition_warden', 22, 22),
      _Foe('white_soldier', 11, 16),
    ];
    Directory(shots!).createSync(recursive: true);
    await tester.runAsync(() async {
      for (final kit in ['apollo', 'b']) {
        for (final n in [
          'stage',
          'table',
          'cardframe',
          'panel',
          'slot',
          'kitcard'
        ]) {
          await _load('$_art/${kit}_$n.png');
        }
      }
      for (final f in [
        '$_art/b_hero.png',
        '$_art/b_foe.png',
        for (final n in [
          'void_sovereign',
          'white_soldier',
          'cleric',
          'mage',
          'die_d6'
        ])
          '$_bsa/$n.png',
        for (final n in [
          'void_sovereign',
          'inquisition_warden',
          'white_soldier'
        ])
          'assets/visuals/fighters/${n}_idle_west.png',
        for (final n in ['warrior', 'cleric', 'mage'])
          'assets/visuals/heroes/${n}_stand_east.png',
        'assets/visuals/dice/die_d6_bone_44.png',
      ]) {
        await _load(f);
      }
    });
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final layouts = <String, Widget Function(BuildContext, _L)>{
      'one-stage': _stage,
      'table': _table,
      'frame-kit': _hud,
    };
    for (final MapEntry(key: name, value: build) in layouts.entries) {
      for (final b in [false, true]) {
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(
                AppPalette.stitchedInk.schemeFor(Brightness.dark)),
            home: Builder(
              builder: (context) => Scaffold(
                  body: SizedBox(
                      width: 360,
                      height: 780,
                      child: build(context, b ? _L.b() : _L.current(context)))),
            ),
          ),
        ));
        for (var i = 0; i < 2; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/$name-${b ? 'b' : 'current'}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }
  });
}

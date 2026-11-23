// Six whole fight screens at 360 wide (UX_SHOTS=<folder>), pictures only:
// three layouts, each in today's style ("current") and in B (Art's style 1,
// ink and one colour). The user's complaint: the ground, the dice, the cards
// and the sprites look like four games. Rules for all six: one pixel scale
// (1 art pixel = 2 dp everywhere), one outline weight, the dice and the ground
// share a material, the cards wear the panels' frame family, and the weakness
// mark (B of this morning) and the matching-die hint are in every one.
//   1 One stage: the fight is one scene, the tray is the ground carried on,
//     the cards are cut from the same planks;
//   2 Table: tokens on a table, the dice roll on it, the cards are a hand;
//   3 One frame kit: a strict HUD, one frame family for every panel and slot.
// Real: the foes (enemies.json: The Sovereign weak to Light, resists Void; the
// Inquisition Warden weak to Electricity; the White Soldier weak to Fire), the
// heroes' and foes' sprites, the dice, the skill cards. Mock only: the drawing
// code below is not used by the app.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart' show CardTier;
import 'package:narrative_data_app/widgets/story_panel.dart';

import 'support/fonts.dart';

/// One art pixel in dp: the one pixel scale of every piece.
const double u = 2;
const String _bAssets = 'docs/ux-shots/fight-proposals/b-assets';

// B's greys and its one accent (Art's style 1: 090A14 202E37 394A50 8B9BA0
// EBEDE9, and the gold F2C14E).
const Color _ink = Color(0xFF090A14);
const Color _g1 = Color(0xFF202E37);
const Color _g2 = Color(0xFF394A50);
const Color _g3 = Color(0xFF8B9BA0);
const Color _paper = Color(0xFFEBEDE9);
const Color _gold = Color(0xFFF2C14E);

/// A look: today's, or B.
class _L {
  _L.current(BuildContext c)
      : b = false,
        bg = Theme.of(c).colorScheme.surface,
        panel = Theme.of(c).colorScheme.surfaceContainer,
        edge = Theme.of(c).colorScheme.outlineVariant,
        ink = Palette.apolloOutline,
        text = Theme.of(c).colorScheme.onSurface,
        dim = Theme.of(c).colorScheme.onSurfaceVariant,
        accent = const Color(0xFFE0A93A),
        hp = Palette.goodDeep,
        hpTrack = const Color(0xFF2A2A33),
        weak = Palette.goodDeep,
        resist = Palette.slate,
        wood = const Color(0xFF3B2A1E),
        woodEdge = const Color(0xFF22160F);
  _L.b()
      : b = true,
        bg = _ink,
        panel = _g1,
        edge = _g2,
        ink = _ink,
        text = _paper,
        dim = _g3,
        accent = _gold,
        hp = _gold,
        hpTrack = _g1,
        weak = _gold,
        resist = _g3,
        wood = _g1,
        woodEdge = _g2;

  final bool b;
  final Color bg, panel, edge, ink, text, dim, accent, hp, hpTrack;
  final Color weak, resist, wood, woodEdge;

  String foe(String id) =>
      b ? '$_bAssets/$id.png' : 'assets/visuals/fighters/${id}_idle_west.png';
  String hero(String id) =>
      b ? '$_bAssets/$id.png' : 'assets/visuals/heroes/${id}_stand_east.png';
  String get d6 =>
      b ? '$_bAssets/die_d6.png' : 'assets/visuals/dice/die_d6_bone_44.png';
  String get ground =>
      b ? '$_bAssets/ground.png' : 'assets/visuals/fight_plates/quay.png';

  /// The sprite's drawn size: 48 px, and B's outlined ones are 50.
  double get sprite => (b ? 50 : 48) * u;

  Image img(String path, {double? w, double? h, BoxFit? fit}) {
    final bytes = _bBytes[path];
    return bytes != null
        ? Image.memory(bytes,
            width: w,
            height: h,
            fit: fit ?? BoxFit.contain,
            filterQuality: FilterQuality.none)
        : Image.asset(path,
            width: w,
            height: h,
            fit: fit ?? BoxFit.contain,
            filterQuality: FilterQuality.none);
  }
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

Color _elementTint(_L l, String e) {
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

// ----------------------------------------------------------------- frames ---

/// B's one frame family: ink outline, a grey inner line, studs at the corners
/// (the accent on the one that matters). Every panel, slot and card of B.
class _PixelFramePainter extends CustomPainter {
  _PixelFramePainter(this.fill, {this.lit = false});
  final Color fill;
  final bool lit;

  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(r, Paint()..color = fill);
    final p = Paint()..style = PaintingStyle.fill;
    // The outer ink line, 1 art pixel, and the inner grey one.
    void ring(Rect rect, Color color) {
      p.color = color;
      canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, u), p);
      canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.bottom - u, rect.width, u), p);
      canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, u, rect.height), p);
      canvas.drawRect(
          Rect.fromLTWH(rect.right - u, rect.top, u, rect.height), p);
    }

    ring(r, _ink);
    ring(r.deflate(u), lit ? _gold : _g2);
    // The studs: a 2 x 2 art pixel square in each corner, inside both lines.
    final stud = Paint()..color = lit ? _gold : _g3;
    for (final c in [
      Offset(3 * u, 3 * u),
      Offset(s.width - 5 * u, 3 * u),
      Offset(3 * u, s.height - 5 * u),
      Offset(s.width - 5 * u, s.height - 5 * u),
    ]) {
      canvas.drawRect(Rect.fromLTWH(c.dx, c.dy, 2 * u, 2 * u), stud);
    }
  }

  @override
  bool shouldRepaint(_PixelFramePainter old) =>
      old.fill != fill || old.lit != lit;
}

/// The frame family of the look round [child]: B's own, today's rarity metal
/// (the story kit) in the current look. [tier] only matters for the current.
Widget _frame(_L l, Widget child,
    {Color? fill,
    CardTier tier = CardTier.common,
    EdgeInsets pad = const EdgeInsets.all(8),
    bool lit = false}) {
  if (l.b) {
    return CustomPaint(
      painter: _PixelFramePainter(fill ?? _g1, lit: lit),
      child: Padding(padding: pad + EdgeInsets.all(3 * u), child: child),
    );
  }
  return StoryFrame(
      tier: tier, band: 0.5, padding: pad, fill: fill ?? l.panel, child: child);
}

// ---------------------------------------------------------------- pieces ---

class _Foe {
  _Foe(this.id, this.sprite, this.hp, this.max, {this.boss = false})
      : data = _enemies[id] as Map<String, dynamic>;
  final String id, sprite;
  final int hp, max;
  final bool boss;
  final Map<String, dynamic> data;
  String get name => data['enemyName'] as String;
  List<String> get weak => [for (final e in (data['weakTo'] as List)) '$e'];
  List<String> get resist => [for (final e in (data['resists'] as List)) '$e'];
}

late Map<String, dynamic> _enemies;

/// B's pieces, read before the screens are built.
final Map<String, Uint8List> _bBytes = {};

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

/// The skill cards of the hand: real skills and their real rarities.
const _hand = [
  ('radiant_judgment', CardTier.common, 'Light'),
  ('fireball', CardTier.rare, 'Fire'),
  ('cleric_absolution', CardTier.epic, 'Light'),
  ('heavy_attack', CardTier.common, ''),
];

/// The dice rolled: one per hero; the Light one matches the aimed foe.
const _dice = [('Light', 5), ('Fire', 4), ('Void', 3)];

/// A weakness / resistance mark (B of this morning): the element's icon and
/// ×3 (or ×½) in a small pixel-cornered pill, the weak one in the look's
/// accent, ringed when it is the one the hero's die hits.
Widget _mark(_L l, String e, {required bool weak, bool ring = false}) {
  final frame = weak ? l.weak : l.resist;
  return Container(
    height: 16 + (ring ? 2 : 0),
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
      Icon(_icon(e), size: 11, color: _elementTint(l, e)),
      const SizedBox(width: 1),
      Text(weak ? '×3' : '×½',
          style: TextStyle(
              fontFamily: InkFonts.prose,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              height: 1,
              color: weak ? l.weak : l.dim)),
    ]),
  );
}

/// The foe's name, health and weakness marks: one plate, one place.
Widget _foePlate(_L l, _Foe f, {double width = 104, bool aimed = false}) {
  return Container(
    width: width,
    padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
    decoration: ShapeDecoration(
      color: l.bg.withValues(alpha: 0.88),
      shape: PixelChipBorder(
          side: BorderSide(
              color: aimed ? l.accent : l.edge, width: aimed ? 2.5 : 1.5),
          step: 3,
          steps: 3),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(f.name, maxLines: 1, style: _display(l, 11.5))),
      const SizedBox(height: 2),
      _hpBar(l, f.hp, f.max),
      const SizedBox(height: 3),
      Wrap(
          spacing: 2,
          runSpacing: 2,
          alignment: WrapAlignment.center,
          children: [
            for (final e in f.weak)
              _mark(l, e, weak: true, ring: aimed && e == 'Light'),
            for (final e in f.resist) _mark(l, e, weak: false),
          ]),
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

Widget _heroPlate(_L l, _Hero h, {double width = 104, bool turn = false}) {
  return Container(
    width: width,
    padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
    decoration: ShapeDecoration(
      color: l.bg.withValues(alpha: 0.88),
      shape: PixelChipBorder(
          side: BorderSide(
              color: turn ? l.accent : l.edge, width: turn ? 2.5 : 1.5),
          step: 3,
          steps: 3),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(h.name, style: _display(l, 11.5)),
      const SizedBox(height: 2),
      _hpBar(l, h.hp, h.max),
    ]),
  );
}

Widget _shadow(_L l, {double w = 64}) => Container(
      width: w,
      height: 9,
      decoration: ShapeDecoration(
        color: l.ink.withValues(alpha: 0.55),
        shape: const StadiumBorder(),
      ),
    );

/// Each sprite's canvas and the box its figure fills (art pixels), so a figure
/// is cropped tight and drawn at the one pixel scale. B's are outlined: a pixel
/// larger on every side.
const Map<String, (int, int, int, int, int, int)> _meta = {
  // name: (canvas w, canvas h, x0, y0, x1, y1)
  'void_sovereign': (60, 60, 19, 2, 46, 58),
  'inquisition_warden': (48, 48, 15, 2, 33, 46),
  'white_soldier': (48, 48, 15, 2, 34, 46),
  'warrior': (48, 48, 16, 7, 32, 48),
  'cleric': (48, 48, 17, 7, 32, 47),
  'mage': (48, 48, 16, 7, 32, 48),
};

/// The figure's box in dp and a widget that draws just it.
({double w, double h, Widget draw}) _figure(_L l, String name,
    {bool foe = true, double? headOnly}) {
  final (cw, ch, x0, y0, x1, y1) = _meta[name]!;
  final pad = l.b ? 1 : 0;
  final path = foe ? l.foe(name) : l.hero(name);
  final cwp = cw + 2 * pad, chp = ch + 2 * pad;
  final bx = x0, by = y0; // outline grows the box by one and the pad shifts it
  final bw = (x1 - x0) + 2 * pad, bh = (y1 - y0) + 2 * pad;
  final w = bw * u, h = (headOnly ?? bh.toDouble()) * u;
  return (
    w: w,
    h: h,
    draw: SizedBox(
      width: w,
      height: h,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: cwp * u,
          maxHeight: chp * u,
          child: Transform.translate(
            offset: Offset(-bx * u, -by * u),
            child: l.img(path, w: cwp * u, h: chp * u),
          ),
        ),
      ),
    ),
  );
}

/// A figure standing on its shadow (one light, from the top left: the shadow
/// falls a little to the right). Returns the figure's box too.
Widget _stand(_L l, String name, {bool foe = true, double minW = 0}) {
  final f = _figure(l, name, foe: foe);
  final w = f.w > minW ? f.w : minW;
  return SizedBox(
    width: w,
    height: f.h + 4,
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned(
          left: (w - (f.w + 22)) / 2 + 5,
          bottom: 0,
          child: _shadow(l, w: f.w + 22)),
      Positioned(left: (w - f.w) / 2, top: 0, child: f.draw),
    ]),
  );
}

/// A die with its face: the element's mark and the number on the top face; lit
/// and tagged when it is the one that hits the aimed foe for ×3.
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
          Positioned(top: 0, child: l.img(l.d6, w: size, h: size)),
          Positioned(
            top: size * 0.30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: ShapeDecoration(
                color: l.ink.withValues(alpha: 0.88),
                shape: PixelChipBorder(
                    side:
                        BorderSide(color: lit ? l.accent : l.edge, width: 1.5),
                    step: 2,
                    steps: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_icon(element),
                    size: 13 * scale,
                    color: l.b
                        ? (lit ? _gold : _paper)
                        : _elementTint(l, element)),
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
          Positioned(
            bottom: 0,
            child: Text(element, style: _sys(l, 8)),
          ),
        ]),
  );
}

/// A skill's pixel icon; in B it is folded to greys (B has one colour).
Widget _skillIcon(_L l, String id) {
  final icon = SkillPixelIcon(id, size: 40);
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

/// A skill card: its icon, name; in the look's frame family (rarity metal
/// today, B's one frame), over [back] (the planks it was cut from).
Widget _card(_L l, (String, CardTier, String) c,
    {double w = 78, double h = 108, Widget? back, bool lit = false}) {
  final (id, tier, element) = c;
  final body = Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (element.isNotEmpty)
        Icon(_icon(element), size: 11, color: _elementTint(l, element))
      else
        const SizedBox(height: 11),
      const SizedBox(height: 2),
      _skillIcon(l, id),
      const SizedBox(height: 4),
      Text(skillDisplayName(id),
          textAlign: TextAlign.center, maxLines: 2, style: _display(l, 10.5)),
    ],
  );
  final framed = _frame(
    l,
    SizedBox(width: w - 22, height: h - 22, child: Center(child: body)),
    fill: back == null ? null : Colors.transparent,
    tier: tier,
    pad: const EdgeInsets.all(2),
    lit: lit,
  );
  return SizedBox(
    width: w,
    height: h,
    child: Stack(children: [
      if (back != null) Positioned.fill(child: back),
      Positioned.fill(child: framed),
    ]),
  );
}

/// The turn bar: the next to act, left to right; the one acting wears the
/// accent. Each token is the figure's head, at the same pixel scale.
Widget _turnBar(_L l) {
  Widget token(String name, bool foe, {bool now = false}) {
    final f = _figure(l, name, foe: foe, headOnly: 17);
    return Container(
      width: 38,
      height: 38,
      margin: const EdgeInsets.only(right: 5),
      alignment: Alignment.bottomCenter,
      decoration: ShapeDecoration(
        color: l.panel,
        shape: PixelChipBorder(
            side: BorderSide(
                color: now ? l.accent : l.edge, width: now ? 2.5 : 1.5),
            step: 3,
            steps: 3),
      ),
      child: ClipRect(
          child: Align(alignment: Alignment.bottomCenter, child: f.draw)),
    );
  }

  return Row(children: [
    Text('TURN', style: _sys(l, 9)),
    const SizedBox(width: 6),
    token('warrior', false, now: true),
    token('void_sovereign', true),
    token('cleric', false),
    token('inquisition_warden', true),
    token('mage', false),
    token('white_soldier', true),
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
        color: primary ? l.accent : l.panel,
        shape: PixelChipBorder(
            side: BorderSide(color: primary ? l.ink : l.edge, width: 2),
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

// -------------------------------------------------------------- layouts ---

final _foes = [
  _Foe('void_sovereign', 'void_sovereign', 86, 86, boss: true),
  _Foe('inquisition_warden', 'inquisition_warden', 22, 22),
  _Foe('white_soldier', 'white_soldier', 11, 16),
];

Widget _pos(double l, double t, Widget child) =>
    Positioned(left: l, top: t, child: child);

Widget _foeAt(_L l, _Foe f, double w, {bool aimed = false}) => SizedBox(
      width: w,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _stand(l, f.sprite, minW: w),
        const SizedBox(height: 2),
        _foePlate(l, f, width: w, aimed: aimed),
      ]),
    );

Widget _heroAt(_L l, _Hero h, double w, {bool turn = false}) => SizedBox(
      width: w,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _stand(l, h.sprite, foe: false, minW: w),
        const SizedBox(height: 2),
        _heroPlate(l, h, width: w, turn: turn),
      ]),
    );

/// 1 One stage.
Widget _stage(BuildContext c, _L l) {
  const groundTop = 780.0 - 640;
  final planks = l.img(l.ground, w: 360, h: 640, fit: BoxFit.fill);
  Widget cut(double x, double y) => ClipRect(
        child: Stack(children: [
          Positioned(
              left: -x,
              top: -(y - groundTop),
              child: SizedBox(width: 360, height: 640, child: planks)),
          Positioned.fill(
              child:
                  Container(color: l.ink.withValues(alpha: l.b ? 0.5 : 0.6))),
        ]),
      );
  const cardY = 668.0;
  const cardX = [14.0, 98.0, 182.0, 266.0];
  return Stack(children: [
    Positioned.fill(
        child: Container(
            color: l.b ? const Color(0xFF37484E) : const Color(0xFF7F5F3C))),
    Positioned(
        bottom: 0,
        left: 0,
        child: SizedBox(width: 360, height: 640, child: planks)),
    Positioned(top: 0, left: 0, right: 0, child: _topBar(l)),
    _pos(12, 54, _turnBar(l)),
    // Foes stand on the far ground, the boss at the back.
    _pos(232, 104, _foeAt(l, _foes[0], 118, aimed: true)),
    _pos(140, 284, _foeAt(l, _foes[1], 104)),
    _pos(250, 356, _foeAt(l, _foes[2], 100)),
    // Heroes stand nearer, in a line down the left.
    _pos(10, 126, _heroAt(l, _party[0], 96, turn: true)),
    _pos(34, 256, _heroAt(l, _party[1], 96)),
    _pos(10, 386, _heroAt(l, _party[2], 96)),
    // The hint, then the tray: the ground carried on, the dice on the planks.
    _pos(14, 522, SizedBox(width: 332, child: _hint(l))),
    for (var i = 0; i < 3; i++)
      _pos(10.0 + i * 92, 548 + (i == 1 ? 6 : 0),
          _die(l, _dice[i].$1, _dice[i].$2, lit: i == 0, scale: 0.9)),
    _pos(290, 566, _button(l, 'Strike ×3', w: 62, fs: 11)),
    // The cards are cut from the same planks, in the same frame.
    for (var i = 0; i < 4; i++)
      _pos(cardX[i], cardY,
          _card(l, _hand[i], back: cut(cardX[i], cardY), lit: i == 0)),
  ]);
}

/// 2 Table.
Widget _table(BuildContext c, _L l) {
  return Stack(children: [
    Positioned.fill(child: Container(color: l.bg)),
    Positioned(top: 0, left: 0, right: 0, child: _topBar(l)),
    _pos(12, 54, _turnBar(l)),
    // The table: one material for the surface, the dice and the tokens.
    _pos(
        8,
        100,
        SizedBox(
          width: 344,
          height: 508,
          child: _frame(
              l,
              ClipRect(
                  child: CustomPaint(
                      size: const Size(344, 508),
                      painter: _PlankPainter(l.wood, l.woodEdge, l.b))),
              fill: l.wood,
              pad: const EdgeInsets.all(0)),
        )),
    // The foes along the far edge; the aimed one is in the middle.
    _pos(16, 112, _foeAt(l, _foes[1], 100)),
    _pos(118, 108, _foeAt(l, _foes[0], 124, aimed: true)),
    _pos(246, 112, _foeAt(l, _foes[2], 100)),
    // The dice roll in the middle of the same table.
    for (var i = 0; i < 3; i++)
      _pos(
          [30.0, 136.0, 242.0][i],
          [306.0, 316.0, 308.0][i],
          Transform.rotate(
              angle: [-0.08, 0.06, -0.04][i],
              child:
                  _die(l, _dice[i].$1, _dice[i].$2, lit: i == 0, scale: 0.95))),
    // The heroes along the near edge.
    for (var i = 0; i < 3; i++)
      _pos(18.0 + i * 108, 410, _heroAt(l, _party[i], 98, turn: i == 0)),
    _pos(18, 548, SizedBox(width: 210, child: _hint(l))),
    _pos(244, 552, _button(l, 'Strike ×3', w: 98)),
    // The hand: the cards fanned at the bottom, on the dark cloth.
    for (var i = 0; i < 4; i++)
      Positioned(
        left: 20.0 + i * 78,
        top: 646 + (i == 1 || i == 2 ? 0.0 : 10.0),
        child: Transform.rotate(
            angle: [-0.1, -0.035, 0.035, 0.1][i],
            child: _card(l, _hand[i], lit: i == 0)),
      ),
  ]);
}

class _PlankPainter extends CustomPainter {
  _PlankPainter(this.base, this.line, this.b);
  final Color base, line;
  final bool b;
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = base);
    final p = Paint()..color = line;
    var row = 0;
    for (var y = 6 * u; y < s.height; y += 12 * u) {
      canvas.drawRect(Rect.fromLTWH(0, y, s.width, u), p);
      for (var x = (row.isEven ? 30 : 56) * u; x < s.width; x += 74 * u) {
        canvas.drawRect(Rect.fromLTWH(x, y + u, u, 11 * u), p);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(_PlankPainter old) => false;
}

/// 3 One frame kit.
Widget _hud(BuildContext c, _L l) {
  Widget slot(Widget child,
          {bool lit = false, double w = 104, double h = 166}) =>
      SizedBox(
        width: w,
        height: h,
        child: _frame(l, Align(alignment: Alignment.bottomCenter, child: child),
            pad: const EdgeInsets.all(0), fill: l.panel, lit: lit),
      );
  Widget panel(double top, double height, Widget child) => _pos(
      8,
      top,
      SizedBox(
        width: 344,
        height: height,
        child: _frame(l, child, pad: const EdgeInsets.all(0)),
      ));
  return Stack(children: [
    Positioned.fill(child: Container(color: l.bg)),
    Positioned(top: 0, left: 0, right: 0, child: _topBar(l)),
    panel(
        54,
        46,
        Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Center(
                child: Align(
                    alignment: Alignment.centerLeft, child: _turnBar(l))))),
    // Foes: three slots of the one size.
    panel(
        104,
        202,
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          slot(_foeAt(l, _foes[1], 88), h: 190),
          slot(_foeAt(l, _foes[0], 88, aimed: true), lit: true, h: 190),
          slot(_foeAt(l, _foes[2], 88), h: 190),
        ])),
    // The party: the same three slots.
    panel(
        310,
        150,
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          slot(_heroAt(l, _party[0], 88, turn: true), lit: true, h: 140),
          slot(_heroAt(l, _party[1], 88), h: 140),
          slot(_heroAt(l, _party[2], 88), h: 140),
        ])),
    // The dice, each in a slot of the same frame.
    panel(
        464,
        122,
        Column(children: [
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (var i = 0; i < 3; i++)
              SizedBox(
                width: 104,
                height: 84,
                child: _frame(
                    l,
                    Center(
                        child: _die(l, _dice[i].$1, _dice[i].$2,
                            lit: i == 0, scale: 0.72)),
                    pad: const EdgeInsets.all(0),
                    lit: i == 0),
              ),
          ]),
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: _hint(l)),
        ])),
    // The hand, each card in a slot of the same frame.
    panel(
        590,
        134,
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (var i = 0; i < 4; i++)
            _card(l, _hand[i], w: 78, h: 108, lit: i == 0),
        ])),
    _pos(
        8,
        730,
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
    await tester.runAsync(StoryFrames.instance.preload);
    _enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    for (final f in Directory(_bAssets).listSync().whereType<File>()) {
      _bBytes[f.path.replaceAll('\\', '/')] = f.readAsBytesSync();
    }
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
        for (var i = 0; i < 3; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 400)));
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

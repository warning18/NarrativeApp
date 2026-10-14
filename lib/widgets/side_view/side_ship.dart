import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/ship_forms.dart';
import '../ship_dress.dart';
import 'side_view.dart';

/// The Eel's hulls in side view (v1.298): every hull of ships.json, drawn
/// in scene pixels from its record (the same [ShipForm] the top-down
/// painter reads): the length, the beam (how high she sits and how deep),
/// how full her ends are, the castles, the masts and how each is rigged,
/// the jibs, the oars, the beak, and for the odd hulls their own build (a
/// twin hull, an ironclad, the four flying boats). What she wears (see
/// [ShipDress]) colours her: the hull, the trim, the cloth and its pattern,
/// the ensign, the figurehead.

/// A ship's length in scene pixels: the Rusty Eel's sloop is 36, the others
/// by their `length`.
double sideShipLength(ShipForm form) => (36 * form.length).roundToDouble();

const Color _woodHull = Color(0xFF5A3A24);
const Color _woodTrim = Color(0xFF8A6038);
const Color _clothDefault = Color(0xFFE8E0C8);

Color _shade(Color c, double k) => Color.fromARGB(
    (c.a * 255).round(),
    (c.r * 255 * k).round().clamp(0, 255),
    (c.g * 255 * k).round().clamp(0, 255),
    (c.b * 255 * k).round().clamp(0, 255));

/// Fills the scene pixels whose centres lie inside [pts].
void _fillPoly(
    Canvas canvas, double u, Paint paint, List<(double, double)> pts) {
  var minY = pts.first.$2, maxY = pts.first.$2;
  for (final p in pts) {
    minY = math.min(minY, p.$2);
    maxY = math.max(maxY, p.$2);
  }
  for (var y = minY.floor(); y <= maxY.ceil(); y++) {
    final cy = y + 0.5;
    final xs = <double>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      if ((a.$2 <= cy && b.$2 > cy) || (b.$2 <= cy && a.$2 > cy)) {
        xs.add(a.$1 + (cy - a.$2) / (b.$2 - a.$2) * (b.$1 - a.$1));
      }
    }
    xs.sort();
    for (var i = 0; i + 1 < xs.length; i += 2) {
      final x0 = (xs[i] - 0.5).ceilToDouble();
      final x1 = (xs[i + 1] - 0.5).floorToDouble();
      if (x1 >= x0) {
        canvas.drawRect(
            Rect.fromLTWH(x0 * u, y * u, (x1 - x0 + 1) * u, u), paint);
      }
    }
  }
}

/// A line of scene pixels.
void _line(Canvas canvas, double u, Paint paint, double x0, double y0,
    double x1, double y1) {
  final n = math.max((x1 - x0).abs(), (y1 - y0).abs()).ceil();
  for (var i = 0; i <= n; i++) {
    final f = n == 0 ? 0.0 : i / n;
    canvas.drawRect(
        Rect.fromLTWH((x0 + (x1 - x0) * f).roundToDouble() * u,
            (y0 + (y1 - y0) * f).roundToDouble() * u, u, u),
        paint);
  }
}

class _Palette {
  _Palette(ShipForm form, ShipDress? dress, {Color? clothOverride})
      : hull = dress?.hull ?? _woodHull,
        trim = dress?.trim ?? _woodTrim,
        deck = dress?.deck ?? const Color(0xFF9A7448),
        cloth = clothOverride ?? dress?.cloth ?? _clothDefault,
        edge = dress?.clothEdge,
        pattern = dress?.clothPattern ?? 'plain',
        patternColor = dress?.clothPatternColor,
        ensign = dress?.ensignColor ?? const Color(0xFFC0392B),
        figurehead = dress?.figurehead ?? 'none',
        figureheadColor = dress?.figureheadColor ?? const Color(0xFFD9B36A),
        figureheadEye = dress?.figureheadEye ?? const Color(0xFF1B1B1B),
        mast = const Color(0xFF2E1E12);
  final Color hull, trim, deck, cloth, ensign, figureheadColor, figureheadEye;
  final Color? edge, patternColor;
  final String pattern, figurehead;
  final Color mast;

  Color get hullDark => _shade(hull, 0.62);
  Color get hullDeep => _shade(hull, 0.42);
  Color get clothShade => _shade(cloth, 0.84);
}

/// Paints [form] in side view, her stern at scene pixel [x] and her
/// waterline on row [base]. [t] is the scene's time (the sails belly, the
/// oars swing, the wings beat, the smoke drifts); [flying] only matters for
/// a hull that does not fly itself.
void paintSideShip(
  Canvas canvas,
  double u, {
  required double x,
  required double base,
  required ShipForm form,
  ShipDress? dress,
  double t = 0,
  bool rough = false,
}) {
  final pal = _Palette(form, dress);
  final len = sideShipLength(form);
  switch (form.kind) {
    case HullKind.twin:
      _twin(canvas, u, x, base, len, form, pal, t);
    case HullKind.iron:
      _ironclad(canvas, u, x, base, len, form, pal, t);
    case HullKind.gasbag:
      _hullAndRig(canvas, u, x, base, len, form, pal, t, rig: false);
      _gasbag(canvas, u, x, base, len, form, pal, t);
    case HullKind.batwing:
      _hullAndRig(canvas, u, x, base, len, form, pal, t, rig: false);
      _batwings(canvas, u, x, base, len, form, pal, t);
    case HullKind.lodestone:
      _lodestone(canvas, u, x, base, len, form, pal, t);
    case HullKind.bone:
      _bone(canvas, u, x, base, len, form, pal, t);
    case HullKind.hull:
      _hullAndRig(canvas, u, x, base, len, form, pal, t);
  }
}

/// The silhouette of a plain hull: the top row and the keel row of each
/// column, from the sheer, the castles and the fullness of the ends.
({List<double> top, List<double> keel, double freeboard}) _profile(
    ShipForm form, double len, double base,
    {double? freeboard, double sheerRise = 2.0, double? draft}) {
  final fb = freeboard ?? (3 + form.beam * 12).roundToDouble();
  final d = draft ?? (2 + form.beam * 7).roundToDouble();
  final n = len.toInt();
  final top = <double>[], keel = <double>[];
  for (var i = 0; i < n; i++) {
    final f = (i + 0.5) / n;
    final sheer = sheerRise * math.pow((2 * f - 1).abs(), 2);
    var y = base - fb - sheer.roundToDouble();
    for (final (from, to) in form.castles) {
      if (f >= from && f <= to) y -= 4;
    }
    top.add(y);
    keel.add(base + (d * math.pow(form.widthAt(f), 0.7)).roundToDouble());
  }
  return (top: top, keel: keel, freeboard: fb);
}

void _hull(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal,
    {Color? colour, double? freeboard, double sheerRise = 2.0, double? draft}) {
  final p = _profile(form, len, base,
      freeboard: freeboard, sheerRise: sheerRise, draft: draft);
  final hull = Paint()..color = colour ?? pal.hull;
  final dark = Paint()..color = _shade(colour ?? pal.hull, 0.62);
  final deep = Paint()..color = _shade(colour ?? pal.hull, 0.42);
  final trim = Paint()..color = pal.trim;
  for (var i = 0; i < p.top.length; i++) {
    final yt = p.top[i], yk = p.keel[i];
    // Above the waterline: the hull's side, a plank line, the rail.
    sidePixels(canvas, u, hull, x + i, yt, 1, base - yt);
    sidePixels(canvas, u, dark, x + i, yt + ((base - yt) * 0.55).floor(), 1, 1);
    sidePixels(canvas, u, trim, x + i, yt, 1, 1);
    // Below it: darker with the keel line.
    if (yk > base) {
      sidePixels(canvas, u, deep, x + i, base, 1, yk - base);
    }
  }
  // The stem and the stern post: one lighter pixel at each end.
  sidePixels(canvas, u, trim, x, p.top.first, 1, 2);
  sidePixels(canvas, u, trim, x + len - 1, p.top.last, 1, 2);
  // A castle shows its break: a rail on top and, aft, a lit cabin window.
  for (final (from, to) in form.castles) {
    final i0 = (from * len).floor().clamp(0, p.top.length - 1);
    final i1 = (to * len).floor().clamp(0, p.top.length - 1);
    sidePixels(canvas, u, dark, x + i0, p.top[i0], 1, base - p.top[i0]);
    sidePixels(canvas, u, dark, x + i1, p.top[i1], 1, base - p.top[i1]);
    if (from < 0.4) {
      for (var i = i0 + 2; i < i1 - 1; i += 3) {
        sidePixels(canvas, u, Paint()..color = const Color(0xFFE8C46A), x + i,
            p.top[i] + 2, 1, 1);
      }
    }
  }
  // Gun ports on the great ships.
  if (form.castles.isNotEmpty || (form.beam >= 0.25 && form.length >= 1.0)) {
    final port = Paint()..color = const Color(0xFF1A110A);
    for (var i = (len * 0.30).floor(); i < len * 0.76; i += 4) {
      final y = p.top[i] + 3;
      if (y < base - 1) sidePixels(canvas, u, port, x + i, y, 2, 1);
    }
  }
}

/// The figurehead at the bow and the beak (bowsprit) beyond it.
void _bow(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double bowTop) {
  final bx = x + len;
  final spar = Paint()..color = pal.mast;
  if (form.beak || form.jibs > 0 || form.kind == HullKind.hull) {
    _line(canvas, u, spar, bx - 3, bowTop + 1, bx + (form.beak ? 8 : 4),
        bowTop - (form.beak ? 4 : 2));
  }
  if (pal.figurehead != 'none') {
    sidePixels(canvas, u, Paint()..color = pal.figureheadColor, bx - 1,
        bowTop + 1, 3, 3);
    sidePixels(canvas, u, Paint()..color = pal.figureheadEye, bx + 1,
        bowTop + 1, 1, 1);
  }
}

void _pennant(
    Canvas canvas, double u, double mx, double top, _Palette pal, double t) {
  final flag = Paint()..color = pal.ensign;
  final wag = math.sin(t * 3.0).roundToDouble();
  sidePixels(canvas, u, flag, mx + 1, top - 1, 3, 1);
  sidePixels(canvas, u, flag, mx + 4, top - 1 + wag * 0.0, 2, 1);
  sidePixels(canvas, u, flag, mx + 1, top, 2 + (wag > 0 ? 1 : 0), 1);
}

void _stampPattern(Canvas canvas, double u, _Palette pal, double x0, double y0,
    double w, double h) {
  final c = pal.patternColor;
  if (c == null || pal.pattern == 'plain') return;
  final paint = Paint()..color = c;
  switch (pal.pattern) {
    case 'stripes':
      for (var i = 2; i < w - 1; i += 4) {
        sidePixels(canvas, u, paint, x0 + i, y0 + 1, 2, h - 2);
      }
    case 'patches':
      sidePixels(canvas, u, paint, x0 + w * 0.2, y0 + h * 0.2, 3, 3);
      sidePixels(canvas, u, paint, x0 + w * 0.55, y0 + h * 0.55, 4, 3);
    case 'diamonds':
      for (var j = 2; j < h - 1; j += 4) {
        for (var i = 2 + (j % 8 == 2 ? 0 : 2); i < w - 1; i += 4) {
          sidePixels(canvas, u, paint, x0 + i, y0 + j, 1, 1);
        }
      }
  }
}

/// A square sail, bellied toward the bow, with a yard on top.
void _squareSail(Canvas canvas, double u, double mx, double top, double w,
    double h, _Palette pal, double t) {
  final cloth = Paint()..color = pal.cloth;
  final shade = Paint()..color = pal.clothShade;
  final yard = Paint()..color = pal.mast;
  final belly = 0.8 + 0.4 * math.sin(t * 1.4);
  final x0 = mx - w / 2;
  for (var j = 0; j < h; j++) {
    final bulge = (math.sin(math.pi * (j + 0.5) / h) * 1.6 * belly).round();
    sidePixels(canvas, u, cloth, x0, top + j, w + bulge, 1);
    sidePixels(canvas, u, shade, x0 + w - 2 + bulge, top + j, 2, 1);
  }
  sidePixels(canvas, u, shade, x0, top + h - 2, w, 2);
  _stampPattern(canvas, u, pal, x0, top, w, h);
  if (pal.edge != null) {
    sidePixels(canvas, u, Paint()..color = pal.edge!, x0, top + h - 1, w, 1);
  }
  sidePixels(canvas, u, yard, x0 - 1, top - 1, w + 3, 1);
}

/// A fore-and-aft (gaff) sail aft of its mast.
void _gaffSail(Canvas canvas, double u, double mx, double top, double bottom,
    double w, _Palette pal) {
  final cloth = Paint()..color = pal.cloth;
  final shade = Paint()..color = pal.clothShade;
  _fillPoly(canvas, u, cloth, [
    (mx + 0.5, top),
    (mx - w * 0.55, top + 3),
    (mx - w, bottom),
    (mx + 0.5, bottom),
  ]);
  _fillPoly(canvas, u, shade, [
    (mx - w * 0.55, top + 3 + (bottom - top) * 0.5),
    (mx - w, bottom),
    (mx - w * 0.45, bottom),
  ]);
  final spar = Paint()..color = pal.mast;
  _line(canvas, u, spar, mx + 1, top, mx - w * 0.55, top + 3);
  sidePixels(canvas, u, spar, mx - w, bottom, w + 1, 1);
}

/// A lateen sail: a long triangle on a slanting yard.
void _lateenSail(Canvas canvas, double u, double mx, double top, double bottom,
    double w, _Palette pal) {
  final cloth = Paint()..color = pal.cloth;
  final shade = Paint()..color = pal.clothShade;
  final peak = (mx - w * 0.2, top);
  final tack = (mx + w * 0.55, bottom);
  final clew = (mx - w * 0.75, bottom);
  _fillPoly(canvas, u, cloth, [peak, tack, clew]);
  _fillPoly(canvas, u, shade, [
    (mx - w * 0.2, top + (bottom - top) * 0.5),
    (mx + w * 0.2, bottom),
    (mx - w * 0.55, bottom),
  ]);
  _line(canvas, u, Paint()..color = pal.mast, clew.$1, clew.$2 + 1, peak.$1,
      peak.$2);
  if (pal.edge != null) {
    _line(canvas, u, Paint()..color = pal.edge!, clew.$1, clew.$2, tack.$1,
        tack.$2);
  }
}

void _rig(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t, List<double> top) {
  final s = len / 36;
  final deckY = base - (3 + form.beam * 12).roundToDouble() - 1;
  final mastPaint = Paint()..color = pal.mast;
  final tall = form.masts.length >= 3;
  double highest = deckY;
  double firstMast = x + len;
  for (final m in form.masts) {
    final mx = (x + len * m.at).floorToDouble();
    firstMast = math.min(firstMast, mx);
    final hMast =
        (24 * s * math.pow(m.size, 0.7) + (tall ? 8 : 0)).roundToDouble();
    final topY = deckY - hMast;
    highest = math.min(highest, topY);
    final ground = deckY + 1;
    sidePixels(canvas, u, mastPaint, mx, topY, 1, ground - topY);
    switch (m.kind) {
      case SailKind.square:
        final crowd = form.masts.length >= 3
            ? 0.68
            : (form.masts.length == 2 ? 0.86 : 1.0);
        final w = (13 * s * m.size * crowd).roundToDouble();
        if (tall) {
          final hCourse = (12 * s * m.size).roundToDouble();
          final hTop = (7 * s * m.size).roundToDouble();
          _squareSail(canvas, u, mx, deckY - hCourse - 1, w, hCourse, pal, t);
          _squareSail(canvas, u, mx, deckY - hCourse - hTop - 3, w * 0.74, hTop,
              pal, t);
        } else {
          final h = (14 * s * m.size).roundToDouble();
          _squareSail(canvas, u, mx, topY + 2, w, h, pal, t);
        }
      case SailKind.gaff:
        _gaffSail(canvas, u, mx, topY + 2, deckY - 3,
            (15 * s * m.size).roundToDouble(), pal);
      case SailKind.lateen:
        _lateenSail(canvas, u, mx, topY + 1, deckY - 2,
            (18 * s * m.size).roundToDouble(), pal);
    }
  }
  if (form.masts.isNotEmpty) {
    final mainMast = form.masts[form.masts.length ~/ 2];
    _pennant(canvas, u, (x + len * mainMast.at).floorToDouble(), highest - 1,
        pal, t);
  }
  // Jibs: slanting triangles from the foremost mast to the bowsprit.
  final cloth = Paint()..color = pal.cloth;
  final shade = Paint()..color = pal.clothShade;
  for (var j = 0; j < form.jibs; j++) {
    final headX = x + len * (form.masts.isEmpty ? 0.7 : form.masts.last.at) + 1;
    final headY = deckY - 18 * s + j * 4;
    final tackX = x + len + 3 - j * 5;
    final tackY = deckY - 1 - j;
    _fillPoly(
        canvas, u, cloth, [(headX, headY), (headX, tackY), (tackX, tackY)]);
    _line(canvas, u, shade, headX, tackY, tackX, tackY);
  }
}

void _oars(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t, List<double> top) {
  if (form.oars <= 0) return;
  final n = (form.oars / 2).ceil();
  final oar = Paint()..color = const Color(0xFFB08A58);
  final blade = Paint()..color = const Color(0xFF8A6A3E);
  for (var i = 0; i < n; i++) {
    final f = 0.16 + 0.68 * (n == 1 ? 0.5 : i / (n - 1));
    final col = (f * len).floor().clamp(0, top.length - 1);
    final swing = (math.sin(t * 2.0 + i * 0.7) * 2.5).roundToDouble();
    final x0 = x + col, y0 = top[col] + 2;
    final x1 = x0 - 4 + swing, y1 = base + 4;
    _line(canvas, u, oar, x0, y0, x1, y1);
    sidePixels(canvas, u, blade, x1 - 1, y1, 3, 1);
  }
}

void _hullAndRig(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t,
    {bool rig = true}) {
  _hull(canvas, u, x, base, len, form, pal);
  final p = _profile(form, len, base);
  _bow(canvas, u, x, base, len, form, pal, p.top.last);
  if (rig) _rig(canvas, u, x, base, len, form, pal, t, p.top);
  _oars(canvas, u, x, base, len, form, pal, t, p.top);
}

/// Two slender hulls under one deck, one behind the other, two lateens.
void _twin(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t) {
  final far = _Palette(form, null);
  _hull(canvas, u, x + 3, base - 2, len - 4, form, far,
      colour: _shade(pal.hull, 0.7), freeboard: 3, sheerRise: 1.5, draft: 2);
  _hull(canvas, u, x, base, len, form, pal,
      freeboard: 4, sheerRise: 1.5, draft: 3);
  final deck = Paint()..color = pal.deck;
  final rail = Paint()..color = pal.trim;
  // The deck between the hulls, a cabin on it.
  sidePixels(canvas, u, deck, x + len * 0.12, base - 8, len * 0.72, 2);
  sidePixels(canvas, u, rail, x + len * 0.12, base - 9, len * 0.72, 1);
  sidePixels(canvas, u, Paint()..color = pal.hullDark, x + len * 0.42,
      base - 14, 7, 5);
  sidePixels(canvas, u, rail, x + len * 0.42, base - 15, 8, 1);
  sidePixels(canvas, u, Paint()..color = const Color(0xFFE8C46A),
      x + len * 0.42 + 2, base - 12, 2, 1);
  final p = _profile(form, len, base, freeboard: 4, sheerRise: 1.5, draft: 3);
  _bow(canvas, u, x, base, len, form, pal, p.top.last);
  final mastPaint = Paint()..color = pal.mast;
  for (final m in form.masts) {
    final mx = (x + len * m.at).floorToDouble();
    final topY = base - 8 - (22 * m.size).roundToDouble();
    sidePixels(canvas, u, mastPaint, mx, topY, 1, base - 7 - topY);
    _lateenSail(
        canvas, u, mx, topY + 1, base - 10, (19 * m.size).roundToDouble(), pal);
  }
  if (form.masts.isNotEmpty) {
    _pennant(canvas, u, (x + len * form.masts.first.at).floorToDouble(),
        base - 8 - 22 - 1, pal, t);
  }
}

/// An ironclad: a low plated hull, a sloped casemate, two funnels, smoke.
void _ironclad(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t) {
  const iron = Color(0xFF4F5863);
  final plate = Paint()..color = iron;
  final light = Paint()..color = _shade(iron, 1.35);
  final dark = Paint()..color = _shade(iron, 0.6);
  // The hull: a long low slab with a ram.
  sidePixels(canvas, u, plate, x + 2, base - 4, len - 4, 4);
  sidePixels(canvas, u, light, x + 2, base - 4, len - 4, 1);
  sidePixels(canvas, u, dark, x + 3, base, len - 6, 3);
  _fillPoly(canvas, u, plate, [
    (x + len - 2, base - 4),
    (x + len + 1, base - 1),
    (x + len - 2, base),
  ]);
  _line(canvas, u, dark, x + len, base + 1, x + len + 4, base + 1); // the ram
  sidePixels(canvas, u, plate, x, base - 5, 3, 5);
  // The casemate: a sloped box, riveted.
  _fillPoly(canvas, u, Paint()..color = _shade(iron, 1.1), [
    (x + len * 0.2, base - 4),
    (x + len * 0.28, base - 11),
    (x + len * 0.74, base - 11),
    (x + len * 0.82, base - 4),
  ]);
  sidePixels(canvas, u, light, x + len * 0.28, base - 11, len * 0.46, 1);
  for (var i = 0; i < len * 0.5; i += 3) {
    sidePixels(canvas, u, light, x + len * 0.26 + i, base - 7, 1, 1);
  }
  final port = Paint()..color = const Color(0xFF14110F);
  for (final f in [0.36, 0.5, 0.64]) {
    sidePixels(canvas, u, port, x + len * f, base - 9, 3, 2);
  }
  // Two funnels, each banded, with smoke streaming aft.
  for (final f in [0.38, 0.58]) {
    final fx = (x + len * f).floorToDouble();
    sidePixels(canvas, u, Paint()..color = const Color(0xFF1B1B20), fx,
        base - 20, 4, 9);
    sidePixels(canvas, u, Paint()..color = pal.ensign, fx, base - 15, 4, 1);
    sidePixels(canvas, u, Paint()..color = const Color(0xFF3A3A44), fx,
        base - 20, 4, 1);
    for (var i = 0; i < 5; i++) {
      final age = ((t * 0.7 + i / 5 + f) % 1.0);
      final sx = fx + 1 - age * 18;
      final sy = base - 21 - age * 12;
      final a = (1 - age) * 0.55;
      sidePixels(
          canvas,
          u,
          Paint()..color = const Color(0xFF9A9AA4).withValues(alpha: a),
          sx,
          sy,
          2 + age * 3,
          2 + age * 2);
    }
  }
  sidePixels(
      canvas, u, Paint()..color = pal.mast, x + len * 0.48, base - 18, 1, 8);
  _pennant(canvas, u, x + len * 0.48, base - 19, pal, t);
}

/// A sky-sloop: a gasbag over the deck on its lines, a boiler chimney and a
/// screw aft.
void _gasbag(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t) {
  final cx = x + len * 0.5;
  final cy = base - 22;
  final rx = len * 0.42, ry = 9.0;
  final env = Paint()..color = const Color(0xFFBBA77C);
  final band = Paint()..color = const Color(0xFF9A8860);
  final rim = Paint()..color = const Color(0xFF6D5E3E);
  for (var j = -ry.toInt(); j <= ry.toInt(); j++) {
    final w = rx * math.sqrt(1 - math.pow(j / ry, 2));
    sidePixels(canvas, u, env, cx - w, cy + j, w * 2, 1);
    if (j.abs() >= ry.toInt() - 1) {
      sidePixels(canvas, u, rim, cx - w, cy + j, w * 2, 1);
    }
  }
  for (var i = -rx.toInt() + 4; i < rx; i += 6) {
    final w = (ry * math.sqrt(1 - math.pow(i / rx, 2))).floor();
    sidePixels(canvas, u, band, cx + i, cy - w + 1, 1, w * 2 - 1);
  }
  final rope = Paint()..color = pal.mast;
  for (final f in [0.22, 0.4, 0.6, 0.78]) {
    _line(canvas, u, rope, x + len * f, cy + ry - 1, x + len * f, base - 9);
  }
  // The boiler chimney, with smoke.
  final bx = (x + len * 0.3).floorToDouble();
  sidePixels(
      canvas, u, Paint()..color = const Color(0xFF2A2A30), bx, base - 13, 3, 6);
  for (var i = 0; i < 4; i++) {
    final age = ((t * 0.8 + i / 4) % 1.0);
    sidePixels(
        canvas,
        u,
        Paint()
          ..color = const Color(0xFFB0B0B8).withValues(alpha: (1 - age) * 0.5),
        bx - age * 10,
        base - 15 - age * 6,
        2 + age * 2,
        2);
  }
  // The screw, turning.
  final screw = Paint()..color = const Color(0xFFB8B8C0);
  final sy = base - 4;
  final blade = (math.sin(t * 14) > 0) ? 4.0 : 2.0;
  sidePixels(canvas, u, screw, x - 2, sy - blade / 2 + 1, 1, blade);
  sidePixels(
      canvas, u, Paint()..color = const Color(0xFF6B6B74), x - 1, sy + 1, 2, 1);
  _pennant(canvas, u, cx, cy - ry - 2, pal, t);
}

/// A cloud-cutter: two bat-wing sails, a furnace glowing aft.
void _batwings(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t) {
  final membrane = Paint()..color = const Color(0xFF3C2A52);
  final rib = Paint()..color = const Color(0xFF7A6A92);
  final mastPaint = Paint()..color = pal.mast;
  for (final f in [0.34, 0.64]) {
    final mx = (x + len * f).floorToDouble();
    final topY = base - 31;
    sidePixels(canvas, u, mastPaint, mx, topY, 1, 24);
    final flap = math.sin(t * 1.6 + f * 4) * 1.5;
    final tips = [
      (mx - 11.0, topY + 9 + flap),
      (mx - 7.0, topY + 17 + flap * 0.6),
      (mx - 2.0, topY + 20),
    ];
    _fillPoly(canvas, u, membrane, [
      (mx, topY),
      tips[0],
      (mx - 7.0, topY + 8),
      tips[1],
      (mx - 4.0, topY + 14),
      tips[2],
      (mx, topY + 17)
    ]);
    for (final tp in tips) {
      _line(canvas, u, rib, mx, topY + 1, tp.$1, tp.$2);
    }
    sidePixels(canvas, u, rib, mx - 1, topY - 1, 3, 1);
  }
  // The furnace aft: a glow that gutters.
  final flicker = 0.6 + 0.4 * math.sin(t * 9);
  sidePixels(
      canvas,
      u,
      Paint()..color = const Color(0xFFE8782E).withValues(alpha: flicker),
      x + 2,
      base - 9,
      3,
      3);
  sidePixels(
      canvas,
      u,
      Paint()..color = const Color(0xFFFFD27A).withValues(alpha: flicker),
      x + 3,
      base - 8,
      1,
      1);
  _pennant(canvas, u, (x + len * 0.34).floorToDouble(), base - 32, pal, t);
}

/// A lodestone barge: a heavy iron-and-stone slab held up by lodestones
/// hanging from her keel, with sparks between them.
void _lodestone(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t) {
  const stone = Color(0xFF6E6A72);
  final slab = Paint()..color = stone;
  final lightS = Paint()..color = _shade(stone, 1.3);
  final darkS = Paint()..color = _shade(stone, 0.6);
  final iron = Paint()..color = const Color(0xFF3F4650);
  sidePixels(canvas, u, slab, x, base - 6, len, 6);
  sidePixels(canvas, u, lightS, x, base - 6, len, 1);
  sidePixels(canvas, u, darkS, x + 1, base - 1, len - 2, 2);
  for (var i = 4; i < len - 2; i += 8) {
    sidePixels(canvas, u, iron, x + i, base - 6, 2, 6);
  }
  // Cargo: boulders on the deck, and two iron pylons.
  sidePixels(canvas, u, darkS, x + len * 0.5, base - 10, 8, 4);
  sidePixels(canvas, u, slab, x + len * 0.5 + 1, base - 11, 5, 1);
  sidePixels(canvas, u, darkS, x + len * 0.3, base - 9, 5, 3);
  sidePixels(canvas, u, iron, x + len * 0.12, base - 14, 2, 8);
  sidePixels(canvas, u, iron, x + len * 0.86, base - 14, 2, 8);
  final glow = 0.55 + 0.45 * math.sin(t * 3);
  for (final f in [0.2, 0.42, 0.64, 0.84]) {
    final lx = (x + len * f).floorToDouble();
    sidePixels(canvas, u, iron, lx + 1, base, 1, 2);
    sidePixels(canvas, u, Paint()..color = const Color(0xFF3F6A8A), lx - 1,
        base + 2, 4, 3);
    sidePixels(
        canvas,
        u,
        Paint()..color = const Color(0xFF7FD8F0).withValues(alpha: glow),
        lx,
        base + 3,
        2,
        1);
  }
  // Spark arcs between the pylons.
  if (math.sin(t * 5) > 0.3) {
    final spark = Paint()..color = const Color(0xFF7FD8F0);
    _line(canvas, u, spark, x + len * 0.12 + 1, base - 14, x + len * 0.86,
        base - 14);
  }
  _pennant(canvas, u, x + len * 0.12, base - 15, pal, t);
}

/// A void carrack: a bone-pale hull with the dark sail of the void, and
/// bone wings that beat.
void _bone(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, double t) {
  final boneHull = Color.lerp(pal.hull, const Color(0xFFD8D0BC), 0.8)!;
  _hull(canvas, u, x, base, len, form, pal, colour: boneHull);
  final p = _profile(form, len, base);
  _bow(canvas, u, x, base, len, form, pal, p.top.last);
  // The wings: three finger-bones from the shoulder, a membrane between.
  final sx = x + len * 0.46, sy = base - 8;
  final beat = math.sin(t * 1.5);
  final bone = Paint()..color = const Color(0xFFE6DFCB);
  final membrane = Paint()
    ..color = const Color(0xFF4A2F6B).withValues(alpha: 0.85);
  final tips = [
    (sx - 22 + beat * 3, sy - 22 - beat * 5),
    (sx - 14 + beat * 2, sy - 28 - beat * 4),
    (sx - 3 + beat * 1, sy - 30 - beat * 3),
  ];
  _fillPoly(canvas, u, membrane, [(sx, sy), tips[0], tips[1], tips[2]]);
  for (final tp in tips) {
    _line(canvas, u, bone, sx, sy, tp.$1, tp.$2);
  }
  // A short square sail of void cloth ahead of the wings.
  final mx = (x + len * 0.62).floorToDouble();
  sidePixels(canvas, u, Paint()..color = pal.mast, mx, base - 26, 1, 20);
  final voidCloth =
      _Palette(form, null, clothOverride: const Color(0xFF3B2A5A));
  _squareSail(canvas, u, mx + 1, base - 24, 10, 10, voidCloth, t);
  _pennant(canvas, u, mx, base - 27, pal, t);
}

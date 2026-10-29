// The front of a building, for a scene played outside it (v1.544, see
// street_view.dart): the street-view kit's counterpart of the room kits,
// which draw the inside. Six styles by what the building is (a house, an
// inn or den, a warehouse, a shop or forge, a temple, a hall or keep), each
// on the side-view engine's grid: a wall, a roof, a door with a step, windows
// that light at dusk and night, and the small things that say what it is.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/room_plan.dart' show RoomKind;
import '../side_view/side_view.dart';

enum FacadeStyle { house, tavern, warehouse, shop, temple, fort }

/// The style of a building of [kind] named [name] (the same reading as the
/// room kits: the name decides when it says what the building is).
FacadeStyle facadeStyleOf(String kind, String name) {
  return switch (RoomKind.of(RoomKind.resolve(kind, name))) {
    RoomKind.den ||
    RoomKind.tavern ||
    RoomKind.inn ||
    RoomKind.casino ||
    RoomKind.theatre ||
    RoomKind.baths =>
      FacadeStyle.tavern,
    RoomKind.warehouse ||
    RoomKind.cellar ||
    RoomKind.cave =>
      FacadeStyle.warehouse,
    RoomKind.shop || RoomKind.forge || RoomKind.library => FacadeStyle.shop,
    RoomKind.temple => FacadeStyle.temple,
    RoomKind.hall ||
    RoomKind.keep ||
    RoomKind.tower ||
    RoomKind.barracks ||
    RoomKind.prison =>
      FacadeStyle.fort,
    _ => FacadeStyle.house,
  };
}

/// Where a facade stands on the scene's grid.
class FacadeBox {
  const FacadeBox(this.left, this.top, this.width, this.base);

  final double left;
  final double top;
  final double width;

  /// The kerb: the row the wall stands on.
  final double base;

  double get height => base - top;
  double get doorX => left + width / 2;
}

/// The building's place in a scene [cols] scene pixels wide: left of
/// centre, so the party's door and the pins before it share the middle.
FacadeBox facadeBoxFor(FacadeStyle style, double cols, double base) {
  final w = math.min(
      cols * 0.56,
      switch (style) {
        FacadeStyle.warehouse => 78.0,
        FacadeStyle.tavern => 70.0,
        FacadeStyle.fort => 62.0,
        FacadeStyle.temple => 52.0,
        _ => 58.0,
      });
  final h = switch (style) {
    FacadeStyle.temple => 40.0,
    FacadeStyle.fort => 38.0,
    FacadeStyle.warehouse => 30.0,
    _ => 34.0,
  };
  return FacadeBox((cols - w) / 2, base - h, w, base);
}

/// The colours of a facade by the hour is the wash's job; these are the
/// day's. [snow] whitens the roof; the rest does not change with weather.
class FacadePalette {
  const FacadePalette({
    required this.wall,
    required this.shade,
    required this.roof,
    required this.timber,
    required this.door,
    required this.glass,
  });

  final Color wall;
  final Color shade;
  final Color roof;
  final Color timber;
  final Color door;
  final Color glass;

  static FacadePalette of(FacadeStyle style) => switch (style) {
        FacadeStyle.house => const FacadePalette(
            wall: Color(0xFFC3B08F),
            shade: Color(0xFF9C8A6E),
            roof: Color(0xFF7A4B3B),
            timber: Color(0xFF4F3B2D),
            door: Color(0xFF3D2A1D),
            glass: Color(0xFF6D8FA0)),
        FacadeStyle.tavern => const FacadePalette(
            wall: Color(0xFFA98E6E),
            shade: Color(0xFF7F6850),
            roof: Color(0xFF5E3F36),
            timber: Color(0xFF3F2E24),
            door: Color(0xFF2E2018),
            glass: Color(0xFF5E7A86)),
        FacadeStyle.warehouse => const FacadePalette(
            wall: Color(0xFF8F8575),
            shade: Color(0xFF6D6559),
            roof: Color(0xFF55483E),
            timber: Color(0xFF3B3028),
            door: Color(0xFF3A2D22),
            glass: Color(0xFF58707A)),
        FacadeStyle.shop => const FacadePalette(
            wall: Color(0xFFBBA383),
            shade: Color(0xFF93805F),
            roof: Color(0xFF6C4A3A),
            timber: Color(0xFF4A3828),
            door: Color(0xFF3A2A1E),
            glass: Color(0xFF75929F)),
        FacadeStyle.temple => const FacadePalette(
            wall: Color(0xFFB4B0A6),
            shade: Color(0xFF8A877E),
            roof: Color(0xFF5B5C66),
            timber: Color(0xFF45464F),
            door: Color(0xFF3A2C22),
            glass: Color(0xFF7A8FB0)),
        FacadeStyle.fort => const FacadePalette(
            wall: Color(0xFF8E8C88),
            shade: Color(0xFF6A6865),
            roof: Color(0xFF55555A),
            timber: Color(0xFF3F3F44),
            door: Color(0xFF362A20),
            glass: Color(0xFF4F5A64)),
      };
}

/// Paints the facade of [style] in [box]. [lit] lights its windows warm
/// (the evening's and the night's): done again over the hour's wash by
/// [paintFacadeLights], so the glow is not dimmed with the rest. [snow]
/// whitens the roof.
void paintFacade(Canvas canvas, double u, FacadeStyle style, FacadeBox box,
    {bool snow = false}) {
  final p = FacadePalette.of(style);
  final paint = Paint();
  void rect(Color c, double x, double y, double w, double h) {
    paint.color = c;
    sidePixels(canvas, u, paint, x, y, w, h);
  }

  final x0 = box.left, w = box.width, base = box.base;
  final roofColour = snow ? Color.lerp(p.roof, Colors.white, 0.65)! : p.roof;

  switch (style) {
    case FacadeStyle.house:
    case FacadeStyle.tavern:
    case FacadeStyle.shop:
      final roofH = style == FacadeStyle.tavern ? 9.0 : 10.0;
      final wallTop = box.top + roofH;
      rect(p.wall, x0, wallTop, w, base - wallTop);
      rect(p.shade, x0, wallTop, 2, base - wallTop);
      rect(p.shade, x0 + w - 2, wallTop, 2, base - wallTop);
      // A gable: rows of roof narrowing to the ridge.
      for (var i = 0; i < roofH; i++) {
        final inset = (roofH - 1 - i) * (w / 2 / roofH);
        rect(roofColour, x0 - 2 + inset, box.top + i, w + 4 - inset * 2, 1);
      }
      rect(p.shade, x0 - 2, wallTop - 1, w + 4, 1);
      if (style != FacadeStyle.shop) {
        // Timber framing: a beam across the floors and posts.
        rect(p.timber, x0, wallTop + 11, w, 1);
        for (final f in [0.0, 0.5, 1.0]) {
          rect(p.timber, x0 + (w - 1) * f, wallTop, 1, base - wallTop);
        }
      }
      // A chimney on the roof.
      rect(p.shade, x0 + w * 0.74, box.top - 3, 4, 8);
      rect(roofColour, x0 + w * 0.74 - 1, box.top - 4, 6, 1);
    case FacadeStyle.warehouse:
      const roofH = 6.0;
      final wallTop = box.top + roofH;
      rect(p.wall, x0, wallTop, w, base - wallTop);
      for (var y = wallTop + 3; y < base; y += 4) {
        rect(p.shade, x0, y, w, 1);
      }
      for (var i = 0; i < roofH; i++) {
        final inset = (roofH - 1 - i) * 1.4;
        rect(roofColour, x0 - 1 + inset, box.top + i, w + 2 - inset * 2, 1);
      }
    case FacadeStyle.temple:
      const roofH = 12.0;
      final wallTop = box.top + roofH;
      rect(p.wall, x0, wallTop, w, base - wallTop);
      rect(p.shade, x0, wallTop, 3, base - wallTop);
      rect(p.shade, x0 + w - 3, wallTop, 3, base - wallTop);
      for (var i = 0; i < roofH; i++) {
        final inset = (roofH - 1 - i) * (w / 2 / roofH);
        rect(roofColour, x0 - 1 + inset, box.top + i, w + 2 - inset * 2, 1);
      }
      // A cross-gable's finial and a bell-opening under the ridge.
      rect(p.timber, x0 + w / 2 - 0.5, box.top - 5, 1, 6);
      rect(p.timber, x0 + w / 2 - 2, box.top - 3, 5, 1);
    case FacadeStyle.fort:
      final wallTop = box.top + 4;
      rect(p.wall, x0, wallTop, w, base - wallTop);
      for (var y = wallTop + 4; y < base; y += 5) {
        rect(p.shade, x0, y, w, 1);
      }
      // Crenellations along the top.
      for (var x = x0; x < x0 + w - 2; x += 6) {
        rect(p.wall, x, box.top, 4, 4);
        rect(p.shade, x, box.top + 3, 4, 1);
      }
      rect(p.shade, x0, wallTop, 3, base - wallTop);
      rect(p.shade, x0 + w - 3, wallTop, 3, base - wallTop);
  }

  _door(canvas, u, style, box, p);
  _windows(canvas, u, style, box, p, lit: false);
  _signs(canvas, u, style, box, p);
  // The step.
  rect(p.shade, box.doorX - 7, base - 1, 14, 1);
  rect(const Color(0xFF6B655C), box.doorX - 8, base, 16, 1);
}

(double, double, double) _doorSize(FacadeStyle style) => switch (style) {
      FacadeStyle.warehouse => (16.0, 15.0, 0.0),
      FacadeStyle.temple => (9.0, 15.0, 0.0),
      FacadeStyle.fort => (9.0, 13.0, 0.0),
      _ => (8.0, 13.0, 0.0),
    };

void _door(Canvas canvas, double u, FacadeStyle style, FacadeBox box,
    FacadePalette p) {
  final paint = Paint();
  final (dw, dh, _) = _doorSize(style);
  final x = box.doorX - dw / 2, y = box.base - dh;
  paint.color = p.timber;
  sidePixels(canvas, u, paint, x - 1, y - 1, dw + 2, dh + 1);
  paint.color = p.door;
  sidePixels(canvas, u, paint, x, y, dw, dh);
  if (style == FacadeStyle.temple) {
    // An arched head.
    paint.color = p.wall;
    sidePixels(canvas, u, paint, x, y, 1, 1);
    sidePixels(canvas, u, paint, x + dw - 1, y, 1, 1);
  }
  if (style == FacadeStyle.warehouse) {
    paint.color = p.timber;
    sidePixels(canvas, u, paint, box.doorX - 0.5, y, 1, dh);
  }
  if (style == FacadeStyle.fort) {
    paint.color = const Color(0xFF8C8C92);
    for (var i = 0; i < 3; i++) {
      sidePixels(canvas, u, paint, x + 2 + i * 2, y + 4, 1, 1);
    }
  }
  // A handle.
  paint.color = const Color(0xFFD6B25E);
  sidePixels(canvas, u, paint, box.doorX + dw / 2 - 2, box.base - dh / 2, 1, 1);
}

/// The windows' rectangles, shared by the painter and the lights.
List<Rect> facadeWindows(FacadeStyle style, FacadeBox box) {
  final x0 = box.left, w = box.width, base = box.base;
  switch (style) {
    case FacadeStyle.house:
      final y = base - 25;
      return [
        Rect.fromLTWH(x0 + w * 0.2, y, 6, 6),
        Rect.fromLTWH(x0 + w * 0.8 - 6, y, 6, 6),
        Rect.fromLTWH(x0 + w * 0.2, base - 11, 6, 5),
        Rect.fromLTWH(x0 + w * 0.8 - 6, base - 11, 6, 5),
      ];
    case FacadeStyle.tavern:
      return [
        Rect.fromLTWH(x0 + w * 0.12, base - 11, 8, 6),
        Rect.fromLTWH(x0 + w * 0.88 - 8, base - 11, 8, 6),
        Rect.fromLTWH(x0 + w * 0.2, base - 25, 6, 6),
        Rect.fromLTWH(x0 + w * 0.5 - 3, base - 25, 6, 6),
        Rect.fromLTWH(x0 + w * 0.8 - 6, base - 25, 6, 6),
      ];
    case FacadeStyle.shop:
      return [
        Rect.fromLTWH(x0 + w * 0.1, base - 12, 14, 8),
        Rect.fromLTWH(x0 + w * 0.9 - 14, base - 12, 14, 8),
        Rect.fromLTWH(x0 + w * 0.3, base - 26, 6, 6),
        Rect.fromLTWH(x0 + w * 0.7 - 6, base - 26, 6, 6),
      ];
    case FacadeStyle.warehouse:
      return [
        Rect.fromLTWH(x0 + w * 0.12, base - 22, 4, 3),
        Rect.fromLTWH(x0 + w * 0.88 - 4, base - 22, 4, 3),
      ];
    case FacadeStyle.temple:
      return [
        Rect.fromLTWH(x0 + w * 0.5 - 3, base - 30, 6, 6),
        Rect.fromLTWH(x0 + w * 0.18, base - 20, 3, 8),
        Rect.fromLTWH(x0 + w * 0.82 - 3, base - 20, 3, 8),
      ];
    case FacadeStyle.fort:
      return [
        Rect.fromLTWH(x0 + w * 0.2, base - 24, 2, 6),
        Rect.fromLTWH(x0 + w * 0.5 - 1, base - 28, 2, 6),
        Rect.fromLTWH(x0 + w * 0.8 - 2, base - 24, 2, 6),
      ];
  }
}

void _windows(
    Canvas canvas, double u, FacadeStyle style, FacadeBox box, FacadePalette p,
    {required bool lit}) {
  final paint = Paint();
  for (final r in facadeWindows(style, box)) {
    paint.color = p.timber;
    sidePixels(
        canvas, u, paint, r.left - 1, r.top - 1, r.width + 2, r.height + 2);
    paint.color = lit ? const Color(0xFFFFD27A) : p.glass;
    sidePixels(canvas, u, paint, r.left, r.top, r.width, r.height);
    if (!lit && r.width >= 5) {
      paint.color = Colors.white.withValues(alpha: 0.22);
      sidePixels(canvas, u, paint, r.left, r.top, 2, 1);
    }
  }
}

/// What says what it is: an inn's hanging sign, a shop's awning, a
/// warehouse's hoist, a temple's rose window.
void _signs(Canvas canvas, double u, FacadeStyle style, FacadeBox box,
    FacadePalette p) {
  final paint = Paint();
  void rect(Color c, double x, double y, double w, double h) {
    paint.color = c;
    sidePixels(canvas, u, paint, x, y, w, h);
  }

  switch (style) {
    case FacadeStyle.tavern:
      // A bracket and a hanging board.
      final bx = box.left + box.width - 1;
      rect(p.timber, bx, box.base - 21, 6, 1);
      rect(p.timber, bx + 5, box.base - 20, 1, 2);
      rect(const Color(0xFFB8893A), bx + 2, box.base - 18, 7, 5);
      rect(p.timber, bx + 2, box.base - 18, 7, 1);
      rect(p.door, bx + 4, box.base - 16, 3, 2);
    case FacadeStyle.shop:
      // An awning in two colours over the shopfront.
      final y = box.base - 17;
      for (var i = 0; i < box.width ~/ 4; i++) {
        rect(i.isEven ? const Color(0xFF9E3A32) : const Color(0xFFE9DCC1),
            box.left + i * 4, y, 4, 4);
      }
      rect(const Color(0x33000000), box.left, y + 4, box.width, 1);
    case FacadeStyle.warehouse:
      // A hoist beam out of the loft, and crates by the door.
      final hx = box.left + box.width * 0.78;
      rect(p.timber, hx, box.top + 1, 1, 8);
      rect(p.timber, hx, box.top + 1, 8, 1);
      rect(p.timber, hx + 7, box.top + 2, 1, 5);
      rect(const Color(0xFF7B5B3A), box.left + 3, box.base - 6, 7, 6);
      rect(p.timber, box.left + 3, box.base - 6, 7, 1);
      rect(const Color(0xFF6B4D30), box.left + 6, box.base - 10, 6, 4);
      rect(const Color(0xFF5E4630), box.left + box.width - 11, box.base - 7, 6,
          7);
    case FacadeStyle.temple:
      // The rose window above the door.
      rect(p.glass, box.doorX - 3, box.base - 25, 6, 6);
      rect(p.timber, box.doorX - 4, box.base - 26, 8, 1);
      rect(p.timber, box.doorX - 4, box.base - 19, 8, 1);
      rect(p.timber, box.doorX - 0.5, box.base - 25, 1, 6);
    case FacadeStyle.house:
      // A flower box under the upper windows.
      rect(p.timber, box.left + box.width * 0.2 - 1, box.base - 18, 8, 2);
      rect(const Color(0xFF5E8A4B), box.left + box.width * 0.2, box.base - 19,
          6, 1);
    case FacadeStyle.fort:
      break;
  }
}

/// The windows lit warm, and the lantern by the door: painted over the
/// hour's wash so the light is not dimmed with the night. [t] makes the
/// lantern flicker.
void paintFacadeLights(
    Canvas canvas, double u, FacadeStyle style, FacadeBox box, double t,
    {required double strength}) {
  if (strength <= 0) return;
  final p = FacadePalette.of(style);
  _windows(canvas, u, style, box, p, lit: true);
  final paint = Paint();
  // A lantern by the door.
  final lx = box.doorX + _doorSize(style).$1 / 2 + 3, ly = box.base - 12;
  final flick = 0.8 + 0.2 * math.sin(t * 7.3);
  canvas.drawCircle(Offset((lx + 0.5) * u, (ly + 1.5) * u), 7 * u,
      Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.18 * flick));
  paint.color = const Color(0xFF3A2A1C);
  sidePixels(canvas, u, paint, lx, ly - 1, 2, 1);
  paint.color = const Color(0xFFFFD27A);
  sidePixels(canvas, u, paint, lx, ly, 2, 2);
}

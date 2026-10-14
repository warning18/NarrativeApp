part of 'side_ship.dart';

// What is fitted aboard her, in side view (v1.302): the guns she carries
// (each family its own: cannon muzzles at the ports, a ballista on the
// rail, fire-pots, harpoon guns, the trophy beak), the plating on her side
// (iron plates, bracing, hung shields, the trophy scales) and the gear on
// her deck (stores, orders, helm, gunnery, hold, command, the trophy
// hull). All of it read off the [ShipDress] (see buildShipDress), and drawn
// on the hull profile the hull painter computed ([top] is each column's
// rail row).

/// The painted sails' sigils on the canvas, one a sail aboard, on the
/// biggest sails first (as from above). In the colour of the people whose
/// medium the sail is painted in.
void _paintSigils(Canvas canvas, double u, List<_SailBox> sails,
    List<ShipSigil> sigils, double t) {
  final bySize = [...sails]..sort((a, b) =>
      (b.rect.width * b.rect.height).compareTo(a.rect.width * a.rect.height));
  for (var i = 0; i < math.min(sigils.length, bySize.length); i++) {
    final box = bySize[i];
    final r = box.rect;
    // The fore-and-aft and lateen sails are triangles: the sigil sits low
    // and toward the mast.
    final (fx, fy) = switch (box.kind) {
      SailKind.square => (0.5, 0.48),
      SailKind.gaff => (0.62, 0.62),
      SailKind.lateen => (0.55, 0.66),
    };
    final size = (math.min(r.width, r.height) * 0.3).clamp(2.5, 6.5);
    _sigil(canvas, u, r.left + r.width * fx, r.top + r.height * fy, size,
        sigils[i].power, sigils[i].color, t);
  }
}

void _sigil(Canvas canvas, double u, double cx, double cy, double r,
    SailPower power, Color ink, double t) {
  final paint = Paint()..color = ink;
  void dot(double dx, double dy) =>
      sidePixels(canvas, u, paint, cx + dx, cy + dy, 1, 1);
  switch (power) {
    case SailPower.flight:
      // Two wings, spread, over a dot.
      for (var k = 0.0; k <= r * 1.3; k++) {
        dot(-k, -k * 0.7 + 1);
        dot(k, -k * 0.7 + 1);
        if (k > 1) {
          dot(-k, -k * 0.7 + 2);
          dot(k, -k * 0.7 + 2);
        }
      }
      dot(0, 1);
      dot(0, 2);
    case SailPower.foresight:
      // An eye: the lids, and the pupil.
      for (var k = -r; k <= r; k++) {
        final h = (r * 0.55 * math.sqrt(math.max(0, 1 - math.pow(k / r, 2))))
            .roundToDouble();
        dot(k, -h);
        dot(k, h);
      }
      sidePixels(canvas, u, paint, cx - 1, cy - 1, 2, 2);
    case SailPower.hearth:
      // A flame, a pale core in it.
      for (var k = -r.toInt(); k <= r.toInt(); k++) {
        final f = (k + r) / (2 * r);
        final w = (math.sin(math.pi * math.pow(f, 0.7)) * r * 0.55).round();
        sidePixels(canvas, u, paint, cx - w, cy + k, 2 * w + 1, 1);
      }
      sidePixels(canvas, u, Paint()..color = const Color(0xFFFFE08A), cx,
          cy + r * 0.3, 1, 2);
    case SailPower.windknot:
      // A knot: two crossed loops.
      for (var a = 0; a < 24; a++) {
        final ang = a * math.pi / 12;
        dot(math.cos(ang) * r, math.sin(ang) * r * 0.5);
        dot(math.cos(ang) * r * 0.5, math.sin(ang) * r);
      }
    case SailPower.voidmark:
      // A ring and a small spiral turning in it.
      for (var a = 0; a < 28; a++) {
        final ang = a * math.pi / 14;
        dot(math.cos(ang) * r, math.sin(ang) * r);
      }
      for (var k = 1; k <= 8; k++) {
        final ang = k * 0.8 + t * 0.6;
        dot(math.cos(ang) * r * 0.6 * k / 8, math.sin(ang) * r * 0.6 * k / 8);
      }
  }
}

const Color _iron = Color(0xFF6A727C);
const Color _ironDark = Color(0xFF3F464E);
const Color _brass = Color(0xFFC9A24A);

void _paintGear(Canvas canvas, double u, double x, double base, double len,
    ShipForm form, _Palette pal, ShipDress dress, double t, List<double> top,
    [List<double>? deck]) {
  final on = deck ?? top;
  double rail(double f) => on[(f * len).floor().clamp(0, on.length - 1)];
  _plating(canvas, u, x, base, len, pal, dress.plating, top);
  _guns(canvas, u, x, base, len, dress.mounts, rail, t);
  _deckGear(canvas, u, x, base, len, pal, dress.gear, rail, t);
}

/// The plating on her side.
void _plating(Canvas canvas, double u, double x, double base, double len,
    _Palette pal, ShipPlating? plating, List<double> top) {
  if (plating == null) return;
  final tier = plating.tier.clamp(1, 3);
  switch (plating.family) {
    case 'plating':
      // Iron plates riveted along the side, more of her covered at each tier.
      final from = (len * 0.10).floor();
      final to =
          (len * (0.38 + 0.2 * tier)).floor().clamp(from + 4, len.floor() - 2);
      final plate = Paint()..color = _iron;
      final edge = Paint()..color = _ironDark;
      final rivet = Paint()..color = const Color(0xFFB9C0C8);
      for (var i = from; i < to; i++) {
        final y = top[i] + 2;
        final h = math.max(2.0, base - y - 1);
        sidePixels(canvas, u, plate, x + i, y, 1, h);
        if ((i - from) % 5 == 0) sidePixels(canvas, u, edge, x + i, y, 1, h);
        if ((i - from) % 5 == 2) {
          sidePixels(canvas, u, rivet, x + i, y + 1, 1, 1);
          sidePixels(canvas, u, rivet, x + i, y + h - 2, 1, 1);
        }
      }
    case 'bracing':
      // Timbers crossed over the planking.
      final beam = Paint()..color = _shade(pal.hull, 1.45);
      final n = 1 + tier;
      for (var k = 0; k < n; k++) {
        final c0 = (len * (0.22 + 0.5 * k / n)).floor();
        final y0 = top[c0] + 1;
        _line(canvas, u, beam, x + c0, y0, x + c0 + 6, base - 1);
        _line(canvas, u, beam, x + c0 + 6, y0, x + c0, base - 1);
      }
    case 'screens':
      // Round shields hung along the rail.
      final n = 3 + tier;
      for (var k = 0; k < n; k++) {
        final col = (len * (0.18 + 0.6 * k / (n - 1))).floor();
        final y = top[col] + 1;
        final boss =
            k.isEven ? const Color(0xFFB8862B) : const Color(0xFF7A3A2A);
        sidePixels(canvas, u, Paint()..color = _ironDark, x + col - 1, y, 4, 4);
        sidePixels(canvas, u, Paint()..color = boss, x + col, y + 1, 2, 2);
      }
    case 'trophy_plating':
      // Pale scales of the beast she took it from, spined along the rail.
      final scale = Paint()..color = const Color(0xFFD8D0BC);
      final shade = Paint()..color = const Color(0xFFA89E86);
      for (var i = (len * 0.12).floor(); i < len * 0.82; i += 2) {
        final y = top[i] + 2;
        sidePixels(canvas, u, scale, x + i, y, 2, 3);
        sidePixels(canvas, u, shade, x + i, y + 3, 2, 1);
        if (i % 6 == 0) sidePixels(canvas, u, scale, x + i, top[i] - 1, 1, 2);
      }
  }
}

/// The guns she carries, in the order they stand in the gun room.
void _guns(Canvas canvas, double u, double x, double base, double len,
    List<ShipMount> mounts, double Function(double) rail, double t) {
  if (mounts.isEmpty) return;
  final n = mounts.length;
  for (var i = 0; i < n; i++) {
    final m = mounts[i];
    final f = n == 1 ? 0.52 : 0.30 + 0.46 * i / (n - 1);
    final col = x + (f * len).floorToDouble();
    final top = rail(f);
    final tier = m.tier.clamp(1, 3);
    final bright =
        m.rarity == 'rare' || m.rarity == 'epic' || m.rarity == 'legendary';
    switch (m.family) {
      case 'ballista':
        // A bow on a post at the rail, a bolt laid in it.
        final wood = Paint()..color = const Color(0xFF8A6038);
        sidePixels(canvas, u, wood, col, top - 3, 1, 3);
        sidePixels(canvas, u, wood, col - 1, top - 5, 3, 1);
        sidePixels(canvas, u, Paint()..color = _ironDark, col - 1, top - 4,
            6 + tier.toDouble(), 1);
        sidePixels(canvas, u, Paint()..color = bright ? _brass : _iron,
            col + 5 + tier, top - 5, 1, 3);
      case 'chain':
      case 'grape':
      case 'carronade':
      case 'culverin':
        // A muzzle out of a port, longer for the better guns.
        final stub = m.family == 'carronade' || m.family == 'grape';
        final length = (stub ? 3 : 5) + tier - 1.0;
        final y = top + 3;
        sidePixels(canvas, u, Paint()..color = const Color(0xFF14110F), col - 1,
            y - 1, 4, 3);
        sidePixels(canvas, u, Paint()..color = _ironDark, col + 1, y, length,
            stub ? 2 : 1.0);
        sidePixels(canvas, u, Paint()..color = bright ? _brass : _iron, col + 1,
            y, 1, stub ? 2 : 1.0);
        if (m.family == 'carronade') {
          final glow = 0.5 + 0.5 * math.sin(t * 5 + i);
          sidePixels(
              canvas,
              u,
              Paint()..color = const Color(0xFFF2992E).withValues(alpha: glow),
              col + length,
              y,
              1,
              2);
        }
        if (m.family == 'chain') {
          sidePixels(
              canvas, u, Paint()..color = _iron, col + length + 1, y - 1, 1, 1);
          sidePixels(
              canvas, u, Paint()..color = _iron, col + length + 3, y + 1, 1, 1);
        }
      case 'fire_pots':
        // Clay pots on the rail, a flicker on each.
        for (var k = 0; k < 2 + tier; k++) {
          final px = col - 3 + k * 3;
          sidePixels(canvas, u, Paint()..color = const Color(0xFF8A4A2A), px,
              top - 2, 2, 2);
          final fl = (1 + (math.sin(t * 8 + k + i) > 0 ? 1 : 0)).toDouble();
          sidePixels(canvas, u, Paint()..color = const Color(0xFFF2992E), px,
              top - 2 - fl, 1, fl);
        }
      case 'harpoon':
      case 'hunters_harpoon':
        // A harpoon gun at the bow rail: a long shaft aimed ahead and up.
        final hf = 0.78 + 0.03 * i;
        final hx = x + (hf * len).floorToDouble();
        final ht = rail(hf);
        _line(canvas, u, Paint()..color = const Color(0xFF8A6038), hx - 2,
            ht - 1, hx + 6 + tier, ht - 4);
        sidePixels(canvas, u, Paint()..color = bright ? _brass : _iron,
            hx + 6 + tier, ht - 5, 2, 2);
        sidePixels(canvas, u, Paint()..color = const Color(0xFFB8A07A), hx - 3,
            ht - 2, 2, 2);
      case 'trophy_beak':
        // A horn of bone at the stem, below the bowsprit.
        final bx = x + len - 1;
        final by = rail(1.0) + 2;
        _fillPoly(canvas, u, Paint()..color = const Color(0xFFE6DFCB),
            [(bx, by), (bx + 7, by + 1), (bx, by + 3)]);
    }
  }
}

/// The gear on deck, by the utility she carries.
void _deckGear(Canvas canvas, double u, double x, double base, double len,
    _Palette pal, String? gear, double Function(double) rail, double t) {
  if (gear == null) return;
  final crate = Paint()..color = const Color(0xFF9A7448);
  final crateDark = Paint()..color = const Color(0xFF6B4E2E);
  switch (gear) {
    case 'stores':
      // Crates and a barrel lashed on deck.
      final top = rail(0.2);
      sidePixels(canvas, u, crate, x + len * 0.18, top - 3, 4, 3);
      sidePixels(canvas, u, crateDark, x + len * 0.18, top - 3, 4, 1);
      sidePixels(canvas, u, crate, x + len * 0.18 + 4, top - 4, 3, 4);
      sidePixels(canvas, u, crateDark, x + len * 0.18 + 4, top - 4, 3, 1);
    case 'orders':
      // Signal flags strung from the stern to the mast.
      final y0 = rail(0.08) - 14;
      final xs = x + len * 0.08, xe = x + len * 0.44;
      final line = Paint()..color = pal.mast;
      _line(canvas, u, line, xs, rail(0.08) - 3, xe, y0 - 10);
      const colours = [
        Color(0xFFC0392B),
        Color(0xFFE8B94E),
        Color(0xFF2E6FB0),
        Color(0xFFECE7DC)
      ];
      for (var k = 0; k < 5; k++) {
        final f = (k + 1) / 6;
        final fx = xs + (xe - xs) * f;
        final fy = rail(0.08) - 3 + (y0 - 10 - rail(0.08) + 3) * f;
        final wag = math.sin(t * 4 + k).round();
        sidePixels(canvas, u, Paint()..color = colours[k % 4], fx, fy + 1, 2,
            2 + (wag > 0 ? 1 : 0));
      }
    case 'helm':
      // A stern lantern on a post, glowing.
      final top = rail(0.03);
      sidePixels(canvas, u, Paint()..color = pal.mast, x + 2, top - 6, 1, 6);
      final glow = 0.7 + 0.3 * math.sin(t * 3);
      sidePixels(
          canvas,
          u,
          Paint()
            ..color = const Color(0xFFF2B85A).withValues(alpha: 0.35 * glow),
          x,
          top - 9,
          5,
          5);
      sidePixels(canvas, u, Paint()..color = const Color(0xFFFFE08A), x + 1,
          top - 8, 2, 3);
    case 'gunnery':
      // A pyramid of shot by the rail and a rammer propped up.
      final top = rail(0.34);
      final shot = Paint()..color = _ironDark;
      for (var r = 0; r < 3; r++) {
        for (var k = 0; k < 3 - r; k++) {
          sidePixels(canvas, u, shot, x + len * 0.34 + r + k * 2,
              top - 2 - r * 2, 2, 2);
        }
      }
      _line(canvas, u, Paint()..color = const Color(0xFFB08A58),
          x + len * 0.34 + 7, top, x + len * 0.34 + 9, top - 7);
    case 'hold':
      // Barrels roped along the deck.
      final top = rail(0.3);
      final barrel = Paint()..color = const Color(0xFF7A4E2A);
      for (var k = 0; k < 3; k++) {
        sidePixels(canvas, u, barrel, x + len * 0.24 + k * 4, top - 3, 3, 3);
        sidePixels(canvas, u, crateDark, x + len * 0.24 + k * 4, top - 2, 3, 1);
      }
      sidePixels(canvas, u, Paint()..color = const Color(0xFFB08A58),
          x + len * 0.24, top - 4, 10, 1);
    case 'command':
      // A banner on a tall pole at the stern: a gold star on the ensign's
      // colour.
      final top = rail(0.05);
      sidePixels(canvas, u, Paint()..color = _brass, x + 3, top - 16, 1, 16);
      final w = 5 + math.sin(t * 3).round();
      sidePixels(canvas, u, Paint()..color = pal.ensign, x + 4, top - 16,
          w.toDouble(), 6);
      sidePixels(canvas, u, Paint()..color = _brass, x + 6, top - 14, 2, 2);
    case 'trophy_hull':
      // Tusks crossed on the stern rail.
      final top = rail(0.04);
      final bone = Paint()..color = const Color(0xFFE6DFCB);
      _line(canvas, u, bone, x + 1, top - 1, x + 6, top - 7);
      _line(canvas, u, bone, x + 6, top - 1, x + 1, top - 7);
  }
}

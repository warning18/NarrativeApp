// What the Eel wears (v1.226): her paint, cloth, figurehead and flag (the
// looks, see ship_looks.dart) and what is fitted aboard her (the parts, see
// ship_parts.json), gathered into one [ShipDress] that her painter reads
// (see TopShipPainter): each gun in the gun room as the kind of gun it is,
// the bulwark in the plating it wears, the painted sail's sigil on the
// canvas, a utility's gear on deck.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../combat/ship_combat.dart';
import '../data/sail_powers.dart';
import '../data/ship_looks.dart';

/// One weapon fitted in the gun room, as the painter needs it.
class ShipMount {
  const ShipMount({
    required this.family,
    required this.tier,
    required this.rarity,
    this.ammo = '',
    this.fire = false,
  });

  /// The part's `family` (ballista, chain, grape, carronade...).
  final String family;

  /// Its version in the family, from 1.
  final int tier;
  final String rarity;

  /// The shot it fires (round, chain, grape, heated).
  final String ammo;

  /// It sets what it hits on fire.
  final bool fire;

  @override
  bool operator ==(Object other) =>
      other is ShipMount &&
      other.family == family &&
      other.tier == tier &&
      other.rarity == rarity &&
      other.ammo == ammo &&
      other.fire == fire;

  @override
  int get hashCode => Object.hash(family, tier, rarity, ammo, fire);
}

/// The sigil of the painted sail: its power, in the colour of the people
/// whose way it is painted.
class ShipSigil {
  const ShipSigil(this.power, this.color);
  final SailPower power;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is ShipSigil && other.power == power && other.color == color;

  @override
  int get hashCode => Object.hash(power, color);
}

/// The plating on the bulwark: what the shield part is, and how good a
/// version of it.
class ShipPlating {
  const ShipPlating(this.family, this.tier, this.partId);

  /// plating, bracing, screens, trophy_plating.
  final String family;
  final int tier;
  final String partId;

  @override
  bool operator ==(Object other) =>
      other is ShipPlating &&
      other.family == family &&
      other.tier == tier &&
      other.partId == partId;

  @override
  int get hashCode => Object.hash(family, tier, partId);
}

/// Everything the painter dresses the Eel in. A null colour leaves the
/// ship's own.
class ShipDress {
  const ShipDress({
    this.hull,
    this.deck,
    this.trim,
    this.cloth,
    this.clothPattern = 'plain',
    this.clothPatternColor,
    this.clothEdge,
    this.figurehead = 'none',
    this.figureheadColor,
    this.figureheadEye,
    this.ensign = 'pennant',
    this.ensignColor,
    this.ensignDevice,
    this.mounts = const [],
    this.plating,
    this.gear,
    this.sigils = const [],
  });

  final Color? hull;
  final Color? deck;
  final Color? trim;
  final Color? cloth;
  final String clothPattern;
  final Color? clothPatternColor;
  final Color? clothEdge;
  final String figurehead;
  final Color? figureheadColor;
  final Color? figureheadEye;
  final String ensign;
  final Color? ensignColor;
  final Color? ensignDevice;

  /// The guns fitted, in the order they stand in the gun room.
  final List<ShipMount> mounts;
  final ShipPlating? plating;

  /// The utility's family (stores, orders, helm, gunnery, hold, command,
  /// trophy_hull), if one is fitted, which draws its gear on deck.
  final String? gear;

  /// The painted sails' sigils, one a sail aboard.
  final List<ShipSigil> sigils;

  ShipSigil? get sigil => sigils.isEmpty ? null : sigils.first;

  static const bare = ShipDress();

  @override
  bool operator ==(Object other) =>
      other is ShipDress &&
      other.hull == hull &&
      other.deck == deck &&
      other.trim == trim &&
      other.cloth == cloth &&
      other.clothPattern == clothPattern &&
      other.clothPatternColor == clothPatternColor &&
      other.clothEdge == clothEdge &&
      other.figurehead == figurehead &&
      other.figureheadColor == figureheadColor &&
      other.figureheadEye == figureheadEye &&
      other.ensign == ensign &&
      other.ensignColor == ensignColor &&
      other.ensignDevice == ensignDevice &&
      _sameList(other.mounts, mounts) &&
      other.plating == plating &&
      other.gear == gear &&
      _sameList(other.sigils, sigils);

  @override
  int get hashCode => Object.hashAll([
        hull,
        deck,
        trim,
        cloth,
        clothPattern,
        clothPatternColor,
        clothEdge,
        figurehead,
        figureheadColor,
        figureheadEye,
        ensign,
        ensignColor,
        ensignDevice,
        ...mounts,
        plating,
        gear,
        ...sigils,
      ]);
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The colour each people paints its sigils in.
const Map<String, Color> sailMediumColors = {
  'human': Color(0xFFB8862B),
  'elf': Color(0xFF3F7A5A),
  'dwarf': Color(0xFF6C7A8C),
  'orc': Color(0xFF2B2830),
  'voidkin': Color(0xFF7E57C2),
};

/// The dress of the Eel with [installed] parts fitted and [looks] worn:
/// the weapons, shield and utility within her slots (see
/// [partsWithinSlots]), the painted sail's sigil, and the looks [chosen]
/// per category (or their defaults) among those [owned] (or the free
/// defaults).
ShipDress buildShipDress({
  required Map<String, dynamic> ship,
  required Map<String, dynamic> parts,
  required List<String> installed,
  required Map<String, dynamic> lookRecords,
  Map<String, String> chosen = const {},
  Iterable<String> owned = const [],
}) {
  final looks = shipLooksFrom(lookRecords);
  ShipLook? worn(String category) => wornLook(looks, category, chosen, owned);
  final hull = worn('hull');
  final sail = worn('sail');
  final figurehead = worn('figurehead');
  final ensign = worn('ensign');

  final fitted =
      partsWithinSlots(ship: ship, parts: parts, installedPartIds: installed);
  final mounts = <ShipMount>[];
  ShipPlating? plating;
  String? gear;
  for (final id in fitted) {
    final part = parts[id] as Map<String, dynamic>?;
    if (part == null) continue;
    final family = part['family']?.toString() ?? id;
    final tier = (part['tier'] as num?)?.toInt() ?? 1;
    switch (part['slotType']?.toString()) {
      case 'Weapon':
        mounts.add(ShipMount(
          family: family,
          tier: tier,
          rarity: part['rarity']?.toString() ?? 'common',
          ammo: part['ammo']?.toString() ?? '',
          fire: part['setsFire'] == true,
        ));
      case 'Shield':
        plating ??= ShipPlating(family, tier, id);
      case 'Utility':
        gear ??= family;
    }
  }
  return ShipDress(
    hull: hull?.color,
    deck: hull?.color2,
    trim: hull?.color3,
    cloth: sail?.color,
    clothPattern: sail?.pattern ?? 'plain',
    clothPatternColor: sail?.color2,
    clothEdge: sail?.color3,
    figurehead: figurehead?.pattern ?? 'none',
    figureheadColor: figurehead?.color,
    figureheadEye: figurehead?.color2,
    ensign: ensign?.pattern ?? 'pennant',
    ensignColor: ensign?.color,
    ensignDevice: ensign?.color2,
    mounts: mounts,
    plating: plating,
    gear: gear,
    sigils: [
      for (final painted in installedSails(parts, fitted))
        ShipSigil(painted.power,
            sailMediumColors[painted.medium] ?? const Color(0xFF6B4A2E)),
    ],
  );
}

/// The parts aboard if [partId] were fitted too: added when its slot has
/// room, else in place of the first part of its slot already aboard (the
/// painted sail replaces the sigil on the canvas). [installed] itself when
/// the part is aboard or unknown. For trying a part on the ship before it
/// is bought.
List<String> fittedWith({
  required Map<String, dynamic> ship,
  required Map<String, dynamic> parts,
  required List<String> installed,
  required String partId,
}) {
  final part = parts[partId] as Map<String, dynamic>?;
  if (part == null || installed.contains(partId)) return installed;
  final slot = part['slotType']?.toString() ?? '';
  // A painted sail of a power already aboard goes over it.
  final power = sailPowerOf(part);
  if (power != null) {
    for (final id in installed) {
      final other = parts[id] as Map<String, dynamic>?;
      if (other != null && sailPowerOf(other) == power) {
        return [
          for (final kept in installed)
            if (kept != id) kept,
          partId,
        ];
      }
    }
  }
  final sameSlot = [
    for (final id in installed)
      if ((parts[id] as Map<String, dynamic>?)?['slotType']?.toString() == slot)
        id,
  ];
  if (sameSlot.length < slotCapacity(ship, slot)) {
    return [...installed, partId];
  }
  if (sameSlot.isEmpty) return installed;
  // The weakest gun of the slot goes first; any other slot gives up the
  // part it has.
  var out = sameSlot.first;
  if (slot == 'Weapon') {
    int damageOf(String id) =>
        ((parts[id] as Map<String, dynamic>)['damageAmount'] as num?)
            ?.toInt() ??
        0;
    for (final id in sameSlot) {
      if (damageOf(id) < damageOf(out)) out = id;
    }
  }
  return [
    for (final id in installed)
      if (id != out) id,
    partId,
  ];
}

// ------------------------------------------------------------------ painting

const Color _timber = Color(0xFF3A2818);
const Color _ironTone = Color(0xFF4A484F);

/// A gun's metal by its rarity.
Color _metalFor(String rarity) => switch (rarity) {
      'uncommon' => const Color(0xFF6C7480),
      'rare' => const Color(0xFF8B6B3E),
      'epic' => const Color(0xFFB88A2C),
      'legendary' => const Color(0xFFD8A93A),
      _ => _ironTone,
    };

/// How much bigger a version of a gun is than the first.
double _grow(int tier) => 1 + 0.1 * (tier - 1).clamp(0, 4);

Paint _fill(Color c) => Paint()..color = c;
Paint _line(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// Draws the guns of [dress] along the broadside of [room] (the gun room
/// on the deck), each from the centre line out toward [towards] (-1 up, 1
/// down), as the kind of gun it is. With none fitted the ports are empty.
void paintMounts(Canvas canvas, Rect room, double cy, double beam,
    double towards, ShipDress dress, double t) {
  final n = math.min(3, dress.mounts.length);
  for (var i = 0; i < n; i++) {
    final x = room.left + room.width * (i + 0.5) / n;
    final mount = dress.mounts[i];
    canvas.save();
    canvas.translate(x, cy);
    // Drawn pointing up (toward -y); a ship firing down is flipped.
    if (towards > 0) canvas.scale(1, -1);
    final scale = beam / 72 * _grow(mount.tier) * (n == 1 ? 1.5 : 1.35);
    canvas.scale(scale);
    _mount(canvas, mount, t);
    canvas.restore();
  }
}

/// One gun, 30 units long from the centre line (0, 0) up to its muzzle
/// at (0, -30), 20 wide.
void _mount(Canvas canvas, ShipMount m, double t) {
  final metal = _metalFor(m.rarity);
  final dark = Color.lerp(metal, const Color(0xFF000000), 0.45)!;
  final light = Color.lerp(metal, const Color(0xFFFFFFFF), 0.35)!;
  // A carriage under every gun.
  void carriage(double w, double h) {
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -h / 2 - 2), width: w, height: h),
        const Radius.circular(2));
    canvas.drawRRect(r, _fill(_timber));
    canvas.drawRRect(r, _line(const Color(0xFF6E5A46), 1));
  }

  void barrel(double w, double from, double to) {
    final r = Rect.fromLTRB(-w / 2, -to, w / 2, -from);
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(w * 0.3)), _fill(metal));
    canvas.drawRect(Rect.fromLTRB(-w / 2, -to, w / 2, -to + 2.2), _fill(dark));
    canvas.drawLine(Offset(-w * 0.2, -to + 3), Offset(-w * 0.2, -from - 1),
        _line(light.withValues(alpha: 0.8), 1));
  }

  switch (m.family) {
    case 'ballista':
      // Stock, two bowed arms across the front, a bolt laid in the groove.
      canvas.drawLine(const Offset(0, 0), const Offset(0, -26),
          _line(const Color(0xFF6E5A46), 3.2));
      final arm = _line(const Color(0xFF8A6A44), 2.6);
      final reach = 9.0 + m.tier * 1.4;
      canvas.drawPath(
          Path()
            ..moveTo(-reach, -13)
            ..quadraticBezierTo(0, -19, reach, -13),
          arm);
      canvas.drawLine(Offset(-reach, -13), const Offset(0, -6),
          _line(const Color(0xFFD7C9A6), 0.8));
      canvas.drawLine(Offset(reach, -13), const Offset(0, -6),
          _line(const Color(0xFFD7C9A6), 0.8));
      canvas.drawLine(
          const Offset(0, -6), const Offset(0, -30), _line(metal, 1.8));
      canvas.drawPath(
          Path()
            ..moveTo(0, -33)
            ..lineTo(-2.2, -28)
            ..lineTo(2.2, -28)
            ..close(),
          _fill(light));
      if (m.tier >= 3) {
        // The siege engine: a winch drum behind the stock.
        canvas.drawCircle(const Offset(0, -3), 4, _fill(dark));
        canvas.drawCircle(const Offset(0, -3), 4, _line(metal, 1));
      }
    case 'chain':
    case 'grape':
      carriage(11, 10);
      barrel(5.4, 4, 24);
      if (m.family == 'chain') {
        // Two balls on a bar, hung at the muzzle.
        canvas.drawLine(
            const Offset(-4.5, -27), const Offset(4.5, -27), _line(light, 1));
        canvas.drawCircle(const Offset(-4.5, -27), 2.2, _fill(dark));
        canvas.drawCircle(const Offset(4.5, -27), 2.2, _fill(dark));
      } else {
        // A bag of shot beside the carriage.
        for (final (dx, dy) in [(8.0, -6.0), (10.5, -9.5), (6.5, -10.0)]) {
          canvas.drawCircle(
              Offset(dx, dy), 2.3, _fill(const Color(0xFF8A7A56)));
        }
      }
      canvas.drawCircle(const Offset(0, -3), 2.4, _fill(light));
    case 'carronade':
      carriage(14, 11);
      barrel(10.5, 3, 20);
      canvas.drawRect(const Rect.fromLTRB(-6.5, -14, 6.5, -12.4), _fill(dark));
      if (m.ammo == 'heated' || m.fire) {
        final glow = 0.55 + 0.25 * math.sin(t * 6);
        canvas.drawCircle(const Offset(0, -22), 6.5,
            _fill(const Color(0xFFFF7A2E).withValues(alpha: glow * 0.5)));
        canvas.drawCircle(const Offset(0, -21), 2.6,
            _fill(const Color(0xFFFFC857).withValues(alpha: glow)));
      }
    case 'fire_pots':
      carriage(20, 12);
      for (final (dx, dy) in [(-6.0, -7.0), (6.0, -7.0), (0.0, -12.0)]) {
        canvas.drawCircle(Offset(dx, dy), 4.4, _fill(const Color(0xFF9A5A32)));
        canvas.drawCircle(
            Offset(dx, dy), 4.4, _line(const Color(0xFF5E331C), 1));
        final flick = 1.4 * math.sin(t * 9 + dx);
        canvas.drawCircle(Offset(dx, dy - 1), 2.3,
            _fill(const Color(0xFFFF8A2E).withValues(alpha: 0.9)));
        canvas.drawCircle(Offset(dx, dy - 2 - flick.abs()), 1.2,
            _fill(const Color(0xFFFFE08A)));
      }
    case 'harpoon':
    case 'hunters_harpoon':
      // A rack with spears pointing out and a coil of rope at the foot.
      carriage(16, 8);
      final spears = m.tier >= 3 ? 1 : 3;
      for (var k = 0; k < spears; k++) {
        final dx = spears == 1 ? 0.0 : (k - 1) * 5.0;
        canvas.drawLine(Offset(dx, -3), Offset(dx, -29),
            _line(const Color(0xFF8A6A44), spears == 1 ? 3.2 : 1.7));
        canvas.drawPath(
            Path()
              ..moveTo(dx, -34)
              ..lineTo(dx - 3, -28)
              ..lineTo(dx + 3, -28)
              ..close(),
            _fill(light));
        canvas.drawLine(
            Offset(dx - 3, -30), Offset(dx - 5, -27.5), _line(metal, 1));
        canvas.drawLine(
            Offset(dx + 3, -30), Offset(dx + 5, -27.5), _line(metal, 1));
      }
      canvas.drawCircle(
          const Offset(7, -4), 3.2, _line(const Color(0xFFC9B58A), 1.4));
      if (m.tier >= 3) {
        // The whaling gun's stock and hawser.
        barrel(6.5, 2, 16);
      }
    case 'culverin':
      carriage(10, 9);
      barrel(4.6, 4, 30);
      canvas.drawRect(const Rect.fromLTRB(-3.6, -20, 3.6, -19), _fill(dark));
      canvas.drawRect(const Rect.fromLTRB(-3.6, -12, 3.6, -11), _fill(dark));
    case 'trophy_beak':
      // The Tide-Mother's beak: a bone hook, tip out.
      canvas.drawPath(
          Path()
            ..moveTo(-7, -2)
            ..quadraticBezierTo(-6, -22, 2, -30)
            ..quadraticBezierTo(2, -17, 7, -2)
            ..close(),
          _fill(const Color(0xFFD9CDB0)));
      canvas.drawPath(
          Path()
            ..moveTo(-7, -2)
            ..quadraticBezierTo(-6, -22, 2, -30),
          _line(const Color(0xFF6E5A46), 1.2));
    default:
      carriage(11, 10);
      barrel(5, 4, 22);
  }
}

/// Draws the plating on the bulwark room [room], along both rails of the
/// hull of width [beam] centred on [cy].
void paintPlating(Canvas canvas, Rect room, double cy, double beam,
    ShipPlating? plating, int refit, Color wood) {
  if (plating == null) {
    final plate = _line(refit >= 2 ? const Color(0xFF8C98A6) : wood, 2.5);
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(Offset(room.left + 4, cy + s * beam * 0.34),
          Offset(room.right - 2, cy + s * beam * 0.18), plate);
    }
    return;
  }
  void rails(void Function(Offset a, Offset b) each) {
    for (final s in [-1.0, 1.0]) {
      each(Offset(room.left + 4, cy + s * beam * 0.34),
          Offset(room.right - 2, cy + s * beam * 0.18));
    }
  }

  switch (plating.family) {
    case 'plating':
      final tone = switch (plating.tier) {
        1 => const Color(0xFF8C98A6),
        2 => const Color(0xFFB6C2CF),
        3 => const Color(0xFF34313A),
        4 => const Color(0xFF9AA6B2),
        5 => const Color(0xFF59555E),
        6 => const Color(0xFFC7CFD8),
        _ => const Color(0xFF3F8E86),
      };
      final width = 2.6 + plating.tier * 0.55;
      rails((a, b) {
        canvas.drawLine(a, b, _line(tone, width));
        canvas.drawLine(
            a, b, _line(Color.lerp(tone, const Color(0xFFFFFFFF), 0.4)!, 0.8));
        // Rivets, or scales for the deep's own plate.
        final steps = plating.tier >= 7 ? 9 : 6;
        for (var k = 0; k < steps; k++) {
          final p = Offset.lerp(a, b, (k + 0.5) / steps)!;
          if (plating.tier >= 7) {
            canvas.drawCircle(p, width * 0.42,
                _fill(const Color(0xFF9EE0D2).withValues(alpha: 0.8)));
          } else {
            canvas.drawCircle(p, 0.9, _fill(const Color(0xFF1C1B1F)));
          }
        }
        if (plating.tier == 6) {
          // Dwarf-gold studs.
          for (var k = 0; k < 3; k++) {
            canvas.drawCircle(Offset.lerp(a, b, 0.2 + k * 0.3)!, 1.5,
                _fill(const Color(0xFFE0A93A)));
          }
        }
      });
    case 'bracing':
      // Timber ribs crossing the rail.
      final tone = Color.lerp(
          wood, const Color(0xFFC9A36B), 0.25 + 0.15 * (plating.tier - 1))!;
      rails((a, b) {
        canvas.drawLine(a, b, _line(tone, 2.4));
        final ribs = 4 + plating.tier * 2;
        for (var k = 0; k < ribs; k++) {
          final p = Offset.lerp(a, b, (k + 0.5) / ribs)!;
          final out = (p.dy - cy).sign;
          canvas.drawLine(
              p, p + Offset(0, -out * beam * 0.1), _line(tone, 1.4));
        }
      });
    case 'screens':
      switch (plating.partId) {
        case 'shuttered_gunports':
          rails((a, b) {
            canvas.drawLine(a, b, _line(const Color(0xFF6E5A46), 2.2));
            for (var k = 0; k < 3; k++) {
              final p = Offset.lerp(a, b, 0.2 + k * 0.3)!;
              final out = (p.dy - cy).sign;
              canvas.drawRect(
                  Rect.fromCenter(
                      center: p + Offset(0, out * 2.2), width: 6, height: 4.2),
                  _fill(const Color(0xFF4A3A28)));
              canvas.drawRect(
                  Rect.fromCenter(
                      center: p + Offset(0, out * 2.2), width: 6, height: 4.2),
                  _line(const Color(0xFFB59A74), 0.8));
            }
          });
        case 'netted_rails':
          rails((a, b) {
            canvas.drawLine(a, b, _line(const Color(0xFFB59A74), 1.4));
            final out = ((a.dy + b.dy) / 2 - cy).sign;
            final off = Offset(0, out * beam * 0.13);
            canvas.drawLine(
                a + off, b + off, _line(const Color(0xFFB59A74), 1));
            for (var k = 0; k <= 8; k++) {
              final p = Offset.lerp(a, b, k / 8)!;
              canvas.drawLine(p, p + off, _line(const Color(0xFFB59A74), 0.8));
            }
          });
        default:
          // Runes cut in the rail, glowing.
          rails((a, b) {
            canvas.drawLine(a, b, _line(const Color(0xFF6E5A46), 2.2));
            for (var k = 0; k < 5; k++) {
              final p = Offset.lerp(a, b, (k + 0.5) / 5)!;
              canvas.drawCircle(p, 2.6,
                  _fill(const Color(0xFF9A6BFF).withValues(alpha: 0.28)));
              canvas.drawCircle(p, 1.1, _fill(const Color(0xFFCFB8FF)));
            }
          });
      }
    case 'trophy_plating':
      rails((a, b) {
        canvas.drawLine(a, b, _line(const Color(0xFFD9CDB0), 4.2));
        canvas.drawLine(a, b, _line(const Color(0xFF8E8468), 1));
        for (var k = 0; k < 5; k++) {
          canvas.drawCircle(Offset.lerp(a, b, (k + 0.5) / 5)!, 1.2,
              _fill(const Color(0xFF6E6246)));
        }
      });
    default:
      rails(
          (a, b) => canvas.drawLine(a, b, _line(const Color(0xFF8C98A6), 2.5)));
  }
}

/// A utility's gear, drawn on [helm], [hold] and [guns] (the rooms on
/// the deck), [beam] wide.
void paintGear(Canvas canvas, String? gear, Rect helm, Rect hold, Rect guns,
    double cy, double beam, double towards, double t) {
  if (gear == null) return;
  final u = beam / 72;
  switch (gear) {
    case 'stores':
      // Barrels lashed beside the hatch.
      for (final (dx, dy) in [(-0.26, -0.3), (0.26, -0.3), (-0.26, 0.3)]) {
        final c =
            Offset(hold.center.dx + dx * hold.width, cy + dy * beam * 0.95);
        canvas.drawCircle(c, 5.2 * u * 1.4, _fill(const Color(0xFF7A5230)));
        canvas.drawCircle(c, 5.2 * u * 1.4, _line(const Color(0xFF2E1E10), 1));
        canvas.drawCircle(
            c, 3.0 * u * 1.4, _line(const Color(0xFF2E1E10), 0.8));
      }
    case 'orders':
      // Lanterns on posts at the helm, and a chart table.
      for (final dy in [-0.3, 0.3]) {
        final c = Offset(helm.left + helm.width * 0.18, cy + dy * beam);
        final glow = 0.5 + 0.2 * math.sin(t * 5 + dy * 10);
        canvas.drawCircle(c, 7 * u * 1.4,
            _fill(const Color(0xFFFFC857).withValues(alpha: glow * 0.4)));
        canvas.drawCircle(c, 2.6 * u * 1.4, _fill(const Color(0xFFFFE08A)));
      }
      final table = Rect.fromCenter(
          center: Offset(helm.center.dx + helm.width * 0.18, cy + beam * 0.22),
          width: 13 * u * 1.4,
          height: 9 * u * 1.4);
      canvas.drawRect(table, _fill(const Color(0xFFE3D5B0)));
      canvas.drawRect(table, _line(const Color(0xFF6E5A46), 1));
      canvas.drawLine(
          table.topLeft + const Offset(2, 3),
          table.bottomRight - const Offset(3, 3),
          _line(const Color(0xFFA2472E), 0.8));
    case 'helm':
      // Coils of rope and a spare yard along the helm.
      for (var k = 0; k < 2; k++) {
        final c = Offset(helm.left + helm.width * (0.22 + k * 0.2),
            cy + beam * (k == 0 ? -0.26 : 0.27));
        canvas.drawCircle(c, 5 * u * 1.4, _line(const Color(0xFFC9B58A), 1.8));
        canvas.drawCircle(c, 2 * u * 1.4, _line(const Color(0xFFC9B58A), 1.2));
      }
    case 'gunnery':
      // A rack of shot by the guns.
      for (final (dx, dy) in [(0.0, 0.0), (5.0, 0.0), (2.5, -4.4)]) {
        final c = Offset(guns.right - guns.width * 0.14 + dx * u * 1.4,
            cy - towards * beam * 0.3 + dy * u * 1.4);
        canvas.drawCircle(c, 2.6 * u * 1.4, _fill(const Color(0xFF2C2A30)));
        canvas.drawCircle(
            c, 2.6 * u * 1.4, _line(const Color(0xFF7A7886), 0.7));
      }
    case 'hold':
      // A pump handle on the hatch, buckets beside it.
      final c = Offset(hold.center.dx, cy - beam * 0.3);
      canvas.drawLine(c, c + Offset(10 * u * 1.4, -4 * u * 1.4),
          _line(const Color(0xFFB59A74), 2));
      canvas.drawCircle(c, 2.4 * u * 1.4, _fill(const Color(0xFF6C7480)));
      canvas.drawCircle(
          Offset(hold.center.dx - hold.width * 0.3, cy + beam * 0.3),
          3.4 * u * 1.4,
          _fill(const Color(0xFF6C7480)));
    case 'command':
      // A cabin roof at the stern, with a trim stripe.
      final roof = Rect.fromLTRB(helm.left - helm.width * 0.02,
          cy - beam * 0.24, helm.left + helm.width * 0.46, cy + beam * 0.24);
      canvas.drawRRect(
          RRect.fromRectAndRadius(roof, Radius.circular(beam * 0.05)),
          _fill(const Color(0xFF5A3A26)));
      canvas.drawRRect(
          RRect.fromRectAndRadius(roof, Radius.circular(beam * 0.05)),
          _line(const Color(0xFFD9B15B), 1.4));
      canvas.drawLine(Offset(roof.left + 3, cy), Offset(roof.right - 3, cy),
          _line(const Color(0xFFD9B15B), 1));
    case 'trophy_hull':
      // Sharkskin patches over the stern planks.
      for (final (dx, dy) in [(0.15, -0.3), (0.3, 0.28), (0.1, 0.18)]) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(helm.left + helm.width * dx, cy + dy * beam),
                width: 12 * u * 1.4,
                height: 7 * u * 1.4),
            _fill(const Color(0xFF6C7C78).withValues(alpha: 0.85)));
      }
  }
}

/// Works the cloth of the sail inside [sail] (clipped to it), by
/// [pattern], with [mark] and [edge] colours.
void paintCloth(
    Canvas canvas, Path sail, Rect bounds, String pattern, Color mark) {
  canvas.save();
  canvas.clipPath(sail);
  switch (pattern) {
    case 'stripes':
      for (var k = 1; k <= 3; k++) {
        final x = bounds.left + bounds.width * k / 4.2;
        canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom),
            _line(mark.withValues(alpha: 0.9), bounds.width * 0.09));
      }
    case 'patches':
      for (final (fx, fy, w, h) in [
        (0.3, 0.2, 0.28, 0.14),
        (0.6, 0.55, 0.3, 0.16),
        (0.35, 0.78, 0.22, 0.12),
      ]) {
        final r = Rect.fromCenter(
            center: Offset(bounds.left + bounds.width * fx,
                bounds.top + bounds.height * fy),
            width: bounds.width * w,
            height: bounds.height * h);
        canvas.drawRect(r, _fill(mark.withValues(alpha: 0.85)));
        canvas.drawRect(
            r, _line(const Color(0xFF000000).withValues(alpha: 0.3), 0.7));
      }
    case 'diamonds':
      final d = bounds.width * 0.14;
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 2; col++) {
          final c = Offset(
              bounds.left + bounds.width * (0.28 + col * 0.4),
              bounds.top +
                  bounds.height * (0.2 + row * 0.2) +
                  (col.isOdd ? bounds.height * 0.1 : 0));
          canvas.drawPath(
              Path()
                ..moveTo(c.dx, c.dy - d)
                ..lineTo(c.dx + d * 0.7, c.dy)
                ..lineTo(c.dx, c.dy + d)
                ..lineTo(c.dx - d * 0.7, c.dy)
                ..close(),
              _fill(mark.withValues(alpha: 0.85)));
        }
      }
  }
  canvas.restore();
}

/// The painted sail's sigil, [size] across, centred at [c].
void paintSigil(
    Canvas canvas, Offset c, double size, ShipSigil sigil, double t) {
  final ink = sigil.color;
  final r = size / 2;
  switch (sigil.power) {
    case SailPower.flight:
      // Two wings, spread.
      for (final s in [-1.0, 1.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy)
              ..quadraticBezierTo(c.dx - r * 0.2, c.dy + s * r * 0.9,
                  c.dx - r * 0.9, c.dy + s * r * 0.8),
            _line(ink, size * 0.14));
      }
      canvas.drawCircle(c, size * 0.1, _fill(ink));
    case SailPower.foresight:
      // An eye.
      final eye = Path()
        ..moveTo(c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy - r * 0.9, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + r * 0.9, c.dx - r, c.dy);
      canvas.drawPath(eye, _line(ink, size * 0.12));
      canvas.drawCircle(c, size * 0.17, _fill(ink));
    case SailPower.hearth:
      // A flame.
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..quadraticBezierTo(c.dx + r * 0.9, c.dy, c.dx, c.dy + r * 0.9)
            ..quadraticBezierTo(c.dx - r * 0.9, c.dy, c.dx, c.dy - r),
          _fill(ink));
      canvas.drawCircle(Offset(c.dx, c.dy + r * 0.25), size * 0.12,
          _fill(const Color(0xFFFFE08A).withValues(alpha: 0.85)));
    case SailPower.windknot:
      // A knot: two crossed loops.
      canvas.drawOval(
          Rect.fromCenter(center: c, width: size, height: size * 0.5),
          _line(ink, size * 0.12));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(math.pi / 2);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.5),
          _line(ink, size * 0.12));
      canvas.restore();
    case SailPower.voidmark:
      // A ring and a spiral.
      canvas.drawCircle(c, r, _line(ink, size * 0.11));
      final spiral = Path()..moveTo(c.dx, c.dy);
      for (var k = 1; k <= 14; k++) {
        final a = k * 0.55 + t * 0.4;
        final rr = r * 0.75 * k / 14;
        spiral.lineTo(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      }
      canvas.drawPath(spiral, _line(ink, size * 0.09));
  }
}

/// The figurehead of [dress] at the stem, its tip at [tip] (the hull's
/// bow), looking right, [size] across.
void paintFigurehead(
    Canvas canvas, Offset tip, double size, ShipDress dress, double t) {
  final body = dress.figureheadColor ?? const Color(0xFF6B4A2E);
  final eye = dress.figureheadEye ?? const Color(0xFFF2E3A0);
  final dark = Color.lerp(body, const Color(0xFF000000), 0.5)!;
  final s = size;
  canvas.save();
  canvas.translate(tip.dx, tip.dy);
  switch (dress.figurehead) {
    case 'gull':
      for (final k in [-1.0, 1.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(
                  -s * 0.15, k * s * 0.6, -s * 0.75, k * s * 0.9),
            _line(body, s * 0.2));
      }
      canvas.drawCircle(Offset(s * 0.05, 0), s * 0.2, _fill(body));
      canvas.drawPath(
          Path()
            ..moveTo(s * 0.4, 0)
            ..lineTo(s * 0.18, -s * 0.09)
            ..lineTo(s * 0.18, s * 0.09)
            ..close(),
          _fill(eye));
    case 'eel':
      final p = Path()
        ..moveTo(-s * 0.7, s * 0.3)
        ..cubicTo(-s * 0.4, -s * 0.5, s * 0.1, s * 0.6, s * 0.35, 0);
      canvas.drawPath(p, _line(dark, s * 0.34));
      canvas.drawPath(p, _line(body, s * 0.24));
      canvas.drawCircle(Offset(s * 0.3, -s * 0.05), s * 0.07, _fill(eye));
    case 'siren':
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(s * 0.1, 0), width: s * 0.55, height: s * 0.42),
          _fill(body));
      for (final k in [-0.25, -0.08, 0.08, 0.25]) {
        canvas.drawLine(Offset(-s * 0.1, k * s), Offset(-s * 0.85, k * s * 2.2),
            _line(eye, s * 0.1));
      }
      canvas.drawCircle(Offset(s * 0.22, 0), s * 0.05, _fill(dark));
    case 'wolf':
      canvas.drawPath(
          Path()
            ..moveTo(s * 0.55, 0)
            ..lineTo(-s * 0.1, -s * 0.3)
            ..lineTo(-s * 0.1, s * 0.3)
            ..close(),
          _fill(body));
      for (final k in [-1.0, 1.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(-s * 0.05, k * s * 0.18)
              ..lineTo(-s * 0.3, k * s * 0.5)
              ..lineTo(-s * 0.32, k * s * 0.12)
              ..close(),
            _fill(dark));
      }
      canvas.drawCircle(Offset(s * 0.12, -s * 0.1), s * 0.04, _fill(eye));
      canvas.drawCircle(Offset(s * 0.12, s * 0.1), s * 0.04, _fill(eye));
      canvas.drawCircle(
          Offset(s * 0.55, 0), s * 0.05, _fill(const Color(0xFF1C1B1F)));
    case 'skull':
      canvas.drawCircle(Offset.zero, s * 0.34, _fill(body));
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(s * 0.3, 0), width: s * 0.22, height: s * 0.3),
          _fill(body));
      canvas.drawCircle(Offset(s * 0.05, -s * 0.13), s * 0.09, _fill(eye));
      canvas.drawCircle(Offset(s * 0.05, s * 0.13), s * 0.09, _fill(eye));
      for (var k = -1; k <= 1; k++) {
        canvas.drawLine(Offset(s * 0.22, k * s * 0.08),
            Offset(s * 0.4, k * s * 0.08), _line(eye, s * 0.04));
      }
    case 'lion':
      for (var k = 0; k < 9; k++) {
        final a = k * math.pi * 2 / 9;
        canvas.drawCircle(
            Offset(math.cos(a), math.sin(a)) * s * 0.34, s * 0.14, _fill(eye));
      }
      canvas.drawCircle(Offset.zero, s * 0.3, _fill(body));
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(s * 0.32, 0), width: s * 0.3, height: s * 0.24),
          _fill(body));
      canvas.drawCircle(Offset(s * 0.12, -s * 0.1), s * 0.04, _fill(dark));
      canvas.drawCircle(Offset(s * 0.12, s * 0.1), s * 0.04, _fill(dark));
    case 'dragon':
      canvas.drawPath(
          Path()
            ..moveTo(s * 0.7, 0)
            ..lineTo(s * 0.2, -s * 0.18)
            ..lineTo(-s * 0.2, -s * 0.3)
            ..lineTo(-s * 0.3, 0)
            ..lineTo(-s * 0.2, s * 0.3)
            ..lineTo(s * 0.2, s * 0.18)
            ..close(),
          _fill(body));
      for (final k in [-1.0, 1.0]) {
        canvas.drawLine(Offset(-s * 0.1, k * s * 0.25),
            Offset(-s * 0.8, k * s * 0.55), _line(eye, s * 0.1));
      }
      canvas.drawCircle(
          Offset(s * 0.2, -s * 0.08), s * 0.05, _fill(const Color(0xFFFFE08A)));
      canvas.drawCircle(
          Offset(s * 0.2, s * 0.08), s * 0.05, _fill(const Color(0xFFFFE08A)));
    case 'maw':
      for (final k in [-1.0, 1.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(-s * 0.3, k * s * 0.05)
              ..lineTo(s * 0.7, k * s * 0.4)
              ..lineTo(s * 0.7, k * s * 0.28)
              ..lineTo(-s * 0.3, k * s * 0.0)
              ..close(),
            _fill(body));
        for (var j = 0; j < 4; j++) {
          final x = s * (0.1 + j * 0.15);
          canvas.drawPath(
              Path()
                ..moveTo(x, k * s * (0.1 + j * 0.06))
                ..lineTo(x + s * 0.05, k * s * (0.03 + j * 0.03))
                ..lineTo(x - s * 0.05, k * s * (0.03 + j * 0.03))
                ..close(),
              _fill(const Color(0xFFF2F0E6)));
        }
      }
    case 'horn':
      canvas.drawPath(
          Path()
            ..moveTo(-s * 0.2, -s * 0.12)
            ..quadraticBezierTo(s * 0.5, -s * 0.2, s * 1.1, s * 0.05)
            ..quadraticBezierTo(s * 0.45, s * 0.06, -s * 0.2, s * 0.14)
            ..close(),
          _fill(body));
      canvas.drawPath(
          Path()
            ..moveTo(-s * 0.1, 0)
            ..quadraticBezierTo(s * 0.5, -s * 0.07, s * 1.0, s * 0.04),
          _line(eye, 1));
    case 'eye':
      canvas.drawCircle(Offset.zero, s * 0.42, _fill(const Color(0xFFB08A4E)));
      canvas.drawCircle(Offset.zero, s * 0.34, _fill(const Color(0xFFF2EFE6)));
      canvas.drawCircle(Offset.zero, s * 0.22, _fill(body));
      canvas.drawCircle(Offset.zero, s * 0.1, _fill(eye));
      canvas.drawCircle(Offset(-s * 0.05, -s * 0.07), s * 0.04,
          _fill(const Color(0xFFFFFFFF)));
    default:
      break;
  }
  canvas.restore();
}

/// The flag of [dress] flying from the mast at [mast], streaming aft (to
/// the left), [length] long.
void paintEnsign(Canvas canvas, Offset mast, double length, ShipDress dress,
    Color fallback, double t) {
  final cloth = dress.ensignColor ?? fallback;
  final device = dress.ensignDevice ?? const Color(0xFFF2E3A0);
  final h = length * 0.4;
  double wave(double x) => math.sin(t * 5 - x * 7) * h * 0.14 * x;
  // The cloth as a strip from the mast aft, rippling.
  Path strip(double top, double bottom, {double end = 1, bool fork = false}) {
    final p = Path()..moveTo(mast.dx, mast.dy + top * h);
    for (var k = 1; k <= 8; k++) {
      final x = k / 8 * end;
      p.lineTo(mast.dx - x * length, mast.dy + top * h + wave(x));
    }
    if (fork) {
      p.lineTo(mast.dx - (end - 0.18) * length,
          mast.dy + (top + bottom) / 2 * h + wave(end - 0.18));
    }
    for (var k = 8; k >= 1; k--) {
      final x = k / 8 * end;
      p.lineTo(mast.dx - x * length, mast.dy + bottom * h + wave(x));
    }
    p.lineTo(mast.dx, mast.dy + bottom * h);
    p.close();
    return p;
  }

  switch (dress.ensign) {
    case 'swallowtail':
      canvas.drawPath(strip(-0.5, 0.5, fork: true), _fill(cloth));
      canvas.drawPath(strip(-0.12, 0.12, end: 0.5), _fill(device));
    case 'wave':
      canvas.drawPath(strip(-0.5, 0.5), _fill(cloth));
      final p = Path();
      for (var k = 0; k <= 10; k++) {
        final x = k / 10;
        final y = math.sin(x * math.pi * 3) * h * 0.14;
        final o =
            Offset(mast.dx - x * length * 0.9, mast.dy + y + wave(x * 0.9));
        k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p, _line(device, h * 0.14));
    case 'streamers':
      canvas.drawPath(strip(-0.5, -0.12), _fill(cloth));
      canvas.drawPath(strip(0.12, 0.5, end: 0.85), _fill(device));
    case 'checkered':
      canvas.drawPath(strip(-0.5, 0.5, end: 0.75), _fill(cloth));
      canvas.save();
      canvas.clipPath(strip(-0.5, 0.5, end: 0.75));
      for (var cx = 0; cx < 4; cx++) {
        for (var cy = 0; cy < 2; cy++) {
          if ((cx + cy).isEven) continue;
          final x0 = cx / 4 * 0.75, x1 = (cx + 1) / 4 * 0.75;
          canvas.drawRect(
              Rect.fromLTRB(mast.dx - x1 * length, mast.dy + (cy - 1) * h * 0.5,
                  mast.dx - x0 * length, mast.dy + cy * h * 0.5 - h * 0.0),
              _fill(device));
        }
      }
      canvas.restore();
    case 'skull':
      canvas.drawPath(strip(-0.5, 0.5, end: 0.8), _fill(cloth));
      final c = Offset(mast.dx - length * 0.4, mast.dy + wave(0.4));
      canvas.drawCircle(c, h * 0.2, _fill(device));
      canvas.drawLine(c + Offset(-h * 0.28, h * 0.22),
          c + Offset(h * 0.28, -h * 0.22), _line(device, h * 0.07));
      canvas.drawLine(c + Offset(-h * 0.28, -h * 0.22),
          c + Offset(h * 0.28, h * 0.22), _line(device, h * 0.07));
    case 'crown':
      canvas.drawPath(strip(-0.5, 0.5, end: 0.8), _fill(cloth));
      final cc = Offset(mast.dx - length * 0.4, mast.dy + wave(0.4));
      canvas.drawPath(
          Path()
            ..moveTo(cc.dx - h * 0.3, cc.dy + h * 0.15)
            ..lineTo(cc.dx - h * 0.3, cc.dy - h * 0.1)
            ..lineTo(cc.dx - h * 0.15, cc.dy + h * 0.02)
            ..lineTo(cc.dx, cc.dy - h * 0.18)
            ..lineTo(cc.dx + h * 0.15, cc.dy + h * 0.02)
            ..lineTo(cc.dx + h * 0.3, cc.dy - h * 0.1)
            ..lineTo(cc.dx + h * 0.3, cc.dy + h * 0.15)
            ..close(),
          _fill(device));
    case 'void':
      final glow = 0.35 + 0.15 * math.sin(t * 3);
      canvas.drawPath(
          strip(-0.55, 0.55, end: 1.1),
          _fill(device.withValues(alpha: glow))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawPath(strip(-0.5, 0.5, end: 1.0, fork: true), _fill(cloth));
      canvas.drawPath(strip(-0.1, 0.1, end: 0.8), _fill(device));
    default:
      // The pennant: a triangle tapering aft.
      final p = Path()..moveTo(mast.dx, mast.dy - h * 0.35);
      for (var k = 1; k <= 8; k++) {
        final x = k / 8;
        p.lineTo(mast.dx - x * length, mast.dy - h * 0.35 * (1 - x) + wave(x));
      }
      for (var k = 8; k >= 1; k--) {
        final x = k / 8;
        p.lineTo(mast.dx - x * length, mast.dy + h * 0.35 * (1 - x) + wave(x));
      }
      p.close();
      canvas.drawPath(p, _fill(cloth));
  }
}

// The party's faces (wave 17, UX, item 5, the stand-in): the companions
// walk the land and stand on the Eel's deck as cloaked placeholders, each in
// a colour of its own, until the user's sprite art arrives. Until then each
// has a face of its own, small but different: the skin of their people, the
// hair, a hood, a veil or a helm, a dwarf's beard, an orc's tusks, an elf's
// ears. There is no portrait art for the companions to crop (the repository
// has none), so the looks are set here by race and profession; a companion
// this table does not know gets a look from their id. When `companion_<id>`
// sprites exist this file is what they replace.
import 'package:flutter/material.dart';

import 'side_view.dart';

/// What a figure wears on its head.
enum PartyHeadgear { none, hood, veil, helm }

/// How a companion's face is drawn: skin, hair (null for none), headgear
/// and its colour, and the marks of their people.
class PartyLook {
  const PartyLook({
    required this.skin,
    this.hair,
    this.headgear = PartyHeadgear.none,
    this.gear = const Color(0xFF3A3A44),
    this.beard = false,
    this.tusks = false,
    this.ears = false,
  });

  final Color skin;
  final Color? hair;
  final PartyHeadgear headgear;
  final Color gear;
  final bool beard;
  final bool tusks;
  final bool ears;

  @override
  bool operator ==(Object other) =>
      other is PartyLook &&
      other.skin == skin &&
      other.hair == hair &&
      other.headgear == headgear &&
      other.gear == gear &&
      other.beard == beard &&
      other.tusks == tusks &&
      other.ears == ears;

  @override
  int get hashCode =>
      Object.hash(skin, hair, headgear, gear, beard, tusks, ears);
}

const Map<String, PartyLook> _looks = {
  // Dwarves: ruddy, bearded. Kelda in a plain helm, Brother Tobin in a cowl.
  'kelda': PartyLook(
      skin: Color(0xFFE0A183),
      hair: Color(0xFF8A3B1E),
      headgear: PartyHeadgear.helm,
      gear: Color(0xFF7C8591),
      beard: true),
  'tobin': PartyLook(
      skin: Color(0xFFD9A582),
      hair: Color(0xFF9A9A9A),
      headgear: PartyHeadgear.hood,
      gear: Color(0xFF6B5B45),
      beard: true),
  // Humans: Sable hooded in black, Sister Maren veiled in white.
  'sable': PartyLook(
      skin: Color(0xFFD9B08C),
      hair: Color(0xFF1E1A1A),
      headgear: PartyHeadgear.hood,
      gear: Color(0xFF2B2630)),
  'maren': PartyLook(
      skin: Color(0xFFEBC9A5),
      hair: Color(0xFF6B4A32),
      headgear: PartyHeadgear.veil,
      gear: Color(0xFFEDE6D6)),
  // The elf: fair, long gold hair, pointed ears.
  'liora':
      PartyLook(skin: Color(0xFFF0D2B4), hair: Color(0xFFE3C26B), ears: true),
  // The voidkin: grey-violet, white hair under a dark hood.
  'vess': PartyLook(
      skin: Color(0xFF9A8CC4),
      hair: Color(0xFFEDEBF5),
      headgear: PartyHeadgear.hood,
      gear: Color(0xFF3B2F5E)),
  // The orcs: green, tusked. Grosh bare-headed, Malrik hooded.
  'grosh':
      PartyLook(skin: Color(0xFF7FA06A), hair: Color(0xFF1E1A1A), tusks: true),
  'malrik': PartyLook(
      skin: Color(0xFF6E8F5A),
      headgear: PartyHeadgear.hood,
      gear: Color(0xFF3C4A2E),
      tusks: true),
};

/// The look of the companion [id]: the table's, else one made from the id
/// (the same every time), so a companion added before their art has a face.
PartyLook partyLookFor(String id) {
  final known = _looks[id];
  if (known != null) return known;
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  const skins = [
    Color(0xFFE2B890),
    Color(0xFFC99A74),
    Color(0xFF9C6B4B),
    Color(0xFFEBC9A5),
  ];
  const hairs = [
    Color(0xFF1E1A1A),
    Color(0xFF6B4A32),
    Color(0xFFB5893E),
    Color(0xFF9A9A9A),
  ];
  return PartyLook(
    skin: skins[hash % skins.length],
    hair: hairs[(hash ~/ 7) % hairs.length],
    headgear: hash % 3 == 0 ? PartyHeadgear.hood : PartyHeadgear.none,
  );
}

/// Paints [look]'s face as a 3 by 3 block with its top-left at scene pixel
/// ([x], [y]): the headgear on the row above (a hood and a veil come down
/// the sides), the hair, the marks of the face, facing the bow.
void paintPartyHead(Canvas canvas, double u, double x, double y, PartyLook look,
    {Color? cloak}) {
  final paint = Paint();
  void dot(double dx, double dy, Color c, {double w = 1, double h = 1}) {
    paint.color = c;
    sidePixels(canvas, u, paint, x + dx, y + dy, w, h);
  }

  // The face.
  dot(0, 0, look.skin, w: 3, h: 3);
  // Hair: a fringe, and a lock down each side when the head is bare.
  final hair = look.hair;
  if (look.headgear == PartyHeadgear.none && hair != null) {
    dot(0, -1, hair, w: 3);
    dot(0, 0, hair);
    dot(2, 0, hair);
    if (look.ears) {
      dot(-1, 1, look.skin);
      dot(3, 1, look.skin);
      dot(-1, 0, hair);
      dot(3, 0, hair);
    }
  }
  switch (look.headgear) {
    case PartyHeadgear.none:
      if (hair == null) dot(0, -1, look.skin, w: 3);
    case PartyHeadgear.hood:
      dot(-1, -1, look.gear, w: 5);
      dot(-1, 0, look.gear);
      dot(3, 0, look.gear);
      dot(-1, 1, look.gear);
      dot(3, 1, look.gear);
      if (hair != null) dot(1, 0, hair);
    case PartyHeadgear.veil:
      dot(-1, -1, look.gear, w: 5);
      dot(-1, 0, look.gear, h: 3);
      dot(3, 0, look.gear, h: 3);
    case PartyHeadgear.helm:
      dot(-1, -1, look.gear, w: 5);
      dot(-1, 0, look.gear);
      dot(3, 0, look.gear);
      dot(1, -2, look.gear);
  }
  if (look.beard && look.hair != null) {
    dot(0, 2, look.hair!, w: 3, h: 2);
  }
  if (look.tusks) {
    dot(0, 2, const Color(0xFFF2EAD0));
    dot(2, 2, const Color(0xFFF2EAD0));
  }
  // A dark eye, toward the bow.
  dot(2, 1, const Color(0xFF241812));
}

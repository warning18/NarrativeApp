// The crew on deck (wave 16, the sea as the land): the hero and the
// companions of the party stand on the Eel's deck in the side view, small,
// as they walk the land. They stand on the rail line the hull painter
// worked out, so they ride the hull's sheer and the swell with her; the
// hero is nearest the helm, the companions behind. Each has a cloak of a
// colour that stays theirs (the land walk's), and now and then looks round.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../providers/walking_party_provider.dart';
import 'desert_kit.dart' show walkPlaceholderColour;
import 'party_look.dart';
import 'side_view.dart';

/// One of the crew on deck: [id] (`hero` or a companion's id) and the cloak
/// colour.
class DeckCrew {
  const DeckCrew(this.id, this.cloak);

  final String id;
  final Color cloak;

  bool get isHero => id == heroWalkerId;

  @override
  bool operator ==(Object other) =>
      other is DeckCrew && other.id == id && other.cloak == cloak;

  @override
  int get hashCode => Object.hash(id, cloak);
}

/// The crew of [party] (see walkingPartyProvider), the hero first.
List<DeckCrew> deckCrewOf(List<WalkingPartyMember> party) => [
      for (final m in party)
        DeckCrew(m.id,
            m.isHero ? const Color(0xFFC0392B) : walkPlaceholderColour(m.id)),
    ];

/// How far along the hull, as a fraction of her length from the stern,
/// each of [count] crew stands: the hero first, a little forward of the middle
/// (toward the bow), the others behind, 0.2 of her length apart.
List<double> deckCrewAt(int count) => [
      for (var i = 0; i < count; i++) 0.66 - 0.2 * i,
    ];

/// Where crew [index] of [count] stands across a scene [width] scene
/// pixels wide, for a ship of [length] pixels (see seaShipX).
double deckCrewX(int index, int count, double length, double width) =>
    seaShipX(length, width) + deckCrewAt(count)[index] * length;

/// Where the ship's stern is in a scene [width] scene pixels wide.
double seaShipX(double length, double width) =>
    (width * 0.34 - length / 2 + 18).floorToDouble();

/// How tall a figure is, in scene pixels.
const double deckCrewHeight = 8;

/// Paints [crew] on a hull of [len] pixels whose stern is at [x]; [top] is
/// her rail line, one row per column from the stern (the hull painter's).
void paintDeckCrew(
  Canvas canvas,
  double u, {
  required List<DeckCrew> crew,
  required double x,
  required double len,
  required List<double> top,
  required double t,
  bool rough = false,
}) {
  if (crew.isEmpty || top.isEmpty) return;
  final at = deckCrewAt(crew.length);
  const skin = Color(0xFFE2B890);
  const boots = Color(0xFF2B2420);
  // Back to front: the last of the crew first, the hero in front.
  for (var i = crew.length - 1; i >= 0; i--) {
    final who = crew[i];
    final col = (at[i] * len).round().clamp(0, top.length - 1);
    final feet = top[col].roundToDouble() + 1;
    final fx = (x + at[i] * len).floorToDouble();
    // A look round now and then; braced low in a squall.
    final look = math.sin(t * 0.9 + i * 2.1) > 0.8;
    final crouch = rough ? 1.0 : 0.0;
    final paint = Paint();
    // Boots and legs.
    paint.color = boots;
    sidePixels(canvas, u, paint, fx, feet - 2, 3, 2);
    // The cloak, the body.
    paint.color = who.cloak;
    sidePixels(canvas, u, paint, fx - 1, feet - 5 + crouch, 5, 3);
    paint.color = Color.lerp(who.cloak, Colors.black, 0.3)!;
    sidePixels(canvas, u, paint, fx - 1, feet - 3 + crouch, 5, 1);
    if (who.isHero) {
      // The head, turned toward the bow, or back for a moment.
      paint.color = skin;
      sidePixels(
          canvas, u, paint, fx + (look ? 0 : 1), feet - 7 + crouch, 3, 2);
      // The hero's pale hat.
      paint.color = const Color(0xFFEFE6CF);
      sidePixels(canvas, u, paint, fx, feet - 8 + crouch, 4, 1);
      // A dark eye.
      paint.color = boots;
      sidePixels(
          canvas, u, paint, fx + (look ? 0 : 2), feet - 7 + crouch, 1, 1);
    } else {
      // A companion's own face (party_look.dart), over the cloak.
      paintPartyHead(
          canvas, u, fx + 1, feet - 8 + crouch, partyLookFor(who.id));
    }
  }
}

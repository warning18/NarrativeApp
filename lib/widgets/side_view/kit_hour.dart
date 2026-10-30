// The part of the day over a side-view scene (wave 17, UX, item 1): the
// town plan darkens at dusk and lights its windows at night; the roads and
// the sea now do too. A thin warm wash at dawn, a violet one at dusk, a deep
// blue one at night, with stars in the sky at night (a few at dusk), laid
// behind the hills so no star shines through a mountain; and the hero carries
// a lantern on the Eel's deck after dark (see deck_crew.dart). By day
// nothing changes at all.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/journey_rules.dart' show DayPhase;
import 'side_view.dart';

/// The wash over the whole scene for [phase], or null by day.
SideLayer? hourWash(DayPhase phase) {
  final colour = hourWashColour(phase);
  if (colour == null) return null;
  return SideLayer(0, (canvas, size, scroll, t, u) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colour);
  });
}

/// The wash's colour, by phase: the town plan's own, so a place reads the
/// same hour on the plan and on the road to it.
Color? hourWashColour(DayPhase phase) => switch (phase) {
      DayPhase.day => null,
      DayPhase.dawn => const Color(0xFFF2A36B).withValues(alpha: 0.10),
      DayPhase.dusk => const Color(0xFF7A4A7C).withValues(alpha: 0.20),
      DayPhase.night => const Color(0xFF0B1230).withValues(alpha: 0.42),
    };

/// How many stars the sky shows at [phase].
int hourStarCount(DayPhase phase) => switch (phase) {
      DayPhase.night => 34,
      DayPhase.dusk => 8,
      _ => 0,
    };

/// The stars: one layer, painted just after the sky so the far hills and
/// everything in front of it cover them.
SideLayer _hourStars(DayPhase phase) {
  final count = hourStarCount(phase);
  return SideLayer(0, (canvas, size, scroll, t, u) {
    if (count == 0) return;
    final w = size.width / u;
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final x = _hash(i, 1) * w;
      final y = 2 + _hash(i, 2) * 30;
      final twinkle = 0.55 + 0.45 * math.sin(t * 1.3 + i * 1.7);
      paint.color = Colors.white.withValues(alpha: 0.35 + 0.5 * twinkle);
      sidePixels(canvas, u, paint, x, y, 1, 1);
    }
  });
}

/// [layers] with the stars of [phase] right behind everything but the sky
/// (the first layer): the same list by day.
List<SideLayer> withHourStars(List<SideLayer> layers, DayPhase phase) {
  if (hourStarCount(phase) == 0 || layers.isEmpty) return layers;
  return [layers.first, _hourStars(phase), ...layers.skip(1)];
}

double _hash(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

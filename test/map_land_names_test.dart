// The lands' names read before the land is reached (wave 3 of the Maps
// review): a name not yet reached is drawn at 85 % of the look's land-name
// ink, and that still has a contrast of 4.5 at the least against the fog,
// the land and the sea of the look.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('a land not yet reached is named at a contrast of 4.5 or more', () {
    expect(ChartPalette.unreachedLandName, lessThan(1),
        reason: 'a reached land still reads stronger');
    for (final look in MapLook.values) {
      final p = ChartPalette.of(look);
      for (final (name, ground) in [
        ('fog', p.fog),
        ('land', p.land),
        ('sea', p.sea),
      ]) {
        final drawn = Color.alphaBlend(
            p.landName.withValues(alpha: ChartPalette.unreachedLandName),
            ground);
        expect(_contrast(drawn, ground), greaterThanOrEqualTo(4.5),
            reason: '${look.name} on its $name');
        // Reached, at full strength, it is stronger still.
        expect(_contrast(p.landName, ground),
            greaterThan(_contrast(drawn, ground)),
            reason: '${look.name} on its $name, reached');
      }
    }
  });
}

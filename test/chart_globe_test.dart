// The chart as a sphere (v1.200): the projection round-trips, hides the
// far side, presses a crossing shape against the limb, and turns.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chart_globe.dart';
import 'package:narrative_data_app/data/world_map.dart';

void main() {
  const centre = Offset(128, 88);
  final look = GlobeView.at(const Offset(128, 88), 1, centre);

  test('the chart middle sits at the globe centre, and round-trips', () {
    expect(look.clamp(const Offset(128, 88)), centre);
    for (final p in const [Offset(128, 88), Offset(60, 40), Offset(200, 150)]) {
      final on = look.clamp(p);
      final back = look.chartAt(on)!;
      expect((back - p).distance, lessThan(0.05), reason: '$p');
    }
    expect(look.chartAt(const Offset(128 + 200, 88)), isNull);
  });

  test('the far side is hidden and pressed against the limb', () {
    final far = GlobeView.at(const Offset(0, 88), 1, centre);
    expect(far.visible(const Offset(0, 88)), isTrue);
    expect(far.visible(const Offset(256, 88)), isFalse);
    final pressed = far.clamp(const Offset(256, 88));
    expect((pressed - centre).distance, closeTo(GlobeView.baseRadius, 0.01));
  });

  test('a polygon shows while a corner shows; runs split at the limb', () {
    final far = GlobeView.at(const Offset(0, 88), 1, centre);
    expect(
        far.polygon(const [Offset(250, 80), Offset(254, 90), Offset(246, 96)]),
        isNull);
    expect(far.polygon(const [Offset(10, 80), Offset(254, 90), Offset(20, 96)]),
        hasLength(3));
    final runs = far.runs([
      for (var x = 0.0; x <= 256; x += 8) Offset(x, 88),
    ]);
    expect(runs, hasLength(1));
    expect(runs.single.length, greaterThan(5));
  });

  test('turning and zooming keep the view sound', () {
    final turned = look.turned(0.5, 3);
    expect(turned.lat0, 1.45);
    expect(turned.lon0, closeTo(0.5, 1e-9));
    expect(look.copyWith(radius: 160).zoom, 2);
    expect(look.key, isNot(turned.key));
    expect(GlobeView.graticule(), isNotEmpty);
    expect(worldMapWidth, 256);
  });
}

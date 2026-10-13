// The travel-history map (v1.268): its names are laid out one clear of the
// next even where the places crowd, it frames the road taken, and a tap
// says which place and whether it was been to or only heard of.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/travel_map_view.dart';

void main() {
  test('names in a crowd sit clear of each other, of the marks, and inside',
      () {
    // Twelve places in a patch where their names, side by side, would
    // overlap (the north continent of the story world).
    final marks = <Offset>[
      for (var i = 0; i < 12; i++)
        Offset(120 + (i % 4) * 34.0, 80 + (i ~/ 4) * 22.0),
    ];
    final requests = [
      for (var i = 0; i < marks.length; i++)
        TravelLabelRequest('p$i', marks[i], const Size(90, 14)),
    ];
    const bounds = Rect.fromLTWH(0, 0, 360, 250);
    final placed = placeTravelLabels(requests, bounds: bounds, markRadius: 5);
    expect(placed, isNotEmpty);
    final rects = placed.values.toList();
    for (var i = 0; i < rects.length; i++) {
      expect(bounds.contains(rects[i].topLeft), isTrue);
      expect(bounds.contains(rects[i].bottomRight), isTrue);
      for (var j = i + 1; j < rects.length; j++) {
        expect(rects[i].overlaps(rects[j]), isFalse,
            reason: '${rects[i]} and ${rects[j]}');
      }
      for (final m in marks) {
        expect(
            rects[i].overlaps(Rect.fromCircle(center: m, radius: 5)), isFalse);
      }
    }
    // The first asked for is the first served.
    expect(placed.containsKey('p0'), isTrue);
  });

  test('a name that cannot fit anywhere is left out', () {
    final placed = placeTravelLabels(
      [
        const TravelLabelRequest('a', Offset(50, 20), Size(200, 14)),
      ],
      bounds: const Rect.fromLTWH(0, 0, 100, 40),
    );
    expect(placed, isEmpty);
  });

  testWidgets('a tap names the place and whether it was been to or heard of',
      (tester) async {
    tester.view.physicalSize = const Size(360, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final geo = chartOf(MapShape.archipelago);
    final ids = [for (final l in worldMapLandmarks) l.id];
    final visited = ids.take(4).toList();
    final known = {ids[8]};
    final taps = <(String, TravelPlaceState)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TravelMapView(
          geography: geo,
          palette: ChartPalette.of(MapLook.night),
          language: AppLanguage.en,
          visited: visited,
          known: known,
          here: visited.last,
          nameOf: (id) => landmarkById(id)?.nameEn ?? id,
          onTapPlace: (id, state) => taps.add((id, state)),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    // Where a place is on screen: the chart's corner and its scale.
    final canvas = find.byKey(const Key('travel_map_canvas'));
    final corner = tester.getTopLeft(canvas);
    final scale = (tester.getBottomRight(canvas).dx - corner.dx) / 256;
    Offset at(String id) => corner + geo.places[id]! * scale;

    await tester.tapAt(at(visited[1]));
    await tester.tapAt(at(ids[8]));
    expect(taps, [
      (visited[1], TravelPlaceState.visited),
      (ids[8], TravelPlaceState.known),
    ]);
    // Nothing near: nothing tapped.
    taps.clear();
    await tester.tapAt(corner + const Offset(2, 2));
    expect(taps, isEmpty);

    // The button that brings the party's place to the middle, and zoom.
    await tester.tap(find.byKey(const Key('travel_map_here')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('travel_map_zoom_in')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('travel_map_zoom_out')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

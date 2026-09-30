// The Journey map on the real map (v1.181): in a place the ways ring the
// party and the ways out sit at the edge in their true direction.
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_map.dart';
import 'package:narrative_data_app/widgets/journey_place.dart';

void main() {
  const area = Size(360, 420);
  const here = Offset(180, 210);

  test('a way out sits at the edge in its true direction', () {
    // East, then south-west.
    final p = journeyPlaceLayout(
        area: area, here: here, bearings: [0, math.pi * 3 / 4, null]);
    expect(p[0].dy, closeTo(here.dy, 0.01));
    expect(p[0].dx, closeTo(area.width - 34, 0.01));
    expect(p[1].dx, lessThan(here.dx));
    expect(p[1].dy, greaterThan(here.dy));
    // Its direction is the one asked for.
    final d = p[1] - here;
    expect(math.atan2(d.dy, d.dx), closeTo(math.pi * 3 / 4, 1e-6));
    // Names go under the marks: the foot keeps more room than the top.
    expect(p[1].dy, lessThanOrEqualTo(area.height - 86 + 0.01));
  });

  test('the ways in a place ring the party, all on the map, none stacked', () {
    for (final count in [1, 3, 6, 7, 13, 17]) {
      final p = journeyPlaceLayout(
          area: area, here: here, bearings: List<double?>.filled(count, null));
      for (final q in p) {
        expect(q.dx, inInclusiveRange(0, area.width), reason: '$count');
        expect(q.dy, inInclusiveRange(0, area.height), reason: '$count');
        expect((q - here).distance, greaterThan(40), reason: '$count');
      }
      for (var i = 0; i < p.length; i++) {
        for (var j = i + 1; j < p.length; j++) {
          expect((p[i] - p[j]).distance, greaterThan(30),
              reason: '$count ways: $i and $j');
        }
      }
      // Not all above the party: every way round, not just up.
      if (count >= 3) {
        expect(p.where((q) => q.dy > here.dy), isNotEmpty);
      }
    }
  });

  test('ways in the place keep clear of the ways out', () {
    final p = journeyPlaceLayout(
        area: area, here: here, bearings: [-math.pi / 2, null, null, null]);
    for (final q in p.skip(1)) {
      final a = math.atan2((q - here).dy, (q - here).dx);
      expect((a - -math.pi / 2).abs(), greaterThan(0.2));
    }
  });

  test('ways out to the same place fan out along the edge', () {
    // Three choices leading to the square, one bearing (scene 270), and
    // two a hair apart across the turn of the circle.
    for (final bearings in [
      <double?>[0.4, 0.4, 0.4, null],
      <double?>[-0.05, 2 * math.pi - 0.02, null],
    ]) {
      final p = journeyPlaceLayout(area: area, here: here, bearings: bearings);
      final exits = [
        for (var i = 0; i < bearings.length; i++)
          if (bearings[i] != null) p[i]
      ];
      for (var i = 0; i < exits.length; i++) {
        for (var j = i + 1; j < exits.length; j++) {
          expect((exits[i] - exits[j]).distance, greaterThan(30),
              reason: '$bearings: $i and $j');
        }
      }
    }
    // Ways out far apart keep their true bearings.
    expect(fanOutBearings([0, math.pi, null]), [0, math.pi, null]);
  });

  test('a way\'s name never lies on another way\'s mark', () {
    // Scene 270 on a 360-wide phone: three ways out to the square fanned
    // into one corner, the party below them.
    const map = Size(328, 220);
    const party = Offset(164, 110);
    final centres = journeyPlaceLayout(
        area: map, here: party, bearings: [-0.4, -0.4, -0.4]);
    const name = Size(112, 46);
    final marks = [
      for (final c in centres) Rect.fromCircle(center: c, radius: 22),
    ];
    final partyMark = Rect.fromCircle(center: party, radius: 26);
    for (final keep in [null, 0, 1, 2]) {
      final spots = journeyLabelSpots(
        area: map,
        centres: centres,
        radius: 22,
        labels: const [name, name, name],
        avoid: [partyMark],
        keep: keep,
      );
      final named = [
        for (var i = 0; i < spots.length; i++)
          if (spots[i] != null) i
      ];
      // The way picked is always named; the rest where they fit.
      if (keep != null) expect(named, contains(keep));
      expect(named.length, greaterThanOrEqualTo(2), reason: '$keep');
      for (final i in named) {
        final spot = spots[i]!;
        if (i != keep) {
          expect((Offset.zero & map).intersect(spot), spot, reason: '$i');
          expect(spot.overlaps(partyMark), isFalse, reason: '$i');
          for (var j = 0; j < marks.length; j++) {
            if (j != i) {
              expect(spot.overlaps(marks[j]), isFalse, reason: '$i on $j');
            }
          }
        }
        for (final other in named) {
          if (other != i) {
            expect(spot.overlaps(spots[other]!), isFalse,
                reason: '$i and $other');
          }
        }
      }
    }
    // With room, a name goes under its mark, centred.
    final alone = journeyLabelSpots(
        area: map, centres: const [party], radius: 22, labels: const [name]);
    expect(alone.single!.topCenter, party + const Offset(0, 26));
    // A mark shown without its name keeps none.
    expect(
        journeyLabelSpots(
            area: map,
            centres: const [party],
            radius: 22,
            labels: const [null]),
        [null]);
  });

  test('what each place is drawn as', () {
    expect(placeKindOf('camp'), PlaceKind.camp);
    expect(placeKindOf('town'), PlaceKind.town);
    expect(placeKindOf('village'), PlaceKind.town);
    expect(placeKindOf('site'), PlaceKind.site);
    // A street or quarter with no settlement of its own is town.
    expect(placeKindOf(null), PlaceKind.town);
    expect(placeKindOf('town', atSea: true), PlaceKind.sea);
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/sea_events.dart';

void main() {
  const enemyShips = {
    'raider_skiff': {'minChapter': 2, 'maxHull': 60},
    'inquisition_cutter': {'minChapter': 3, 'maxHull': 95},
    'void_barge': {'minChapter': 4, 'maxHull': 140},
  };

  test('raiderPoolFor only admits ships the chapter has reached', () {
    expect(raiderPoolFor(enemyShips, 1), isEmpty);
    expect(raiderPoolFor(enemyShips, 2), ['raider_skiff']);
    expect(
        raiderPoolFor(enemyShips, 3), ['inquisition_cutter', 'raider_skiff']);
    expect(raiderPoolFor(enemyShips, 6).length, 3);
  });

  test('a voyage has exactly its length in events, never fewer than one', () {
    for (final length in [0, 1, 2, 5]) {
      final voyage = buildVoyage(
          random: Random(7),
          length: length,
          enemyShips: enemyShips,
          chapter: 3);
      expect(voyage.length, max(1, length));
    }
  });

  test('the same seed draws the same voyage', () {
    final a = buildVoyage(
        random: Random(42), length: 6, enemyShips: enemyShips, chapter: 3);
    final b = buildVoyage(
        random: Random(42), length: 6, enemyShips: enemyShips, chapter: 3);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].kind, b[i].kind);
      expect(a[i].description, b[i].description);
      expect(a[i].enemyShipId, b[i].enemyShipId);
      expect(a[i].gold, b[i].gold);
      expect(a[i].hullDelta, b[i].hullDelta);
    }
  });

  test('raiders come only from the chapter pool, and never before it exists',
      () {
    final kinds = <SeaEventKind>{};
    for (var seed = 0; seed < 200; seed++) {
      for (final event in buildVoyage(
          random: Random(seed),
          length: 3,
          enemyShips: enemyShips,
          chapter: 2)) {
        kinds.add(event.kind);
        if (event.kind == SeaEventKind.raider) {
          expect(event.enemyShipId, 'raider_skiff');
        }
      }
      for (final event in buildVoyage(
          random: Random(seed),
          length: 3,
          enemyShips: enemyShips,
          chapter: 1)) {
        expect(event.kind, isNot(SeaEventKind.raider));
      }
    }
    expect(kinds, containsAll(SeaEventKind.values));
  });

  test('storms cost hull, calm days mend it, derelicts pay in gold', () {
    for (var seed = 0; seed < 100; seed++) {
      for (final event in buildVoyage(
          random: Random(seed),
          length: 4,
          enemyShips: enemyShips,
          chapter: 4)) {
        switch (event.kind) {
          case SeaEventKind.storm:
            expect(event.hullDelta, lessThan(0));
            expect(event.hullDelta, greaterThanOrEqualTo(-16));
          case SeaEventKind.calm:
            expect(event.hullDelta, greaterThan(0));
          case SeaEventKind.derelict:
            expect(event.gold, greaterThanOrEqualTo(50));
          case SeaEventKind.raider:
          case SeaEventKind.sighting:
            expect(event.hullDelta, 0);
            expect(event.gold, 0);
        }
        expect(event.descriptionFor(true), isNotEmpty);
        expect(event.choiceTextFor(true), isNotEmpty);
        expect(event.descriptionFor(false), isNot(event.descriptionFor(true)));
      }
    }
  });
}

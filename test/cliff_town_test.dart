// The camp's cliff town: where each piece goes, how a save's houses
// become a town, and how many of each addition it may hold.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_works.dart';
import 'package:narrative_data_app/data/cliff_town.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

void main() {
  test('the first house stands on the quay against the right-hand cliff', () {
    final town = CliffTown.build(['keldas_hall']);
    final hall = town.pieces.single;
    expect(hall.row, 0);
    expect(hall.column, townColumns - 2);
  });

  test('the column over the water holds nothing on the quay', () {
    final town = CliffTown.build(
        ['barracks_annex', 'keldas_hall', 'sharpweave_den', 'hearth_hall']);
    for (final piece in town.pieces.where((p) => p.row == 0)) {
      expect(piece.column, greaterThanOrEqualTo(1), reason: piece.id);
    }
  });

  test('pieces never overlap and each rests on something', () {
    final order = [
      ...houseFootprints.keys,
      for (var i = 0; i < 12; i++) townAdditions[i % townAdditions.length].id,
    ];
    final town = CliffTown.build(order);
    expect(town.pieces, hasLength(order.length));
    final taken = <String>{};
    for (final p in town.pieces) {
      var rests = p.row == 0;
      for (var c = p.column; c < p.column + p.footprint.width; c++) {
        for (var r = p.row; r < p.top; r++) {
          expect(taken.add('$r,$c'), isTrue, reason: '${p.id} overlaps');
        }
        if (p.row > 0 && town.isOccupied(p.row - 1, c)) rests = true;
      }
      expect(rests, isTrue, reason: '${p.id} floats');
      expect(p.column + p.footprint.width, lessThanOrEqualTo(townColumns));
    }
  });

  test('the same order always gives the same town', () {
    final order = ['keldas_hall', 'academy', 'add_tower', 'banner_loft'];
    final a = CliffTown.build(order).pieces;
    final b = CliffTown.build(order).pieces;
    expect([for (final p in a) '${p.id}@${p.row},${p.column}'],
        [for (final p in b) '${p.id}@${p.row},${p.column}']);
  });

  test('a save from before the town builds its houses in order', () {
    final session = PlayerSession.fromJson({
      'builtHouseIds': ['keldas_hall', 'hammersmith'],
    });
    expect(session.townPieces, ['keldas_hall', 'hammersmith']);
    final later = session.copyWith(
      townOrder: ['keldas_hall', 'add_floor', 'hammersmith', 'add_tower'],
    );
    expect(later.townPieces,
        ['keldas_hall', 'add_floor', 'hammersmith', 'add_tower']);
    final json = later.toJson();
    expect(PlayerSession.fromJson(json).townPieces, later.townPieces);
  });

  test('a house no longer built leaves the town', () {
    final session = PlayerSession.fromJson({
      'builtHouseIds': ['keldas_hall'],
      'townOrder': ['keldas_hall', 'add_floor', 'hammersmith'],
    });
    expect(session.townPieces, ['keldas_hall', 'add_floor']);
  });

  test('the watchtower is unique; storehouses and stairs grow with the town',
      () {
    expect(townAdditionLimit('add_tower', houseCount: 0), 1);
    expect(townAdditionLimit('add_tower', houseCount: 9), 1);
    expect(townAdditionLimit('add_store', houseCount: 0), 1);
    expect(townAdditionLimit('add_store', houseCount: 4), 2);
    expect(townAdditionLimit('add_stair', houseCount: 1), 1);
    expect(townAdditionLimit('add_stair', houseCount: 2), 2);
    // Plain rooms are free.
    expect(townAdditionLimit('add_floor', houseCount: 0), isNull);
    final pieces = ['harbor', 'add_tower', 'add_floor', 'add_floor'];
    final tower =
        townAdditionLimitOf('add_tower', pieces: pieces, houseCount: 1);
    expect((tower.built, tower.limit, tower.atLimit), (1, 1, true));
    final floor =
        townAdditionLimitOf('add_floor', pieces: pieces, houseCount: 1);
    expect((floor.built, floor.atLimit), (2, false));
  });

  test('a house is one of one', () {
    const built = CampWork(
        houseId: 'harbor',
        category: WorkCategory.sea,
        tier: 1,
        chapter: 1,
        state: WorkState.built);
    expect((built.limit.built, built.limit.limit, built.limit.atLimit),
        (1, 1, true));
  });

  testWidgets('the camp refuses an addition past its limit', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Let the notifier's own first load finish before seeding the session.
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester
        .runAsync(() => notifier.loadSession(PlayerSession.fromJson(const {
              'gold': 1000,
              'builtHouseIds': ['harbor'],
            })));
    await tester.runAsync(() => notifier.buildTownAddition('add_tower', 120));
    await tester.runAsync(() => notifier.buildTownAddition('add_tower', 120));
    final session = container.read(playerSessionProvider);
    expect(townPieceCount(session.townPieces, 'add_tower'), 1);
    expect(session.gold, 880);
    await tester.runAsync(() => notifier.buildTownAddition('add_floor', 40));
    await tester.runAsync(() => notifier.buildTownAddition('add_floor', 40));
    expect(
        townPieceCount(
            container.read(playerSessionProvider).townPieces, 'add_floor'),
        2);
  });
}

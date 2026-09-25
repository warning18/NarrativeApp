// The camp's cliff town: where each piece goes, and how a save's houses
// become a town.
import 'package:flutter_test/flutter_test.dart';

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
}

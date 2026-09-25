/// The camp's town, stacked up the cliff above the quay.
///
/// The town is a grid against the right-hand cliff: [townColumns] plots
/// across, each [townCellWidth] x [townRowHeight] units, standing on the
/// quay (row 0, every column but the first, which is over the water).
/// Each piece — a house or a town addition — has a footprint of whole
/// plots. A new piece goes where it fits lowest and furthest right,
/// resting on at least one plot below it; the plots it overhangs get
/// timber struts. Placing the pieces again in the same order always gives
/// the same town, so only the order is saved (`PlayerSession.townOrder`).
library;

const int townColumns = 5;
const double townCellWidth = 62;
const double townRowHeight = 46;

/// The rock on either side of the town, in the same units.
const double townCliffWidth = 40;

/// The harbour under the quay, in the same units.
const double townHarborHeight = 130;

/// The width the town is drawn at before it is scaled to the screen.
const double townWidth = townCliffWidth * 2 + townColumns * townCellWidth;

/// A piece's footprint, in plots.
class TownFootprint {
  const TownFootprint(this.width, this.height);
  final int width;
  final int height;
}

/// The houses of houses.json, by id. A house not listed takes one plot.
const Map<String, TownFootprint> houseFootprints = {
  'keldas_hall': TownFootprint(2, 1),
  'barracks_annex': TownFootprint(3, 1),
  'hammersmith': TownFootprint(2, 1),
  'academy': TownFootprint(1, 2),
  'sharpweave_den': TownFootprint(1, 1),
  'hearth_hall': TownFootprint(3, 1),
  'banner_loft': TownFootprint(2, 2),
  'shroud_shrine': TownFootprint(1, 2),
};

/// A town addition: a piece bought with gold that only adds to the town.
class TownAddition {
  const TownAddition(this.id, this.cost, this.footprint);
  final String id;
  final int cost;
  final TownFootprint footprint;
}

const List<TownAddition> townAdditions = [
  TownAddition('add_floor', 40, TownFootprint(1, 1)),
  TownAddition('add_stair', 60, TownFootprint(1, 1)),
  TownAddition('add_store', 90, TownFootprint(2, 1)),
  TownAddition('add_tower', 120, TownFootprint(1, 2)),
];

bool isTownAddition(String id) => townAdditions.any((a) => a.id == id);

TownFootprint footprintOf(String id) {
  for (final addition in townAdditions) {
    if (addition.id == id) return addition.footprint;
  }
  return houseFootprints[id] ?? const TownFootprint(1, 1);
}

/// One piece standing in the town: its bottom-left plot and footprint.
class TownPiece {
  const TownPiece(this.id, this.row, this.column, this.footprint);
  final String id;
  final int row;
  final int column;
  final TownFootprint footprint;

  int get top => row + footprint.height;
}

/// A plot a piece hangs over with nothing under it: it gets struts.
class TownStrut {
  const TownStrut(this.row, this.column);
  final int row;
  final int column;
}

/// The town built from [order], and where the next piece would go.
class CliffTown {
  CliffTown._(this.pieces, this._occupied);

  /// Places each of [order]'s pieces in turn.
  factory CliffTown.build(List<String> order) {
    final town = CliffTown._([], <int>{});
    for (final id in order) {
      final footprint = footprintOf(id);
      final spot = town.spotFor(footprint);
      if (spot == null) continue;
      town._add(TownPiece(id, spot.$1, spot.$2, footprint));
    }
    return town;
  }

  final List<TownPiece> pieces;
  final Set<int> _occupied;

  static int _key(int row, int column) => row * townColumns + column;

  bool isOccupied(int row, int column) => _occupied.contains(_key(row, column));

  /// How many rows the town reaches.
  int get height => pieces.fold(0, (top, p) => p.top > top ? p.top : top);

  void _add(TownPiece piece) {
    pieces.add(piece);
    for (var r = piece.row; r < piece.top; r++) {
      for (var c = piece.column;
          c < piece.column + piece.footprint.width;
          c++) {
        _occupied.add(_key(r, c));
      }
    }
  }

  /// Where a piece of [footprint] would go next: (row, column), or null
  /// if it is wider than the town.
  (int, int)? spotFor(TownFootprint footprint) {
    if (footprint.width > townColumns) return null;
    (int, int)? best;
    double bestScore = double.infinity;
    for (var r = 0; r <= height + 1; r++) {
      for (var c = townColumns - footprint.width; c >= 0; c--) {
        if (!_fits(r, c, footprint) || !_rests(r, c, footprint)) continue;
        // Lower is better; each plot away from the right-hand cliff costs
        // most of a row, so the town climbs before it spreads, and hanging
        // out over the water costs more again.
        final score =
            r + (townColumns - footprint.width - c) * 0.8 + (c == 0 ? 1.5 : 0);
        if (score < bestScore) {
          bestScore = score;
          best = (r, c);
        }
      }
    }
    return best;
  }

  bool _fits(int row, int column, TownFootprint footprint) {
    for (var r = row; r < row + footprint.height; r++) {
      for (var c = column; c < column + footprint.width; c++) {
        if (isOccupied(r, c)) return false;
      }
    }
    return true;
  }

  bool _rests(int row, int column, TownFootprint footprint) {
    // The quay takes every column but the first, over the water.
    if (row == 0) return column >= 1;
    for (var c = column; c < column + footprint.width; c++) {
      if (isOccupied(row - 1, c)) return true;
    }
    return false;
  }

  /// The plots pieces hang over with nothing below.
  List<TownStrut> get struts => [
        for (final piece in pieces)
          if (piece.row > 0)
            for (var c = piece.column;
                c < piece.column + piece.footprint.width;
                c++)
              if (!isOccupied(piece.row - 1, c)) TownStrut(piece.row, c),
      ];
}

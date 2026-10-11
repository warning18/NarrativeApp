import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../widgets/ship_dress.dart';
import '../widgets/ship_widgets.dart' show playerShipRecord;
import 'game_db_providers.dart';
import 'player_session_provider.dart';

/// What the Eel wears and carries as she is now: her parts and her looks
/// (see ship_dress.dart). Null until the ship, parts and looks tables
/// have loaded, when she is drawn as she always was.
final shipDressProvider = Provider<ShipDress?>((ref) {
  final session = ref.watch(playerSessionProvider);
  final ships = ref.watch(localizedDbProvider(shipsSchema)).value;
  final parts = ref.watch(localizedDbProvider(shipPartsSchema)).value;
  final looks = ref.watch(localizedDbProvider(shipLooksSchema)).value;
  if (ships == null || parts == null || looks == null) return null;
  final ship = playerShipRecord(ships);
  if (ship == null) return null;
  return buildShipDress(
    ship: ship,
    parts: parts,
    installed: session.shipPartIds,
    lookRecords: looks,
    chosen: session.shipLooks,
    owned: session.ownedShipLooks,
  );
});

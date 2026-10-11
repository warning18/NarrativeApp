import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ship_forms.dart';
import '../gamedata/db_schema.dart';
import '../widgets/sea_battlefield.dart' show TopShipLook;
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
  final ship = playerShipRecord(ships, session.shipHullId);
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

/// The hull the Eel is built on, as the painter draws it (see
/// ship_forms.dart); null until the ships table has loaded.
final shipFormProvider = Provider<ShipForm?>((ref) {
  final session = ref.watch(playerSessionProvider);
  final ships = ref.watch(localizedDbProvider(shipsSchema)).value;
  if (ships == null) return null;
  final hullId = ships.containsKey(session.shipHullId)
      ? session.shipHullId
      : defaultHullId;
  final record = ships[hullId];
  return record is Map<String, dynamic>
      ? ShipForm.fromRecord(hullId, record)
      : null;
});

/// The Eel as the sea fight draws her: her hull's form in her paint and
/// cloth.
final playerShipLookProvider = Provider<TopShipLook>((ref) {
  final form = ref.watch(shipFormProvider);
  final base = form == null ? TopShipLook.rustyEel : TopShipLook.player(form);
  return base.dressed(ref.watch(shipDressProvider));
});

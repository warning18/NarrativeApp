// Who fights (the user's rules, v1.664): three fighters at most, the player
// and two companions; a companion in the reserve seat (the Barracks Annex)
// steps in once a fight for a fielded one knocked out; and before a fight
// the player may pick which companions go, the seated ones by default
// (fightPickProvider, fight_pick_provider.dart).
import '../providers/player_session_provider.dart'
    show PlayerSession, basePartyCapacity;

/// Who [session]'s fight fields and who waits in reserve: [pick] when given
/// (the pre-fight sheet's), else the seated companions. At most
/// [basePartyCapacity], each recruited once, with their own house built
/// (companions.json `requiredHouseId`, from [companions]). The reserve is
/// [PlayerSession.reserveAlly] unless the pick fields them.
({List<String> fielded, String? reserve}) fightLineup(
  PlayerSession session, {
  List<String>? pick,
  Map<String, dynamic> companions = const {},
}) {
  bool canFight(String id) {
    if (!session.recruitedAllies.any((a) => a.companionId == id)) return false;
    final house = (companions[id] as Map?)?['requiredHouseId']?.toString();
    return house == null ||
        house.isEmpty ||
        session.builtHouseIds.contains(house);
  }

  final fielded = <String>[];
  for (final id in pick ?? session.activeAllyIds) {
    if (fielded.length >= basePartyCapacity) break;
    if (fielded.contains(id) || !canFight(id)) continue;
    fielded.add(id);
  }
  final reserve = session.reserveAlly;
  return (
    fielded: fielded,
    reserve: reserve == null || fielded.contains(reserve) || !canFight(reserve)
        ? null
        : reserve,
  );
}

/// The member a reserve steps in for at the round's turn: the first
/// companion knocked out ([knockedOut] in seat order, the player never
/// counted), or -1 when none is down or the reserve was used ([used]).
int reserveStepsInFor(List<bool> knockedOut, {required bool used}) {
  if (used) return -1;
  // Seat 0 is the player's.
  for (var i = 1; i < knockedOut.length; i++) {
    if (knockedOut[i]) return i;
  }
  return -1;
}

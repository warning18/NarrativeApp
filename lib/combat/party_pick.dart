// Who fights (the user's rules, v1.667): three fighters at most, the
// player and two companions; before a fight the player may pick which
// companions go, the seated ones by default (fightPickProvider,
// fight_pick_provider.dart).
import '../providers/player_session_provider.dart'
    show PlayerSession, basePartyCapacity;

/// The companions [session]'s fight fields: [pick] when given (the
/// pre-fight sheet's), else the seated ones. At most [basePartyCapacity],
/// each recruited once, with their own house built (companions.json
/// `requiredHouseId`, from [companions]).
List<String> fightLineup(
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
  return fielded;
}

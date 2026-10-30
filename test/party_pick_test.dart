// Who fights (the user's rules, v1.667, party_pick.dart): three fighters
// at most, and the pre-fight pick.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/party_pick.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

AllyState _ally(String id) =>
    AllyState(companionId: id, currentHealth: AllyState.fullHealthSentinel);

PlayerSession _session({
  List<String> active = const ['sable', 'liora'],
  List<String> built = const [],
}) =>
    PlayerSession.fromJson({
      'recruitedAllies': [
        for (final id in ['sable', 'liora', 'kelda', 'vess'])
          _ally(id).toJson(),
      ],
      'activeAllyIds': active,
      'builtHouseIds': built,
    });

void main() {
  test('the seated ones by default', () {
    expect(fightLineup(_session()), ['sable', 'liora']);
  });

  test('a pick fields its own, two at most, each once and recruited', () {
    expect(
        fightLineup(_session(),
            pick: ['vess', 'vess', 'nobody', 'sable', 'liora']),
        ['vess', 'sable']);
    // An empty pick goes alone.
    expect(fightLineup(_session(), pick: const []), isEmpty);
  });

  test("a companion whose house isn't built stays home", () {
    const companions = {
      'kelda': {'requiredHouseId': 'keldas_hall'},
    };
    expect(
        fightLineup(_session(),
            pick: ['kelda', 'vess'], companions: companions),
        ['vess']);
    expect(
        fightLineup(_session(built: ['keldas_hall']),
            pick: ['kelda', 'vess'], companions: companions),
        ['kelda', 'vess']);
  });
}

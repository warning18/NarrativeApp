// Who fights (the user's rules, v1.664, party_pick.dart): three fighters
// at most, the pre-fight pick, and the reserve seat's one swap.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/party_pick.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

AllyState _ally(String id) =>
    AllyState(companionId: id, currentHealth: AllyState.fullHealthSentinel);

PlayerSession _session({
  List<String> active = const ['sable', 'liora'],
  String reserve = 'kelda',
  List<String> built = const [],
}) =>
    PlayerSession.fromJson({
      'recruitedAllies': [
        for (final id in ['sable', 'liora', 'kelda', 'vess'])
          _ally(id).toJson(),
      ],
      'activeAllyIds': active,
      'reserveAllyId': reserve,
      'builtHouseIds': built,
    });

void main() {
  group('fightLineup', () {
    test('the seated ones by default, the reserve waiting', () {
      final lineup = fightLineup(_session());
      expect(lineup.fielded, ['sable', 'liora']);
      expect(lineup.reserve, 'kelda');
    });

    test('a pick fields its own, two at most, each once and recruited', () {
      final lineup = fightLineup(_session(),
          pick: ['vess', 'vess', 'nobody', 'sable', 'liora']);
      expect(lineup.fielded, ['vess', 'sable']);
      expect(lineup.reserve, 'kelda');
      // An empty pick goes alone.
      expect(fightLineup(_session(), pick: const []).fielded, isEmpty);
    });

    test('a picked reserve fights and leaves the reserve seat empty', () {
      final lineup = fightLineup(_session(), pick: ['kelda', 'sable']);
      expect(lineup.fielded, ['kelda', 'sable']);
      expect(lineup.reserve, isNull);
    });

    test("a companion whose house isn't built stays home", () {
      const companions = {
        'kelda': {'requiredHouseId': 'keldas_hall'},
      };
      final lineup = fightLineup(_session(),
          pick: ['kelda', 'vess'], companions: companions);
      expect(lineup.fielded, ['vess']);
      expect(lineup.reserve, isNull);
      final built = fightLineup(_session(built: ['keldas_hall']),
          pick: ['kelda', 'vess'], companions: companions);
      expect(built.fielded, ['kelda', 'vess']);
    });
  });

  group('reserveStepsInFor', () {
    test('the first companion down, never the player', () {
      expect(reserveStepsInFor([false, false, false], used: false), -1);
      expect(reserveStepsInFor([true, false, false], used: false), -1);
      expect(reserveStepsInFor([false, false, true], used: false), 2);
      expect(reserveStepsInFor([false, true, true], used: false), 1);
    });

    test('once a fight', () {
      expect(reserveStepsInFor([false, true, true], used: true), -1);
    });
  });
}

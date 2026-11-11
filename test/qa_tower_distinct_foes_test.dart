// QA guard: every Tower floor's foes are distinct ids.
//
// The Tower's fight launcher (`towerFightFor`) builds a map of foe records
// keyed by id and gives up ("not fought", no message) when the map is
// shorter than the floor's list of foes. A floor of two Street Bandits or two
// Harbour Rats therefore never starts: "Fight" does nothing and the climb
// cannot go on. Found in a real run (floor 6 and 7, human warrior).
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_floors.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';

void main() {
  test('no Tower floor has the same foe twice (the launcher would not start)',
      () {
    final data = towerDataFromAssets();
    final bad = <String>[];
    for (var seed = 1; seed <= 300 && bad.length < 20; seed++) {
      final floors = towerFloorsFor(seed, data.enemies);
      for (final f in floors) {
        if (f.enemyIds.toSet().length != f.enemyIds.length) {
          bad.add('seed $seed floor ${f.floor}: ${f.enemyIds.join(', ')}');
        }
      }
    }
    expect(bad, isEmpty,
        reason:
            'floors with a repeated foe cannot be fought:\n${bad.join('\n')}');
  });
}

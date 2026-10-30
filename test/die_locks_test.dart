// The party's dice between rolls (the user's lock rules, v1.662,
// die_locks.dart): a tap selects, a second locks, a double tap releases
// until the next roll, a roll freezes the round's locks.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/die_locks.dart';

void main() {
  test('a first tap selects, a second locks', () {
    final locks = DieLocks();
    expect(locks.tap('player'), DieTap.selected);
    expect(locks.selected, 'player');
    expect(locks.locked, isEmpty);
    expect(locks.tap('player'), DieTap.locked);
    expect(locks.locked, {'player'});
    // A locked die stays locked on a further tap.
    expect(locks.tap('player'), DieTap.none);
    // Another die is selected first, then locked.
    expect(locks.tap('vica'), DieTap.selected);
    expect(locks.locked, {'player'});
    expect(locks.tap('vica'), DieTap.locked);
    expect(locks.locked, {'player', 'vica'});
  });

  test('a lock is released until the next roll, then frozen', () {
    final locks = DieLocks()
      ..tap('player')
      ..tap('player');
    expect(locks.canRelease('player'), isTrue);
    expect(locks.release('player'), isTrue);
    expect(locks.locked, isEmpty);

    locks
      ..tap('player')
      ..tap('player');
    locks.rolled();
    // The roll froze it: kept for the round, the double tap does nothing.
    expect(locks.canRelease('player'), isFalse);
    expect(locks.release('player'), isFalse);
    expect(locks.locked, {'player'});
    // After the roll a tap selects afresh; a die locked now can still be
    // released until the next roll.
    expect(locks.selected, isNull);
    expect(locks.tap('vica'), DieTap.selected);
    expect(locks.tap('vica'), DieTap.locked);
    expect(locks.release('vica'), isTrue);
    expect(locks.release('nobody'), isFalse);
  });

  test('a new round clears it all', () {
    final locks = DieLocks()
      ..tap('player')
      ..tap('player')
      ..rolled()
      ..clear();
    expect(locks.locked, isEmpty);
    expect(locks.frozen, isEmpty);
    expect(locks.selected, isNull);
    expect(locks.tap('player'), DieTap.selected);
  });
}

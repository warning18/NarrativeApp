import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dice a fight rolls: every roll of the fight screen (the faces, the
/// crits and dodges, the enemy's moves and targets, the affixes, the ground
/// and its anomaly, the loot) is drawn from the one Random it makes from
/// this. A fresh unseeded Random for each fight in play; a test hands in a
/// seeded one (`() => Random(7)`) so the fight it asserts on cannot turn out
/// differently from one run to the next. A fight screen built with its own
/// `random:` uses that instead.
final fightRandomProvider = Provider<Random Function()>((ref) => Random.new);

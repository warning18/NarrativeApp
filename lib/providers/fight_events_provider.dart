import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/fight_events.dart';

export '../combat/fight_events.dart';

/// The fight's events (fight_events.dart): the fight screen publishes each
/// hit and each status tick here; the screen's looks (panels, effects)
/// listen. One fight is played at a time, so one hub serves them all.
final fightEventsProvider = Provider<FightEvents>((ref) {
  final events = FightEvents();
  ref.onDispose(events.dispose);
  return events;
});

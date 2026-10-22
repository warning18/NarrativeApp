import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journey_rules.dart';
import 'player_session_provider.dart';

/// The part of the day the world clock is at (wave 16): dawn, day, dusk or
/// night, from the session's watch (see [dayPhaseOf]). A screen drawn at
/// the hour (the town's dusk wash, lit windows at night) watches this; it
/// changes only when the watch does, not on every save.
final dayPhaseProvider = Provider<DayPhase>((ref) =>
    dayPhaseOf(ref.watch(playerSessionProvider.select((s) => s.watch))));

/// The hour (0..23) the world clock shows (see [hourOfWatch]).
final hourOfDayProvider = Provider<int>((ref) =>
    hourOfWatch(ref.watch(playerSessionProvider.select((s) => s.watch))));

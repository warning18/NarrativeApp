import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dice the road rolls besides its own (whether a detour waits is the
/// road's own roll, see detourRandomFor): an alignment event, a familiar
/// face, what a detour of today's chain holds (see startRoadEncounter). A
/// fresh Random for each roll in play; a test hands in its own to keep
/// them quiet or busy.
final roadRandomProvider = Provider<Random Function()>((ref) => Random.new);

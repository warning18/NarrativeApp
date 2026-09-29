import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dice the road rolls: whether a detour waits, an alignment event, a
/// familiar face (see rollRoadEncounter). A fresh Random for each roll in
/// play; a test hands in its own to keep the road quiet or busy.
final roadRandomProvider = Provider<Random Function()>((ref) => Random.new);

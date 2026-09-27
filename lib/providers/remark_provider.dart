import 'dart:math';

import 'package:flutter_riverpod/legacy.dart';

import '../data/companion_remarks.dart';

/// Who has spoken up about the player's choices this session, and with
/// which lines (see companion_remarks.dart): companions take turns and
/// don't repeat themselves back to back.
final remarkMemoryProvider = StateProvider<RemarkMemory>(
    (ref) => RemarkMemory(seed: Random().nextInt(1 << 20)));

/// The companion's remark the next scene opens with, set when a choice is
/// made and cleared as soon as the player makes the next one.
final pendingRemarkProvider = StateProvider<CompanionRemark?>((ref) => null);

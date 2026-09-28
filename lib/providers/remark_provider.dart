import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';

import '../data/companion_remarks.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';

/// The companions' remark lines, from the Companion Remarks table (edits
/// made in the Data tab included); empty until the table has loaded.
final remarkBookProvider = Provider<RemarkBook>((ref) {
  final records = ref.watch(gameDbProvider(companionRemarksSchema)).value;
  return records == null ? RemarkBook.empty : RemarkBook(records);
});

/// Who has spoken up about the player's choices this session, and with
/// which lines (see companion_remarks.dart): companions take turns and
/// don't repeat themselves back to back.
final remarkMemoryProvider = StateProvider<RemarkMemory>(
    (ref) => RemarkMemory(seed: Random().nextInt(1 << 20)));

/// What the party says the next scene opens with (a remark, and maybe an
/// answer to it), set when a choice is made and cleared as soon as the
/// player makes the next one.
final pendingRemarksProvider =
    StateProvider<List<CompanionRemark>>((ref) => const []);

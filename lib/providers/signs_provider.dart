import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/signs.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';

/// patrons.json and signs.json, parsed (see signs.dart), loaded the way
/// every gamedata table is: the asset, or the Data tab's edited copy. Read
/// raw, not French-overlaid: a patron and a sign pick their language
/// themselves (nameFor, greetingsFor...), and the session's notifier
/// needs the same records whatever the language.
final patronsProvider = Provider<Map<String, Patron>>((ref) =>
    parsePatrons(ref.watch(gameDbProvider(patronsSchema)).value ?? const {}));

final signDefsProvider = Provider<Map<String, SignDef>>((ref) =>
    parseSigns(ref.watch(gameDbProvider(signsSchema)).value ?? const {}));

/// What the character's held signs add up to right now (see
/// signEffectsFor): a fight, a voyage and a ship battle read it once as
/// they start.
final signEffectsProvider = Provider<SignEffects>((ref) {
  final held = ref.watch(playerSessionProvider.select((s) => s.heldSigns));
  final alignment =
      ref.watch(playerSessionProvider.select((s) => s.alignmentScore));
  return signEffectsFor(held, ref.watch(signDefsProvider),
      alignment: alignment);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/spells.dart' show parseSpells;
import '../data/offers.dart';
import '../data/signs.dart';
import '../gamedata/db_schema.dart';
import 'clans_provider.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'signs_provider.dart';

/// The tables an offer is drawn from and applied with (see offers.dart),
/// as they stand: raw records, not French-overlaid -- the rules need the
/// same ids whatever the language. Empty until each has loaded.
final offerTablesProvider = Provider<OfferTables>((ref) {
  Map<String, dynamic> table(DbSchema schema) =>
      ref.watch(gameDbProvider(schema)).value ?? const {};
  return OfferTables(
    data: ref.watch(clanDataProvider),
    signs: ref.watch(signDefsProvider),
    skills: table(skillsSchema),
    skillTrees: table(skillTreesSchema),
    items: table(itemsSchema),
    spells: parseSpells(table(spellsSchema)),
  );
});

/// The offer tables once every one has loaded: for the code that draws or
/// takes an offer and may be the first to ask (a level-up after a cold
/// start), where [offerTablesProvider] could still be empty.
Future<OfferTables> loadOfferTables(WidgetRef ref) async {
  Future<Map<String, dynamic>> table(DbSchema schema) =>
      ref.read(gameDbProvider(schema).notifier).whenLoaded();
  return OfferTables(
    data: await loadClanData(ref),
    signs: parseSigns(await table(signsSchema)),
    skills: await table(skillsSchema),
    skillTrees: await table(skillTreesSchema),
    items: await table(itemsSchema),
    spells: parseSpells(await table(spellsSchema)),
  );
}

/// What the clans add to a fight now (see clanEffectsFor): the title worn,
/// every bad title, and the Sworn boon while still sworn.
final clanEffectsProvider = Provider<List<SignEffect>>((ref) {
  final session = ref.watch(playerSessionProvider);
  return clanEffectsFor(
    activeTitleId: session.activeTitleId,
    heldTitleIds: session.heldTitleIds,
    swornBoonIds: session.swornBoonIds,
    swornFactionId: session.politics.swornFactionId,
    data: ref.watch(clanDataProvider),
  );
});

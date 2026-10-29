import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/spec_variants.dart' show specVariantsFrom;
import '../combat/specialisations.dart' show specInfosFrom;
import '../combat/spells.dart' show parseSpells;
import '../data/description_text.dart';
import '../data/offers.dart';
import '../data/signs.dart';
import '../gamedata/db_schema.dart';
import 'clans_provider.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'signs_provider.dart';

/// The tables an offer is drawn from and applied with (see offers.dart),
/// as they stand: raw records, not French-overlaid -- the rules need the
/// same ids whatever the language (the skills' descriptions have their
/// placeholders filled, see description_text.dart). Empty until each has
/// loaded.
final offerTablesProvider = Provider<OfferTables>((ref) {
  Map<String, dynamic> table(DbSchema schema) =>
      ref.watch(gameDbProvider(schema)).value ?? const {};
  return OfferTables(
    data: ref.watch(clanDataProvider),
    signs: ref.watch(signDefsProvider),
    skills: withResolvedPlaceholders(skillsSchema.id, table(skillsSchema)),
    skillTrees: table(skillTreesSchema),
    items: table(itemsSchema),
    spells: parseSpells(table(spellsSchema)),
    specs: specInfosFrom(table(specialisationsSchema)),
    specVariants: specVariantsFrom(table(specVariantsSchema)),
  );
});

/// The offer tables once every one has loaded: for the code that draws or
/// takes an offer and may be the first to ask (a level-up after a cold
/// start), where [offerTablesProvider] could still be empty. Every table is
/// asked for before the first wait, so [ref]'s widget may go meanwhile (a
/// fight left while the offer after its level-up loads).
Future<OfferTables> loadOfferTables(WidgetRef ref) async {
  Future<Map<String, dynamic>> table(DbSchema schema) =>
      ref.read(gameDbProvider(schema).notifier).whenLoaded();
  final data = loadClanData(ref);
  final signs = table(signsSchema);
  final skills = table(skillsSchema);
  final skillTrees = table(skillTreesSchema);
  final items = table(itemsSchema);
  final spells = table(spellsSchema);
  final specs = table(specialisationsSchema);
  final specVariants = table(specVariantsSchema);
  return OfferTables(
    data: await data,
    signs: parseSigns(await signs),
    skills: withResolvedPlaceholders(skillsSchema.id, await skills),
    skillTrees: await skillTrees,
    items: await items,
    spells: parseSpells(await spells),
    specs: specInfosFrom(await specs),
    specVariants: specVariantsFrom(await specVariants),
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

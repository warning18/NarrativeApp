import '../combat/combat_engine.dart' show elementFieldPrefixes;
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../models/ally_state.dart';
import '../providers/player_session_provider.dart';

/// What a spell would do if the player cast it right now, read from the
/// session alone -- the character and skills screens show these numbers
/// outside a fight, and they match what the battle screen's spell button
/// lands with (base damage, gear, stat scaling, alignment gear and the
/// spell's own element bonus, then `spellAmountFor`).
class SpellPreview {
  const SpellPreview({required this.amount, this.status});

  final int amount;
  final StatusEffect? status;
}

/// The damage total a spell of [element] rides on for the player -- the
/// same sum a dice face hits with.
int sessionCasterDamage(
  PlayerSession session,
  Map<String, dynamic> items,
  String element,
) {
  final scaling = equipmentScalingBonusFor(
    session.equippedItemIds,
    items,
    strength: session.strength,
    dexterity: session.dexterity,
    constitution: session.constitution,
    intelligence: session.intelligence,
  );
  final aligned = alignmentGearBonusFor(
      session.equippedItemIds, items, session.alignmentLabel);
  final prefix = elementFieldPrefixes[element];
  final elemental = prefix == null
      ? 0
      : equipmentBonusFor(session.equippedItemIds, items, '${prefix}DmgBonus');
  return session.baseDamage +
      equipmentBonusFor(session.equippedItemIds, items, 'attackDamage') +
      scaling.damageBonus +
      aligned.damageBonus +
      elemental;
}

SpellPreview previewSpellFor(
  SpellSpec spell,
  PlayerSession session,
  Map<String, dynamic> items,
) =>
    SpellPreview(
      amount: spellAmountFor(
        spell,
        intelligence: session.intelligence,
        wisdom: session.wisdom,
        level: session.level,
        casterDamage: sessionCasterDamage(session, items, spell.element),
      ),
      status: spellStatusFor(spell, level: session.level),
    );

/// The shops (ids, in shops.json order) whose stock includes a spellbook
/// teaching [spellId] -- where the player can go to learn it. Empty for a
/// starting spell or one no shop sells.
List<String> spellbookShopsFor(
  String spellId,
  Map<String, dynamic> items,
  Map<String, dynamic> shops,
) {
  final bookIds = <String>{
    for (final entry in items.entries)
      if (spellbookSpellIdFor(entry.value as Map<String, dynamic>?) == spellId)
        entry.key,
  };
  if (bookIds.isEmpty) return const [];
  return [
    for (final entry in shops.entries)
      if (((entry.value as Map<String, dynamic>?)?['initialStock'] as List?)
              ?.any((id) => bookIds.contains(id.toString())) ==
          true)
        entry.key,
  ];
}

/// The spells a character of [professionId] can ever cast, known ones
/// first (in the order they were learned), then the rest of the
/// profession's spells alphabetically by name.
List<SpellSpec> spellsForProfession(
  Map<String, SpellSpec> spells,
  String professionId,
  List<String> knownSpellIds,
) {
  final known = <SpellSpec>[
    for (final id in knownSpellIds)
      if (spells[id] != null) spells[id]!,
  ];
  final rest = spells.values
      .where((s) =>
          !knownSpellIds.contains(s.id) &&
          (s.professionId.isEmpty || s.professionId == professionId))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return [...known, ...rest];
}

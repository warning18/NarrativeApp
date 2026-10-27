/// Forging rolls for its result (docs/proposals/forge-roll.md): the forge
/// rolls one d20, adds its modifiers, and the total sets the piece's tier.
///
/// - **Tiers** ([forgeTierFor]): 1-4 Flawed (-1 to the main number, never
///   below 0), 5-14 Sound (as listed), 15-19 Fine (+1), 20+ Masterwork
///   (+2). A flawed roll loses nothing extra: gold and materials are spent
///   as for any piece.
/// - **Modifiers** ([forgeModifiersFor]): a dwarf hero +2 (at any forge);
///   standing with the clan holding the forge's place, +1 at Friendly or
///   better, -1 at Unfriendly or worse, nothing when no clan holds it.
/// - **Variants** ([forgedVariantId], [ForgedItems]): a piece forged above
///   or below Sound keeps its tier in its id, `<baseId>@fine`; the items
///   table resolves such an id to the base item with the tier's change
///   ([forgedVariantOf]), so saves, equipping, the pack and the shop all
///   read one id.
///
/// Everything here is pure; PlayerSessionNotifier.craftItem rolls and the
/// forge sheet shows the [ForgeRoll] (and [forgedPieceBeforeAfter]).
library;

import 'dart:collection';
import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart' show trFor;
import '../providers/player_session_provider.dart' show sellPriceFor;
import 'factions.dart';

/// How well a piece came off the anvil, worst first.
enum ForgeTier { flawed, sound, fine, masterwork }

/// The tier a forge total of [total] lands in.
ForgeTier forgeTierFor(int total) {
  if (total <= 4) return ForgeTier.flawed;
  if (total <= 14) return ForgeTier.sound;
  if (total <= 19) return ForgeTier.fine;
  return ForgeTier.masterwork;
}

/// What [tier] does to a piece's main number.
int forgeStatChange(ForgeTier tier) => switch (tier) {
      ForgeTier.flawed => -1,
      ForgeTier.sound => 0,
      ForgeTier.fine => 1,
      ForgeTier.masterwork => 2,
    };

/// What [tier] does to a piece's resale price, as a factor.
double forgeResaleFactor(ForgeTier tier) => switch (tier) {
      ForgeTier.flawed => 0.75,
      ForgeTier.sound => 1.0,
      ForgeTier.fine => 1.25,
      ForgeTier.masterwork => 1.5,
    };

/// The string key of [tier]'s name ("Fine").
String forgeTierLabelKey(ForgeTier tier) => 'forge_tier_${tier.name}';

/// The race whose forge lore adds [dwarfForgeBonus].
const String dwarfRaceId = 'dwarf';
const int dwarfForgeBonus = 2;

/// Standing with the forge place's holder: [friendlyForgeBonus] at
/// Friendly or better, [unfriendlyForgePenalty] at Unfriendly or worse.
const int friendlyForgeBonus = 1;
const int unfriendlyForgePenalty = -1;

/// One thing added to the forge's d20: where it comes from ([source]:
/// `dwarf`, `standing`), the string key naming it ([labelKey]), its
/// [value], and the clan it is about ([clanId], '' for none).
class ForgeModifier {
  const ForgeModifier({
    required this.source,
    required this.labelKey,
    required this.value,
    this.clanId = '',
  });

  final String source;
  final String labelKey;
  final int value;
  final String clanId;

  /// Its label in [language] ("Dwarf", "Friends of the Cinder Compact"),
  /// the clan named from [clans].
  String labelFor(AppLanguage language, {ClanData? clans}) {
    final faction = clans?.faction(clanId);
    return trFor(language, labelKey)
        .replaceAll('{clan}', faction?.nameFor(language) ?? clanId)
        .replaceAll('{of}', faction?.nameOfFor(language) ?? clanId);
  }

  @override
  bool operator ==(Object other) =>
      other is ForgeModifier &&
      other.source == source &&
      other.labelKey == labelKey &&
      other.value == value &&
      other.clanId == clanId;

  @override
  int get hashCode => Object.hash(source, labelKey, value, clanId);

  @override
  String toString() => 'ForgeModifier($source $value $clanId)';
}

/// The modifiers on a forge roll for a hero of [raceId] at a forge whose
/// place [holderId] holds ('' for none), the hero standing at
/// [holderTier] with that clan.
List<ForgeModifier> forgeModifiersFor({
  String raceId = '',
  String holderId = '',
  StandingTier? holderTier,
}) =>
    [
      if (raceId == dwarfRaceId)
        const ForgeModifier(
            source: 'dwarf',
            labelKey: 'forge_mod_dwarf',
            value: dwarfForgeBonus),
      if (holderId.isNotEmpty && holderTier != null)
        if (holderTier.isAtLeast(StandingTier.friendly))
          ForgeModifier(
              source: 'standing',
              labelKey: 'forge_mod_friends',
              value: friendlyForgeBonus,
              clanId: holderId)
        else if (!holderTier.isAtLeast(StandingTier.wary))
          ForgeModifier(
              source: 'standing',
              labelKey: 'forge_mod_distrust',
              value: unfriendlyForgePenalty,
              clanId: holderId),
    ];

/// The chance of each tier over a fair d20 with [modifierTotal] added.
Map<ForgeTier, double> forgeOdds(int modifierTotal) {
  final counts = {for (final t in ForgeTier.values) t: 0};
  for (var face = 1; face <= 20; face++) {
    final tier = forgeTierFor(face + modifierTotal);
    counts[tier] = counts[tier]! + 1;
  }
  return {for (final e in counts.entries) e.key: e.value / 20};
}

/// One forge roll: the d20's [face], the [modifiers] added, the [total],
/// the [tier] it lands in, and the [odds] of each tier those modifiers
/// gave before the roll.
class ForgeRoll {
  ForgeRoll({required this.face, this.modifiers = const []})
      : modifierTotal = modifiers.fold(0, (n, m) => n + m.value) {
    total = face + modifierTotal;
    tier = forgeTierFor(total);
    odds = forgeOdds(modifierTotal);
  }

  final int face;
  final List<ForgeModifier> modifiers;
  final int modifierTotal;
  late final int total;
  late final ForgeTier tier;
  late final Map<ForgeTier, double> odds;
}

/// Rolls the forge's d20 on [random] with [modifiers].
ForgeRoll rollForge({
  required Random random,
  List<ForgeModifier> modifiers = const [],
}) =>
    ForgeRoll(face: random.nextInt(20) + 1, modifiers: modifiers);

// --- Variants ------------------------------------------------------------

/// The separator between a base id and its tier in a variant id.
const String forgeVariantSeparator = '@';

/// The id a piece of [baseId] forged at [tier] takes: the base id for
/// Sound, `<baseId>@<tier>` otherwise.
String forgedVariantId(String baseId, ForgeTier tier) => tier == ForgeTier.sound
    ? baseId
    : '$baseId$forgeVariantSeparator${tier.name}';

/// [id] read as a forged piece: its base id and tier (Sound for a plain
/// id), or null for an id with an unknown tier after the separator.
({String baseId, ForgeTier tier})? parseForgedId(String id) {
  final at = id.lastIndexOf(forgeVariantSeparator);
  if (at < 0) return (baseId: id, tier: ForgeTier.sound);
  final name = id.substring(at + 1);
  final tier = ForgeTier.values.where((t) => t.name == name).firstOrNull;
  if (tier == null || tier == ForgeTier.sound) return null;
  return (baseId: id.substring(0, at), tier: tier);
}

/// The base item id of [id] (itself when it is no variant).
String baseItemIdOf(String id) => parseForgedId(id)?.baseId ?? id;

/// The field holding [item]'s main number: `attackDamage` for a weapon
/// that strikes (or any piece with damage and no armour), else `armor`.
String forgeMainStatOf(Map<String, dynamic> item) {
  final attack = (item['attackDamage'] as num?)?.toInt() ?? 0;
  final armor = (item['armor'] as num?)?.toInt() ?? 0;
  if (attack > 0 && (item['itemType']?.toString() == 'Weapon' || armor <= 0)) {
    return 'attackDamage';
  }
  return 'armor';
}

/// [name] with [tier]'s mark in [language] ("Fine Iron-Shod Boots",
/// « Bottes ferrées (belle facture) »); [name] itself for Sound.
String forgedNameFor(String name, ForgeTier tier, AppLanguage language) =>
    tier == ForgeTier.sound
        ? name
        : trFor(language, 'forged_name_${tier.name}')
            .replaceAll('{item}', name);

/// What a shop pays for [base] forged at [tier] (sellPriceFor, by
/// [forgeResaleFactor]), at least 1 gold.
int forgedResalePrice(Map<String, dynamic>? base, ForgeTier tier) =>
    max(1, (sellPriceFor(base) * forgeResaleFactor(tier)).round());

/// [base] (item [baseId]) as forged at [tier]: its main number moved by
/// [forgeStatChange] (never below 0), its name marked (English in
/// `itemName`, French in `itemName_fr`; [french] when [base] already
/// carries its French text in `itemName`), its resale price in
/// `sellValue`, and no recipe of its own.
Map<String, dynamic> forgedVariantOf(
  String baseId,
  Map<String, dynamic> base,
  ForgeTier tier, {
  bool french = false,
}) {
  if (tier == ForgeTier.sound) return base;
  final stat = forgeMainStatOf(base);
  final value = (base[stat] as num?)?.toInt() ?? 0;
  final name = base['itemName']?.toString() ?? baseId;
  final nameFr = base['itemName_fr']?.toString() ?? name;
  return {
    for (final e in base.entries)
      if (!const {'craftedAt', 'craftGold', 'craftMaterials'}.contains(e.key))
        e.key: e.value,
    'id': forgedVariantId(baseId, tier),
    'forgedFrom': baseId,
    'forgeTier': tier.name,
    stat: max(0, value + forgeStatChange(tier)),
    'itemName':
        forgedNameFor(name, tier, french ? AppLanguage.fr : AppLanguage.en),
    'itemName_fr': forgedNameFor(nameFr, tier, AppLanguage.fr),
    'sellValue': forgedResalePrice(base, tier),
  };
}

/// An items table (items.json) that also answers for forged variants: a
/// lookup of `<baseId>@<tier>` gives [forgedVariantOf] its base. Its keys,
/// and so any walk over it, are the base items only.
class ForgedItems extends MapBase<String, dynamic> {
  ForgedItems(this.base, {this.french = false});

  final Map<String, dynamic> base;

  /// Whether [base] carries its French text in its English fields.
  final bool french;

  final Map<String, Map<String, dynamic>> _variants = {};

  @override
  dynamic operator [](Object? key) {
    final own = base[key];
    if (own != null || key is! String) return own;
    final cached = _variants[key];
    if (cached != null) return cached;
    final parsed = parseForgedId(key);
    if (parsed == null || parsed.tier == ForgeTier.sound) return null;
    final record = base[parsed.baseId];
    if (record is! Map<String, dynamic>) return null;
    return _variants[key] =
        forgedVariantOf(parsed.baseId, record, parsed.tier, french: french);
  }

  @override
  bool containsKey(Object? key) => this[key] != null || base.containsKey(key);

  @override
  void operator []=(String key, dynamic value) {
    base[key] = value;
    _variants.clear();
  }

  @override
  void clear() {
    base.clear();
    _variants.clear();
  }

  @override
  Iterable<String> get keys => base.keys;

  @override
  dynamic remove(Object? key) {
    _variants.clear();
    return base.remove(key);
  }
}

/// [records] as an items table that resolves forged variants (see
/// [ForgedItems]); [french] when its English fields hold the French text.
Map<String, dynamic> withForgedVariants(Map<String, dynamic> records,
    {bool french = false}) {
  if (records is ForgedItems && records.french == french) return records;
  return ForgedItems(records is ForgedItems ? records.base : records,
      french: french);
}

/// A piece before and after the forge's [tier]: the main number's field
/// ([stat]), its value [before] and [after], and the resale price before
/// and after.
typedef ForgedPieceChange = ({
  String stat,
  int before,
  int after,
  int resaleBefore,
  int resaleAfter,
});

/// [base] as listed, and as forged at [tier] (see [ForgedPieceChange]).
ForgedPieceChange forgedPieceBeforeAfter(
    Map<String, dynamic> base, ForgeTier tier) {
  final stat = forgeMainStatOf(base);
  final before = (base[stat] as num?)?.toInt() ?? 0;
  return (
    stat: stat,
    before: before,
    after: max(0, before + forgeStatChange(tier)),
    resaleBefore: sellPriceFor(base),
    resaleAfter: tier == ForgeTier.sound
        ? sellPriceFor(base)
        : forgedResalePrice(base, tier),
  );
}

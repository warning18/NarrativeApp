import '../l10n/app_locale.dart';

/// Item sets and unique effects -- the build-defining half of itemization
/// on top of the flat attack/armor/element numbers gear already carries.
///
/// A set (see `assets/gamedata/item_sets.json`) names a few items that,
/// worn together, add bonuses at two and three pieces; a unique item
/// carries one [UniqueEffect] of its own (`uniqueEffect`/`uniqueValue` on
/// the items.json record). Both resolve through [gearEffectsFor] into one
/// [GearEffects] value a fight reads once per party member, so the fight
/// screen, the in-app simulator and the character sheet all agree on what
/// a loadout does.

/// The one-of-a-kind behaviors a unique item can carry.
enum UniqueEffect {
  /// Heals the wearer for `uniqueValue`% of the damage each of their hits
  /// deals.
  lifesteal,

  /// An enemy whose hit connects takes `uniqueValue` damage back.
  thorns,

  /// Once per fight, a blow that would drop the wearer leaves them at 1 HP
  /// instead.
  secondWind,

  /// Each damaging hit the wearer lands restores `uniqueValue` mana to
  /// the party pool.
  manaOnHit,

  /// A flat `uniqueValue`% added to the wearer's critical-hit chance.
  critChance,

  /// A flat `uniqueValue`% added to the wearer's dodge chance.
  dodgeChance,
}

UniqueEffect? uniqueEffectFromName(String? name) => switch (name) {
      'lifesteal' => UniqueEffect.lifesteal,
      'thorns' => UniqueEffect.thorns,
      'secondWind' => UniqueEffect.secondWind,
      'manaOnHit' => UniqueEffect.manaOnHit,
      'critChance' => UniqueEffect.critChance,
      'dodgeChance' => UniqueEffect.dodgeChance,
      _ => null,
    };

/// The l10n key describing [effect] (takes the value as a `{v}`
/// placeholder, see [describeUniqueEffect]).
String uniqueEffectDescriptionKey(UniqueEffect effect) => switch (effect) {
      UniqueEffect.lifesteal => 'unique_lifesteal_desc',
      UniqueEffect.thorns => 'unique_thorns_desc',
      UniqueEffect.secondWind => 'unique_second_wind_desc',
      UniqueEffect.manaOnHit => 'unique_mana_on_hit_desc',
      UniqueEffect.critChance => 'unique_crit_desc',
      UniqueEffect.dodgeChance => 'unique_dodge_desc',
    };

/// [item]'s unique effect, if it carries one.
UniqueEffect? uniqueEffectOf(Map<String, dynamic>? item) =>
    uniqueEffectFromName(item?['uniqueEffect']?.toString());

int uniqueValueOf(Map<String, dynamic>? item) =>
    (item?['uniqueValue'] as num?)?.toInt() ?? 0;

/// One threshold of a set's bonuses -- what [pieces] worn pieces grant.
class SetBonusTier {
  const SetBonusTier({
    required this.pieces,
    this.attackDamage = 0,
    this.armor = 0,
    this.critChance = 0,
    this.dodgeChance = 0,
    this.thorns = 0,
    this.lifestealPercent = 0,
    this.manaOnHit = 0,
    this.description = '',
    this.descriptionFr,
  });

  final int pieces;
  final int attackDamage;
  final int armor;
  final int critChance;
  final int dodgeChance;
  final int thorns;
  final int lifestealPercent;
  final int manaOnHit;
  final String description;
  final String? descriptionFr;

  String descriptionFor(AppLanguage language) =>
      language == AppLanguage.fr && (descriptionFr?.isNotEmpty ?? false)
          ? descriptionFr!
          : description;

  factory SetBonusTier.fromJson(Map<String, dynamic> json) => SetBonusTier(
        pieces: (json['pieces'] as num?)?.toInt() ?? 2,
        attackDamage: (json['attackDamage'] as num?)?.toInt() ?? 0,
        armor: (json['armor'] as num?)?.toInt() ?? 0,
        critChance: (json['critChance'] as num?)?.toInt() ?? 0,
        dodgeChance: (json['dodgeChance'] as num?)?.toInt() ?? 0,
        thorns: (json['thorns'] as num?)?.toInt() ?? 0,
        lifestealPercent: (json['lifestealPercent'] as num?)?.toInt() ?? 0,
        manaOnHit: (json['manaOnHit'] as num?)?.toInt() ?? 0,
        description: json['description']?.toString() ?? '',
        descriptionFr: json['descriptionFr']?.toString(),
      );
}

/// A named set of items and the bonuses wearing them together grants.
class ItemSet {
  const ItemSet({
    required this.id,
    required this.name,
    this.nameFr,
    required this.itemIds,
    required this.tiers,
  });

  final String id;
  final String name;
  final String? nameFr;
  final List<String> itemIds;

  /// Ascending by [SetBonusTier.pieces].
  final List<SetBonusTier> tiers;

  String nameFor(AppLanguage language) =>
      language == AppLanguage.fr && (nameFr?.isNotEmpty ?? false)
          ? nameFr!
          : name;

  /// How many of [equippedItemIds] belong to this set.
  int piecesWornIn(List<String> equippedItemIds) =>
      equippedItemIds.where(itemIds.contains).length;

  factory ItemSet.fromJson(String id, Map<String, dynamic> json) {
    final tiers = ((json['bonuses'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => SetBonusTier.fromJson(m.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.pieces.compareTo(b.pieces));
    return ItemSet(
      id: id,
      name: json['setName']?.toString() ?? id,
      nameFr: json['setNameFr']?.toString(),
      itemIds: (json['itemIds'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      tiers: tiers,
    );
  }
}

/// item_sets.json parsed, keyed by set id.
Map<String, ItemSet> parseItemSets(Map<String, dynamic> db) => {
      for (final entry in db.entries)
        if (entry.value is Map)
          entry.key: ItemSet.fromJson(
              entry.key, (entry.value as Map).cast<String, dynamic>()),
    };

/// The set [itemId] belongs to, if any -- by the item's own `setId` field
/// or by appearing in a set's item list.
ItemSet? setForItem(
    String itemId, Map<String, dynamic>? item, Map<String, ItemSet> sets) {
  final setId = item?['setId']?.toString() ?? '';
  if (setId.isNotEmpty && sets[setId] != null) return sets[setId];
  for (final set in sets.values) {
    if (set.itemIds.contains(itemId)) return set;
  }
  return null;
}

/// Everything a loadout's sets and uniques add up to for one combatant.
class GearEffects {
  const GearEffects({
    this.attackDamage = 0,
    this.armor = 0,
    this.critChance = 0,
    this.dodgeChance = 0,
    this.lifestealPercent = 0,
    this.thorns = 0,
    this.manaOnHit = 0,
    this.secondWind = false,
  });

  static const GearEffects none = GearEffects();

  final int attackDamage;
  final int armor;

  /// Percentage points added to the crit / dodge rolls.
  final double critChance;
  final double dodgeChance;

  final int lifestealPercent;
  final int thorns;
  final int manaOnHit;
  final bool secondWind;

  bool get isEmpty =>
      attackDamage == 0 &&
      armor == 0 &&
      critChance == 0 &&
      dodgeChance == 0 &&
      lifestealPercent == 0 &&
      thorns == 0 &&
      manaOnHit == 0 &&
      !secondWind;

  /// The health a [damage]-point hit gives back through lifesteal.
  int lifestealFor(int damage) => damage <= 0 || lifestealPercent <= 0
      ? 0
      : (damage * lifestealPercent / 100).round();
}

/// One set with pieces currently worn, for the inventory and character
/// screens.
class ActiveSet {
  const ActiveSet({required this.set, required this.piecesWorn});

  final ItemSet set;
  final int piecesWorn;

  /// The tiers currently granted.
  List<SetBonusTier> get activeTiers =>
      set.tiers.where((t) => t.pieces <= piecesWorn).toList();
}

/// Every set at least one worn piece belongs to.
List<ActiveSet> activeSetsFor(
    List<String> equippedItemIds, Map<String, ItemSet> sets) {
  final out = <ActiveSet>[];
  for (final set in sets.values) {
    final worn = set.piecesWornIn(equippedItemIds);
    if (worn > 0) out.add(ActiveSet(set: set, piecesWorn: worn));
  }
  return out;
}

/// Sums every set tier the loadout reaches and every unique effect a worn
/// item carries. Pure -- the same call from the fight screen, the in-app
/// simulator and the inventory screen.
GearEffects gearEffectsFor(
  List<String> equippedItemIds,
  Map<String, dynamic> items,
  Map<String, ItemSet> sets,
) {
  var attackDamage = 0;
  var armor = 0;
  var critChance = 0.0;
  var dodgeChance = 0.0;
  var lifesteal = 0;
  var thorns = 0;
  var manaOnHit = 0;
  var secondWind = false;

  for (final id in equippedItemIds) {
    final item = items[id] as Map<String, dynamic>?;
    final effect = uniqueEffectOf(item);
    if (effect == null) continue;
    final value = uniqueValueOf(item);
    switch (effect) {
      case UniqueEffect.lifesteal:
        lifesteal += value;
      case UniqueEffect.thorns:
        thorns += value;
      case UniqueEffect.secondWind:
        secondWind = true;
      case UniqueEffect.manaOnHit:
        manaOnHit += value;
      case UniqueEffect.critChance:
        critChance += value;
      case UniqueEffect.dodgeChance:
        dodgeChance += value;
    }
  }

  for (final active in activeSetsFor(equippedItemIds, sets)) {
    for (final tier in active.activeTiers) {
      attackDamage += tier.attackDamage;
      armor += tier.armor;
      critChance += tier.critChance;
      dodgeChance += tier.dodgeChance;
      thorns += tier.thorns;
      lifesteal += tier.lifestealPercent;
      manaOnHit += tier.manaOnHit;
    }
  }

  return GearEffects(
    attackDamage: attackDamage,
    armor: armor,
    critChance: critChance,
    dodgeChance: dodgeChance,
    lifestealPercent: lifesteal,
    thorns: thorns,
    manaOnHit: manaOnHit,
    secondWind: secondWind,
  );
}

import 'dart:math';

/// Pure, RNG-free rules for the Rusty Eel: fitting parts into her slots,
/// and the turn-by-turn ship battle a voyage's raider event opens (see
/// VoyageScreen). A ship has a hull (sink at 0) behind a bulwark that
/// absorbs damage first and regenerates a little each turn.
class ShipCombatant {
  const ShipCombatant({
    required this.hull,
    required this.maxHull,
    required this.shield,
    required this.maxShield,
  });

  final int hull;
  final int maxHull;
  final int shield;
  final int maxShield;

  bool get isAfloat => hull > 0;

  ShipCombatant copyWith({int? hull, int? shield}) => ShipCombatant(
        hull: hull ?? this.hull,
        maxHull: maxHull,
        shield: shield ?? this.shield,
        maxShield: maxShield,
      );
}

/// The bulwark absorbs first; whatever is left reaches the hull, which
/// never drops below 0.
ShipCombatant applyShipDamage(ShipCombatant target, int damage) {
  if (damage <= 0) return target;
  final absorbed = min(target.shield, damage);
  final through = damage - absorbed;
  return target.copyWith(
    shield: target.shield - absorbed,
    hull: max(0, target.hull - through),
  );
}

/// What one installed part does on the player's turn -- read straight
/// off its ship_parts.json record.
class ShipAction {
  const ShipAction({
    required this.partId,
    required this.label,
    required this.labelFr,
    this.damage = 0,
    this.shieldRestore = 0,
    this.hullRepair = 0,
    this.cooldownTurns = 0,
  });

  factory ShipAction.fromPart(String partId, Map<String, dynamic> part) =>
      ShipAction(
        partId: partId,
        label: part['battleActionLabel']?.toString() ??
            part['partName']?.toString() ??
            partId,
        labelFr: part['battleActionLabel_fr']?.toString() ?? '',
        damage: (part['damageAmount'] as num?)?.toInt() ?? 0,
        shieldRestore: (part['shieldRestoreAmount'] as num?)?.toInt() ?? 0,
        hullRepair: (part['hullRepairAmount'] as num?)?.toInt() ?? 0,
        cooldownTurns: (part['cooldownTurns'] as num?)?.toInt() ?? 0,
      );

  final String partId;
  final String label;
  final String labelFr;
  final int damage;
  final int shieldRestore;
  final int hullRepair;
  final int cooldownTurns;

  bool get isAttack => damage > 0;

  /// A part with nothing to do in a fight (pure slot bonus) has no action.
  bool get isUsable => damage > 0 || shieldRestore > 0 || hullRepair > 0;
}

class ShipTurnResult {
  const ShipTurnResult({
    required this.player,
    required this.enemy,
    this.damageDealt = 0,
    this.shieldRestored = 0,
    this.hullRepaired = 0,
  });

  final ShipCombatant player;
  final ShipCombatant enemy;
  final int damageDealt;
  final int shieldRestored;
  final int hullRepaired;
}

/// The player's turn: an attacking part hits the enemy, a bracing part
/// restores the bulwark, a repairing part patches the hull -- a part may
/// do more than one.
ShipTurnResult resolvePlayerShipAction({
  required ShipCombatant player,
  required ShipCombatant enemy,
  required ShipAction action,
}) {
  var p = player;
  var e = enemy;
  var dealt = 0;
  if (action.damage > 0) {
    final before = e.hull + e.shield;
    e = applyShipDamage(e, action.damage);
    dealt = before - (e.hull + e.shield);
  }
  var restored = 0;
  if (action.shieldRestore > 0) {
    final s = min(p.maxShield, p.shield + action.shieldRestore);
    restored = s - p.shield;
    p = p.copyWith(shield: s);
  }
  var repaired = 0;
  if (action.hullRepair > 0) {
    final h = min(p.maxHull, p.hull + action.hullRepair);
    repaired = h - p.hull;
    p = p.copyWith(hull: h);
  }
  return ShipTurnResult(
    player: p,
    enemy: e,
    damageDealt: dealt,
    shieldRestored: restored,
    hullRepaired: repaired,
  );
}

/// The enemy's turn: it fires for [weaponDamage] at the player, then both
/// bulwarks regenerate ([playerShieldRegen] is the ship's own
/// `shieldRegenPerTurn`; an enemy ship regenerates [enemyShieldRegen]).
ShipTurnResult resolveEnemyShipTurn({
  required ShipCombatant player,
  required ShipCombatant enemy,
  required int weaponDamage,
  int playerShieldRegen = 0,
  int enemyShieldRegen = 0,
}) {
  final before = player.hull + player.shield;
  var p = applyShipDamage(player, weaponDamage);
  final dealt = before - (p.hull + p.shield);
  if (p.isAfloat && playerShieldRegen > 0) {
    p = p.copyWith(shield: min(p.maxShield, p.shield + playerShieldRegen));
  }
  var e = enemy;
  if (enemyShieldRegen > 0) {
    e = e.copyWith(shield: min(e.maxShield, e.shield + enemyShieldRegen));
  }
  return ShipTurnResult(player: p, enemy: e, damageDealt: dealt);
}

/// The player's ship as it sets out: base hull/bulwark from ships.json
/// plus every installed part's `maxShieldBonus`; a stored hull of -1 (a
/// fresh save, or just repaired) means full.
ShipCombatant buildPlayerShip({
  required Map<String, dynamic> ship,
  required Map<String, dynamic> parts,
  required List<String> installedPartIds,
  required int currentHull,
}) {
  final maxHull = max(1, (ship['baseMaxHull'] as num?)?.toInt() ?? 100);
  var maxShield = (ship['baseMaxShield'] as num?)?.toInt() ?? 0;
  for (final id in installedPartIds) {
    final part = parts[id] as Map<String, dynamic>?;
    maxShield += (part?['maxShieldBonus'] as num?)?.toInt() ?? 0;
  }
  final hull = currentHull < 0 ? maxHull : min(maxHull, max(0, currentHull));
  return ShipCombatant(
    hull: hull,
    maxHull: maxHull,
    shield: maxShield,
    maxShield: maxShield,
  );
}

ShipCombatant buildEnemyShip(Map<String, dynamic> enemyShip) {
  final hull = max(1, (enemyShip['maxHull'] as num?)?.toInt() ?? 1);
  final shield = max(0, (enemyShip['maxShield'] as num?)?.toInt() ?? 0);
  return ShipCombatant(
      hull: hull, maxHull: hull, shield: shield, maxShield: shield);
}

/// How many parts of [slotType] ('Weapon' / 'Shield' / 'Utility') the ship
/// can carry.
int slotCapacity(Map<String, dynamic> ship, String slotType) {
  switch (slotType) {
    case 'Weapon':
      return (ship['weaponSlots'] as num?)?.toInt() ?? 0;
    case 'Shield':
      return (ship['shieldSlots'] as num?)?.toInt() ?? 0;
    case 'Utility':
      return (ship['utilitySlots'] as num?)?.toInt() ?? 0;
    case 'Sail':
      // The painted sail (see sail_powers.dart): one sigil at a time.
      return (ship['sailSlots'] as num?)?.toInt() ?? 0;
  }
  return 0;
}

int slotsUsed(
  Map<String, dynamic> parts,
  List<String> installedPartIds,
  String slotType,
) =>
    installedPartIds
        .where((id) =>
            (parts[id] as Map<String, dynamic>?)?['slotType']?.toString() ==
            slotType)
        .length;

/// A part fits if it isn't already aboard and its slot type has room.
bool canInstallPart({
  required Map<String, dynamic> ship,
  required Map<String, dynamic> parts,
  required List<String> installedPartIds,
  required String partId,
}) {
  if (installedPartIds.contains(partId)) return false;
  final part = parts[partId] as Map<String, dynamic>?;
  if (part == null) return false;
  final slotType = part['slotType']?.toString() ?? '';
  return slotsUsed(parts, installedPartIds, slotType) <
      slotCapacity(ship, slotType);
}

/// One gold per hull point missing.
int repairCostFor({required int hull, required int maxHull}) =>
    max(0, maxHull - hull);

/// The hull a sunk ship limps home with (a quarter of max, at least 1).
int limpHomeHull(int maxHull) => max(1, (maxHull * 0.25).round());

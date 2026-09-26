/// Combat visual effects: which effect each skill, spell, die face, enemy
/// move and status plays on screen, and in which colors. Pure data and
/// mapping (colors as ARGB ints) so it is testable without Flutter;
/// lib/widgets/combat_vfx.dart draws the styles.
///
/// Every skill and spell names its effect in its own record (`vfx` in
/// skills.json / spells.json, one of [vfxStyleIds]); a record without one
/// falls back to its element and what it does ([fallbackStyleFor]). The
/// style decides the shape and motion, the element the colors, so a Fire
/// heal glows warm and a Void heal dark from the same `heal` style.
library;

import 'status_effect.dart';

enum VfxStyle {
  slash,
  heavySlash,
  pierce,
  whirl,
  claw,
  impact,
  arrow,
  volley,
  bolt,
  lightning,
  flame,
  fireball,
  meteor,
  holyFire,
  frost,
  splash,
  poison,
  smoke,
  wind,
  quake,
  voidRift,
  drain,
  shadow,
  radiance,
  heal,
  shield,
  stoneShield,
  mana,
  shout,
  stun,
  weaken,
  crit,
  miss,
  phase,
}

/// Each style's id as written in the data files' `vfx` field.
const Map<VfxStyle, String> vfxStyleIds = {
  VfxStyle.slash: 'slash',
  VfxStyle.heavySlash: 'heavy_slash',
  VfxStyle.pierce: 'pierce',
  VfxStyle.whirl: 'whirl',
  VfxStyle.claw: 'claw',
  VfxStyle.impact: 'impact',
  VfxStyle.arrow: 'arrow',
  VfxStyle.volley: 'volley',
  VfxStyle.bolt: 'bolt',
  VfxStyle.lightning: 'lightning',
  VfxStyle.flame: 'flame',
  VfxStyle.fireball: 'fireball',
  VfxStyle.meteor: 'meteor',
  VfxStyle.holyFire: 'holy_fire',
  VfxStyle.frost: 'frost',
  VfxStyle.splash: 'splash',
  VfxStyle.poison: 'poison',
  VfxStyle.smoke: 'smoke',
  VfxStyle.wind: 'wind',
  VfxStyle.quake: 'quake',
  VfxStyle.voidRift: 'void_rift',
  VfxStyle.drain: 'drain',
  VfxStyle.shadow: 'shadow',
  VfxStyle.radiance: 'radiance',
  VfxStyle.heal: 'heal',
  VfxStyle.shield: 'shield',
  VfxStyle.stoneShield: 'stone_shield',
  VfxStyle.mana: 'mana',
  VfxStyle.shout: 'shout',
  VfxStyle.stun: 'stun',
  VfxStyle.weaken: 'weaken',
  VfxStyle.crit: 'crit',
  VfxStyle.miss: 'miss',
  VfxStyle.phase: 'phase',
};

/// The style a data id names, or null for an empty or unknown id.
VfxStyle? vfxStyleFromId(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final entry in vfxStyleIds.entries) {
    if (entry.value == id) return entry.key;
  }
  return null;
}

/// The styles a skill or spell may name in its `vfx` field: every style
/// but the ones the fight itself plays (a critical hit, a miss, a boss
/// changing phase, a status landing).
Set<String> get authorableVfxIds => {
      for (final entry in vfxStyleIds.entries)
        if (!_systemStyles.contains(entry.key)) entry.value,
    };

/// [authorableVfxIds] in a stable order, for the data editor's picker.
List<String> get vfxEnumOptions => [
      for (final entry in vfxStyleIds.entries)
        if (!_systemStyles.contains(entry.key)) entry.value,
    ];

const Set<VfxStyle> _systemStyles = {
  VfxStyle.crit,
  VfxStyle.miss,
  VfxStyle.phase,
  VfxStyle.stun,
  VfxStyle.weaken,
};

/// Styles that tend a friend rather than strike a foe.
const Set<VfxStyle> supportVfxStyles = {
  VfxStyle.heal,
  VfxStyle.shield,
  VfxStyle.stoneShield,
  VfxStyle.mana,
  VfxStyle.shout,
};

/// Styles the fight plays for itself, which the tiers leave as they are.
const Set<VfxStyle> systemVfxStyles = _systemStyles;

/// Styles that travel from whoever acts to whoever is hit before landing.
const Set<VfxStyle> projectileStyles = {
  VfxStyle.arrow,
  VfxStyle.bolt,
  VfxStyle.fireball,
  VfxStyle.drain,
};

/// How long a style plays, in milliseconds.
int vfxDurationMs(VfxStyle style) {
  switch (style) {
    case VfxStyle.meteor:
    case VfxStyle.phase:
      return 1000;
    case VfxStyle.fireball:
    case VfxStyle.bolt:
    case VfxStyle.arrow:
    case VfxStyle.drain:
    case VfxStyle.volley:
    case VfxStyle.holyFire:
    case VfxStyle.radiance:
    case VfxStyle.voidRift:
      return 850;
    case VfxStyle.pierce:
    case VfxStyle.miss:
    case VfxStyle.crit:
      return 550;
    default:
      return 700;
  }
}

/// Two colors, ARGB.
class VfxPalette {
  const VfxPalette(this.primary, this.secondary);
  final int primary;
  final int secondary;
}

const Map<String, VfxPalette> _elementPalettes = {
  'None': VfxPalette(0xFFFFFFFF, 0xFFB0BEC5),
  'Fire': VfxPalette(0xFFFF7043, 0xFFFFD54F),
  'Ice': VfxPalette(0xFFB3E5FC, 0xFFFFFFFF),
  'Water': VfxPalette(0xFF4FC3F7, 0xFFB2EBF2),
  'Earth': VfxPalette(0xFFA1887F, 0xFFD7CCC8),
  'Wind': VfxPalette(0xFFC5E1A5, 0xFFE0F7FA),
  'Void': VfxPalette(0xFF7E57C2, 0xFFCE93D8),
  'Light': VfxPalette(0xFFFFF176, 0xFFFFFDE7),
  'Electricity': VfxPalette(0xFF80D8FF, 0xFFFFEB3B),
  // An enemy's plain attack, with no element of its own.
  'Enemy': VfxPalette(0xFFE53935, 0xFFFF8A65),
};

/// Every element with its own colors.
List<String> get vfxElementNames => _elementPalettes.keys.toList();

/// The colors of [element] ('None' for an unknown one).
VfxPalette paletteForElement(String element) =>
    _elementPalettes[element] ?? _elementPalettes['None']!;

/// The colors [style] plays in for [element]: the element's own, except
/// for the styles that always mean the same thing (poison is green, mana
/// blue, a stun gold, a critical hit gold) and the protective and healing
/// styles, which take a soft default when the element has no color.
VfxPalette paletteFor(VfxStyle style, String element) {
  switch (style) {
    case VfxStyle.poison:
      return const VfxPalette(0xFF66BB6A, 0xFFC5E1A5);
    case VfxStyle.mana:
      return const VfxPalette(0xFF3FA3A8, 0xFFB388FF);
    case VfxStyle.stun:
    case VfxStyle.crit:
      return const VfxPalette(0xFFFFD54F, 0xFFFFFFFF);
    case VfxStyle.weaken:
      return const VfxPalette(0xFFEF5350, 0xFF9E9E9E);
    case VfxStyle.miss:
      return const VfxPalette(0xFFBDBDBD, 0xFFFFFFFF);
    case VfxStyle.phase:
      return const VfxPalette(0xFFE53935, 0xFF7E57C2);
    case VfxStyle.smoke:
      return const VfxPalette(0xFF9E9E9E, 0xFFE0E0E0);
    case VfxStyle.heal:
      return element == 'None' || element == 'Water'
          ? const VfxPalette(0xFF66BB6A, 0xFFFFF59D)
          : paletteForElement(element);
    case VfxStyle.shield:
      return element == 'None'
          ? const VfxPalette(0xFF64B5F6, 0xFFE3F2FD)
          : paletteForElement(element);
    case VfxStyle.stoneShield:
      return element == 'None'
          ? paletteForElement('Earth')
          : paletteForElement(element);
    default:
      return paletteForElement(element);
  }
}

/// The style for a record with no `vfx`: by its element and what it does.
VfxStyle fallbackStyleFor({
  required String element,
  bool damages = true,
  bool heals = false,
  StatusEffectType? status,
}) {
  if (!damages && heals) {
    switch (element) {
      case 'Earth':
        return VfxStyle.stoneShield;
      case 'Light':
        return VfxStyle.radiance;
      case 'Water':
        return VfxStyle.splash;
      case 'Fire':
        return VfxStyle.flame;
      default:
        return VfxStyle.heal;
    }
  }
  if (status == StatusEffectType.poison && element == 'None') {
    return VfxStyle.poison;
  }
  switch (element) {
    case 'Fire':
      return VfxStyle.flame;
    case 'Ice':
      return VfxStyle.frost;
    case 'Water':
      return VfxStyle.splash;
    case 'Earth':
      return VfxStyle.quake;
    case 'Wind':
      return VfxStyle.wind;
    case 'Void':
      return VfxStyle.voidRift;
    case 'Light':
      return VfxStyle.radiance;
    case 'Electricity':
      return VfxStyle.lightning;
    default:
      return VfxStyle.slash;
  }
}

/// The style of a skills.json record: its `vfx`, else its fallback.
VfxStyle styleForSkill(Map<String, dynamic>? skill) {
  if (skill == null) return VfxStyle.slash;
  final named = vfxStyleFromId(skill['vfx']?.toString());
  if (named != null) return named;
  final damage = (skill['damageMod'] as num?)?.toInt() ?? 0;
  final multiplier = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
  final heal = (skill['healAmount'] as num?)?.toInt() ?? 0;
  return fallbackStyleFor(
    element: skill['element']?.toString() ?? 'None',
    damages: damage > 0 || multiplier > 1.0 || heal <= 0,
    heals: heal > 0,
    status: statusEffectTypeFromString(skill['inflictsStatus']?.toString()),
  );
}

/// The style of a rolled die face: a plain strike, a raised shield, a
/// heal, mana, a miss, or the linked skill's own for a Skill face.
VfxStyle styleForFace(String faceType, Map<String, dynamic>? linkedSkill) {
  switch (faceType) {
    case 'Attack':
      return VfxStyle.slash;
    case 'Defend':
      return VfxStyle.shield;
    case 'Heal':
      return VfxStyle.heal;
    case 'Mana':
      return VfxStyle.mana;
    case 'Skill':
      return styleForSkill(linkedSkill);
    default:
      return VfxStyle.miss;
  }
}

/// The style of a spell: its `vfx`, else by its element and effect
/// ('Damage', 'Heal', 'Block', 'Cleanse', 'Status').
VfxStyle styleForSpell({
  String? vfx,
  required String element,
  required String effect,
}) {
  final named = vfxStyleFromId(vfx);
  if (named != null) return named;
  switch (effect.toLowerCase()) {
    case 'heal':
      return fallbackStyleFor(element: element, damages: false, heals: true);
    case 'block':
      return VfxStyle.shield;
    case 'cleanse':
      return VfxStyle.splash;
    default:
      return fallbackStyleFor(element: element);
  }
}

/// Whether a skill is above all a heal: it restores health and adds
/// nothing to the strike it rides on. Its effect then plays on the one who
/// uses it, and the base damage every Skill face still deals lands on the
/// enemy as a plain blow.
bool isSupportSkill(Map<String, dynamic>? skill) {
  if (skill == null) return false;
  final heal = (skill['healAmount'] as num?)?.toInt() ?? 0;
  final damageMod = (skill['damageMod'] as num?)?.toInt() ?? 0;
  final multiplier = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
  return heal > 0 && damageMod <= 0 && multiplier <= 1.0;
}

/// The style an enemy move plays: its skill's, or a plain claw-and-blade
/// strike for a base attack.
VfxStyle styleForEnemyMove(String skillId, Map<String, dynamic> skills) =>
    skillId.isEmpty
        ? VfxStyle.claw
        : styleForSkill(skills[skillId] as Map<String, dynamic>?);

/// The style a status plays as it lands, or as poison ticks.
VfxStyle styleForStatus(StatusEffectType type) {
  switch (type) {
    case StatusEffectType.poison:
      return VfxStyle.poison;
    case StatusEffectType.stun:
      return VfxStyle.stun;
    case StatusEffectType.weaken:
      return VfxStyle.weaken;
  }
}

// --- Power -----------------------------------------------------------------

/// How strongly an effect plays: a light touch, an ordinary blow, a strong
/// one, a mighty one (see [vfxPowerFor] and [vfxTierFor]). The same style
/// grows with it: bigger, with more particles, a little longer, and with
/// details only the stronger tiers get (a shockwave, embers, a flash of
/// the whole screen).
enum VfxTier { light, normal, strong, mighty }

/// A skill's rarity as a starting power.
const Map<String, double> _rarityPower = {
  'common': 0.85,
  'uncommon': 1.0,
  'rare': 1.15,
  'epic': 1.3,
  'legendary': 1.45,
};

/// The weakest and strongest an effect ever plays.
const double minVfxPower = 0.65;
const double maxVfxPower = 1.9;

/// The most an effect grows in size; past it, power shows in its details
/// (more particles, a shockwave, a flash) and its length.
const double maxVfxScale = 1.4;

/// How strongly one effect plays, from [minVfxPower] to [maxVfxPower]
/// (1 is an ordinary blow):
/// - what it is: a skill by its [rarity] (common 0.85 to legendary 1.45),
///   a spell by its [manaCost] (2 mana 1.05, 4 mana 1.25), a plain die
///   face 0.9;
/// - how far the skill is upgraded ([tier], +0.08 each);
/// - how hard it lands: [amount] against the [targetMaxHealth] (a third of
///   the target's health +0.25, a scratch under 4% -0.15), or the amount
///   alone when the target's health is unknown;
/// - a [critical] hit +0.2, a [boss] striking +0.15.
double vfxPowerFor({
  String? rarity,
  int manaCost = 0,
  int tier = 0,
  int amount = 0,
  int targetMaxHealth = 0,
  bool critical = false,
  bool boss = false,
}) {
  var power = rarity != null && _rarityPower.containsKey(rarity)
      ? _rarityPower[rarity]!
      : manaCost > 0
          ? 0.85 + 0.1 * manaCost
          : 0.9;
  power += 0.08 * tier.clamp(0, 5);
  if (amount > 0) {
    if (targetMaxHealth > 0) {
      final share = amount / targetMaxHealth;
      if (share >= 0.3) {
        power += 0.25;
      } else if (share >= 0.18) {
        power += 0.15;
      } else if (share < 0.04) {
        power -= 0.15;
      } else if (share < 0.08) {
        power -= 0.05;
      }
    } else if (amount >= 40) {
      power += 0.25;
    } else if (amount >= 25) {
      power += 0.15;
    } else if (amount <= 5) {
      power -= 0.15;
    }
  }
  if (critical) power += 0.2;
  if (boss) power += 0.15;
  return power.clamp(minVfxPower, maxVfxPower).toDouble();
}

/// The tier a [power] plays at.
VfxTier vfxTierFor(double power) {
  if (power < 0.9) return VfxTier.light;
  if (power < 1.2) return VfxTier.normal;
  if (power < 1.45) return VfxTier.strong;
  return VfxTier.mighty;
}

/// A tier's representative power, for playing a tier on purpose (the
/// Edit Mode effects gallery).
double vfxPowerOfTier(VfxTier tier) => switch (tier) {
      VfxTier.light => 0.75,
      VfxTier.normal => 1.0,
      VfxTier.strong => 1.3,
      VfxTier.mighty => 1.65,
    };

/// How many more (or fewer) particles a tier throws.
double vfxCountFactor(VfxTier tier) => switch (tier) {
      VfxTier.light => 0.6,
      VfxTier.normal => 1.0,
      VfxTier.strong => 1.4,
      VfxTier.mighty => 1.8,
    };

/// How much longer (or shorter) a tier plays.
double vfxDurationFactor(VfxTier tier) => switch (tier) {
      VfxTier.light => 0.85,
      VfxTier.normal => 1.0,
      VfxTier.strong => 1.12,
      VfxTier.mighty => 1.3,
    };

/// When, in a style's own time (0 to 1), its blow lands: a projectile on
/// arrival, a meteor as it falls, a beam as it reaches the ground,
/// anything else almost at once. The strong tiers' flash and shockwave
/// start here.
double vfxImpactAt(VfxStyle style) {
  switch (style) {
    case VfxStyle.arrow:
    case VfxStyle.bolt:
    case VfxStyle.fireball:
    case VfxStyle.volley:
      return 0.45;
    case VfxStyle.meteor:
      return 0.4;
    case VfxStyle.holyFire:
    case VfxStyle.radiance:
      return 0.3;
    case VfxStyle.lightning:
      return 0.05;
    default:
      return 0.12;
  }
}

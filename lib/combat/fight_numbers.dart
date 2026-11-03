// The fight's own numbers that the simulator plays by too (sim_combat.dart,
// sim_companions.dart): one place, so the two never drift apart.

/// HP a healing potion restores, before a perk's and a sign's bonus.
const int potionHealAmount = 8;

/// The rolls a party member has each turn, before a perk's extra ones.
const int maxRollsPerTurn = 3;

/// A knocked-out ally is back at this share of their max health after a
/// won fight.
const double reviveHealthFraction = 0.3;

/// Per-member health and damage multiplier for a multi-enemy pack, by pack
/// size. A pack's threat is its action economy -- two or three hits a
/// round against one party's worth of rolls -- so each member is scaled
/// down to keep the fight winnable for a party at the pack's own chapter
/// level (unscaled, three chapter-2 heavies were a 0% fight at level 3; at
/// 0.85/0.75 a pair of mid-tier enemies was still the worst random fight in
/// the game). Solo fights are never scaled.
const Map<int, double> packStatMultipliers = {2: 0.8, 3: 0.7};

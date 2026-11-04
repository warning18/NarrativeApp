// The clans' dice (the user's rules, v1.676, docs/proposals/clan-dice-gifts.md):
// each main clan has one die (dice.json `clan`), given once a game on its
// banner card from Trusted (offers.dart's GiftKind.die). A clan die
// resonates while its clan is your main clan (sworn, else your patron) and
// you stand Friend or better with it: its faces of value 1 to
// [resonanceMaxFace] count [resonanceBonus] more. Below Friend, or with
// another main clan, it still rolls, without the bonus.
import '../data/clan_crisis.dart' show mainClanOf;
import '../data/factions.dart';

/// The standing a clan's die is given at, on its banner card.
const StandingTier clanDieGiftTier = StandingTier.trusted;

/// The standing a clan die resonates from, with its clan the main one.
const StandingTier resonanceTier = StandingTier.friend;

/// Resonance: faces of value 1 up to this...
const int resonanceMaxFace = 3;

/// ...count this much more.
const int resonanceBonus = 1;

/// The clan [die] (a dice.json record) belongs to; '' for none.
String clanOfDie(Map<String, dynamic>? die) => die?['clan']?.toString() ?? '';

/// The die [factionId] gives (the dice.json record whose `clan` it is),
/// or null when it has none.
String? clanDieOf(String factionId, Map<String, dynamic> dice) {
  if (factionId.isEmpty) return null;
  final ids = [
    for (final e in dice.entries)
      if (e.value is Map<String, dynamic> &&
          clanOfDie(e.value as Map<String, dynamic>) == factionId)
        e.key,
  ]..sort();
  return ids.firstOrNull;
}

/// Where a die stands with Resonance.
enum Resonance {
  /// Not a clan die.
  none,

  /// Lit: its clan is the main one, at Friend or better.
  lit,

  /// Asleep: its clan is not your main clan.
  notMainClan,

  /// Asleep: its clan is your main clan, but you stand below Friend.
  standingLow,
}

/// [die]'s Resonance for a character of [politics] ([data]: the clans).
Resonance resonanceOf(
  Map<String, dynamic>? die, {
  required PoliticsState politics,
  required ClanData data,
}) {
  final clan = clanOfDie(die);
  if (clan.isEmpty) return Resonance.none;
  if (mainClanOf(politics) != clan) return Resonance.notMainClan;
  return politics.tierOf(clan, data).isAtLeast(resonanceTier)
      ? Resonance.lit
      : Resonance.standingLow;
}

/// [faces] as they roll with Resonance lit: each face of value 1 to
/// [resonanceMaxFace] is worth [resonanceBonus] more; the others as they
/// are.
List<Map<String, dynamic>> resonantFaces(List<Map<String, dynamic>> faces) => [
      for (final f in faces)
        if (_resonates(f))
          {...f, 'value': (f['value'] as num).toInt() + resonanceBonus}
        else
          f,
    ];

bool _resonates(Map<String, dynamic> face) {
  final value = (face['value'] as num?)?.toInt() ?? 0;
  return value >= 1 && value <= resonanceMaxFace;
}

import 'dart:math';

/// Enemy squads (v1.215): in a pack, some enemies take a role, so the order
/// the party kills them in becomes a decision.
///
/// - [healer]: mends the most wounded of its friends at the start of the
///   enemies' turn, for [healerHealShare] of that friend's health, but hits
///   [healerDamageMultiplier] as hard. Kill it first, or it undoes your work.
/// - [guard]: while it stands, the party's blows on the other enemies are
///   cut by [guardCoverShare] (a Pierce goes through). Take it down to open
///   the rest.
/// - [striker]: hits [strikerDamageMultiplier] as hard on [strikerHealthMultiplier]
///   of the health. A glass cannon: it dies fast if it is hit.
///
/// About half the packs have roles, and no pack is all roles. Everything
/// here is pure, like enemy_affix.dart.
enum SquadRole { healer, guard, striker }

/// The odds a pack of two or more has roles at all.
const double squadChance = 0.5;

/// The share of a wounded friend's maximum health a healer mends each
/// enemy turn.
const double healerHealShare = 0.12;

const double healerDamageMultiplier = 0.7;
const double guardCoverShare = 0.25;
const double strikerDamageMultiplier = 1.25;
const double strikerHealthMultiplier = 0.8;

/// Rolls the roles of a pack, in enemy order: null for a plain enemy. A pack
/// that rolls no roles has none; one that does gives out at most
/// `packSize - 1` roles, one healer and one guard at most, and only to the
/// enemies [eligible] marks (not a boss, not a unique).
List<SquadRole?> rollSquadRoles({
  required int packSize,
  required List<bool> eligible,
  required Random random,
  double chance = squadChance,
}) {
  final roles = List<SquadRole?>.filled(packSize, null);
  if (packSize < 2 || random.nextDouble() >= chance) return roles;
  final open = [
    for (var i = 0; i < packSize; i++)
      if (i < eligible.length && eligible[i]) i,
  ]..shuffle(random);
  final budget = min(open.length, packSize - 1);
  final pool = <SquadRole>[
    SquadRole.healer,
    SquadRole.guard,
    SquadRole.striker,
  ]..shuffle(random);
  for (var n = 0; n < budget && n < pool.length; n++) {
    roles[open[n]] = pool[n];
  }
  return roles;
}

/// The index of the friend a healer mends: the most wounded by share of its
/// own maximum, among those wounded at all; null when nobody is hurt.
/// [health] and [maxHealth] are the living friends'; [self] is the healer's
/// own index, never mended by itself.
int? squadHealTarget({
  required List<int> health,
  required List<int> maxHealth,
  required int self,
}) {
  int? best;
  var bestShare = 1.0;
  for (var i = 0; i < health.length; i++) {
    if (i == self || health[i] <= 0 || health[i] >= maxHealth[i]) continue;
    final share = health[i] / maxHealth[i];
    if (share < bestShare) {
      bestShare = share;
      best = i;
    }
  }
  return best;
}

/// What a healer mends a friend of [maxHealth] for, at least 1.
int squadHealAmount(int maxHealth) =>
    max(1, (maxHealth * healerHealShare).round());

/// l10n keys of a role's name and one-line rules text.
String squadRoleLabelKey(SquadRole role) => 'squad_${role.name}';
String squadRoleDescriptionKey(SquadRole role) =>
    '${squadRoleLabelKey(role)}_desc';

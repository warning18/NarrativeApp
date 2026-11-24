import 'enemy_affix.dart';

/// How a faction's fighters fight (v1.212): the Dominion's Writ, the Salt
/// Crows' short con. A doctrine is a faction's habit across every fight its
/// people turn up in (enemies.json gives each enemy its `faction`), and is
/// announced on the fight's setup screen:
///
/// - a taste for certain [EnemyAffix]es (its fighters spawn with them
///   likelier);
/// - at most one signature [DoctrineRule].
///
/// A fight against a boss or a unique is never under a doctrine: those are
/// tuned one by one. The doctrines are code, not a table: the enemies are
/// built before any table has loaded. Everything here is pure, like
/// enemy_affix.dart.
enum DoctrineRule {
  /// No signature rule: only the affix taste.
  none,

  /// The Writ: every [_writPeriod]th round, the party's skill faces fall
  /// silent (the Silence of enemy_intent.dart, laid by decree).
  writ,

  /// The short con: each hit one of its fighters lands lifts gold off the
  /// party, carried by that fighter; whatever a fighter still carries when
  /// the fight ends is missing from the spoils. Kill the thief to get it
  /// back.
  plunder,
}

/// The Writ falls on every third round: rounds 3, 6, 9...
const int _writPeriod = 3;

/// The share of an enemy's gold reward each hit it lands as a thief lifts,
/// and the most a thief carries, as a multiple of that reward.
const double _plunderHitShare = 0.35;
const double _plunderStashCap = 2.0;

class Doctrine {
  const Doctrine(this.factionId, this.rule, this.affixes);

  /// The faction (factions.json id) whose fighters follow it.
  final String factionId;
  final DoctrineRule rule;

  /// The affixes the faction's fighters favour.
  final List<EnemyAffix> affixes;

  /// l10n keys of the doctrine's name and one-line rules text.
  String get nameKey => 'doctrine_$factionId';
  String get descriptionKey => 'doctrine_${factionId}_desc';
}

/// Every faction's doctrine, by faction id.
const Map<String, Doctrine> doctrines = {
  'dominion': Doctrine('dominion', DoctrineRule.writ, [EnemyAffix.armored]),
  'crows': Doctrine('crows', DoctrineRule.plunder, [EnemyAffix.skittish]),
  'penitents': Doctrine('penitents', DoctrineRule.none, [EnemyAffix.frenzied]),
  'choir': Doctrine('choir', DoctrineRule.none, [EnemyAffix.armored]),
  'pit': Doctrine('pit', DoctrineRule.none, [EnemyAffix.venomous]),
  'giants': Doctrine('giants', DoctrineRule.none, [EnemyAffix.armored]),
  'tidekin': Doctrine('tidekin', DoctrineRule.none, [EnemyAffix.skittish]),
};

/// The doctrine a fight is under: that of the first enemy with a faction
/// that has one, or null when any enemy is a boss or a unique (those are
/// tuned one by one) or no enemy follows a doctrine. [factions] gives each
/// enemy's faction id in fight order ('' when it has none) and [isBoss]
/// whether it is a boss.
Doctrine? doctrineForFight({
  required List<String> factions,
  required List<bool> isBoss,
}) {
  if (isBoss.any((b) => b)) return null;
  for (final faction in factions) {
    final doctrine = doctrines[faction];
    if (doctrine != null) return doctrine;
  }
  return null;
}

/// True when the Writ silences the party's skill faces in round [round]
/// (1 is the first).
bool writSilencesRound(int round) => round > 0 && round % _writPeriod == 0;

/// The gold one of a thief's hits lifts, given the thief's own gold
/// [reward]: a share of it, at least 1 for any thief with a reward.
int plunderPerHit(int reward) {
  if (reward <= 0) return 0;
  final share = (reward * _plunderHitShare).round();
  return share < 1 ? 1 : share;
}

/// The most a thief with [reward] gold of its own carries.
int plunderCap(int reward) => (reward * _plunderStashCap).round();

/// What a thief with [stash] carries after one more hit that lifts [hit]:
/// never past [cap].
int plunderStashAfter(int stash, int hit, int cap) =>
    stash + hit > cap ? cap : stash + hit;

/// The gold missing from the spoils: what every thief that was not
/// defeated carries off. The winnings never go below zero.
int plunderLoss(
    {required int goldGain, required Iterable<int> escapedStashes}) {
  final lost = escapedStashes.fold<int>(0, (a, b) => a + b);
  return lost > goldGain ? goldGain : lost;
}

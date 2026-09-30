import '../data/approval.dart';

/// Duo techniques (v1.182): two companions who get along fight as one. When
/// both are in the fight with at least [duoApprovalNeeded] approval, and
/// both keep a signature face (one of their die's own skill faces) in the
/// same round, their named move fires after the round's dice, on top of
/// what the two faces do. A companion takes part in one duo a round.
///
/// Each effect is sized off the pair's combined base damage (see
/// [duoPower]), so a duo grows with the party.
enum DuoEffect {
  /// The target takes the pair's power and is Stunned for a turn.
  stunBlow,

  /// The target takes the pair's power as a critical and is Poisoned.
  poisonCrit,

  /// Every party member mends [duoHealShare] of their max health and is
  /// cleansed.
  partyHeal,

  /// Every enemy standing takes [duoVolleyShare] of the pair's power.
  starfall,

  /// Every enemy standing is Weakened and takes half the pair's power.
  weakenAll,

  /// Every party member gains half the pair's power as block.
  partyWard,

  /// The most wounded party member mends [duoMendShare] of their max
  /// health, and the target takes the pair's power.
  mercyShot,

  /// The target takes [duoOathMultiplier] of the pair's power, and the two
  /// share half of what lands as health.
  bloodOath,
}

/// The approval both companions need (the friendly tier, see approval.dart).
const int duoApprovalNeeded = friendlyApproval;

const double duoHealShare = 0.2;
const double duoVolleyShare = 0.75;
const double duoMendShare = 0.3;
const double duoOathMultiplier = 1.25;

/// A Weaken a duo lays: 2 turns, 25% less damage.
const int duoWeakenTurns = 2;
const int duoWeakenPercent = 25;

/// A Poison a duo lays: 3 turns, a fifth of the blow each turn (at least 3).
const int duoPoisonTurns = 3;

class DuoTechnique {
  const DuoTechnique({
    required this.id,
    required this.first,
    required this.second,
    required this.effect,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
  });

  final String id;

  /// The two companions (companions.json ids), in no particular order.
  final String first;
  final String second;
  final DuoEffect effect;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;

  bool pairs(String a, String b) =>
      (first == a && second == b) || (first == b && second == a);

  bool involves(String companionId) =>
      first == companionId || second == companionId;

  String nameFor(bool french) => french ? nameFr : nameEn;
  String descriptionFor(bool french) => french ? descriptionFr : descriptionEn;
}

/// Every duo, one per pair that fights well together: the two warriors,
/// the two rogues, the two clerics, the two dwarves, the two orcs, and the
/// pairs the Void, the woods and the dawn bring together. Tobin and Malrik
/// never share a party (their alignments part them), so neither pair
/// needs the other.
const List<DuoTechnique> duoTechniques = [
  DuoTechnique(
    id: 'anvil_and_hammer',
    first: 'grosh',
    second: 'kelda',
    effect: DuoEffect.stunBlow,
    nameEn: 'Anvil and Hammer',
    nameFr: "L'Enclume et le Marteau",
    descriptionEn:
        'One holds the enemy in place, the other brings the weight down: the '
        'target is struck and stunned for a turn.',
    descriptionFr:
        "Un bras tient l'ennemi en place, l'autre abat tout son poids : la "
        'cible est frappée et étourdie pour un tour.',
  ),
  DuoTechnique(
    id: 'knives_in_the_dark',
    first: 'sable',
    second: 'malrik',
    effect: DuoEffect.poisonCrit,
    nameEn: 'Knives in the Dark',
    nameFr: "Couteaux dans l'ombre",
    descriptionEn:
        'Two blades from two sides, both where it hurts: a critical strike '
        'that leaves the target poisoned.',
    descriptionFr:
        'Deux lames, deux côtés, toutes deux là où ça fait mal : un coup '
        'critique qui laisse la cible empoisonnée.',
  ),
  DuoTechnique(
    id: 'twin_litany',
    first: 'maren',
    second: 'tobin',
    effect: DuoEffect.partyHeal,
    nameEn: 'Twin Litany',
    nameFr: 'Double litanie',
    descriptionEn:
        'Two prayers in one breath: the whole party mends a fifth of its '
        'health and sheds its afflictions.',
    descriptionFr:
        "Deux prières d'un même souffle : tout le groupe récupère un "
        "cinquième de sa santé et se défait de ses maux.",
  ),
  DuoTechnique(
    id: 'starfall',
    first: 'liora',
    second: 'vess',
    effect: DuoEffect.starfall,
    nameEn: 'Starfall',
    nameFr: "Pluie d'étoiles",
    descriptionEn:
        'An arrow for every spark Vess lights: every enemy standing is hit.',
    descriptionFr:
        'Une flèche pour chaque étincelle que Vess allume : chaque ennemi '
        'encore debout est touché.',
  ),
  DuoTechnique(
    id: 'umbral_snare',
    first: 'vess',
    second: 'sable',
    effect: DuoEffect.weakenAll,
    nameEn: 'Umbral Snare',
    nameFr: 'Collet ombral',
    descriptionEn:
        'The shadows close on every enemy at once: all of them are weakened '
        'and hurt.',
    descriptionFr:
        "Les ombres se referment sur tous les ennemis d'un coup : tous sont "
        'affaiblis et blessés.',
  ),
  DuoTechnique(
    id: 'stonewall',
    first: 'kelda',
    second: 'tobin',
    effect: DuoEffect.partyWard,
    nameEn: 'Stonewall',
    nameFr: 'Mur de pierre',
    descriptionEn: 'Two dwarves, one wall: every party member gains a guard.',
    descriptionFr:
        'Deux nains, un seul mur : chaque membre du groupe gagne une garde.',
  ),
  DuoTechnique(
    id: 'dawn_watch',
    first: 'maren',
    second: 'liora',
    effect: DuoEffect.mercyShot,
    nameEn: 'Dawn Watch',
    nameFr: "Veille de l'aube",
    descriptionEn:
        'Maren kneels by the worst hurt while Liora covers her: the most '
        'wounded mends, and the target is shot.',
    descriptionFr:
        "Maren s'agenouille près du membre du groupe le plus blessé pendant "
        'que Liora la couvre : ce membre se soigne, et la cible est touchée.',
  ),
  DuoTechnique(
    id: 'blood_oath',
    first: 'grosh',
    second: 'malrik',
    effect: DuoEffect.bloodOath,
    nameEn: 'Blood Oath',
    nameFr: 'Serment de sang',
    descriptionEn:
        'An old orc promise, kept with both hands: a heavy blow, and half '
        'of what lands heals the two.',
    descriptionFr:
        'Une vieille promesse orque, tenue à deux mains : un coup lourd, '
        'dont la moitié soigne les deux.',
  ),
];

/// A companion's part in a round: their kept face is a signature face, and
/// how much they like the player.
class DuoCandidate {
  const DuoCandidate({
    required this.companionId,
    required this.approval,
    required this.onSignatureFace,
  });

  final String companionId;
  final int approval;
  final bool onSignatureFace;

  bool get ready => onSignatureFace && approval >= duoApprovalNeeded;
}

/// The duos that fire this round among [candidates] (the acting
/// companions, in party order): in [duoTechniques] order, each companion in
/// one duo at most.
List<DuoTechnique> duosFiring(List<DuoCandidate> candidates) {
  final ready = {
    for (final c in candidates)
      if (c.ready) c.companionId,
  };
  final used = <String>{};
  final firing = <DuoTechnique>[];
  for (final duo in duoTechniques) {
    if (!ready.contains(duo.first) || !ready.contains(duo.second)) continue;
    if (used.contains(duo.first) || used.contains(duo.second)) continue;
    used
      ..add(duo.first)
      ..add(duo.second);
    firing.add(duo);
  }
  return firing;
}

/// The duo two companions share, if any.
DuoTechnique? duoFor(String a, String b) {
  for (final duo in duoTechniques) {
    if (duo.pairs(a, b)) return duo;
  }
  return null;
}

/// Every duo [companionId] is part of.
List<DuoTechnique> duosOf(String companionId) => [
      for (final duo in duoTechniques)
        if (duo.involves(companionId)) duo
    ];

/// A duo's power: the two companions' base damage added up.
int duoPower(int firstBaseDamage, int secondBaseDamage) =>
    firstBaseDamage + secondBaseDamage;

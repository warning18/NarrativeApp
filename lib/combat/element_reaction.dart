/// Element reactions (v1.214): two different elements striking the same
/// enemy close together react. The first hit primes the enemy with its
/// element for the rest of that round and the next; the second, of a
/// partner element, springs the reaction and uses the prime up. The order
/// of play matters: the bigger hit belongs second, since most reactions
/// scale with the hit that springs them.
///
/// - [conduct] (Water + Electricity): the hit does [conductBonusShare] more
///   and arcs to every other enemy for [conductChainShare].
/// - [shatter] (Fire + Ice): the hit does [shatterBonusShare] more and
///   breaks the enemy's raised guard.
/// - [firestorm] (Fire + Wind): the hit does [firestormBonusShare] more and
///   the blaze catches every other enemy for [firestormSplashShare].
/// - [freeze] (Water + Ice): the enemy is stunned for a turn (a boss
///   shrugs it off).
/// - [sandblast] (Earth + Wind): the enemy is weakened for [weakenTurns]
///   turns.
/// - [eclipse] (Light + Void): the hit does [eclipseBonusShare] more.
///
/// Everything here is pure, like enemy_affix.dart.
enum ElementReaction {
  conduct,
  shatter,
  firestorm,
  freeze,
  sandblast,
  eclipse,
}

/// How many rounds after the priming hit a partner still springs it: the
/// same round and the next.
const int reactionWindowRounds = 1;

const double conductBonusShare = 0.5;
const double conductChainShare = 0.25;
const double shatterBonusShare = 0.6;
const double firestormBonusShare = 0.25;
const double firestormSplashShare = 0.5;
const double eclipseBonusShare = 1.0;

/// The turns a Sandblast weakens for, and the percent it weakens by.
const int weakenTurns = 2;
const int sandblastWeakenPercent = 30;

/// The reaction between elements [a] and [b], in either order, or null.
ElementReaction? reactionBetween(String a, String b) {
  if (a == b) return null;
  final pair = {a, b};
  bool is_(String x, String y) => pair.contains(x) && pair.contains(y);
  if (is_('Water', 'Electricity')) return ElementReaction.conduct;
  if (is_('Fire', 'Ice')) return ElementReaction.shatter;
  if (is_('Fire', 'Wind')) return ElementReaction.firestorm;
  if (is_('Water', 'Ice')) return ElementReaction.freeze;
  if (is_('Earth', 'Wind')) return ElementReaction.sandblast;
  if (is_('Light', 'Void')) return ElementReaction.eclipse;
  return null;
}

/// The elements still priming an enemy in [round]: [marks] maps an element
/// to the round it was struck in.
List<String> activeMarks(Map<String, int> marks, int round) => [
      for (final entry in marks.entries)
        if (round - entry.value <= reactionWindowRounds) entry.key,
    ]..sort();

/// What a hit of [element] springs on an enemy primed with [marks] in
/// [round]: the reaction and the element that primed it, or null.
({ElementReaction reaction, String primer})? reactionOn(
    Map<String, int> marks, String element, int round) {
  if (element == 'None') return null;
  for (final primer in activeMarks(marks, round)) {
    final reaction = reactionBetween(primer, element);
    if (reaction != null) return (reaction: reaction, primer: primer);
  }
  return null;
}

/// The extra damage a reaction adds to the hit [landed] that sprang it.
int reactionBonus(ElementReaction reaction, int landed) {
  final share = switch (reaction) {
    ElementReaction.conduct => conductBonusShare,
    ElementReaction.shatter => shatterBonusShare,
    ElementReaction.firestorm => firestormBonusShare,
    ElementReaction.eclipse => eclipseBonusShare,
    ElementReaction.freeze || ElementReaction.sandblast => 0.0,
  };
  return share <= 0 || landed <= 0
      ? 0
      : (landed * share).round().clamp(1, 1 << 30);
}

/// The share of the hit that reaches every other enemy, or 0.
double reactionSpreadShare(ElementReaction reaction) => switch (reaction) {
      ElementReaction.conduct => conductChainShare,
      ElementReaction.firestorm => firestormSplashShare,
      _ => 0.0,
    };

/// l10n key of the reaction's name.
String reactionLabelKey(ElementReaction reaction) =>
    'reaction_${reaction.name}';

/// l10n key of the reaction's one-line rules text.
String reactionDescriptionKey(ElementReaction reaction) =>
    '${reactionLabelKey(reaction)}_desc';

/// Every element a strike can carry, in the order the game lists them.
const List<String> strikeElements = [
  'Fire',
  'Water',
  'Ice',
  'Electricity',
  'Wind',
  'Earth',
  'Light',
  'Void',
];

/// The elements that react with [element] (in either order), sorted.
List<String> reactionPartners(String element) => [
      for (final other in strikeElements)
        if (reactionBetween(element, other) != null) other,
    ]..sort();

import 'dart:math';

import '../combat/stat_rules.dart' show damageStatOf;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'factions.dart';

/// Risky gifts (docs/proposals/risky-gifts.md): a clan the character is
/// uneasy with (Wary, Unfriendly or Resented), or whose alignment is
/// opposite theirs, may bring a gift one rarity better than it would -- at
/// a price the die names. Most of the time the gift is given; otherwise
/// the character loses health or gold, or wears the clan's curse for two
/// levels. "Nothing" is never a result, and standing rises whatever the
/// die says.
///
/// Off until the Parley Tent is built at camp ([parleyTentHouseId]). The
/// die is rolled when the offer is drawn (offers.dart's drawOffer saves it
/// on the card as `Suitor.riskRoll`), so reopening or reloading never
/// rerolls it; Luck is read when the card is taken.
///
/// Everything here is pure: the draw is offers.dart's, the session applies
/// the result (player_session_provider.dart's acceptSuitor).

/// The camp building that opens risky gifts (houses.json).
const String parleyTentHouseId = 'parley_tent';

/// Odds an offer with at least one qualifying suitor makes one of them
/// risky (one card at most).
const double riskyGiftChance = 0.30;

/// The health penalty: this share of max health, taken from current
/// health, never below 1.
const double riskyHealthShare = 0.40;

/// The gold penalty: this share of the purse, at least
/// [riskyGoldPerChapter] a chapter, never more than the purse.
const double riskyGoldShare = 0.25;
const int riskyGoldPerChapter = 10;

/// The curse: this many points off the clan's stat, for this many levels.
const int riskyCurseAmount = 2;
const int riskyCurseLevels = 2;

/// Whether risky gifts are open: the Parley Tent is built.
bool riskyGiftsOpen(Iterable<String> builtHouseIds) =>
    builtHouseIds.contains(parleyTentHouseId);

/// The alignment word of [score]: Good from 20, Evil to -20 (as
/// PlayerSession.alignmentLabel).
String riskyAlignmentLabel(int score) => score >= 20
    ? 'Good'
    : score <= -20
        ? 'Evil'
        : 'Neutral';

/// Whether a faction leaning [lean] is opposite a character of alignment
/// [score]: a lean +1 clan and an Evil character, a lean -1 clan and a Good
/// one. A Neutral character or a lean 0 clan is never opposite.
bool alignmentOpposite(int lean, int score) {
  final label = riskyAlignmentLabel(score);
  return lean > 0 && label == 'Evil' || lean < 0 && label == 'Good';
}

/// The tiers counted as "uneasy".
const Set<StandingTier> uneasyTiers = {
  StandingTier.wary,
  StandingTier.unfriendly,
  StandingTier.resented,
};

/// Whether [faction] may make its card risky, standing at [tier] with a
/// character of alignment [alignment], [nemesis] being the clan that hunts
/// them ('' for none): a faction with a curse stat (never the Choir or the
/// Pit), neither Hostile nor Hunted, not the nemesis, and either uneasy
/// ([uneasyTiers]) or of the opposite alignment. Being a suitor at all,
/// and not the Wayfarer, the ticket's own faction or the home seat, is
/// drawOffer's to check.
bool riskyEligible(
  Faction faction, {
  required StandingTier tier,
  required int alignment,
  String nemesis = '',
}) =>
    faction.riskStat.isNotEmpty &&
    faction.kind != FactionKind.otherworld &&
    tier.isAtLeast(StandingTier.resented) &&
    faction.id != nemesis &&
    (uneasyTiers.contains(tier) || alignmentOpposite(faction.lean, alignment));

/// The bonus Luck adds to the roll: +1 at 5, +2 at 10 or more.
int riskyLuckBonus(int luck) => min(2, max(0, luck ~/ 5));

/// What the die says, before the fallbacks.
enum RiskyOutcome {
  /// The gift is given.
  gift,

  /// Health lost.
  health,

  /// Gold lost.
  gold,

  /// The clan's curse.
  curse,
}

RiskyOutcome? riskyOutcomeNamed(String? name) =>
    RiskyOutcome.values.where((o) => o.name == name).firstOrNull;

/// The band [roll] (a d20, 1-20) and [luck] fall in: a natural 1, or 2,
/// the health penalty; 3-4 gold; 5 the curse; 6 or more the gift (the
/// Luck bonus added).
RiskyOutcome riskyBandFor(int roll, int luck) {
  if (roll <= 1) return RiskyOutcome.health;
  final total = roll + riskyLuckBonus(luck);
  if (total <= 2) return RiskyOutcome.health;
  if (total <= 4) return RiskyOutcome.gold;
  if (total == 5) return RiskyOutcome.curse;
  return RiskyOutcome.gift;
}

/// The odds of the gift and of a price, in percent, at [luck] (75/25 at
/// Luck 0-4, 80/20 at 5-9, 85/15 from 10).
({int gift, int price}) riskyOddsFor(int luck) {
  var gifts = 0;
  for (var roll = 1; roll <= 20; roll++) {
    if (riskyBandFor(roll, luck) == RiskyOutcome.gift) gifts++;
  }
  final gift = gifts * 5;
  return (gift: gift, price: 100 - gift);
}

/// The ability [faction]'s curse lowers for a hero of [professionId]: its
/// `riskStat`, or Luck when that is the hero's damage stat or Constitution
/// (or the data names none).
String riskyCurseStatFor(Faction? faction, String professionId) {
  final stat = faction?.riskStat ?? '';
  if (stat.isEmpty ||
      stat == 'constitution' ||
      stat == damageStatOf(professionId)) {
    return 'luck';
  }
  return stat;
}

/// What taking a risky card does: [outcome] after the fallbacks, and how
/// much ([amount]: health or gold lost, curse points), [stat] for a curse.
class RiskyResult {
  const RiskyResult(this.outcome, {this.amount = 0, this.stat = ''});

  final RiskyOutcome outcome;
  final int amount;
  final String stat;

  bool get won => outcome == RiskyOutcome.gift;

  @override
  bool operator ==(Object other) =>
      other is RiskyResult &&
      other.outcome == outcome &&
      other.amount == amount &&
      other.stat == stat;

  @override
  int get hashCode => Object.hash(outcome, amount, stat);

  @override
  String toString() => 'RiskyResult(${outcome.name}, $amount, $stat)';
}

/// The health penalty on a character at [currentHealth] of [maxHealth]:
/// [riskyHealthShare] of the max, never below 1 health.
int riskyHealthLoss({required int maxHealth, required int currentHealth}) =>
    max(0, min((maxHealth * riskyHealthShare).round(), currentHealth - 1));

/// The gold penalty on a purse of [gold] in [chapter]: [riskyGoldShare] of
/// it, at least [riskyGoldPerChapter] a chapter, never more than the purse.
int riskyGoldLoss({required int gold, required int chapter}) => max(
    0,
    min(gold,
        max((gold * riskyGoldShare).round(), riskyGoldPerChapter * chapter)));

/// What the die [roll] means for the character now, with the fallbacks:
/// an empty purse turns the gold penalty into the health penalty, and a
/// character at 1 health turns the health penalty into the curse, so
/// "nothing" never happens. [curseStat]: see [riskyCurseStatFor].
RiskyResult riskyResultFor({
  required int roll,
  required int luck,
  required int gold,
  required int chapter,
  required int maxHealth,
  required int currentHealth,
  required String curseStat,
}) {
  var outcome = riskyBandFor(roll, luck);
  if (outcome == RiskyOutcome.gift) return const RiskyResult(RiskyOutcome.gift);
  if (outcome == RiskyOutcome.gold) {
    final lost = riskyGoldLoss(gold: gold, chapter: max(1, chapter));
    if (lost > 0) return RiskyResult(RiskyOutcome.gold, amount: lost);
    outcome = RiskyOutcome.health;
  }
  if (outcome == RiskyOutcome.health) {
    final lost =
        riskyHealthLoss(maxHealth: maxHealth, currentHealth: currentHealth);
    if (lost > 0) return RiskyResult(RiskyOutcome.health, amount: lost);
  }
  return RiskyResult(RiskyOutcome.curse,
      amount: riskyCurseAmount, stat: curseStat);
}

/// A clan's curse on the character: [amount] points off [stat] until
/// [untilLevel] is reached (the second level-up after it was taken).
class RiskCurse {
  const RiskCurse({
    required this.clan,
    required this.stat,
    required this.amount,
    required this.untilLevel,
  });

  final String clan;
  final String stat;
  final int amount;
  final int untilLevel;

  /// How many levels it still lasts at [level].
  int levelsLeftAt(int level) => max(0, untilLevel - level);

  Map<String, dynamic> toJson() => {
        'clan': clan,
        'stat': stat,
        'amount': amount,
        'untilLevel': untilLevel,
      };

  static RiskCurse? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final clan = raw['clan']?.toString() ?? '';
    final stat = raw['stat']?.toString() ?? '';
    final amount = (raw['amount'] as num?)?.toInt() ?? 0;
    final until = (raw['untilLevel'] as num?)?.toInt() ?? 0;
    if (clan.isEmpty || stat.isEmpty || amount <= 0) return null;
    return RiskCurse(clan: clan, stat: stat, amount: amount, untilLevel: until);
  }

  @override
  bool operator ==(Object other) =>
      other is RiskCurse &&
      other.clan == clan &&
      other.stat == stat &&
      other.amount == amount &&
      other.untilLevel == untilLevel;

  @override
  int get hashCode => Object.hash(clan, stat, amount, untilLevel);
}

/// Saved curses (see PlayerSession.riskCurses): an old save has none.
List<RiskCurse> riskCursesFromJson(Object? raw) => [
      for (final c in (raw is List ? raw : const []))
        if (RiskCurse.tryParse(c) case final curse?) curse,
    ];

// --- What the player reads ----------------------------------------------------

/// The odds line of a risky card at [luck] ("Gift 80% · Price 20%").
String riskyOddsText(int luck, AppLanguage lang) {
  final odds = riskyOddsFor(luck);
  return trFor(lang, 'offer_risky_odds')
      .replaceAll('{gift}', '${odds.gift}')
      .replaceAll('{price}', '${odds.price}');
}

/// [name] inside a sentence: its leading article lowered ("the Grey
/// Vigil", « les Corneilles de Sel »).
String _inSentence(String name) {
  for (final article in const ['The ', 'Le ', 'La ', 'Les ', 'L’', "L'"]) {
    if (name.startsWith(article)) {
      return name[0].toLowerCase() + name.substring(1);
    }
  }
  return name;
}

/// The line that tells what the die said ([result]) about [faction]'s
/// risky gift: `offer_risky_gift`, `_health`, `_gold` or `_curse`, with
/// `{clan}` the clan's name (its article lowered inside a sentence, not
/// at its start),
/// `{clanOf}` its "of" form (« du Dominion de la Lanterne »), `{n}` the
/// amount and `{stat}` the stat's own name.
String riskyResultText(RiskyResult result, Faction? faction, AppLanguage lang) {
  final key = switch (result.outcome) {
    RiskyOutcome.gift => 'offer_risky_gift',
    RiskyOutcome.health => 'offer_risky_health',
    RiskyOutcome.gold => 'offer_risky_gold',
    RiskyOutcome.curse => 'offer_risky_curse',
  };
  final text = trFor(lang, key);
  final name = faction?.nameFor(lang) ?? '';
  // A name that opens a sentence keeps its capital.
  final at = text.indexOf('{clan}');
  final before = at < 0 ? '' : text.substring(0, at).trimRight();
  final opens = before.isEmpty || '.!?'.contains(before[before.length - 1]);
  return text
      .replaceAll('{clan}', opens ? name : _inSentence(name))
      .replaceAll('{clanOf}', faction?.nameOfFor(lang) ?? '')
      .replaceAll('{n}', '${result.amount}')
      .replaceAll('{stat}',
          result.stat.isEmpty ? '' : trFor(lang, '${result.stat}_label'));
}

/// The camp's roll houses in the playthrough simulator (camp_rolls.dart,
/// docs/proposals/camp-roll-buildings.md, its simulator section): the
/// charges and bans a walk holds, and the autoplay policy that spends them.
///
/// The powers draw from a [Random] of their own, so a walk without the
/// houses draws exactly as before, and one with them only differs where a
/// power was used.
library;

import 'dart:math';

import 'camp_rolls.dart';
import 'offers.dart';
import 'signs.dart' show SignRarity;
import 'training.dart';

class SimRolls {
  SimRolls(this.random);

  /// The powers' own draw.
  final Random random;

  final Set<RollPower> built = {};
  int reroll = 0;
  int banish = 0;
  int raise = 0;
  int raiseProgress = 0;
  List<RollBan> bans = const [];

  /// What the walk used: `rerolls`, `bans`, `raises` (the sim JSON's
  /// `campRolls`).
  final Map<String, int> used = {'rerolls': 0, 'bans': 0, 'raises': 0};

  void _use(String key) => used[key] = (used[key] ?? 0) + 1;

  /// [power]'s house went up: its charges filled (camp_rolls.dart's
  /// chargesWhenBuilt).
  void build(RollPower? power) {
    if (power == null || !built.add(power)) return;
    switch (power) {
      case RollPower.reroll:
        reroll = chargesWhenBuilt(power);
      case RollPower.banish:
        banish = chargesWhenBuilt(power);
      case RollPower.raise:
        raise = chargesWhenBuilt(power);
    }
  }

  /// [levels] levels gained: +1 Reroll and +1 Banish each, if built.
  void levels(int levels) {
    if (levels <= 0) return;
    if (built.contains(RollPower.reroll)) {
      reroll = min(rerollMaxCharges, reroll + levels);
    }
    if (built.contains(RollPower.banish)) {
      banish = min(banishMaxCharges, banish + levels);
    }
  }

  /// A fresh draw of [on]: its bans count down, the Raise count moves on.
  void freshDraw(RollBanOn on) {
    final next = afterFreshDraw(
        on: on,
        bans: bans,
        raiseBuilt: built.contains(RollPower.raise),
        raise: raise,
        raiseProgress: raiseProgress);
    bans = next.bans;
    raise = next.raise;
    raiseProgress = next.raiseProgress;
  }

  Set<String> banned(RollBanOn on) => bannedIdsOf(bans, on);

  // --- Stat picks ------------------------------------------------------------

  /// The policy on a stat pick [offer] (drawn fresh), for a build that
  /// wants the abilities of [shares], [mainStat] first. [redraw] draws the
  /// set again at a tier (a reroll); [paths] for the replacements and the
  /// raise. Returns the set as worked, and the card to take is chosen by
  /// [choose] on it:
  /// - **Banish** (2 charges or more): a card whose ability the build
  ///   doesn't want, for 5 draws, replaced at once;
  /// - **Reroll:** no card the build wants -- the set drawn again;
  /// - **Raise:** the card taken, when it raises [mainStat].
  List<StatPickOffer> workStatPick(
    List<StatPickOffer> offer, {
    required Set<String> wanted,
    required String mainStat,
    required Map<String, TrainingPath> paths,
    required List<StatPickOffer> Function(SignRarity tier) redraw,
    required int Function(List<StatPickOffer> offer) choose,
  }) {
    var cards = offer;
    bool wants(StatPickOffer o) => wanted.contains(o.stat);
    if (built.contains(RollPower.banish)) {
      for (var i = 0; i < cards.length && banish >= 2; i++) {
        if (wants(cards[i])) continue;
        final draws = banishLengths.first;
        final next = withRollBan(bans,
            RollBan(on: RollBanOn.pick, id: cards[i].pathId, left: draws));
        final card = replaceStatPickOffer(
            offer: cards,
            index: i,
            paths: paths,
            random: random,
            bannedPaths: bannedIdsOf(next, RollBanOn.pick));
        if (card == null) continue;
        bans = next;
        banish -= banishCostOf(draws);
        cards = [...cards]..[i] = card;
        _use('bans');
      }
    }
    while (
        built.contains(RollPower.reroll) && reroll > 0 && !cards.any(wants)) {
      final again = redraw(cards.first.tier);
      if (again.isEmpty) break;
      cards = again;
      reroll--;
      _use('rerolls');
    }
    if (built.contains(RollPower.raise) && raise > 0) {
      final at = choose(cards);
      if (at >= 0 && at < cards.length && cards[at].stat == mainStat) {
        final raised = raisedStatPickOffer(cards[at], paths, random);
        if (raised != null) {
          cards = [...cards]..[at] = raised;
          raise--;
          _use('raises');
        }
      }
    }
    return cards;
  }

  // --- Offers ----------------------------------------------------------------

  /// The policy on a fresh [offer] whose card the walk would take is
  /// [choose]'s: **Reroll** while that card fills no empty face and is
  /// Common, keeping one charge in hand ([redraw] draws the offer again);
  /// **Raise** the card taken when it is a sign or a skill that fills an
  /// empty face ([fills]). Never Banish (the sim's clan model stays as it
  /// is). Returns the offer and the card taken.
  ({ClanOffer offer, Suitor? suitor}) workOffer(
    ClanOffer offer, {
    required OfferContext context,
    required Suitor? Function(ClanOffer offer) choose,
    required ClanOffer? Function() redraw,
    required bool Function(String skillId) fills,
  }) {
    var current = offer;
    var suitor = choose(current);
    bool fillsFace(Suitor s) =>
        s.gift.kind == GiftKind.skill && fills(s.gift.id);
    while (built.contains(RollPower.reroll) &&
        reroll > 1 &&
        suitor != null &&
        !fillsFace(suitor) &&
        suitor.gift.rarity == SignRarity.common) {
      final again = redraw();
      if (again == null) break;
      reroll--;
      _use('rerolls');
      current = again;
      suitor = choose(current);
    }
    if (built.contains(RollPower.raise) &&
        raise > 0 &&
        suitor != null &&
        (suitor.gift.kind == GiftKind.sign || fillsFace(suitor))) {
      final raised = raisedSuitor(suitor, context, random);
      if (raised != null) {
        current = offerWith(current, suitor.factionId, raised);
        suitor = raised;
        raise--;
        _use('raises');
      }
    }
    return (offer: current, suitor: suitor);
  }
}

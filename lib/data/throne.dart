import 'dart:math';

import '../l10n/app_locale.dart';
import 'factions.dart';
import 'signs.dart';

/// The climb to the Lantern Throne, and the Host (v1.196).
///
/// The game ends with the character on the Lantern Throne at Candlehold,
/// as the head of the faction they raised to it: the Lantern Dominion
/// keeping it, one of the five clans taking it, or the Open Hand revived.
/// Three rungs lead there, for any faction (see [rungFor]):
/// 1. **House:** a friend among its sub-clans (subclans.json `clan`) --
///    as many Houses of as many clans as the story gives;
/// 2. **Clan:** the faction is the character's claim
///    ([PoliticsState.claim]): its three clan quest steps (the flags
///    `clan_<id>_step_1..3`, see [clanStepsFrom]), the third making the
///    character its head. One claim at a time;
/// 3. **Throne:** the claim crowned ([PoliticsState.throneWinner]).
///
/// Crowned, the character musters the **Host** ([hostFor]): the banner
/// (the faction on the Throne, or the claim), the allies (every other
/// faction at Trusted or better, or pledged; the Choir or the Pit when one
/// of their signs was taken this life; never a faction Hostile or worse)
/// and the Houses (each friend sub-clan one champion). Its effects
/// ([hostEffects]: each contingent's factions.json `host` effects and the
/// Houses' small stacking bonus) fight beside the party in the fights a
/// `hostFight` choice starts, through the Signs pipeline.
///
/// Everything here is pure, like factions.dart.

/// The rungs of the climb.
const int rungHouse = 1;
const int rungClan = 2;
const int rungThrone = 3;

/// The steps of a clan's quest; the last makes the character its head.
const int clanQuestSteps = 3;

/// The flag of step [step] of [factionId]'s clan quest.
String clanStepFlag(String factionId, int step) =>
    'clan_${factionId}_step_$step';

/// The flag a claim sets (and the only `claim_*` flag held).
String claimFlag(String factionId) => 'claim_$factionId';

/// The flag a pledge sets.
String pledgedFlag(String factionId) => 'pledged_$factionId';

/// The flag the coronation sets, with [onThroneFlag].
String throneWinnerFlag(String factionId) => 'throne_winner_$factionId';
const String onThroneFlag = 'on_throne';

/// The muster's flags: one per contingent, and how many Houses and how
/// many in all came, each the one exact count (`host_houses_3`: three
/// Houses), the Houses' counted up to [maxHostHousesFlag].
String hostFlag(String factionId) => 'host_$factionId';
String hostHousesFlag(int n) => 'host_houses_$n';
String hostSizeFlag(int n) => 'host_size_$n';

/// The most Houses a flag counts: more read as this many.
const int maxHostHousesFlag = 20;

/// The source of the title the coronation gives (titles.json `source`).
String throneTitleSource(String factionId) => 'throne:$factionId';

/// The standing a renounced claim costs.
const int renounceCost = 15;

/// [factionId]'s sub-clans that are the character's friends: its Houses
/// on the climb, in the data's order.
List<SubClan> friendHousesOf(
        String factionId, PoliticsState politics, ClanData data) =>
    [
      for (final s in data.subclansOf(factionId))
        if (politics.markOf(s.id) == SubclanMark.friend) s,
    ];

/// The rung the character has reached with [factionId]: 3 on the Throne,
/// 2 its claim, 1 a House found, 0 none.
int rungFor(String factionId, PoliticsState politics, ClanData data) {
  if (factionId.isEmpty) return 0;
  if (politics.throneWinner == factionId) return rungThrone;
  if (politics.claim == factionId) return rungClan;
  return friendHousesOf(factionId, politics, data).isNotEmpty ? rungHouse : 0;
}

/// The steps of [factionId]'s clan quest done (0..3): the highest
/// `clan_<id>_step_<n>` held.
int clanStepsFrom(Iterable<String> flags, String factionId) {
  final held = flags.toSet();
  var steps = 0;
  for (var n = 1; n <= clanQuestSteps; n++) {
    if (held.contains(clanStepFlag(factionId, n))) steps = n;
  }
  return steps;
}

/// Where the character stands on [factionId]'s climb: its friend
/// [houses], the clan quest [steps] done, whether it is the claim and
/// whether it is on the Throne.
class Climb {
  const Climb({
    required this.factionId,
    this.houses = const [],
    this.steps = 0,
    this.claimed = false,
    this.crowned = false,
  });

  final String factionId;
  final List<SubClan> houses;
  final int steps;
  final bool claimed;
  final bool crowned;

  /// The first House found, if any.
  SubClan? get house => houses.isEmpty ? null : houses.first;
  bool get hasHouse => houses.isNotEmpty;

  /// The rung reached (see [rungFor]).
  int get rung => crowned
      ? rungThrone
      : claimed
          ? rungClan
          : hasHouse
              ? rungHouse
              : 0;

  /// Whether anything of it has begun.
  bool get begun => rung > 0 || steps > 0;
}

/// [factionId]'s climb (see [Climb]).
Climb climbFor(String factionId, PoliticsState politics, Iterable<String> flags,
        ClanData data) =>
    Climb(
      factionId: factionId,
      houses: friendHousesOf(factionId, politics, data),
      steps: clanStepsFrom(flags, factionId),
      claimed: politics.claim == factionId,
      crowned: politics.throneWinner == factionId,
    );

/// The faction whose climb the Character tab follows: the one on the
/// Throne, else the claim, else the one furthest up (rung, then steps,
/// then standing) among the clans and the lost clan; '' while no climb
/// has begun.
String climbFocusFor(
    PoliticsState politics, Iterable<String> flags, ClanData data) {
  if (politics.throneWinner.isNotEmpty) return politics.throneWinner;
  if (politics.claim.isNotEmpty) return politics.claim;
  Climb? best;
  var bestStanding = 0.0;
  for (final faction in [...data.clans, ...data.lost]) {
    final climb = climbFor(faction.id, politics, flags, data);
    if (!climb.begun) continue;
    final standing = politics.standingOf(faction.id, data);
    final better = best == null ||
        climb.rung > best.rung ||
        (climb.rung == best.rung &&
            (climb.steps > best.steps ||
                (climb.steps == best.steps && standing > bestStanding)));
    if (better) {
      best = climb;
      bestStanding = standing;
    }
  }
  return best?.factionId ?? '';
}

// --- The Host -----------------------------------------------------------

/// Whether [factionId] stands Hostile or worse: it never comes.
bool _hostile(String factionId, PoliticsState politics, ClanData data) =>
    !politics.tierOf(factionId, data).isAtLeast(StandingTier.wary);

/// The Host the character would muster now (see the file's notes): the
/// banner (the faction on the Throne, else the claim), the allies in the
/// data's order, and the friend Houses by their clan's order. A faction
/// of the otherworld (the Choir, the Pit) comes when one of their signs
/// was taken this life ([signPatrons], PlayerSession.signPatronsThisLife)
/// or it pledged; a clan or a tribe at Trusted or better, or pledged; the
/// lost clan never as an ally; and none Hostile or worse.
Host hostFor({
  required PoliticsState politics,
  required ClanData data,
  Iterable<String> signPatrons = const [],
}) {
  final banner =
      politics.throneWinner.isNotEmpty ? politics.throneWinner : politics.claim;
  final otherworld = signPatrons.toSet();
  final allies = <String>[
    for (final faction in data.factions.values)
      if (faction.id != banner &&
          !faction.isLost &&
          !_hostile(faction.id, politics, data) &&
          (politics.hasPledged(faction.id) ||
              (faction.kind == PatronKind.otherworld
                  ? otherworld.contains(faction.id)
                  : politics
                      .tierOf(faction.id, data)
                      .isAtLeast(StandingTier.trusted))))
        faction.id,
  ];
  final houses = <String>[];
  for (final faction in data.factions.values) {
    for (final s in friendHousesOf(faction.id, politics, data)) {
      if (!houses.contains(s.id)) houses.add(s.id);
    }
  }
  for (final s in data.subclans.values) {
    if (politics.markOf(s.id) == SubclanMark.friend && !houses.contains(s.id)) {
      houses.add(s.id);
    }
  }
  return Host(banner: banner, allies: allies, houses: houses);
}

/// The Host the last battles field: the one mustered, else the one the
/// character would muster now (see [hostFor]).
Host fieldedHost({
  required PoliticsState politics,
  required ClanData data,
  Iterable<String> signPatrons = const [],
}) =>
    politics.host.mustered
        ? politics.host
        : hostFor(politics: politics, data: data, signPatrons: signPatrons);

/// The Houses' bonus: +1 block for the whole party as a fight opens per
/// [houseBlockPer] Houses (at most [houseBlockMax]), and +1 % max health
/// for the whole party per House (at most [houseHealthMax]).
const int houseBlockPer = 2;
const int houseBlockMax = 3;
const int houseHealthMax = 6;

/// What [houses] Houses add (see [houseBlockPer]).
List<SignEffect> houseEffects(int houses) => [
      if (houses >= houseBlockPer)
        SignEffect(
          kind: SignEffectKind.partyStartBlock,
          value: min(houseBlockMax, houses ~/ houseBlockPer),
        ),
      if (houses >= 1)
        SignEffect(
          kind: SignEffectKind.partyMaxHealthPercent,
          value: min(houseHealthMax, houses),
        ),
    ];

/// Everything [host] adds to a fight: each contingent's effects
/// (factions.json `host`, the banner's included) and the Houses' bonus.
/// Taken as written through the Signs pipeline (signEffectsFor's
/// `extra`).
List<SignEffect> hostEffects(Host host, ClanData data) => [
      for (final id in host.contingents) ...?data.faction(id)?.host?.effects,
      ...houseEffects(host.houses.length),
    ];

/// The flags a muster of [host] sets (see [hostFlag]): no count flag for
/// none.
List<String> hostFlagsFor(Host host) => [
      for (final id in host.contingents) hostFlag(id),
      if (host.houses.isNotEmpty)
        hostHousesFlag(min(host.houses.length, maxHostHousesFlag)),
      if (host.size > 0) hostSizeFlag(host.size),
    ];

final RegExp _hostCount = RegExp(r'^host_(houses|size)_\d+$');

/// Whether [flag] is one a muster sets -- a contingent of [factionIds] or
/// a count -- which a muster again replaces; the story's other `host_`
/// flags stay.
bool isMusterFlag(String flag, Iterable<String> factionIds) =>
    _hostCount.hasMatch(flag) || factionIds.any((id) => flag == hostFlag(id));

/// The titles the coronation of [factionId] gives (titles.json `source`
/// `throne:<id>`).
List<TitleDef> throneTitlesOf(String factionId, ClanData data) =>
    data.titlesFor(source: throneTitleSource(factionId));

// --- The words --------------------------------------------------------------

/// [name] as it reads inside a sentence: its leading article lowered
/// ("The Grey Vigil" → "the Grey Vigil", « La Veille Grise » → « la
/// Veille Grise »).
String midSentenceName(String name) {
  for (final article in const ['The ', 'Le ', 'La ', 'Les ', 'L’', "L'"]) {
    if (name.startsWith(article)) {
      return name[0].toLowerCase() + name.substring(1);
    }
  }
  return name;
}

/// [factionId]'s name in [language] (its id for one [data] doesn't know).
String throneFactionName(String factionId, ClanData data, AppLanguage lang) =>
    data.faction(factionId)?.nameFor(lang) ?? factionId;

/// Warding the road (docs/proposals/wave16-core.md §2): the Warding
/// Cairn's Banish turns a hunting clan away from the party's trail.
///
/// - **The target:** a clan that hunts the character now
///   ([wardTargets]): a sworn clan's rival at Hostile or Hunted, or the
///   nemesis (rival_hunters.dart's [rivalHunts]).
/// - **The price:** 1, 2 or 3 Banish charges ward it for 3, 6 or 9 roads
///   at rest ([wardLengths]).
/// - **While it holds,** that clan's roll in rival_hunters.dart is skipped.
///   The alignment hunters, the betrayals, the nemesis's champion and the
///   seat's crisis are not wardable. Standing does not move: the party hid
///   from them, it did not make peace.
/// - **The save:** a ward is a [RollBan] `on: road` (its id the clan's),
///   kept with the other bans in PlayerSession `rollBans`; it counts down
///   by one each road at rest ([afterRoadAtRest]).
///
/// Narrative's lines (docs/proposals/ward-lines.json) are app_strings'
/// `ward_*`; [wardLine] fills them.
library;

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart' show trFor;
import 'camp_rolls.dart';
import 'factions.dart';
import 'rival_hunters.dart' show rivalHunts;
import 'throne.dart' show midSentenceName;

/// How long a ward lasts, in roads at rest; the i-th costs i+1 charges.
const List<int> wardLengths = [3, 6, 9];

/// The charges a ward of [roads] costs (1, 2 or 3), 0 for no such length.
int wardCostOf(int roads) => wardLengths.indexOf(roads) + 1;

/// One length a ward may be bought for: [roads] roads at rest for [cost]
/// charges, [affordable] with the charges in hand.
typedef WardOption = ({int roads, int cost, bool affordable});

/// The three lengths, each marked affordable or not with [charges].
List<WardOption> wardOptions(int charges) => [
      for (final roads in wardLengths)
        (
          roads: roads,
          cost: wardCostOf(roads),
          affordable: wardCostOf(roads) <= charges,
        ),
    ];

/// The clans that may be warded now: those hunting the character
/// ([rivalHunts], warded or not; a ward set again keeps the longer).
List<String> wardTargets(PoliticsState state, ClanData data) =>
    rivalHunts(state, data).keys.toList();

/// A ward running: [clanId]'s hunters kept off the road for [roadsLeft]
/// more roads at rest.
typedef RoadWard = ({String clanId, int roadsLeft});

/// The wards among [bans], for the Journey's mark.
List<RoadWard> roadWardsOf(List<RollBan> bans) => [
      for (final b in bans)
        if (b.on == RollBanOn.road && b.left > 0)
          (clanId: b.id, roadsLeft: b.left),
    ];

/// The clans [bans] ward the road against now.
Set<String> wardedClansOf(List<RollBan> bans) =>
    bannedIdsOf(bans, RollBanOn.road);

/// [bans] with [clanId] warded for [roads] roads (a ward already on it
/// keeps the longer).
List<RollBan> withWard(List<RollBan> bans, String clanId, int roads) =>
    withRollBan(bans, RollBan(on: RollBanOn.road, id: clanId, left: roads));

/// A road at rest gone by: the wards count down by one, and [ended] names
/// the clans whose ward ran out on it. The stat picks' and offers' bans
/// are untouched.
({List<RollBan> bans, List<String> ended}) afterRoadAtRest(List<RollBan> bans) {
  final ended = <String>[];
  final next = <RollBan>[];
  for (final b in bans) {
    if (b.on != RollBanOn.road) {
      next.add(b);
    } else if (b.left > 1) {
      next.add(RollBan(on: b.on, id: b.id, left: b.left - 1));
    } else {
      ended.add(b.id);
    }
  }
  return (bans: next, ended: ended);
}

/// Narrative's line [key] (`ward_set`, `ward_set_nemesis`, `ward_ended`,
/// `ward_mark`, `ward_length`...) in [language] for [clanId], and [roads],
/// [cost], [n] its numbers. `{clan}` is the clan's name inside a sentence
/// in English ("the Lantern Dominion"; "{clan}’s" a plural's "the Salt
/// Crows’") and its `nameOf_fr` in French ("du Dominion de la Lanterne",
/// Narrative's `{clanOf}`).
String wardLine(
  String key,
  AppLanguage language, {
  String clanId = '',
  ClanData? data,
  int? roads,
  int? cost,
  int? n,
}) {
  final clan = data?.faction(clanId);
  final name = language == AppLanguage.fr
      ? clan?.nameOfFor(language) ?? clanId
      : midSentenceName(clan?.nameFor(language) ?? clanId);
  var text = trFor(language, key);
  if (name.endsWith('s')) text = text.replaceAll('{clan}’s', '$name’');
  text = text.replaceAll('{clan}', name);
  if (roads != null) text = text.replaceAll('{roads}', '$roads');
  if (cost != null) text = text.replaceAll('{cost}', '$cost');
  if (n != null) text = text.replaceAll('{n}', '$n');
  return text;
}

/// The line when [clanId]'s ward is set: the nemesis's own when it is
/// [nemesis].
String wardSetLine(String clanId, AppLanguage language,
        {required ClanData data, String nemesis = ''}) =>
    wardLine(
        clanId.isNotEmpty && clanId == nemesis
            ? 'ward_set_nemesis'
            : 'ward_set',
        language,
        clanId: clanId,
        data: data);

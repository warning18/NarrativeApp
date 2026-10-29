// The report of a "Play to chapter" walk (the simulator screen's summary
// pop-in, autoplay_summary_dialog.dart): the state it left, the choices it
// took, the items it gained, lost and equipped, the banners (clan offers)
// it took and the one it carries, the fights and the companions.
//
// Pure: built from the session before and after the walk and the walk's
// own log (AutoplayLog).
import '../providers/player_session_provider.dart' show PlayerSession;
import 'autoplay_engine.dart' show AutoplayLog;
import 'clan_crisis.dart' show mainClanOf;
import 'factions.dart';

/// A clan's standing at the end of the walk.
typedef SummaryStanding = ({String factionId, double value, StandingTier tier});

class AutoplaySummary {
  const AutoplaySummary({
    required this.level,
    required this.gold,
    required this.chapter,
    required this.nodeId,
    required this.raceId,
    required this.professionId,
    required this.standings,
    required this.choices,
    required this.gained,
    required this.lost,
    required this.equipped,
    required this.banners,
    required this.carriedBanner,
    required this.offersWaiting,
    required this.fights,
    required this.recruited,
    required this.seated,
  });

  final int level;
  final int gold;
  final int chapter;

  /// The scene the walk stopped on.
  final String nodeId;
  final String raceId;
  final String professionId;

  /// The main clans, highest standing first.
  final List<SummaryStanding> standings;
  final List<({String nodeId, String text})> choices;

  /// Item ids that came into the pack (bought, found, given) and left it
  /// (sold, spent), each as many times as it moved.
  final List<String> gained;
  final List<String> lost;
  final List<String> equipped;

  /// The banners taken on the walk, and the clan whose banner the
  /// character carries now (sworn, else the patron; '' for none).
  final List<({int chapter, String factionId, String gift})> banners;
  final String carriedBanner;

  /// Offers still due (the clans not open yet): taken by hand later.
  final int offersWaiting;
  final List<({String enemyId, String name, bool won, bool forced})> fights;
  final List<String> recruited;
  final List<String> seated;

  int get fightsWon => fights.where((f) => f.won).length;
  int get fightsLost => fights.length - fightsWon;
}

/// The walk from [before] to [after], with its [log] (see the file's
/// notes). [chapter]: the chapter reached.
AutoplaySummary autoplaySummaryOf({
  required PlayerSession before,
  required PlayerSession after,
  required AutoplayLog log,
  required ClanData data,
  required int chapter,
  required String nodeId,
}) {
  final standings = [
    for (final f in data.clans)
      (
        factionId: f.id,
        value: after.politics.standingOf(f.id, data),
        tier: after.politics.tierOf(f.id, data),
      ),
  ]..sort((a, b) => b.value.compareTo(a.value));
  return AutoplaySummary(
    level: after.level,
    gold: after.gold,
    chapter: chapter,
    nodeId: nodeId,
    raceId: after.raceId,
    professionId: after.professionId,
    standings: standings,
    choices: [...log.choices],
    gained: multisetLess(after.inventoryItemIds, before.inventoryItemIds),
    lost: multisetLess(before.inventoryItemIds, after.inventoryItemIds),
    equipped: [...after.equippedItemIds],
    banners: [...log.banners],
    carriedBanner: mainClanOf(after.politics),
    offersWaiting: after.pendingOffers.length,
    fights: [...log.fights],
    recruited: [for (final a in after.recruitedAllies) a.companionId],
    seated: [...after.activeAllyIds],
  );
}

/// [items] less [minus] as multisets: each id as many times as [items]
/// holds it beyond [minus], in [items]' order.
List<String> multisetLess(List<String> items, List<String> minus) {
  final left = <String, int>{};
  for (final id in minus) {
    left[id] = (left[id] ?? 0) + 1;
  }
  final out = <String>[];
  for (final id in items) {
    final n = left[id] ?? 0;
    if (n > 0) {
      left[id] = n - 1;
    } else {
      out.add(id);
    }
  }
  return out;
}

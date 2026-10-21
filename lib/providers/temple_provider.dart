import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/temple.dart';
import 'chapter_loop_provider.dart';
import 'clans_provider.dart';
import 'combat_active_provider.dart';
import 'expedition_active_provider.dart';
import 'geography_provider.dart';
import 'player_session_provider.dart';
import 'town_rulers_provider.dart';

/// The clan that keeps the temple of [placeId] (a temple pin's
/// TownServiceOpen id: its district, else its town) now, '' for a neutral
/// one; it follows the politics, so a temple changes hands with its town.
final templeClanProvider = Provider.family<String, String>((ref, placeId) =>
    templeClanAt(placeId, ref.watch(townRulersProvider),
        parent: ref.watch(geographyProvider).places[placeId]?.parent ?? ''));

/// What the temple of [placeId] offers now (temple.dart's TempleOffer):
/// the keeper, the prices at the standing with them, what blocks each
/// service (Hunted, a fight or an expedition under way, the purse, a
/// Mending today), whether a blessing would replace one or bring standing.
/// Buy with PlayerSessionNotifier.templeMend / templeBless, passing
/// [TempleOffer.clanId].
final templeOfferProvider =
    Provider.family<TempleOffer, String>((ref, placeId) {
  final session = ref.watch(playerSessionProvider);
  return templeOfferFor(
    clanId: ref.watch(templeClanProvider(placeId)),
    data: ref.watch(clanDataProvider),
    politics: session.politics,
    chapter: ref.watch(reachedChapterProvider),
    day: session.day,
    gold: session.gold,
    alignment: session.alignmentScore,
    templeMendDay: session.templeMendDay,
    blessingFights: session.blessingFights,
    standingChapters: session.templeStandingChapters,
    busy:
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider),
  );
});

/// The blessing the party carries: the clan whose temple gave it ('' a
/// neutral one) and the fights it has left; null for none (for the
/// RoadPanel's line and the fight's chip).
final activeBlessingProvider = Provider<({String clanId, int fights})?>((ref) {
  final fights =
      ref.watch(playerSessionProvider.select((s) => s.blessingFights));
  if (fights <= 0) return null;
  return (
    clanId: ref.watch(playerSessionProvider.select((s) => s.blessingClan)),
    fights: fights,
  );
});

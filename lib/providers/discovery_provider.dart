import 'package:flutter_riverpod/legacy.dart';

class PendingDiscovery {
  const PendingDiscovery({this.shopId, this.questId});

  final String? shopId;
  final String? questId;
}

/// Set right when a story choice unlocks a shop and/or quest, so the story
/// reader can show a one-shot "discovered!" modal on the node the player
/// just arrived at, letting them jump straight to it instead of only
/// noticing the Play-tab CTA chip. Cleared immediately after being shown.
final pendingDiscoveryProvider =
    StateProvider<PendingDiscovery?>((ref) => null);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_power.dart';
import 'clans_provider.dart';
import 'geography_provider.dart';
import 'story_providers.dart';

/// The clan that holds the place the story stands at now (clan_power.dart's
/// holderOf), '' for none: its suitor comes more often in an offer made
/// here (offers.dart's heldPlaceSuitorWeight).
final holderHereProvider = Provider<String>((ref) {
  final geography = ref.watch(geographyProvider);
  final node = ref
      .watch(storyDataProvider)
      .value
      ?.nodeFor(ref.watch(storyPlayProvider).currentNodeId);
  return holderOf(
      geography.placeOfNode(node)?.id, geography, ref.watch(politicsProvider));
});

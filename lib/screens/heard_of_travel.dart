import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/heard_of.dart';
import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../widgets/camp_travel.dart' show sailParty, travelToPlace;
import 'port_screen.dart' show launchExpedition;

/// "Set out" for a place only heard of (see heard_of.dart): a place found
/// is travelled to as the camp travels; one not found yet is reached by
/// the expedition that finds it, sailed to first when it sets out from
/// another port. Only for a [HeardOfPlace.setsOut] place.
Future<void> setOutToHeardOf(
    BuildContext context, WidgetRef ref, HeardOfPlace place) async {
  if (!place.setsOut) return;
  final expeditionId = place.expeditionId;
  if (expeditionId == null) {
    final story = await ref.read(storyDataProvider.future);
    final node = story.nodeFor(place.placeNodeId ?? '');
    if (node == null || !context.mounted) return;
    await travelToPlace(context, ref, node);
    return;
  }
  final zones =
      await ref.read(gameDbRepositoryProvider(zonesSchema)).loadRecords();
  final zone = zones[expeditionId];
  if (zone is! Map<String, dynamic> || !context.mounted) return;
  final portId = place.expeditionPortId;
  if (portId != null &&
      portId != ref.read(playerSessionProvider).currentPortId) {
    final arrived = await sailParty(context, ref, destinationPortId: portId);
    if (!arrived || !context.mounted) return;
  }
  await launchExpedition(context, ref, expeditionId, zone);
}

// Seating a companion in the camp's party or benching them, and whether they
// can join now: Core's rules for the party, moved here unchanged from
// camp_screen.dart (v1.606) so the Party tab's formation and a companion's
// page share them (setAllyActive, canBench and the party's capacity stay
// where they are).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import 'immersive_notice.dart';
import 'moments.dart';

/// Puts [companionId] in the party or on the bench, and says which
/// achievements joining earned.
Future<void> setAllyInParty(
  BuildContext context,
  WidgetRef ref, {
  required String companionId,
  required bool active,
  required int partyCapacity,
  required String requiredHouseId,
}) async {
  final notifier = ref.read(playerSessionProvider.notifier);
  await notifier.setAllyActive(companionId, active,
      partyCapacity: partyCapacity,
      requiredHouseId: requiredHouseId,
      companions:
          ref.read(localizedDbProvider(companionsSchema)).value ?? const {});
  if (!active) return;
  final earned = await notifier.checkAchievements();
  if (earned.isEmpty || !context.mounted) return;
  final achievements =
      ref.read(localizedDbProvider(achievementsSchema)).value ?? const {};
  unawaited(announceAchievements(
      context,
      [
        for (final id in earned)
          (achievements[id] as Map<String, dynamic>?)?['achievementName']
                  ?.toString() ??
              id
      ],
      tr(ref, 'achievement_unlocked_prefix').toUpperCase()));
  showImmersiveNotice(
    context,
    icon: Icons.emoji_events_outlined,
    message:
        '${tr(ref, 'achievement_unlocked_prefix')}: ${earned.map((id) => (achievements[id] as Map<String, dynamic>?)?['achievementName']?.toString() ?? id).join(', ')}',
  );
}

/// Whether [companionId] can join the party now, and if not, why.
({bool canJoin, String reason}) allyJoinState(
  WidgetRef ref,
  PlayerSession session, {
  required String companionId,
  required Map<String, dynamic>? companion,
  required Map<String, dynamic> houses,
}) {
  if (session.activeAllyIds.contains(companionId)) {
    return (canJoin: true, reason: '');
  }
  final requiredHouseId = companion?['requiredHouseId']?.toString() ?? '';
  if (requiredHouseId.isNotEmpty &&
      !session.builtHouseIds.contains(requiredHouseId)) {
    final houseName =
        (houses[requiredHouseId] as Map<String, dynamic>?)?['houseName']
                ?.toString() ??
            requiredHouseId;
    return (
      canJoin: false,
      reason: '${tr(ref, 'requires_house_prefix')}: $houseName',
    );
  }
  if (session.activeAllyIds.length >=
      partyCapacityFor(session.builtHouseIds, houses)) {
    return (canJoin: false, reason: tr(ref, 'party_at_capacity'));
  }
  return (canJoin: true, reason: '');
}

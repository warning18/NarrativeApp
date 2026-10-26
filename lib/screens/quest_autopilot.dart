import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quest_tracking.dart';
import '../gamedata/db_schema.dart';
import '../providers/app_mode_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../widgets/quest_turn_in.dart';

/// Whether [settleQuests] is at work (it shows dialogs: one run at a time).
bool _settling = false;

/// Whether [settleQuests] is showing its dialogs (the offers wait for it,
/// see offer_autopilot.dart).
bool get questsSettling => _settling;

/// The quests the party need not act on (Wave 6): a main quest offered is
/// taken on at once, never left for later; a quest whose objectives are all
/// met completes on its own, with its rewards and level-up as a turn-in
/// pays them (a quest settled by a choice still asks how). Called by the
/// story view after each frame while it is on top, in play only (Edit Mode
/// leaves quests to the editor).
Future<void> settleQuests(BuildContext context, WidgetRef ref) async {
  if (_settling) return;
  if (ref.read(appModeProvider) != AppMode.inGame) return;
  final quests = ref.read(localizedDbProvider(questsSchema)).value;
  if (quests == null || quests.isEmpty) return;
  var session = ref.read(playerSessionProvider);
  final toTake = mainQuestsToTake(quests, session);
  final toComplete = questsReadyToComplete(quests, session);
  if (toTake.isEmpty && toComplete.isEmpty) return;
  _settling = true;
  try {
    for (final id in toTake) {
      if (!context.mounted) return;
      await acceptQuestWithNotice(context, ref, id);
    }
    // Taking a quest on may find it already done.
    session = ref.read(playerSessionProvider);
    for (final id in questsReadyToComplete(quests, session)) {
      if (!context.mounted) return;
      await turnInQuest(context, ref, id);
    }
  } finally {
    _settling = false;
  }
}

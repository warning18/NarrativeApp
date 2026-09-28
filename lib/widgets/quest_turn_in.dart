import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../data/companion_remarks.dart';
import '../data/turn_in_choices.dart';
import '../providers/remark_provider.dart';
import 'approval_notice.dart';
import 'immersive_notice.dart';
import 'level_up_dialog.dart';
import 'turn_in_choice_dialog.dart';

/// Takes on [questId] (it becomes the followed quest when none is) and
/// says so.
Future<void> acceptQuestWithNotice(
    BuildContext context, WidgetRef ref, String questId) async {
  final quest = (ref.read(localizedDbProvider(questsSchema)).value ??
      const {})[questId] as Map<String, dynamic>?;
  await ref
      .read(playerSessionProvider.notifier)
      .acceptQuest(questId, quest: quest);
  if (!context.mounted) return;
  final lang = ref.read(appLanguageProvider);
  showImmersiveNotice(
    context,
    icon: Icons.assignment_turned_in_outlined,
    message: '${trFor(lang, 'quest_accepted_prefix')}: '
        '${quest?['questName']?.toString() ?? questId}',
  );
}

/// Turns in [questId], whose objectives are all met: pays its rewards
/// (a reward die made for another class is paid in gold instead),
/// recruits its companion, checks achievements, says what was gained and
/// shows the level-up dialog when the XP brought a level. Shared by the
/// Quests list and the quest tracker above the story.
Future<void> turnInQuest(
    BuildContext context, WidgetRef ref, String questId) async {
  Map<String, dynamic> db(DbSchema schema) =>
      ref.read(localizedDbProvider(schema)).value ?? const {};
  final quest = db(questsSchema)[questId] as Map<String, dynamic>?;
  if (quest == null) return;
  final lang = ref.read(appLanguageProvider);
  final notifier = ref.read(playerSessionProvider.notifier);
  final questName = quest['questName']?.toString() ?? questId;
  final companions = db(companionsSchema);
  final items = db(itemsSchema);

  // A quest that asks how it's settled (see turn_in_choices.dart) pays by
  // the choice; backing out leaves it open.
  final choices = turnInChoicesOf(quest);
  TurnInChoice? picked;
  if (choices.isNotEmpty) {
    picked = await showTurnInChoiceDialog(context, ref,
        quest: quest, choices: choices);
    if (picked == null || !context.mounted) return;
  }
  final questGold = (quest['rewardGold'] as num?)?.toInt() ?? 0;
  final questAlignment = (quest['alignmentChange'] as num?)?.toInt() ?? 0;
  var rewardGold = picked?.goldFor(questGold) ?? questGold;
  final rewardXp = (quest['rewardXP'] as num?)?.toInt() ?? 0;
  final rewardItemId = quest['rewardItemID']?.toString();
  final nextQuestId = quest['nextQuestID']?.toString();
  var rewardDiceId = quest['rewardDiceID']?.toString();
  // A reward die made for another class is paid out in gold instead (its
  // shop price).
  String? tradedDieName;
  if (rewardDiceId != null && rewardDiceId.isNotEmpty) {
    final die = db(diceSchema)[rewardDiceId] as Map<String, dynamic>?;
    final player = ref.read(playerSessionProvider);
    if (!dieUsableBy(die,
        professionId: player.professionId, raceId: player.raceId)) {
      rewardGold += (die?['cost'] as num?)?.toInt() ?? 0;
      tradedDieName = dieDisplayName(rewardDiceId, language: lang);
      rewardDiceId = null;
    }
  }
  final rewardAllyId = quest['rewardAllyId']?.toString();
  final grantsBannerPieceId = quest['grantsBannerPieceId']?.toString();
  final alignmentMod = picked?.alignmentFor(questAlignment) ?? questAlignment;
  final rewardItem = rewardItemId == null
      ? null
      : items[rewardItemId] as Map<String, dynamic>?;

  final leveledUp = await notifier.completeQuest(
    questId,
    rewardGold: rewardGold,
    rewardXP: rewardXp,
    rewardItemId: rewardItemId,
    nextQuestId: nextQuestId,
    rewardDiceId: rewardDiceId,
    grantsBannerPieceId: grantsBannerPieceId,
    alignmentMod: alignmentMod,
    rewardItem: rewardItem,
  );
  String? recruitedName;
  if (rewardAllyId != null && rewardAllyId.isNotEmpty) {
    final companion = companions[rewardAllyId] as Map<String, dynamic>?;
    await notifier.recruitAlly(
      rewardAllyId,
      race: db(racesSchema)[companion?['raceId']?.toString() ?? '']
          as Map<String, dynamic>?,
      profession:
          db(professionsSchema)[companion?['professionId']?.toString() ?? '']
              as Map<String, dynamic>?,
      companion: companion,
      dice: db(diceSchema),
      houses: db(housesSchema),
      requiredHouseId: companion?['requiredHouseId']?.toString(),
    );
    recruitedName = companion?['companionName']?.toString() ?? rewardAllyId;
  }
  if (picked != null && picked.flag.isNotEmpty) {
    await notifier.applyChoiceEffects(flagsToAdd: [picked.flag]);
  }
  // The party's reaction to how it was settled (see approval.dart); a
  // companion who just joined sees it too.
  final deed = RemarkDeed(
    alignmentMod: alignmentMod,
    goldMod: picked?.profitOver(questGold) ?? 0,
    approvalMods: picked?.approvalMods ?? const {},
  );
  final reactions = await notifier.reactToDeed(
    companions: companions,
    alignmentMod: deed.alignmentMod,
    goldMod: deed.goldMod,
    approvalMods: deed.approvalMods,
  );
  final newAchievements =
      await notifier.checkAchievements(totalCompanionCount: companions.length);
  if (!context.mounted) return;
  final achievements = db(achievementsSchema);
  final achievementNames = [
    for (final id in newAchievements)
      (achievements[id] as Map<String, dynamic>?)?['achievementName']
              ?.toString() ??
          id,
  ];
  final gains = [
    '+$rewardGold ${trFor(lang, 'gold_label')}',
    '+$rewardXp XP',
    if (rewardItemId != null && rewardItemId.isNotEmpty)
      '+${rewardItem?['itemName']?.toString() ?? rewardItemId}',
    if (rewardDiceId != null && rewardDiceId.isNotEmpty)
      '+${dieDisplayName(rewardDiceId, language: lang)}',
    if (recruitedName != null)
      '${trFor(lang, 'recruited_prefix')} $recruitedName',
  ];
  final lines = [
    '${trFor(lang, 'quest_complete_prefix')}: $questName (${gains.join(', ')})',
    if (picked != null && picked.resultText.isNotEmpty) picked.resultText,
    if (tradedDieName != null)
      trFor(lang, 'reward_die_traded').replaceAll('{die}', tradedDieName),
    if (grantsBannerPieceId != null && grantsBannerPieceId.isNotEmpty)
      trFor(lang, 'banner_piece_found_prefix'),
    if (achievementNames.isNotEmpty)
      '${trFor(lang, 'achievement_unlocked_prefix')}: '
          '${achievementNames.join(', ')}',
    ...approvalReactionLines(
      reactions,
      companions,
      (key) => trFor(lang, key),
      remarks: speakUpAbout(ref, reactions: reactions, deed: deed),
      book: ref.read(remarkBookProvider),
      french: lang == AppLanguage.fr,
    ),
  ];
  showImmersiveNotice(
    context,
    icon: Icons.emoji_events_outlined,
    message: lines.join('\n'),
  );
  if (leveledUp) {
    showLevelUpDialog(context, ref,
        newLevel: ref.read(playerSessionProvider).level);
  }
}

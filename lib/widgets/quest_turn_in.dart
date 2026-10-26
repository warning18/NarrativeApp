import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/moment_remark_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import '../theme/stitched_ink.dart';
import '../data/companion_remarks.dart';
import '../data/item_origin_here.dart';
import '../data/politics_events.dart' show questTurnInPoliticsKey;
import '../data/turn_in_choices.dart';
import 'approval_notice.dart';
import 'companion_remark_bubble.dart';
import 'immersive_notice.dart';
import 'level_up_dialog.dart';
import 'moments.dart';
import 'reward_card.dart';
import 'reward_cards.dart';
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
  var tradedDieCost = 0;
  if (rewardDiceId != null && rewardDiceId.isNotEmpty) {
    final die = db(diceSchema)[rewardDiceId] as Map<String, dynamic>?;
    final player = ref.read(playerSessionProvider);
    if (!dieUsableBy(die,
        professionId: player.professionId, raceId: player.raceId)) {
      tradedDieCost = (die?['cost'] as num?)?.toInt() ?? 0;
      rewardGold += tradedDieCost;
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

  final xpBefore = ref.read(playerSessionProvider).currentXP;
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
    origin: itemOriginHere(ref),
  );
  // How it was settled moves the clans (v1.204, see
  // TurnInChoice.politics): once, logged under the quest.
  if (picked != null && picked.hasPolitics) {
    await applyStoryPoliticsNow(
      ref,
      picked.politics!,
      nodeId: questId,
      key: questTurnInPoliticsKey(questId, choices.indexOf(picked)),
      cause: 'quest:$questId',
    );
    if (!context.mounted) return;
  }
  // Its influence in the town's district (wave 18): a district changing
  // hands gets a companion's word.
  final swayed =
      await applyQuestInfluenceNow(ref, quest, picked: picked?.politics);
  if (!context.mounted) return;
  final flipRemark = swayed.flipped == null
      ? null
      : speakUpOnMoment(ref, RemarkKind.districtFlipped);
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
  // The card: gold, experience, what else was won, and the notes.
  final after = ref.read(playerSessionProvider);
  final ink = InkColors.of(context);
  final found = <RewardLine>[
    if (rewardItemId != null && rewardItemId.isNotEmpty)
      rewardItemLine(context,
          itemId: rewardItemId, item: rewardItem, lang: lang),
    if (rewardDiceId != null && rewardDiceId.isNotEmpty)
      RewardLine(
        key: Key('reward_die_$rewardDiceId'),
        icon: Icon(Icons.casino, size: 28, color: ink.tide),
        accent: ink.tide,
        title: dieDisplayName(rewardDiceId, language: lang),
        sub: trFor(lang, 'reward_die_made_for'),
        value: trFor(lang, 'reward_new'),
      ),
    if (recruitedName != null)
      RewardLine(
        key: const Key('reward_ally'),
        icon: Icon(Icons.person_add_alt_1, size: 28, color: ink.heal),
        accent: ink.heal,
        title: recruitedName,
        sub: trFor(lang, 'recruited_prefix'),
        value: trFor(lang, 'reward_joins'),
      ),
  ];
  final notes = <RewardNote>[
    if (picked != null && picked.resultText.isNotEmpty)
      RewardNote(picked.resultText),
    if (tradedDieName != null)
      RewardNote(
          trFor(lang, 'reward_die_traded').replaceAll('{die}', tradedDieName),
          chip: '+$tradedDieCost G'),
    if (grantsBannerPieceId != null && grantsBannerPieceId.isNotEmpty)
      RewardNote(trFor(lang, 'banner_piece_found_prefix')),
    for (final line in approvalReactionLines(
        reactions, companions, (key) => trFor(lang, key)))
      RewardNote(line),
  ];
  final card = questRewardCard(
    context,
    lang: lang,
    ink: ink,
    questName: questName,
    chapter: (quest['chapter'] as num?)?.toInt() ?? 1,
    gold: rewardGold,
    xp: rewardXp,
    xpBefore: xpBefore,
    xpAfter: after.currentXP,
    xpNeeded: after.xpToNextLevel,
    level: after.level,
    leveledUp: leveledUp,
    found: found,
    notes: notes,
  );
  // What the party says about how it was settled (see
  // companion_remarks.dart) comes after the notice, in speech bubbles.
  final remarks = [
    ...speakUpAbout(ref, reactions: reactions, deed: deed),
    if (flipRemark != null) flipRemark,
  ];
  // The quest sealed, and each achievement announced up top.
  showQuestSeal(context);
  if (achievementNames.isNotEmpty) {
    unawaited(announceAchievements(context, achievementNames,
        trFor(lang, 'achievement_unlocked_prefix').toUpperCase()));
  }
  await showRewardCard(context, card);
  if (!context.mounted) return;
  await showSpokenLines(context, ref, [
    ...approvalReactionWords(reactions, companions),
    ...spokenRemarks(ref, remarks),
  ]);
  if (!context.mounted) return;
  if (leveledUp) {
    showLevelUpDialog(context, ref,
        newLevel: ref.read(playerSessionProvider).level);
  }
}

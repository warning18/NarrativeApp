// The story's choice flow: which choices are locked, what taking one does
// (the walk, the fights, the arrivals, the narration), cut out of
// story_player_screen.dart with no change.
part of '../story_player_screen.dart';

/// Whether [choice] is currently unreachable because its target node has
/// requirements the player doesn't meet (shown disabled with its
/// lockedText instead of being selectable).
/// Whether [choice]'s road is still shut for [session] (its next scene
/// asks for gold, alignment, flags or Charisma the character lacks, or,
/// on a detour ([isExcursion]), it costs more gold than the purse holds;
/// with [world], v1.196, its politics gate fails and it shows its locked
/// text).
bool isStoryChoiceLocked(
        StoryChoice choice, StoryData story, PlayerSession session,
        {bool isExcursion = false,
        CoastWorld? world,
        Map<String, GeoPlace> shutWays = const {}}) =>
    _isChoiceLocked(choice, story, session, isExcursion,
        world: world, shutWays: shutWays);

/// Whether [node]'s page holds the party until one of its ways is taken
/// (the scene lock, see scene_lock.dart), for the play state now: never on
/// a detour, whose own view has no map to leave by. [mapped] says which
/// ways a map view draws (the Journey's placements, once its map is
/// built); without it, the same data the chart uses decides
/// ([mapDrawsEveryWay]).
bool storySceneLocked(WidgetRef ref, StoryNode node, StoryData story,
    {bool Function(StoryChoice choice)? mapped}) {
  final play = ref.watch(storyPlayProvider);
  if (play.isInExcursion) return false;
  final session = ref.watch(playerSessionProvider);
  final world = ref.watch(coastGateWorldProvider);
  final geography = ref.watch(geographyProvider);
  final shutWays = ref.watch(lockedStoryWaysProvider);
  final mainQuestOpen =
      ref.watch(chapterProgressProvider)?.mainQuestOpen ?? true;
  final everyWayMapped = mapped == null &&
      mapDrawsEveryWay(node,
          history: play.history,
          world: geography,
          cityPlans: ref.watch(cityPlanRecordsProvider).value?.keys.toSet());
  return sceneLocked(
    ways: [
      for (final c in node.choices)
        if (!choiceHiddenFor(c, session, world))
          () {
            final here =
                choiceShape(node, c, story: story, geography: geography).here;
            return (
              here: here,
              takeable: !(c.mainQuest && !mainQuestOpen) &&
                  !isStoryChoiceLocked(c, story, session,
                      world: world, shutWays: shutWays),
              mapped: mapped?.call(c) ?? (everyWayMapped || !here),
            );
          }(),
    ],
    hub: isHubScene(node),
    ending: isStoryEnding(node),
    editMode: ref.watch(appModeProvider) == AppMode.edit,
  );
}

/// Whether the data the map lays the ways on has loaded (the places and
/// biomes, the cities' stored plans): until then [storySceneLocked] can't
/// tell a scene the map draws from one it doesn't, and says unlocked.
bool _storyMapPlacementsKnown(WidgetRef ref) =>
    !ref.watch(gameDbProvider(geographySchema)).isLoading &&
    !ref.watch(gameDbProvider(biomesSchema)).isLoading &&
    !ref.watch(cityPlanRecordsProvider).isLoading;

/// What a shut [choice] reads as instead of its text: why it is shut (see
/// [isStoryChoiceLocked]; [mainQuestShut]: a camp's main quest waiting for
/// the chapter's goals).
String? storyChoiceLockedText(
  WidgetRef ref,
  StoryChoice choice,
  PlayerSession session, {
  required bool isExcursion,
  required bool french,
  bool mainQuestShut = false,
}) {
  if (mainQuestShut) return tr(ref, 'main_quest_shut_lock');
  if (_paymentShort(choice, session.gold, isExcursion)) {
    return _goldShortText(ref, choice, session.gold, french: french);
  }
  // A way into a locked district reads as the district's own line.
  final district =
      isExcursion ? null : ref.watch(lockedStoryWaysProvider)[choice.nextId];
  if (district != null) return district.lockedTextFor(french);
  return choice.lockedTextFor(french);
}

/// Whether [choice] is a payment (one on the road, or a story choice
/// marked [StoryChoice.pays]) a purse of [gold] can't make.
bool _paymentShort(StoryChoice choice, int gold, bool isExcursion) =>
    (isExcursion || choice.pays) && !choice.affordableWith(gold);

/// [choice], a payment a purse of [gold] can't make, as it reads shut.
String _goldShortText(WidgetRef ref, StoryChoice choice, int gold,
        {required bool french}) =>
    tr(ref, 'choice_gold_short_lock')
        .replaceAll('{choice}', choice.textFor(french))
        .replaceAll('{gold}', '$gold');

/// Takes [choice] from the scene the story is on, exactly as tapping it
/// under the story would: its checks, fights, effects and the road after.
/// The camp's way out uses it (see CampScreen); [travelled]: the party has
/// already sailed where the choice goes (see setOutOnMainQuest), and lands
/// there with no road to walk.
Future<void> takeStoryChoice(
    BuildContext context, WidgetRef ref, StoryChoice choice,
    {bool travelled = false}) async {
  final story = await ref.read(storyDataProvider.future);
  if (!context.mounted) return;
  final play = ref.read(storyPlayProvider);
  await _selectChoice(
    context: context,
    ref: ref,
    choice: choice,
    story: story,
    session: ref.read(playerSessionProvider),
    currentNodeId: play.currentNodeId,
    isExcursion: play.isInExcursion,
    french: ref.read(appLanguageProvider) == AppLanguage.fr,
    travelled: travelled,
  );
}

bool _isChoiceLocked(
  StoryChoice choice,
  StoryData story,
  PlayerSession session,
  bool isExcursion, {
  CoastWorld? world,
  Map<String, GeoPlace> shutWays = const {},
}) {
  // A payment on the road (an offering, a toll, a fine) waits for a purse
  // that holds it, and so does a story choice marked as one (a fee, a
  // bribe, a buy-in). The story's other prices lock through the next
  // scene's gold requirement; gold it takes away unmarked is a loss.
  if (_paymentShort(choice, session.gold, isExcursion)) return true;
  if (isExcursion) return false;
  // A way into a locked district (lockedStoryWaysProvider, v1.616).
  if (shutWays.containsKey(choice.nextId)) return true;
  // A politics gate that fails, on a choice with a locked text to show
  // (v1.196); one without is hidden (see choiceHiddenFor).
  if (world != null &&
      choiceGateFor(choice, session, world) == ChoiceGate.locked) {
    return true;
  }
  final targetNode = choice.isEnding ? null : story.nodeFor(choice.nextId);
  return targetNode != null &&
      targetNode.hasRequirements &&
      !session.meetsRequirements(
        reqGold: targetNode.reqGold,
        reqAlignmentScore: targetNode.reqAlignmentScore,
        reqAlignmentMax: targetNode.reqAlignmentMax,
        reqFlags: targetNode.reqFlags,
        reqCharisma: targetNode.reqCharisma,
      );
}

/// Whether [choice] is a camp's main quest still shut (see
/// [chapterProgressProvider]): the camp's own button waits for the
/// chapter's goals, and so does the same choice anywhere under the story.
bool _mainQuestShut(WidgetRef ref, StoryChoice choice, bool isExcursion) =>
    choice.mainQuest &&
    !isExcursion &&
    !(ref.watch(chapterProgressProvider)?.mainQuestOpen ?? true);

/// A node with this many choices or fewer keeps the plain flat list it's
/// always had — most nodes are a handful of genuinely distinct narrative
/// branches, and boxing those into sections would just add ceremony. Above
/// it, a node reads less like "a decision" and more like "a place with
/// several independent things to do" (shop here, fight that, talk to
/// them), so [_HubSections] takes over presenting everything but the node's
/// own main branches.
const int _hubChoiceThreshold = hubChoiceCount;

bool _isHubNode(StoryNode node) =>
    node.choices.length > _hubChoiceThreshold || _isLoopPlace(node);

/// A place of the open chapters (a town, a village, a site): always laid
/// out as a place, with its way back to the camp and on to the others,
/// however few things it has to do.
bool _isLoopPlace(StoryNode node) {
  final settlement = node.settlement;
  return settlement != null && !settlement.isCamp && settlement.chapter != null;
}

/// Which "village" section a hub node's choice belongs in, derived from
/// fields the choice already carries — no new JSON authoring needed. A
/// choice that grants a shop reads as shopping even if it also happens to
/// carry a skill check; combat and ability checks share one "Challenges"
/// bucket since both are the same "risk something, maybe get hurt" beat;
/// a quest grant with neither reads as talking to someone. `null` means
/// this choice stays in the node's own main list instead of being sorted
/// into a section.
enum _HubCategory { shop, challenge, people }

_HubCategory? _hubCategoryFor(StoryChoice choice) {
  if ((choice.unlockShopId ?? '').isNotEmpty) return _HubCategory.shop;
  if (choice.triggersCombat || choice.hasAbilityCheck) {
    return _HubCategory.challenge;
  }
  if ((choice.unlockQuestId ?? '').isNotEmpty) return _HubCategory.people;
  return null;
}

IconData _hubIconFor(StoryChoice choice) {
  switch (_hubCategoryFor(choice)) {
    case _HubCategory.shop:
      return Icons.storefront_outlined;
    case _HubCategory.challenge:
      return choice.triggersCombat
          ? Icons.gpp_maybe_outlined
          : Icons.casino_outlined;
    case _HubCategory.people:
      return Icons.chat_bubble_outline;
    case null:
      return Icons.arrow_forward;
  }
}

/// Runs a chosen [StoryChoice]'s full effect chain: ability checks or a
/// combat gate first, then reward effects and unlocks, then routing to
/// whatever comes next (an excursion sub-node, this choice's own
/// [StoryChoice.nextId], or a restart on an ending). Shared by every widget
/// that lets the player pick a choice — [_ChoiceButton]'s flat list and
/// [_HubChoiceCard]'s categorized "village" cards alike — so both act on a
/// chosen choice identically and never drift apart. [travelled]: see
/// [takeStoryChoice].
Future<void> _selectChoice({
  required BuildContext context,
  required WidgetRef ref,
  required StoryChoice choice,
  required StoryData story,
  required PlayerSession session,
  required String currentNodeId,
  required bool isExcursion,
  required bool french,
  bool travelled = false,
}) async {
  // A payment on the road the purse can't make stays shut, wherever the
  // choice is offered: it says why and waits (see _isChoiceLocked).
  final purse = ref.read(playerSessionProvider);
  if (_paymentShort(choice, purse.gold, isExcursion)) {
    showImmersiveNotice(context,
        icon: Icons.lock_outline,
        message: _goldShortText(ref, choice, purse.gold, french: french));
    return;
  }
  // The last fight's aftermath opened this scene, and a companion's remark
  // on the last choice; moving on retires both.
  ref.read(pendingAftermathProvider.notifier).state = null;
  ref.read(pendingCheckOutcomeProvider.notifier).state = null;
  ref.read(pendingPreludeProvider.notifier).state = const [];
  ref.read(pendingRoadNoteProvider.notifier).state = null;
  ref.read(pendingRemarksProvider.notifier).state = const [];
  // A written detour backed away from at its first beat: the road goes on,
  // nothing spent (see detour_scenes.dart).
  if (isExcursion && choice.nextId == detourLeaveNextId) {
    ref.read(storyPlayProvider.notifier).leaveExcursion();
    await _readThrough(ref, story);
    return;
  }
  // The beat of a written detour the choice is taken on, and how its roll
  // went, for the note it leaves (see _noteDetourBeat).
  final detourNodeId = ref.read(storyPlayProvider).activeExcursionNode?.id;
  bool? checkPassed;
  var skipRewardEffects = false;
  // What the choice showed of the player, for the party to remark on.
  RemarkKind? shown;
  // A sneak that works (avoidFightOnSuccess) leaves the fight behind.
  var fightAvoided = false;
  // Set out again after a lost crossing (see crossingRetryProvider): the
  // choice's check and fight went the party's way the first time, and
  // aren't played again; the crossing is.
  final crossingKey = choice.crossesLand
      ? '$currentNodeId#${_storyChoiceIndex(story, currentNodeId, choice)}'
      : null;
  final crossingRetry =
      crossingKey != null && ref.read(crossingRetryProvider) == crossingKey;
  if (crossingRetry) fightAvoided = true;
  if (choice.hasAbilityCheck && !crossingRetry) {
    bool success;
    if (choice.hasSkillChallenge) {
      final challengeResult =
          await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => SkillChallengeScreen(
          promptText: choice.textFor(french),
          ability: choice.checkAbility!,
          dc: choice.checkDC ?? 10,
          successesNeeded: choice.challengeSuccessesNeeded!,
          maxFailures: choice.challengeMaxFailures!,
          random: ref.read(storyCheckRandomProvider),
        ),
      ));
      if (!context.mounted) return;
      success = challengeResult ?? false;
    } else {
      final result = rollAbilityCheck(
        ability: choice.checkAbility!,
        dc: choice.checkDC ?? 10,
        session: session,
        random: ref.read(storyCheckRandomProvider),
      );
      final abilityLabel = tr(ref, '${result.ability}_label');
      final outcomeKey =
          result.success ? 'ability_check_success' : 'ability_check_fail';
      await showAbilityRoll(
        context,
        result: result,
        message: '$abilityLabel ${tr(ref, 'check_label')}: '
            '${result.roll} + ${result.modifier} = ${result.total} '
            '${tr(ref, 'vs_dc_label')} ${result.dc} — '
            '${tr(ref, outcomeKey)}',
      );
      if (!context.mounted) return;
      success = result.success;
    }
    checkPassed = success;
    if (success && choice.avoidFightOnSuccess) fightAvoided = true;
    // A check with no scene of its own to tell it is told in a sentence.
    if (checkOutcomeNeedsTelling(
      success: success,
      onTheRoad: isExcursion,
      hasFailScene: (choice.failNextId ?? '').isNotEmpty,
      isSneak: choice.avoidFightOnSuccess,
    )) {
      ref.read(pendingCheckOutcomeProvider.notifier).state =
          checkOutcomeLineFor(choice.checkAbility!,
              success: success,
              french: french,
              seed: Random().nextInt(1 << 20));
    }
    shown = !success
        ? RemarkKind.checkFailed
        : fightAvoided
            ? RemarkKind.sneakedPast
            : RemarkKind.checkPassed;
    if (!success) {
      final failTarget = choice.failNextId;
      if (failTarget != null && failTarget.isNotEmpty && !isExcursion) {
        if (failTarget == 'EXIT' || failTarget == 'END') {
          ref
              .read(storyPlayProvider.notifier)
              .restart(StoryRepository.startNodeId);
        } else {
          _noteRemark(ref, shown: shown);
          await _arriveAt(ref, story, failTarget);
        }
        return;
      }
      skipRewardEffects = true;
    }
  }

  if (choice.opensCharacterCreation) {
    await ref.read(playerSessionProvider.notifier).resetSession();
    if (!context.mounted) return;
    final started = await Navigator.of(context).push<bool>(
        creationToStoryRoute<bool>((_) => const RaceProfessionScreen()));
    // Back on the story with a new character, the Story tab's tour plays
    // (see TutorialTrigger in StoryPlayerScreen).
    if (started != true) return;
  }

  if (choice.launchesZone && !isExcursion) {
    // A main zone launched from its story beat: the expedition (and its
    // boss) must be cleared before the story moves on. A retreat or a
    // defeat simply leaves the player on this node.
    final zones = await loadedGameDb(ref, zonesSchema);
    final zone = zones[choice.launchZoneId] as Map<String, dynamic>?;
    final alreadyCleared = ref
        .read(playerSessionProvider)
        .completedZoneIds
        .contains(choice.launchZoneId);
    if (zone != null && !alreadyCleared) {
      ref.read(expeditionActiveProvider.notifier).state = true;
      if (!context.mounted) return;
      final cleared = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ExpeditionScreen(
              zoneId: choice.launchZoneId!,
              zone: zone,
              hostFight: choice.hostFight),
        ),
      );
      ref.read(expeditionActiveProvider.notifier).state = false;
      if (cleared != true) return;
    }
  }

  var resolvedEnemyIds =
      fightAvoided ? const <String>[] : choice.allTriggerEnemyIds;
  // A quest offered by the choice that fights counts that fight's kills:
  // the offer comes after it, so the kill counts are kept now.
  final killsBeforeFight = choice.triggersCombat &&
          !fightAvoided &&
          (choice.unlockQuestId ?? '').isNotEmpty
      ? Map<String, int>.of(ref.read(playerSessionProvider).enemyKillCounts)
      : null;
  if (choice.triggersCombat && !fightAvoided) {
    final enemies = await loadedGameDb(ref, enemiesSchema);
    final ids = await _resolveEnemyIds(ref, choice.allTriggerEnemyIds);
    resolvedEnemyIds = ids;
    final resolvedEnemies = {
      for (final eid in ids) eid: enemies[eid] as Map<String, dynamic>?,
    };
    if (resolvedEnemies.values.every((e) => e != null)) {
      ref.read(combatActiveProvider.notifier).state = true;
      if (!context.mounted) return;
      final won = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FightScreen(
            enemyId: ids.first,
            enemy: resolvedEnemies[ids.first]!,
            additionalEnemyIds: ids.skip(1).toList(),
            additionalEnemies: {
              for (final eid in ids.skip(1)) eid: resolvedEnemies[eid]!,
            },
            modifiers: EncounterModifiers.fromChoice(choice),
          ),
        ),
      );
      ref.read(combatActiveProvider.notifier).state = false;
      _noteFightAftermath(ref, french);
      final retreated = ref.read(lastFightRetreatedProvider);
      ref.read(lastFightRetreatedProvider.notifier).state = false;
      if (won != true && retreated) {
        // Got away: a detour is left behind; a story fight waits here.
        if (isExcursion) ref.read(storyPlayProvider.notifier).leaveExcursion();
        return;
      }
      if (won != true) {
        // A lost fight with a defeat branch is a scene, not a retry: the
        // story goes there and the choice's own effects and unlocks stay
        // the winner's. A permadeath loss never returns here (won is null).
        if (won == false && choice.hasLossBranch && !isExcursion) {
          await _arriveAt(ref, story, choice.loseNextId!);
        }
        return;
      }
    } else {
      // An enemy missing from the table (broken or edited data) is no free
      // win: the choice isn't taken, as a lost fight with no defeat branch,
      // and the player stays on this scene.
      final missing = [
        for (final entry in resolvedEnemies.entries)
          if (entry.value == null) entry.key,
      ];
      FlutterError.reportError(FlutterErrorDetails(
          exception: StateError('No enemy ${missing.join(', ')} for the '
              'fight of "${choice.text}"'),
          library: 'story'));
      return;
    }
  }

  // A sea battle the story starts (see story_ship_battle.dart): won, the
  // story goes on; lost, to its defeat scene. Edit Mode sails past it.
  if (choice.triggersShipBattle && ref.read(appModeProvider) != AppMode.edit) {
    if (!context.mounted) return;
    final won = await runStoryShipBattle(context, ref, choice.shipBattleId!,
        chapter: ref.read(reachedChapterProvider));
    if (won != true) {
      if (won == false && choice.hasLossBranch && !isExcursion) {
        await _arriveAt(ref, story, choice.loseNextId!);
      }
      return;
    }
  }

  // A long land route the choice crosses (v1.285.0, see
  // land_crossing.dart): played on its own screen before the choice takes
  // the story on; lost or turned back from, the party is where it set out
  // and the choice is not taken. Edit Mode walks past it.
  if (choice.crossesLand &&
      !travelled &&
      !isExcursion &&
      ref.read(appModeProvider) != AppMode.edit) {
    if (!context.mounted) return;
    final arrived = await runLandCrossing(context, ref, choice.landRouteId!);
    ref.read(crossingRetryProvider.notifier).state =
        arrived || !(choice.triggersCombat || choice.hasAbilityCheck)
            ? null
            : crossingKey;
    if (!arrived) return;
  }

  final playNotifier = ref.read(storyPlayProvider.notifier);
  var reactions = const <ApprovalChange>[];
  if (choice.hasEffects && !skipRewardEffects) {
    reactions =
        await ref.read(playerSessionProvider.notifier).applyChoiceEffects(
              goldMod: choice.goldMod,
              alignmentMod: choice.alignmentMod,
              healAmount: choice.healAmount,
              shortfallWounds: choice.shortfallWounds,
              flagsToAdd: choice.flagsToAdd,
              questIDToProgress: choice.questIDToProgress,
              bannerPieceId: choice.grantsBannerPieceId,
              itemId: choice.grantItemId,
              materials: choice.grantMaterials,
              loseAllyId: choice.loseAllyId,
              approvalMods: choice.approvalMods,
              companions:
                  ref.read(gameDbProvider(companionsSchema)).value ?? const {},
              // A detour's cache is loot, not greed.
              goldIsProfit: !isExcursion,
              origin: itemOriginHere(ref),
            );
    // The trainer's lesson (feature_unlocks.dart): a strike or a guard.
    final strike = choice.flagsToAdd.contains(trainerStrikeFlag);
    if (strike || choice.flagsToAdd.contains(trainerGuardFlag)) {
      await ref.read(playerSessionProvider.notifier).learnTrainerSkill(
          strike: strike,
          trees: await loadedGameDb(ref, skillTreesSchema),
          skills: await loadedGameDb(ref, skillsSchema));
    }
    // What the scene put in the pack (see StoryChoice.grantItemId).
    if (choice.grantsItem && context.mounted) {
      final items = ref.read(localizedDbProvider(itemsSchema)).value;
      final item = items?[choice.grantItemId] as Map<String, dynamic>?;
      final lang = ref.read(appLanguageProvider);
      final line = rewardItemLine(context,
          itemId: choice.grantItemId!, item: item, lang: lang);
      await showRewardCard(
        context,
        itemFoundCard(
            lang: lang, title: line.title, accent: line.accent, lines: [line]),
      );
    }
    // And the materials it hands over (see StoryChoice.grantMaterials),
    // told on the way: the story goes on under the card.
    if (choice.grantsMaterials && context.mounted) {
      final items = ref.read(localizedDbProvider(itemsSchema)).value;
      final lang = ref.read(appLanguageProvider);
      final lines = [
        for (final MapEntry(key: id, value: count)
            in choice.grantMaterials.entries)
          if (count > 0)
            () {
              final line = rewardItemLine(context,
                  itemId: id,
                  item: items?[id] as Map<String, dynamic>?,
                  lang: lang);
              return RewardLine(
                key: line.key,
                icon: line.icon,
                accent: line.accent,
                title: line.title,
                tag: line.tag,
                tagColor: line.tagColor,
                sub: line.sub,
                value: '×$count',
              );
            }(),
      ];
      if (lines.isNotEmpty) {
        await showRewardCard(
          context,
          itemFoundCard(
              lang: lang,
              title: tr(ref, 'reward_materials_title'),
              accent: lines.first.accent,
              lines: lines),
        );
      }
    }
    // How the party took it, before the story moves on.
    if (reactions.isNotEmpty && context.mounted) {
      await showApprovalReactions(context, ref, reactions);
    }
  }
  // A hazard on the road (v1.197): pushed through, the companions take
  // the wound the character took; waited out, a day goes by on the road.
  if (isExcursion && isHazardPush(choice) && choice.healAmount < 0) {
    await woundCompanionsOnRoad(ref, -choice.healAmount);
  } else if (isExcursion && isHazardWait(choice)) {
    await walkRoadStep(ref, watches: watchesPerDay);
  }
  // What the choice does to the coast (v1.195), once: taken again, or
  // after going back, it moves nothing.
  if (choice.hasPolitics && !skipRewardEffects && !isExcursion) {
    final index = _storyChoiceIndex(story, currentNodeId, choice);
    if (index >= 0) {
      await applyStoryPoliticsNow(ref, choice.politics!,
          nodeId: currentNodeId, key: choicePoliticsKey(currentNodeId, index));
    }
  } else if (choice.hasPolitics &&
      isExcursion &&
      (isClanCrisisNode(detourNodeId) || isSiegeNode(detourNodeId))) {
    // Your clan's crisis or fall, or a district's siege, met on the road
    // (clan_crisis.dart, district_attacks.dart).
    await applyStoryPoliticsNow(ref, choice.politics!,
        nodeId: detourNodeId!, key: '');
  }
  if (choice.hasUnlocks) {
    final enemyIds = resolvedEnemyIds.toSet();
    await ref.read(playerSessionProvider.notifier).unlockContent(
          shopId: choice.unlockShopId,
          questId: choice.unlockQuestId,
          enemyId: enemyIds.isEmpty ? null : enemyIds.first,
          // A stall met on a detour moves on with the road.
          shopUnlockNodeId: isExcursion ? roadShopNodeId : currentNodeId,
        );
    // A pack's remaining distinct enemy ids each get their own unlock
    // call -- the common (single-enemy) case above already covers the
    // first, so this is a no-op loop for every existing single-enemy
    // choice.
    for (final enemyId in enemyIds.skip(1)) {
      await ref
          .read(playerSessionProvider.notifier)
          .unlockContent(enemyId: enemyId);
    }
    if ((choice.unlockShopId ?? '').isNotEmpty) {
      // Silent — no popup here (the discovery modal below already
      // covers "something new happened"); the Achievements
      // screen is where this becomes visible.
      await ref.read(playerSessionProvider.notifier).checkAchievements();
    }
    final newShopId = choice.unlockShopId ?? '';
    final newQuestId = choice.unlockQuestId ?? '';
    if (killsBeforeFight != null && newQuestId.isNotEmpty) {
      final questRecord = (await loadedGameDb(ref, questsSchema))[newQuestId]
          as Map<String, dynamic>?;
      await ref
          .read(playerSessionProvider.notifier)
          .noteQuestOfferedBeforeFight(newQuestId, killsBeforeFight,
              quest: questRecord);
    }
    if (isExcursion && newShopId.isNotEmpty) {
      // A stall met on the road is only there while the player stands at
      // it: "Take a look" opens it now, and the Shops list marks it as met
      // on the road (see roadShopNodeId).
      final shop = (await loadedGameDb(ref, shopsSchema))[newShopId]
          as Map<String, dynamic>?;
      if (shop != null && context.mounted) {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ShopDetailScreen(shopId: newShopId, shop: shop)));
        if (!context.mounted) return;
      }
    } else if (newShopId.isNotEmpty || newQuestId.isNotEmpty) {
      // A job offered on a detour says what it is and can be accepted on
      // the spot, the same as one offered by the story.
      ref.read(pendingDiscoveryProvider.notifier).state = PendingDiscovery(
        shopId: newShopId.isNotEmpty ? newShopId : null,
        questId: newQuestId.isNotEmpty ? newQuestId : null,
      );
    }
  }

  // The next scene opens with what one of the party makes of it. An ending
  // starts the story over: nobody remarks on that.
  if (!choice.isEnding) {
    _noteRemark(
      ref,
      reactions: reactions,
      deed: RemarkDeed(
        alignmentMod: choice.alignmentMod,
        goldMod: isExcursion ? 0 : choice.goldMod,
        approvalMods: choice.approvalMods,
      ),
      deedKeys: isExcursion
          ? const []
          : deedKeysFor(
              currentNodeId,
              story.nodeFor(currentNodeId)?.choices ?? const <StoryChoice>[],
              choice,
              choice.flagsToAdd,
            ),
      shown: shown,
    );
  }

  if (isExcursion) {
    await _noteDetourBeat(ref, detourNodeId, choice,
        passed: checkPassed, french: french);
    playNotifier.advanceExcursion(slippedPast: fightAvoided);
    // Back on the story's road: a plain scene there is read through too.
    if (!ref.read(storyPlayProvider).isInExcursion) {
      await _readThrough(ref, story);
    }
    return;
  }

  if (choice.isEnding) {
    playNotifier.restart(StoryRepository.startNodeId);
    return;
  }

  // A way back to the camp goes to the camp the party stands for (see
  // camp_errands.dart).
  final nextId = storyChoiceTarget(choice,
      campNodeId: ref.read(currentCampNodeIdProvider));
  // Landed where the choice goes: the voyage was the way there, with its
  // days and its sea, and no road after it.
  if (travelled) {
    // The landing rolls as a road arriving there would (v1.361): what
    // waits off the quay, the chapter's landmark among it.
    final started = await startRoadEncounter(ref, story,
        fromNodeId: currentNodeId,
        toNodeId: nextId,
        historyLength: ref.read(storyPlayProvider).history.length,
        travels: true,
        origin: choice.text,
        originFr: choice.textFr);
    if (!context.mounted || started) return;
    await _arriveAt(ref, story, nextId);
    return;
  }

  // Setting out from one place for another is a step on the road: a
  // ration eaten and part of the day gone (see journey_rules.dart). A
  // choice that travels (the camp's main quest, on foot) is a walk
  // between places, as the camp's own trips are.
  // A move between two districts of one city is no road (v1.197, see
  // Geography.travelsBetween).
  final historyBefore = ref.read(storyPlayProvider).history.length;
  final world = await loadGeography(ref);
  final walks = !choice.opensCharacterCreation &&
      (choice.travels || world.travelsBetween(story, currentNodeId, nextId));
  // A walk between places takes the watches of where it goes (a far place
  // can take a day, see GeoPlace.watches).
  final watches = choice.travels
      ? world.watchesToNode(story.nodeFor(choice.travelPlaceId ?? ''),
          fallback: walkWatches)
      : 1;
  if (walks) {
    await walkRoadStep(ref, watches: watches);
    // What waits on this road (see road_events.dart), known before the
    // party set out, takes the place of a detour.
    final event = await roadEventOn(ref, story,
        fromNodeId: currentNodeId,
        toNodeId: nextId,
        historyLength: historyBefore);
    if (!context.mounted) return;
    if (event != null) {
      await startRoadEncounter(ref, story,
          fromNodeId: currentNodeId,
          toNodeId: nextId,
          historyLength: historyBefore,
          travels: choice.travels,
          watches: watches,
          taken: true);
      playNotifier.startExcursion(event, nextId,
          origin: choice.text, originFr: choice.textFr);
      return;
    }
  }

  // What else the road holds (see startRoadEncounter): a hunter, a
  // familiar face or a detour, on a change of place at rest.
  if (!choice.opensCharacterCreation) {
    final started = await startRoadEncounter(ref, story,
        fromNodeId: currentNodeId,
        toNodeId: nextId,
        historyLength: historyBefore,
        travels: choice.travels,
        watches: walks ? watches : 1,
        origin: choice.text,
        originFr: choice.textFr);
    if (!context.mounted) return;
    if (started) return;
  }
  await _arriveAt(ref, story, nextId);
}

/// Remembers [echoes] as read once they are on screen (see
/// PlayerSessionNotifier.noteEchoes), for the journal's What changed.
void noteShownEchoes(
    WidgetRef ref, PlayerSession session, List<SceneEcho> echoes) {
  final fresh = [
    for (final echo in echoes)
      if (!session.seenEchoKeys.contains(echo.key)) echo.key,
  ];
  if (fresh.isEmpty) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(playerSessionProvider.notifier).noteEchoes(fresh);
  });
}

/// What [choice], taken on the beat [nodeId] of a written detour (see
/// detour_scenes.dart), leaves for the next beat to open with: its note
/// (and its roll's), in place of a roll's plain line. Going in past the
/// first beat takes the scene's watches (a check or a fight in it: one),
/// and says so. Nothing for a detour of today's chain.
Future<void> _noteDetourBeat(WidgetRef ref, String? nodeId, StoryChoice choice,
    {required bool? passed, required bool french}) async {
  final play = ref.read(storyPlayProvider.notifier).scenePlay;
  final outcomes = play?.outcomes[nodeId];
  if (play == null || outcomes == null) return;
  final index = play.nodes
      .firstWhere((n) => n.id == nodeId)
      .choices
      .indexWhere((c) => identical(c, choice));
  final note = index < 0 || index >= outcomes.length
      ? ''
      : detourOutcomeNote(outcomes[index], french: french, passed: passed);
  final lines = [
    if (note.isNotEmpty) note,
    if (nodeId == play.firstNodeId && play.watches > 0)
      tr(ref, 'detour_takes_watch'),
  ];
  if (nodeId == play.firstNodeId && play.watches > 0) {
    await ref
        .read(playerSessionProvider.notifier)
        .passTime(play.watches, chapter: ref.read(reachedChapterProvider));
  }
  if (lines.isNotEmpty) {
    ref.read(pendingCheckOutcomeProvider.notifier).state = lines.join(' ');
  }
}

/// The road event waiting between [fromNodeId] and [toNodeId] (see
/// road_events.dart) as the detour it plays out as, or null for a quiet
/// road. Edit Mode's roads hold nothing.
Future<List<StoryNode>?> roadEventOn(
  WidgetRef ref,
  StoryData story, {
  required String fromNodeId,
  required String toNodeId,
  required int historyLength,
}) async {
  if (ref.read(appModeProvider) == AppMode.edit) return null;
  final chapter = ref.read(reachedChapterProvider);
  final condition = ref.read(chapterConditionProvider);
  // The land the road runs through (v1.197): its hazards, and the foes
  // that live there.
  final world = await loadGeography(ref);
  final biome = world.roadBiome(story, fromNodeId, toNodeId);
  final event = roadEventFor(
    story: story,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
    historyLength: historyLength,
    chapter: chapter,
    oddsFactor: (condition?.roadEventOdds ?? 1) *
        WeatherEffects.of(ref.read(skyHereProvider)?.today().kind).roadOdds,
    championShare: condition?.championShare ?? 0.4,
    shrineShare: condition?.shrineShare ?? 0.3,
    hazardShare: hazardShareFor(biome),
    world: world,
  );
  if (event == null) return null;
  final enemies = await loadedGameDb(ref, enemiesSchema);
  return roadEventChain(
    event,
    chapter: chapter,
    enemyPool: championPoolFor(enemies, chapter, biome: biome?.id),
    seed: stableHash('$fromNodeId>$toNodeId#$historyLength'),
    hazard: roadHazardFor(biome,
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        historyLength: historyLength),
  );
}

/// One step on the road (see PlayerSessionNotifier.takeRoadStep), of
/// [watches] (a walk between places is [walkWatches]), and what it cost
/// for the next scene to open with: the day's end, hunger, rations
/// running low. Edit Mode's roads cost nothing.
Future<void> walkRoadStep(WidgetRef ref, {int watches = 1}) async {
  if (ref.read(appModeProvider) == AppMode.edit) return;
  final step = await ref.read(playerSessionProvider.notifier).takeRoadStep(
      chapter: ref.read(reachedChapterProvider), watches: watches);
  if (!step.counted) return;
  final note = [
    if (step.dayEnded)
      tr(ref, 'road_note_day').replaceAll('{day}', '${step.day}'),
    if (step.hungry && step.hunger > 0)
      tr(ref, 'road_note_hungry').replaceAll('{n}', '${step.hunger}')
    else if (!step.hungry && step.provisionsLeft == 0)
      tr(ref, 'road_note_last')
    else if (!step.hungry && step.provisionsLeft <= 2)
      tr(ref, 'road_note_low').replaceAll('{n}', '${step.provisionsLeft}'),
  ].join(' ');
  ref.read(pendingRoadNoteProvider.notifier).state = note.isEmpty ? null : note;
}

/// Moves the story to [nodeId], reading plain scenes straight through: a
/// scene whose only way on just moves on (see scene_flow.dart) opens the
/// scene after it instead of asking for a press of its lone button, its
/// flags set on the way. Edit Mode stops at every scene.
Future<void> _arriveAt(WidgetRef ref, StoryData story, String nodeId) async {
  ref.read(storyPlayProvider.notifier).choose(nodeId);
  await _readThrough(ref, story);
}

/// Reads plain scenes straight through from where the story stands (see
/// [_arriveAt]).
Future<void> _readThrough(WidgetRef ref, StoryData story) async {
  final play = ref.read(storyPlayProvider.notifier);
  // The scene arrived at moves the coast first, once (v1.195).
  await applyEnterPolitics(ref, ref.read(storyPlayProvider).currentNodeId);
  if (ref.read(appModeProvider) == AppMode.edit) return;
  final french = ref.read(appLanguageProvider) == AppLanguage.fr;
  // A way on to another stop (another building, district or location, see
  // choice_flow.dart) is a stop; without the stops, one that leaves the
  // location (v1.209, see Geography.travelsBetween).
  final world = await loadGeography(ref);
  final preludes = <ScenePrelude>[];
  for (var i = 0; i < maxPassThrough; i++) {
    // Each scene read through on the way moves it too.
    await applyEnterPolitics(ref, ref.read(storyPlayProvider).currentNodeId);
    final session = ref.read(playerSessionProvider);
    final node = story.nodeFor(ref.read(storyPlayProvider).currentNodeId);
    if (node == null) break;
    final gateWorld = ref.read(coastGateWorldProvider);
    // It stops where the stop changes (a building, a district: see
    // choice_flow.dart).
    final stops = ref.read(storyStopsProvider);
    final way = passThroughChoiceOf(node, session.flags,
        hidden: (c) => choiceHiddenFor(c, session, gateWorld),
        travels: (from, to) =>
            stops?.changesStop(from, to) ??
            world.travelsBetween(story, from, to));
    // A way on the party cannot take yet stays a stop, with its reason.
    if (way == null ||
        isStoryChoiceLocked(way, story, session, world: gateWorld)) {
      break;
    }
    final parts = composeNarrationParts(node, session, story, french: french);
    preludes.add(ScenePrelude(
      nodeId: node.id,
      body: parts.text,
      echoes: parts.echoes,
      speaker: speakerLabelFor(node.speaker, french: french),
    ));
    if (way.flagsToAdd.isNotEmpty) {
      await ref
          .read(playerSessionProvider.notifier)
          .applyChoiceEffects(flagsToAdd: way.flagsToAdd);
    }
    if (way.hasPolitics) {
      final index = _storyChoiceIndex(story, node.id, way);
      if (index >= 0) {
        await applyStoryPoliticsNow(ref, way.politics!,
            nodeId: node.id, key: choicePoliticsKey(node.id, index));
      }
    }
    play.choose(way.nextId);
  }
  await applyEnterPolitics(ref, ref.read(storyPlayProvider).currentNodeId);
  if (preludes.isNotEmpty) {
    ref.read(pendingPreludeProvider.notifier).state = preludes;
  }
}

/// The news a chapter's card tells, in [lang]: the first
/// [_chapterCardNewsShown], then how many more the journal keeps.
List<String> chapterCardNews(List<CoastNews> news, AppLanguage lang) {
  final lines = [
    for (final n in news)
      if (n.textFor(lang).isNotEmpty) n.textFor(lang),
  ];
  if (lines.length <= _chapterCardNewsShown) return lines;
  return [
    ...lines.take(_chapterCardNewsShown),
    trFor(lang, 'coast_news_more')
        .replaceAll('{n}', '${lines.length - _chapterCardNewsShown}'),
  ];
}

/// News lines a chapter's card has room for.
const int _chapterCardNewsShown = 3;

/// [choice]'s place among [nodeId]'s choices (the key its politics are
/// remembered under, see choicePoliticsKey), -1 when it is none of them.
int _storyChoiceIndex(StoryData story, String nodeId, StoryChoice choice) {
  final choices = story.nodeFor(nodeId)?.choices ?? const <StoryChoice>[];
  final same = choices.indexWhere((c) => identical(c, choice));
  if (same >= 0) return same;
  return choices.indexWhere((c) =>
      c.nextId == choice.nextId &&
      c.text == choice.text &&
      c.textFr == choice.textFr);
}

/// The siege to meet on the road from [fromNodeId] to [toNodeId]
/// (district_attacks.dart): the sieges run out settled away first, then
/// one of the town either end stands in, or null.
Future<DistrictSiege?> _siegeOnRoad(
  WidgetRef ref,
  StoryData story,
  Geography geo, {
  required String fromNodeId,
  required String toNodeId,
  required int chapter,
}) async {
  final session = ref.read(playerSessionProvider.notifier);
  await session.settleExpiredSieges(
      data: ref.read(clanDataProvider), geography: geo, chapter: chapter);
  return siegeToMeet(ref.read(playerSessionProvider).politics,
      fromCity: geo.locationOfNode(story.nodeFor(fromNodeId))?.id ?? '',
      toCity: geo.locationOfNode(story.nodeFor(toNodeId))?.id ?? '');
}

/// What the road from [fromNodeId] to [toNodeId] holds (see
/// detour_pacing.dart), started as the excursion the story plays before
/// arriving; true when one was. Only a change of place (D1: never between
/// two scenes of one place) in the chapter the party has reached, at rest
/// (a crisis owes its detour, a set piece holds nothing), in this order:
/// an alignment event (a hunter's ambush for a Good or Evil character, a
/// temptation for a Neutral one, see alignment_events.dart), the chapter's
/// landmark when it is due, the cooldown, an owed detour, a familiar face
/// (see recurring_encounters.dart), then a detour by the pity timer: a
/// written scene that fits the road (detour_scenes.dart), else today's
/// chain (SubNodeEngine), with the lines of where the road leads.
/// [taken]: a road event holds the road (the caller starts it); only the
/// pacing notes it. The road's dice are its own (see detourRandomFor):
/// chosen the same way, it holds the same. Shared by the story's own
/// roads and the trips between the camp and its places (see
/// camp_travel.dart). Edit Mode's roads hold nothing.
Future<bool> startRoadEncounter(
  WidgetRef ref,
  StoryData story, {
  required String fromNodeId,
  required String toNodeId,
  required int historyLength,
  bool travels = false,
  int watches = 1,
  bool taken = false,
  String? origin,
  String? originFr,
}) async {
  if (ref.read(appModeProvider) == AppMode.edit) return false;
  final chapter = ref.read(reachedChapterProvider);
  final geo = await loadGeography(ref);
  final road = detourRoadBetween(story, geo,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      chapter: chapter,
      travels: travels,
      watches: watches);
  if (road == null) return false;
  final scenes = await loadDetourScenes(ref);
  final enemies = await loadedGameDb(ref, enemiesSchema);
  final session = ref.read(playerSessionProvider);
  final sessionNotifier = ref.read(playerSessionProvider.notifier);
  final playNotifier = ref.read(storyPlayProvider.notifier);
  final dice = ref.read(roadRandomProvider);
  // An alignment event, on a road at rest from chapter 2 on. The hunters
  // setting's saved value, not its default: a party that turned them off
  // meets none on the first road after a cold start.
  List<StoryNode>? alignmentEvent;
  final landmarkDue = landmarkDueOn(
      pacing: session.detourPacing,
      road: road,
      scenes: scenes,
      flags: session.flags.toSet());
  if (!taken &&
      !landmarkDue &&
      road.atRest &&
      chapter >= SubNodeEngine.firstDetourChapter) {
    await ref.read(alignmentHuntersEnabledProvider.notifier).loaded;
    // A hunter spared and set on betrayal comes first, when its road is
    // due (hunter_mercy.dart): it strikes from behind.
    final betrayer = await sessionNotifier.tickBetrayals();
    if (betrayer != null) {
      alignmentEvent = [betrayalAmbushNode(betrayer, enemies, dice())];
    }
    // A district of the town under siege (district_attacks.dart): the
    // sieges run out are settled first, then the one of the town the road
    // comes from or goes to is met, before your clan's crisis.
    final siege = await _siegeOnRoad(ref, story, geo,
        fromNodeId: fromNodeId, toNodeId: toNodeId, chapter: chapter);
    if (siege != null) {
      final node = buildSiegeNode(
          ref.read(playerSessionProvider).politics, siege,
          data: ref.read(clanDataProvider),
          geography: geo,
          enemies: enemies,
          chapter: chapter,
          random: dice());
      if (node != null) alignmentEvent ??= [node];
    }
    // Your clan's seat threatened, or fallen (clan_crisis.dart): before
    // any hunter.
    alignmentEvent ??= clanCrisisRoadEvent(session.politics,
        data: ref.read(clanDataProvider),
        geography: geo,
        enemies: enemies,
        chapter: chapter,
        gold: session.gold,
        materials: {
          for (final id in session.inventoryItemIds)
            if (id.startsWith('material_')) id: 0,
        }..updateAll(
            (id, _) => session.inventoryItemIds.where((i) => i == id).length),
        random: dice());
    // Your nemesis's trail, then its champion, its quest under way
    // (nemesis.dart).
    alignmentEvent ??= maybeChampionRoad(
        politics: session.politics,
        activeQuestIds: session.activeQuestIds,
        enemies: enemies,
        chapter: chapter,
        random: dice(),
        flags: session.flags,
        quests: await loadedGameDb(ref, questsSchema));
    alignmentEvent ??= maybeAlignmentEvent(
      alignmentScore: session.alignmentScore,
      activeQuestIds: session.activeQuestIds,
      completedQuestIds: session.completedQuestIds,
      enemies: enemies,
      chapter: chapter,
      random: dice(),
      enabled: ref.read(alignmentHuntersEnabledProvider),
      rollsSinceAmbush: session.alignmentRollsSinceAmbush,
    );
    // Sworn, the rivals' hunters (v5.2 step 3b) share the road and its
    // cooldown.
    alignmentEvent ??= maybeRivalHunter(
      politics: session.politics,
      data: ref.read(clanDataProvider),
      enemies: enemies,
      chapter: chapter,
      random: dice(),
      enabled: ref.read(alignmentHuntersEnabledProvider),
      cooledDown: session.alignmentRollsSinceAmbush >= hunterCooldownRolls,
      flags: session.flags,
      warded: wardedClansOf(session.rollBans),
    );
    await sessionNotifier.noteAlignmentRoll(
        ambushed:
            alignmentEvent != null && isHunterAmbushChain(alignmentEvent));
    // The Warding Cairn's wards count down (road_wards.dart).
    await sessionNotifier.tickRoadWards(
        data: ref.read(clanDataProvider), chapter: chapter);
  }
  // Someone met on an earlier road, when one may come.
  List<StoryNode>? familiarFace;
  final turn = planRoad(
    pacing: session.detourPacing,
    road: road,
    scenes: scenes,
    flags: session.flags.toSet(),
    random: detourRandomFor(
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        historyLength: historyLength,
        salt: session.runSeed),
    taken: taken || alignmentEvent != null,
    familiar: () {
      familiarFace = maybeRecurringEncounter(
        flags: session.flags.toSet(),
        chapter: chapter,
        random: dice(),
        enemyPool: SubNodeEngine.filterEnemyPool(
            enemies: enemies, unlockedEnemyIds: const [], chapter: chapter),
      );
      return familiarFace != null;
    },
  );
  await sessionNotifier.setDetourPacing(turn.next);
  if (taken) return false;
  void start(List<StoryNode> chain) => playNotifier
      .startExcursion(chain, toNodeId, origin: origin, originFr: originFr);
  switch (turn.kind) {
    case RoadTurnKind.quiet:
    case RoadTurnKind.owed:
      return false;
    case RoadTurnKind.taken:
      if (alignmentEvent == null) return false;
      start(alignmentEvent);
      return true;
    case RoadTurnKind.familiar:
      if (familiarFace == null) return false;
      start(familiarFace!);
      return true;
    case RoadTurnKind.detour:
      break;
  }
  final scene = turn.scene;
  if (scene != null) {
    final play = buildDetourScene(scene,
        chapter: chapter, random: dice(), enemies: enemies);
    playNotifier.startScene(play, toNodeId, origin: origin, originFr: originFr);
    return play.nodes.isNotEmpty;
  }
  // Today's chain, with the lines of where the road leads (the place it
  // is set at is the road's, not the camp's), unless a theme is forced
  // (Edit Mode's).
  final shops = await loadedGameDb(ref, shopsSchema);
  final quests = await loadedGameDb(ref, questsSchema);
  final pools = await loadPlacePools(ref);
  final forcedTheme = ref.read(mapThemeProvider);
  final toNode = story.nodeFor(toNodeId);
  final resolvedTheme = forcedTheme ??
      mapThemeForUiTheme(toNode?.uiTheme ?? story.nodeFor(fromNodeId)?.uiTheme);
  final location =
      geo.placeOfNode(toNode)?.id ?? story.nodeFor(fromNodeId)?.location;
  final chain = SubNodeEngine.maybeGenerate(
    random: dice(),
    triggerChance: 1.0,
    chapter: chapter,
    shops: shops,
    enemies: enemies,
    quests: quests,
    unlockedShopIds: session.unlockedShopIds,
    unlockedEnemyIds: session.unlockedEnemyIds,
    unlockedQuestIds: session.unlockedQuestIds,
    completedQuestIds: session.completedQuestIds,
    theme: resolvedTheme,
    flavor: forcedTheme != null
        ? null
        : pools.flavorAt(
            chain: placeChainOf(geo, location),
            biomeId: road.biome ?? placeBiomeOf(geo, location),
            theme: resolvedTheme,
            chapter: chapter,
            mood: toNode?.mood,
          ),
    partySize: 1 + session.activeAllyIds.length,
    alignmentLabel: session.alignmentLabel,
  );
  if (chain == null || chain.isEmpty) return false;
  start(chain);
  return true;
}

/// `@first_ally` among a choice's enemies is the first active companion
/// (never Vica, v1.601),
/// turned: they leave the party for good before the fight and stand across
/// the sand as `<id>_turned`; with no one left to turn, the Inquisition's
/// own champion takes the field. The flags `companion_turned` /
/// `legate_fought` let the scene say which it was.
Future<List<String>> _resolveEnemyIds(WidgetRef ref, List<String> ids) async {
  if (!ids.contains('@first_ally')) return ids;
  final notifier = ref.read(playerSessionProvider.notifier);
  final session = ref.read(playerSessionProvider);
  final companions =
      ref.read(gameDbProvider(companionsSchema)).value ?? const {};
  // Never Vica, who cannot be taken (story_companions.dart).
  final allyId =
      storyLossOf('*', active: session.activeAllyIds, companions: companions);
  if (allyId != null) {
    notifier.loseAlly(allyId, companions: companions);
    await notifier.applyChoiceEffects(flagsToAdd: const ['companion_turned']);
  } else {
    await notifier.applyChoiceEffects(flagsToAdd: const ['legate_fought']);
  }
  return [
    for (final id in ids)
      if (id == '@first_ally')
        allyId == null ? 'inquisition_legate' : '${allyId}_turned'
      else
        id,
  ];
}

/// Picks what one of the party says about the choice just made (see
/// companion_remarks.dart) for the next scene to open with: [reactions] to
/// [deed] if it moved anyone, else, now and then, what the choice [shown]
/// of the player.
void _noteRemark(
  WidgetRef ref, {
  List<ApprovalChange> reactions = const [],
  RemarkDeed deed = const RemarkDeed(),
  List<String> deedKeys = const [],
  RemarkKind? shown,
}) {
  ref.read(pendingRemarksProvider.notifier).state = speakUpAbout(ref,
      reactions: reactions, deed: deed, deedKeys: deedKeys, action: shown);
}

/// Writes the fight that just ended into the next scene's opening line
/// (or, after a retreat, into this scene's -- the player is still here).
/// Nothing after a permadeath: the fight screen retires its outcome before
/// the death screen, so the new character's first scene opens clean.
void _noteFightAftermath(WidgetRef ref, bool french) {
  final outcome = ref.read(lastFightOutcomeProvider);
  if (outcome == null) return;
  ref.read(pendingAftermathProvider.notifier).state = aftermathLineFor(
    outcome,
    french: french,
    seed: Random().nextInt(1 << 20),
  );
}

/// A node's text as this player reads it: the companion's line in their
/// own voice, then the hub's what-has-changed note, the callbacks the
/// player's flags earned and the sentence for their race or profession,
/// with every `{name}`/`{race}`/`{profession}` token filled in. Exposed
/// so the narration tests can read a scene the way the screen does.
String composeNarration(StoryNode node, PlayerSession session,
        {required bool french}) =>
    _composeNarration(node, session, french: french);

/// A node's text as [composeNarration] gives it, less the lines earned by
/// an earlier choice of [story], which come back apart as echoes, each
/// with the choice that earned it (see echoes.dart).
({String text, List<SceneEcho> echoes}) composeNarrationParts(
    StoryNode node, PlayerSession session, StoryData story,
    {required bool french}) {
  final echoes = <SceneEcho>[];
  final text = _composeNarration(node, session,
      french: french, story: story, echoesOut: echoes);
  return (text: text, echoes: echoes);
}

String _composeNarration(StoryNode node, PlayerSession session,
    {required bool french, StoryData? story, List<SceneEcho>? echoesOut}) {
  final buffer = StringBuffer(withAllyAcknowledgment(
    node.id,
    node.descriptionFor(french),
    activeAllyIds: session.activeAllyIds,
    french: french,
  ));
  final progress = node.hubProgressLineFor(session.flags, french);
  final echoed = <FlagCallback>[];
  final callbacks = <String>[];
  for (final callback in node.firedCallbacks(session.flags)) {
    if (story != null &&
        echoesOut != null &&
        echoCause(story, callback.flag) != null) {
      echoed.add(callback);
    } else {
      callbacks.add(callback.line.textFor(french));
    }
  }
  final extras = [
    if (progress != null) progress,
    ...callbacks,
    ...node.personaLinesFor(
      raceId: session.raceId,
      professionId: session.professionId,
      french: french,
    ),
  ];
  for (final extra in extras) {
    buffer.write('\n\n');
    buffer.write(extra);
  }
  final firstAlly =
      session.activeAllyIds.isEmpty ? null : session.activeAllyIds.first;
  final lastLost =
      session.lostAllyIds.isEmpty ? null : session.lostAllyIds.last;
  String? capitalized(String? id) => id == null || id.isEmpty
      ? null
      : '${id[0].toUpperCase()}${id.substring(1)}';
  String personal(String text) => personalizeNarration(
        text,
        name: session.characterName,
        raceId: session.raceId,
        professionId: session.professionId,
        companionName: capitalized(firstAlly),
        lostCompanionName: capitalized(lastLost),
        french: french,
      );
  for (final callback in echoed) {
    echoesOut!.add(SceneEcho(
      nodeId: node.id,
      flag: callback.flag,
      line: personal(callback.line.textFor(french)),
      cause: personal(echoCause(story!, callback.flag)!.textFor(french)),
    ));
  }
  return personal(buffer.toString());
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_aftermath.dart';
import '../combat/combat_engine.dart' show newGamePlusStep;
import '../combat/encounter.dart';
import '../data/ability_check.dart';
import '../data/alignment_events.dart';
import '../data/ally_acknowledgments.dart';
import '../data/chapter_spine.dart';
import '../data/encounter_text.dart';
import '../data/map_themes.dart';
import '../data/narration_tokens.dart';
import '../data/port_helpers.dart';
import '../data/settlements.dart';
import '../data/story_repository.dart';
import '../data/sub_node_engine.dart';
import '../data/ui_theme_palettes.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/aftermath_provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/gemini_tts_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_theme_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/settings_providers.dart';
import '../providers/story_providers.dart';
import '../providers/tts_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/voice_settings_provider.dart';
import '../providers/walk_companion_provider.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/walking_companion_strip.dart';
import '../widgets/zone_card.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'expedition_screen.dart';
import 'fight_screen.dart';
import 'race_profession_screen.dart';
import 'shop_detail_screen.dart';
import 'skill_challenge_screen.dart';
import 'story_node_editor_screen.dart';

/// Tracks the id of the last scene auto-read aloud, so the auto-read
/// effect (see [_StoryView.build]) speaks each scene exactly once instead
/// of re-triggering on every rebuild that doesn't actually change the
/// displayed node.
final _autoReadLastNodeKeyProvider = StateProvider<String?>((ref) => null);

/// Whether the status header (level/HP/gold and the quests/shops chips) is
/// collapsed to give the narration more room. Resets on app restart —
/// a per-session reading preference, not a persisted setting.
final _statusBarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Whether the walking companion strip is collapsed. Independent from
/// [walkCompanionEnabledProvider] (the permanent Settings toggle that
/// disables the feature outright) — this is a quick per-session way to
/// hide the dog without turning the feature off.
final _companionCollapsedProvider = StateProvider<bool>((ref) => false);

/// Whether the story text is showing in distraction-free fullscreen —
/// toggled by double-tapping the narration itself, hiding everything else
/// (status bar, header row, companion strip, choices) so only the prose
/// remains. Resets on app restart, same as the other reading-view toggles
/// above.
final _fullscreenReadingProvider = StateProvider<bool>((ref) => false);

/// The last story scene the reader was shown (detours aside), so reaching a
/// town or camp can tell an arrival from a return out of one of its own
/// scenes.
final _lastStoryNodeIdProvider = StateProvider<String?>((ref) => null);

/// Speaks [text] via the device's on-device text-to-speech engine — the
/// fast default voice, used for auto-read and as read-aloud's fallback
/// when the (opt-in) Gemini voice isn't enabled.
Future<void> _speakNarration(WidgetRef ref, String text, AppLanguage language) {
  return ref.read(ttsProvider.notifier).speak(text, language);
}

void _stopAllNarration(WidgetRef ref) {
  ref.read(ttsProvider.notifier).stop();
  ref.read(geminiTtsProvider.notifier).stop();
}

class StoryPlayerScreen extends ConsumerWidget {
  const StoryPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyAsync = ref.watch(storyDataProvider);

    return storyAsync.when(
      data: (story) => _StoryView(story: story),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('${tr(ref, 'failed_to_load_story')}: $error'),
        ),
      ),
    );
  }
}

class _StoryView extends ConsumerWidget {
  const _StoryView({required this.story});

  final StoryData story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playState = ref.watch(storyPlayProvider);
    final notifier = ref.read(storyPlayProvider.notifier);
    final session = ref.watch(playerSessionProvider);
    final node =
        playState.activeExcursionNode ?? story.nodeFor(playState.currentNodeId);
    final language = ref.watch(appLanguageProvider);
    final french = language == AppLanguage.fr;
    final displayDescription =
        node == null ? '' : composeNarration(node, session, french: french);
    final epilogue = node?.epilogueFor(session.alignmentLabel, french);
    final pendingAftermath = ref.watch(pendingAftermathProvider);
    final speakerLabel = speakerLabelFor(node?.speaker, french: french);
    final walkCompanionEnabled = ref.watch(walkCompanionEnabledProvider);
    final statusBarCollapsed = ref.watch(_statusBarCollapsedProvider);
    final companionCollapsed = ref.watch(_companionCollapsedProvider);
    final fullscreenReading = ref.watch(_fullscreenReadingProvider);

    // Stop any in-progress narration when the story moves to a different
    // node, so stale audio never plays over newly-displayed text.
    ref.listen<StoryPlayState>(storyPlayProvider, (previous, next) {
      final prevId =
          previous?.activeExcursionNode?.id ?? previous?.currentNodeId;
      final nextId = next.activeExcursionNode?.id ?? next.currentNodeId;
      if (prevId != nextId) {
        _stopAllNarration(ref);
      }
    });

    final pendingDiscovery = ref.watch(pendingDiscoveryProvider);
    if (pendingDiscovery != null) {
      final shopsAsync = ref.watch(gameDbProvider(shopsSchema));
      final questsAsync = ref.watch(gameDbProvider(questsSchema));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(pendingDiscoveryProvider.notifier).state = null;
        _showDiscoveryModal(
          context,
          ref,
          pendingDiscovery,
          shops: shopsAsync.value ?? const {},
          quests: questsAsync.value ?? const {},
        );
      });
    }

    if (node == null) {
      return _EndingView(
        title: tr(ref, 'trail_cold_title'),
        message: tr(ref, 'trail_cold_message'),
        restartLabel: tr(ref, 'restart_story'),
        onRestart: () => notifier.restart(StoryRepository.startNodeId),
      );
    }

    // Arriving in a town or camp from elsewhere in the story says so, and
    // what the place offers, before anything else happens there.
    if (!playState.isInExcursion &&
        ref.read(_lastStoryNodeIdProvider) != node.id) {
      final previousNodeId = ref.read(_lastStoryNodeIdProvider);
      final arrivedNode = node;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (ref.read(_lastStoryNodeIdProvider) == arrivedNode.id) return;
        ref.read(_lastStoryNodeIdProvider.notifier).state = arrivedNode.id;
        final settlement = arrivedNode.settlement;
        if (settlement != null &&
            isSettlementArrival(arrivedNode.id, previousNodeId)) {
          _showSettlementArrival(context, ref, settlement, french);
        }
      });
    }

    // Fetch this node's Gemini narration ahead of time (if that voice is
    // in use) so tapping read-aloud plays back instantly instead of
    // waiting on a network round-trip. preload() itself no-ops once this
    // node's clip is cached or already in flight, so calling it on every
    // rebuild is cheap.
    final geminiVoiceForPreload = ref.watch(geminiVoiceSettingsProvider);
    final apiKeyForPreload = ref.watch(apiKeyProvider);
    if (geminiVoiceForPreload.enabled &&
        (apiKeyForPreload?.isNotEmpty ?? false)) {
      ref.read(geminiTtsProvider.notifier).preload(
            text: storyBodyFor(displayDescription),
            apiKey: apiKeyForPreload!,
            voiceName: geminiVoiceForPreload.voiceName,
            language: language,
          );
    }

    // Auto-read: once enabled, speak each scene the moment it appears
    // instead of waiting for a manual tap on the read-aloud button — always
    // via the fast on-device voice, never Gemini (which would mean a
    // network wait on every single scene).
    if (ref.watch(autoReadAloudProvider)) {
      final autoReadKey = '${node.id}_${playState.isInExcursion}';
      if (ref.read(_autoReadLastNodeKeyProvider) != autoReadKey) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          ref.read(_autoReadLastNodeKeyProvider.notifier).state = autoReadKey;
          ref.read(geminiTtsProvider.notifier).stop();
          try {
            await _speakNarration(
                ref, storyBodyFor(displayDescription), language);
          } catch (e) {
            // Auto-read fires without the player asking for it, so a
            // failure here must still surface — otherwise it just looks
            // like the voice silently never triggers.
            if (!context.mounted) return;
            showImmersiveNotice(
              context,
              icon: Icons.error_outline,
              message: '${tr(ref, 'voice_error_prefix')}: $e',
            );
          }
        });
      }
    }

    // A hub activity already done this visit (see StoryChoice.hideIfFlags)
    // drops out of the list entirely -- the hub keeps its "village" layout
    // off the node's full authored choice count, not the remaining one, so
    // it doesn't snap back to a flat list as the last activities are used.
    final isHubNode = _isHubNode(node);
    final visibleChoices =
        node.choices.where((c) => !c.isHiddenFor(session.flags)).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // No dedicated expand/collapse icon button — it only ever sat
            // alone taking up its own row, in the way without adding much.
            // Tapping the header itself now toggles it, on top of the
            // existing auto-collapse on scroll-down below.
            if (fullscreenReading)
              const SizedBox.shrink()
            else if (statusBarCollapsed)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => ref
                    .read(_statusBarCollapsedProvider.notifier)
                    .state = false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => ref
                        .read(_statusBarCollapsedProvider.notifier)
                        .state = true,
                    child: const PlayerStatsBar(),
                  ),
                  if (session.activeQuestIds.isNotEmpty ||
                      session.unlockedShopIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (session.activeQuestIds.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(Icons.assignment, size: 16),
                            label: Text(
                                '${tr(ref, 'quests')} (${session.activeQuestIds.length})'),
                            onPressed: () => ref
                                .read(homeTabIndexProvider.notifier)
                                .state = 1,
                          ),
                        if (session.unlockedShopIds.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(Icons.storefront, size: 16),
                            label: Text(
                                '${tr(ref, 'shops')} (${session.unlockedShopIds.length})'),
                            onPressed: () => ref
                                .read(homeTabIndexProvider.notifier)
                                .state = 1,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            if (!fullscreenReading) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (playState.history.isNotEmpty &&
                      ref.watch(appModeProvider) == AppMode.edit)
                    TextButton.icon(
                      onPressed: notifier.goBack,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(tr(ref, 'back')),
                    ),
                  const Spacer(),
                  _ReadAloudButton(
                      text: displayDescription, language: language),
                  const SizedBox(width: 4),
                  Text(
                    playState.isInExcursion
                        ? tr(ref, 'detour')
                        : '${tr(ref, 'node')} ${node.id}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (!playState.isInExcursion &&
                      ref.watch(appModeProvider) == AppMode.edit) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: tr(ref, 'edit_node'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StoryNodeEditorScreen(node: node),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              // Scrolling down into the narration gives the status bar and
              // companion collapse toggles above/below no purpose (they'd
              // just be pushed off-screen anyway), so collapse both
              // automatically the moment the player starts reading down the
              // page. The manual chevrons stay available to re-expand.
              child: LayoutBuilder(
                // Captured here, above the SingleChildScrollView, because
                // that view gives its child unbounded height on the scroll
                // axis -- a LayoutBuilder nested inside it would only ever
                // see infinite height, not the actual viewport size.
                builder: (context, viewportConstraints) {
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification &&
                          (notification.scrollDelta ?? 0) > 0) {
                        if (!statusBarCollapsed) {
                          ref.read(_statusBarCollapsedProvider.notifier).state =
                              true;
                        }
                        if (!companionCollapsed) {
                          ref.read(_companionCollapsedProvider.notifier).state =
                              true;
                        }
                      }
                      return false;
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: () => ref
                          .read(_fullscreenReadingProvider.notifier)
                          .state = !fullscreenReading,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: _nodeTransition,
                        child: SingleChildScrollView(
                          key: ValueKey(
                              '${node.id}_${playState.isInExcursion}_text'),
                          // Short narration otherwise leaves the freed-up
                          // space (status bar, node header, companion strip,
                          // choices all hidden) as dead blank area below the
                          // text card, which reads as "nothing happened"
                          // rather than an actual fullscreen mode. Centering
                          // it in the full viewport height makes the
                          // toggle's effect obvious.
                          child: fullscreenReading
                              ? SizedBox(
                                  // A ConstrainedBox with only minHeight set
                                  // still leaves maxHeight unbounded here
                                  // (SingleChildScrollView never bounds its
                                  // child's height) -- and Center collapses
                                  // to wrap-content, ignoring minHeight,
                                  // whenever its incoming max is unbounded.
                                  // A fixed-height SizedBox forces a tight
                                  // constraint so Center actually centers.
                                  height: viewportConstraints.maxHeight,
                                  child: Center(
                                    child: _StoryText(
                                      text: displayDescription,
                                      uiTheme: node.uiTheme,
                                      epilogue: epilogue,
                                      speakerLabel: speakerLabel,
                                      aftermath: pendingAftermath,
                                      aftermathHeading:
                                          tr(ref, 'aftermath_heading'),
                                      epilogueHeading:
                                          tr(ref, 'epilogue_heading'),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (playState.isInExcursion)
                                      _DetourContextCard(
                                        origin: playState
                                            .excursionOriginFor(french),
                                        note: node.contextNoteFor(french),
                                      ),
                                    _StoryText(
                                      text: displayDescription,
                                      uiTheme: node.uiTheme,
                                      epilogue: epilogue,
                                      speakerLabel: speakerLabel,
                                      aftermath: pendingAftermath,
                                      aftermathHeading:
                                          tr(ref, 'aftermath_heading'),
                                      epilogueHeading:
                                          tr(ref, 'epilogue_heading'),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!fullscreenReading) ...[
              if (walkCompanionEnabled) ...[
                if (!companionCollapsed)
                  WalkingCompanionStrip(
                    trigger: '${node.id}_${playState.isInExcursion}',
                    fightAvailable: node.choices.any(
                      (c) =>
                          c.triggersCombat &&
                          !_isChoiceLocked(
                              c, story, session, playState.isInExcursion),
                    ),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(companionCollapsed
                        ? Icons.expand_more
                        : Icons.expand_less),
                    tooltip: tr(
                        ref,
                        companionCollapsed
                            ? 'show_companion'
                            : 'hide_companion'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref
                        .read(_companionCollapsedProvider.notifier)
                        .state = !companionCollapsed,
                  ),
                ),
              ] else
                const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _nodeTransition,
                child: Column(
                  key:
                      ValueKey('${node.id}_${playState.isInExcursion}_choices'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (node.choices.isEmpty)
                      _EndingView(
                        title: tr(ref, 'the_end'),
                        message: tr(ref, 'branch_end_message'),
                        restartLabel: tr(ref, 'restart_story'),
                        onRestart: () =>
                            notifier.restart(StoryRepository.startNodeId),
                        session: session,
                        onNewGamePlus: session.raceId.isEmpty
                            ? null
                            : () => _startNewGamePlus(context, ref),
                      )
                    else if (isHubNode)
                      _HubSections(
                        node: node,
                        choices: visibleChoices,
                        story: story,
                        session: session,
                        currentNodeId: playState.currentNodeId,
                        isExcursion: playState.isInExcursion,
                        french: french,
                      )
                    else ...[
                      for (var i = 0; i < visibleChoices.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _StaggeredReveal(
                            delay: Duration(milliseconds: 60 * i),
                            child: _ChoiceButton(
                              choice: visibleChoices[i],
                              story: story,
                              session: session,
                              currentNodeId: playState.currentNodeId,
                              isExcursion: playState.isInExcursion,
                              french: french,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Whether [choice] is currently unreachable because its target node has
/// requirements the player doesn't meet (shown disabled with its
/// lockedText instead of being selectable).
bool _isChoiceLocked(
  StoryChoice choice,
  StoryData story,
  PlayerSession session,
  bool isExcursion,
) {
  final targetNode =
      (isExcursion || choice.isEnding) ? null : story.nodeFor(choice.nextId);
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

/// A node with this many choices or fewer keeps the plain flat list it's
/// always had — most nodes are a handful of genuinely distinct narrative
/// branches, and boxing those into sections would just add ceremony. Above
/// it, a node reads less like "a decision" and more like "a place with
/// several independent things to do" (shop here, fight that, talk to
/// them), so [_HubSections] takes over presenting everything but the node's
/// own main branches.
const int _hubChoiceThreshold = 5;

bool _isHubNode(StoryNode node) => node.choices.length > _hubChoiceThreshold;

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
/// chosen choice identically and never drift apart.
Future<void> _selectChoice({
  required BuildContext context,
  required WidgetRef ref,
  required StoryChoice choice,
  required StoryData story,
  required PlayerSession session,
  required String currentNodeId,
  required bool isExcursion,
  required bool french,
}) async {
  // The last fight's aftermath opened this scene; moving on retires it.
  ref.read(pendingAftermathProvider.notifier).state = null;
  var skipRewardEffects = false;
  if (choice.hasAbilityCheck) {
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
        ),
      ));
      if (!context.mounted) return;
      success = challengeResult ?? false;
    } else {
      final result = rollAbilityCheck(
        ability: choice.checkAbility!,
        dc: choice.checkDC ?? 10,
        session: session,
      );
      final abilityLabel = tr(ref, '${result.ability}_label');
      final outcomeKey =
          result.success ? 'ability_check_success' : 'ability_check_fail';
      await showImmersiveNotice(
        context,
        icon: result.success ? Icons.check_circle : Icons.cancel,
        message: '$abilityLabel ${tr(ref, 'check_label')}: '
            '${result.roll} + ${result.modifier} = ${result.total} '
            '${tr(ref, 'vs_dc_label')} ${result.dc} — '
            '${tr(ref, outcomeKey)}',
      );
      if (!context.mounted) return;
      success = result.success;
    }
    if (!success) {
      final failTarget = choice.failNextId;
      if (failTarget != null && failTarget.isNotEmpty && !isExcursion) {
        if (failTarget == 'EXIT' || failTarget == 'END') {
          ref
              .read(storyPlayProvider.notifier)
              .restart(StoryRepository.startNodeId);
        } else {
          ref.read(storyPlayProvider.notifier).choose(failTarget);
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
        MaterialPageRoute(builder: (_) => const RaceProfessionScreen()));
    if (started != true) return;
    // Show the guided tour once the player is back on the story
    // view with a freshly created character, rather than on any
    // generic "entered the app" trigger.
    final tutorial = ref.read(tutorialProvider);
    if (tutorial.enabled && !tutorial.seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showTutorialOverlay(context, ref);
      });
    }
  }

  if (choice.launchesZone && !isExcursion) {
    // A main zone launched from its story beat: the expedition (and its
    // boss) must be cleared before the story moves on. A retreat or a
    // defeat simply leaves the player on this node.
    final zones = ref.read(gameDbProvider(zonesSchema)).value;
    final zone = zones?[choice.launchZoneId] as Map<String, dynamic>?;
    final alreadyCleared = ref
        .read(playerSessionProvider)
        .completedZoneIds
        .contains(choice.launchZoneId);
    if (zone != null && !alreadyCleared) {
      ref.read(expeditionActiveProvider.notifier).state = true;
      if (!context.mounted) return;
      final cleared = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              ExpeditionScreen(zoneId: choice.launchZoneId!, zone: zone),
        ),
      );
      ref.read(expeditionActiveProvider.notifier).state = false;
      if (cleared != true) return;
    }
  }

  var resolvedEnemyIds = choice.allTriggerEnemyIds;
  if (choice.triggersCombat) {
    final enemies = ref.read(gameDbProvider(enemiesSchema)).value;
    final ids = await _resolveEnemyIds(ref, choice.allTriggerEnemyIds);
    resolvedEnemyIds = ids;
    final resolvedEnemies = {
      for (final eid in ids) eid: enemies?[eid] as Map<String, dynamic>?,
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
      if (won != true) {
        // A lost fight with a defeat branch is a scene, not a retry: the
        // story goes there and the choice's own effects and unlocks stay
        // the winner's. A permadeath loss never returns here (won is null).
        if (won == false && choice.hasLossBranch && !isExcursion) {
          ref.read(storyPlayProvider.notifier).choose(choice.loseNextId!);
        }
        return;
      }
    }
  }

  final playNotifier = ref.read(storyPlayProvider.notifier);
  if (choice.hasEffects && !skipRewardEffects) {
    ref.read(playerSessionProvider.notifier).applyChoiceEffects(
          goldMod: choice.goldMod,
          alignmentMod: choice.alignmentMod,
          healAmount: choice.healAmount,
          flagsToAdd: choice.flagsToAdd,
          questIDToProgress: choice.questIDToProgress,
          bannerPieceId: choice.grantsBannerPieceId,
          loseAllyId: choice.loseAllyId,
        );
  }
  if (choice.hasUnlocks) {
    final enemyIds = resolvedEnemyIds.toSet();
    await ref.read(playerSessionProvider.notifier).unlockContent(
          shopId: choice.unlockShopId,
          questId: choice.unlockQuestId,
          enemyId: enemyIds.isEmpty ? null : enemyIds.first,
          shopUnlockNodeId: currentNodeId,
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
    if (isExcursion && newShopId.isNotEmpty) {
      // A stall met on the road is only there while the player stands at
      // it: "Take a look" opens it now. (Recorded against the scene the
      // detour left, it could never be reached from the Shops tab.)
      final shop = (ref.read(gameDbProvider(shopsSchema)).value ??
          const {})[newShopId] as Map<String, dynamic>?;
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

  if (isExcursion) {
    playNotifier.advanceExcursion();
    return;
  }

  if (choice.isEnding) {
    playNotifier.restart(StoryRepository.startNodeId);
    return;
  }

  // A choice that loops back onto its own node (a shop visit at the docks
  // hub, say) is a moment inside the same scene, not a step down the road
  // -- no excursion or alignment event rolls for it.
  final chapter = chapterForNode(currentNodeId);
  final atRest = SubNodeEngine.detourAllowedBetween(
    story.nodeFor(currentNodeId)?.mood,
    story.nodeFor(choice.nextId)?.mood,
  );
  if (chapter != null &&
      !choice.opensCharacterCreation &&
      choice.nextId != currentNodeId &&
      !atRest) {
    // A crisis runs on from this scene into the next: whatever the road
    // held waits until it is over.
    if (Random().nextDouble() < SubNodeEngine.detourChance) {
      playNotifier.oweDetour();
    }
  }
  if (chapter != null &&
      !choice.opensCharacterCreation &&
      choice.nextId != currentNodeId &&
      atRest) {
    final shops = ref.read(gameDbProvider(shopsSchema)).value ?? const {};
    final enemies = ref.read(gameDbProvider(enemiesSchema)).value ?? const {};
    final quests = ref.read(gameDbProvider(questsSchema)).value ?? const {};
    final manualTheme = ref.read(mapThemeProvider);
    final resolvedTheme = manualTheme ??
        mapThemeForUiTheme(story.nodeFor(currentNodeId)?.uiTheme);
    // Alignment has consequences on the road before anything else rolls:
    // a hunter's ambush for a Good/Evil character, a temptation for a
    // Neutral one (see alignment_events.dart). One fires instead of, not
    // on top of, an ordinary excursion this transition.
    final alignmentEvent = maybeAlignmentEvent(
      alignmentScore: session.alignmentScore,
      activeQuestIds: session.activeQuestIds,
      completedQuestIds: session.completedQuestIds,
      enemies: enemies,
      chapter: chapter,
      random: Random(),
      enabled: ref.read(alignmentHuntersEnabledProvider),
    );
    if (alignmentEvent != null) {
      playNotifier.startExcursion(alignmentEvent, choice.nextId,
          origin: choice.text, originFr: choice.textFr);
      return;
    }
    final excursion = SubNodeEngine.maybeGenerate(
      random: Random(),
      // A detour put off by a crisis is taken at the first road after it.
      triggerChance:
          playNotifier.takeOwedDetour() ? 1.0 : SubNodeEngine.detourChance,
      chapter: chapter,
      shops: shops,
      enemies: enemies,
      quests: quests,
      unlockedShopIds: session.unlockedShopIds,
      unlockedEnemyIds: session.unlockedEnemyIds,
      unlockedQuestIds: session.unlockedQuestIds,
      completedQuestIds: session.completedQuestIds,
      theme: resolvedTheme,
      partySize: 1 + session.activeAllyIds.length,
      alignmentLabel: session.alignmentLabel,
    );
    if (excursion != null) {
      playNotifier.startExcursion(excursion, choice.nextId,
          origin: choice.text, originFr: choice.textFr);
      return;
    }
  }
  playNotifier.choose(choice.nextId);
}

/// `@first_ally` among a choice's enemies is the first active companion,
/// turned: they leave the party for good before the fight and stand across
/// the sand as `<id>_turned`; with no one left to turn, the Inquisition's
/// own champion takes the field. The flags `companion_turned` /
/// `legate_fought` let the scene say which it was.
Future<List<String>> _resolveEnemyIds(WidgetRef ref, List<String> ids) async {
  if (!ids.contains('@first_ally')) return ids;
  final notifier = ref.read(playerSessionProvider.notifier);
  final session = ref.read(playerSessionProvider);
  final allyId =
      session.activeAllyIds.isEmpty ? null : session.activeAllyIds.first;
  if (allyId != null) {
    notifier.loseAlly(allyId);
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
    {required bool french}) {
  final buffer = StringBuffer(withAllyAcknowledgment(
    node.id,
    node.descriptionFor(french),
    activeAllyIds: session.activeAllyIds,
    french: french,
  ));
  final progress = node.hubProgressLineFor(session.flags, french);
  final extras = [
    if (progress != null) progress,
    ...node.callbacksFor(session.flags, french),
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
  return personalizeNarration(
    buffer.toString(),
    name: session.characterName,
    raceId: session.raceId,
    professionId: session.professionId,
    companionName: capitalized(firstAlly),
    lostCompanionName: capitalized(lastLost),
    french: french,
  );
}

/// Presents a hub node as a place: a Rest option, then what can be done
/// here -- its boutiques (the story's shops and, in a town, the port's own),
/// its expeditions (a town's or camp's zones), its people and its
/// challenges -- and only after all of that, the way onward. Choices whose
/// scene leads back to the hub are the place's own; any other choice moves
/// the story on and sits under "Onward" (folded away in a town, under a
/// "Leave" header, so the town reads as a town first). Reuses
/// [_selectChoice] for the actual effect/routing logic, so a card behaves
/// exactly like a [_ChoiceButton] would have.
class _HubSections extends ConsumerWidget {
  const _HubSections({
    required this.node,
    required this.choices,
    required this.story,
    required this.session,
    required this.currentNodeId,
    required this.isExcursion,
    required this.french,
  });

  final StoryNode node;
  final List<StoryChoice> choices;
  final StoryData story;
  final PlayerSession session;
  final String currentNodeId;
  final bool isExcursion;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = choices.where((c) => isLocalChoice(c, node.id)).toList();
    final onward = choices.where((c) => !isLocalChoice(c, node.id)).toList();
    List<StoryChoice> of(_HubCategory? category) =>
        local.where((c) => _hubCategoryFor(c) == category).toList();
    final shopChoices = of(_HubCategory.shop);
    final challenges = of(_HubCategory.challenge);
    final people = [...of(_HubCategory.people), ...of(null)];

    // A town's port: its own shops (those the story isn't offering as a
    // scene right now) and its expeditions.
    final settlement = node.settlement;
    final ports = ref.watch(gameDbProvider(portsSchema)).value;
    final shopsDb = ref.watch(gameDbProvider(shopsSchema)).value;
    final zones = ref.watch(gameDbProvider(zonesSchema)).value;
    final enemies = ref.watch(gameDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};
    final port = settlement?.portId == null
        ? null
        : ports?[settlement!.portId] as Map<String, dynamic>?;
    final storyShopIds = {for (final c in shopChoices) c.unlockShopId};
    final portShops = port == null || shopsDb == null
        ? const <String>[]
        : portShopIds(port)
            .where((id) =>
                shopsDb[id] is Map<String, dynamic> &&
                !storyShopIds.contains(id))
            .toList();
    final portZones = port == null || zones == null
        ? const <String>[]
        : portZoneIds(port)
            .where((id) => zones[id] is Map<String, dynamic>)
            .toList();
    final expeditionBlocked =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);

    Widget header(String title, IconData icon) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        );

    Widget card(StoryChoice choice) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _HubChoiceCard(
            choice: choice,
            story: story,
            session: session,
            currentNodeId: currentNodeId,
            isExcursion: isExcursion,
            french: french,
          ),
        );

    final services = <Widget>[
      if (shopChoices.isNotEmpty || portShops.isNotEmpty) ...[
        header(tr(ref, 'hub_shops_section'), Icons.storefront_outlined),
        for (final choice in shopChoices) card(choice),
        for (final shopId in portShops)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: ShopPixelIcon(shopId),
                title: Text(
                    (shopsDb![shopId] as Map<String, dynamic>)['shopName']
                            ?.toString() ??
                        shopId),
                subtitle: Text(
                  (shopsDb[shopId] as Map<String, dynamic>)['shopDescription']
                          ?.toString() ??
                      '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShopDetailScreen(
                      shopId: shopId,
                      shop: shopsDb[shopId] as Map<String, dynamic>,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      if (portZones.isNotEmpty) ...[
        header(tr(ref, 'hub_expeditions_section'), Icons.explore_outlined),
        for (final zoneId in portZones)
          ZoneCard(
            zoneId: zoneId,
            zone: zones![zoneId] as Map<String, dynamic>,
            zones: zones,
            enemies: enemies,
            enabled: !expeditionBlocked,
            onBegin: () async {
              ref.read(expeditionActiveProvider.notifier).state = true;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpeditionScreen(
                      zoneId: zoneId,
                      zone: zones[zoneId] as Map<String, dynamic>),
                ),
              );
              ref.read(expeditionActiveProvider.notifier).state = false;
            },
          ),
      ],
      if (people.isNotEmpty) ...[
        header(tr(ref, 'hub_people_section'), Icons.chat_bubble_outline),
        for (final choice in people) card(choice),
      ],
      if (challenges.isNotEmpty) ...[
        header(tr(ref, 'hub_challenges_section'), Icons.gpp_maybe_outlined),
        for (final choice in challenges) card(choice),
      ],
    ];

    final onwardButtons = [
      for (final choice in onward)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ChoiceButton(
            choice: choice,
            story: story,
            session: session,
            currentNodeId: currentNodeId,
            isExcursion: isExcursion,
            french: french,
          ),
        ),
    ];
    final maxServicesHeight = MediaQuery.of(context).size.height * 0.42;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (settlement != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    settlement.isCamp
                        ? Icons.local_fire_department_outlined
                        : Icons.location_city_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      settlement.nameFor(french),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(playerSessionProvider.notifier).healPartyToFull();
              if (!context.mounted) return;
              showImmersiveNotice(
                context,
                icon: Icons.local_fire_department,
                message: tr(ref, 'party_rested_message'),
              );
            },
            icon: const Icon(Icons.local_fire_department_outlined),
            label: Text(tr(ref, 'rest_button')),
          ),
          // A hub can carry a dozen things to do, and the choice area under
          // the narration doesn't scroll on its own -- this block scrolls
          // within a cap so the way onward below always stays on screen.
          if (services.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxServicesHeight),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: services,
                ),
              ),
            ),
          if (onward.isNotEmpty) ...[
            const Divider(height: 24),
            if (settlement != null)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text(tr(ref, 'leave_settlement_title')
                      .replaceAll('{place}', settlement.nameFor(french))),
                  subtitle: Text(tr(ref, 'leave_settlement_hint')),
                  children: onwardButtons,
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_forward, size: 18),
                    const SizedBox(width: 6),
                    Text(tr(ref, 'hub_onward_section'),
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              ...onwardButtons,
            ],
          ],
        ],
      ),
    );
  }
}

/// The pop-up on reaching a town or camp from elsewhere in the story: where
/// the player is, and that the place's shops, expeditions and people are
/// listed under the story, with the way onward at the bottom.
void _showSettlementArrival(
  BuildContext context,
  WidgetRef ref,
  Settlement settlement,
  bool french,
) {
  final ports = ref.read(gameDbProvider(portsSchema)).value;
  final port = settlement.portId == null
      ? null
      : ports?[settlement.portId] as Map<String, dynamic>?;
  final portText = port == null ? '' : portDescriptionFor(port, french);
  final name = settlement.nameFor(french);
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        icon: Icon(
          settlement.isCamp ? Icons.local_fire_department : Icons.location_city,
          size: 36,
        ),
        title: Text(
          tr(
                  ref,
                  settlement.isCamp
                      ? 'arrival_camp_title'
                      : 'arrival_town_title')
              .replaceAll('{place}', name),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (portText.isNotEmpty) ...[
              Text(portText,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic, height: 1.4)),
              const SizedBox(height: 12),
            ],
            Text(
              tr(
                      ref,
                      settlement.isCamp
                          ? 'arrival_camp_body'
                          : 'arrival_town_body')
                  .replaceAll('{place}', name),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr(
                ref,
                settlement.isCamp
                    ? 'arrival_camp_button'
                    : 'arrival_town_button')),
          ),
        ],
      );
    },
  );
}

/// A single card within a [_HubSections] section — the categorized,
/// icon-led counterpart to [_ChoiceButton], reached only for choices a
/// hub node sorted out of its main list.
class _HubChoiceCard extends ConsumerWidget {
  const _HubChoiceCard({
    required this.choice,
    required this.story,
    required this.session,
    required this.currentNodeId,
    required this.isExcursion,
    required this.french,
  });

  final StoryChoice choice;
  final StoryData story;
  final PlayerSession session;
  final String currentNodeId;
  final bool isExcursion;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = _isChoiceLocked(choice, story, session, isExcursion);
    final lockedLabel = locked ? choice.lockedTextFor(french) : null;
    final label = (lockedLabel?.isNotEmpty ?? false)
        ? lockedLabel!
        : choice.textFor(french);

    if (choice.triggersCombat) {
      // Keep the enemies database warm so it's ready by the time this
      // card is tapped.
      ref.watch(gameDbProvider(enemiesSchema));
    }

    final roster = isExcursion
        ? null
        : _fightRosterFor(
            choice, ref.watch(gameDbProvider(enemiesSchema)).value);
    final subtitle = choice.hasAbilityCheck
        ? '${tr(ref, '${choice.checkAbility}_label')} DC ${choice.checkDC ?? 10}'
        : roster == null
            ? null
            : tr(ref, 'choice_fight_roster').replaceAll('{roster}', roster);

    return Card(
      child: ListTile(
        leading: Icon(_hubIconFor(choice)),
        title: Text(label),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Icon(locked ? Icons.lock_outline : Icons.chevron_right),
        onTap: locked
            ? null
            : () => _selectChoice(
                  context: context,
                  ref: ref,
                  choice: choice,
                  story: story,
                  session: session,
                  currentNodeId: currentNodeId,
                  isExcursion: isExcursion,
                  french: french,
                ),
      ),
    );
  }
}

/// Who a story fight choice sends the party against ("Street Bandit ×3"),
/// or null for a choice with no fight, a fight whose enemies are not
/// loaded yet, or the pact's turned companion (`@first_ally`), which the
/// scene deliberately does not name before it happens.
String? _fightRosterFor(StoryChoice choice, Map<String, dynamic>? enemies) {
  if (!choice.triggersCombat || enemies == null) return null;
  final ids = choice.allTriggerEnemyIds;
  if (ids.any((id) => id.startsWith('@'))) return null;
  return enemyRoster(ids, enemies);
}

/// The strip above a detour's text: that this scene is met on the way to
/// the choice the player just made, why it is happening when the builder
/// knows (a hunter's reason, the job on offer), and that the story picks
/// up where the player was going once it is dealt with.
class _DetourContextCard extends ConsumerWidget {
  const _DetourContextCard({required this.origin, required this.note});

  final String? origin;
  final String? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onColor = scheme.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.alt_route, size: 18, color: onColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    origin == null
                        ? tr(ref, 'detour')
                        : '${tr(ref, 'detour_on_the_way')} “$origin”',
                    style: theme.textTheme.labelLarge?.copyWith(color: onColor),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: onColor, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    tr(ref, 'detour_resumes'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: onColor.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fade + subtle upward slide used whenever the story advances to a
/// different node (or leaves/enters an excursion), for both the narrative
/// text and the choice list below it.
Widget _nodeTransition(Widget child, Animation<double> animation) {
  final offset = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
      .animate(animation);
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(position: offset, child: child),
  );
}

/// Fades and slides [child] up into place, starting after [delay] — used to
/// stagger each choice button's entrance so a fresh node's options reveal
/// one after another instead of popping in all at once.
class _StaggeredReveal extends StatefulWidget {
  const _StaggeredReveal({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _ChoiceButton extends ConsumerWidget {
  const _ChoiceButton({
    required this.choice,
    required this.story,
    required this.session,
    required this.currentNodeId,
    required this.isExcursion,
    required this.french,
  });

  final StoryChoice choice;
  final StoryData story;
  final PlayerSession session;
  final String currentNodeId;
  final bool isExcursion;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = _isChoiceLocked(choice, story, session, isExcursion);

    final lockedLabel = locked ? choice.lockedTextFor(french) : null;
    final label = (lockedLabel?.isNotEmpty ?? false)
        ? lockedLabel!
        : choice.textFor(french);

    // A fight is never a surprise behind a plain label ("Return to the
    // stalls"): the button carries crossed swords and who is fought. A
    // detour's own fight button already names them.
    // Watching the enemies database also keeps it warm, so it is ready by
    // the time a fight button is tapped.
    final enemies = choice.triggersCombat
        ? ref.watch(gameDbProvider(enemiesSchema)).value
        : null;
    final roster = isExcursion ? null : _fightRosterFor(choice, enemies);

    return ElevatedButton(
      onPressed: locked
          ? null
          : () => _selectChoice(
                context: context,
                ref: ref,
                choice: choice,
                story: story,
                session: session,
                currentNodeId: currentNodeId,
                isExcursion: isExcursion,
                french: french,
              ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: roster != null && !choice.hasAbilityCheck
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_martial_arts, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label),
                        Text(
                          tr(ref, 'choice_fight_roster')
                              .replaceAll('{roster}', roster),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : choice.hasAbilityCheck
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.casino_outlined, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$label '
                          '(${tr(ref, '${choice.checkAbility}_label')} '
                          'DC ${choice.checkDC ?? 10})',
                        ),
                      ),
                    ],
                  )
                : Text(label),
      ),
    );
  }
}

/// Toggles reading the current node's narrative text aloud via the device's
/// text-to-speech engine — voiced in whichever language the app is set to.
/// Tapping again while speaking stops it.
class _ReadAloudButton extends ConsumerWidget {
  const _ReadAloudButton({required this.text, required this.language});

  final String text;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geminiVoice = ref.watch(geminiVoiceSettingsProvider);
    final apiKey = ref.watch(apiKeyProvider);
    final useGemini = geminiVoice.enabled && (apiKey?.isNotEmpty ?? false);

    final geminiState = useGemini ? ref.watch(geminiTtsProvider) : null;
    final isLoading = geminiState == GeminiTtsPlaybackState.loading;
    final isSpeaking = useGemini
        ? geminiState != GeminiTtsPlaybackState.idle
        : ref.watch(ttsProvider);

    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isSpeaking
                  ? Icons.stop_circle_outlined
                  : Icons.volume_up_outlined,
              size: 18),
      tooltip: isLoading
          ? tr(ref, 'loading_voice_tooltip')
          : (isSpeaking
              ? tr(ref, 'stop_reading_tooltip')
              : tr(ref, 'read_aloud_tooltip')),
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        if (useGemini) {
          final notifier = ref.read(geminiTtsProvider.notifier);
          if (isSpeaking) {
            // Covers both the loading and playing states — tapping again
            // cancels an in-flight request just as readily as it stops
            // audio that's already sounding.
            await notifier.stop();
            return;
          }
          try {
            await notifier.speak(
              text: storyBodyFor(text),
              apiKey: apiKey!,
              voiceName: geminiVoice.voiceName,
              language: language,
            );
          } catch (e) {
            if (!context.mounted) return;
            showImmersiveNotice(
              context,
              icon: Icons.error_outline,
              message: '${tr(ref, 'gemini_voice_error_prefix')}: $e',
            );
          }
          return;
        }

        final notifier = ref.read(ttsProvider.notifier);
        if (isSpeaking) {
          notifier.stop();
        } else {
          notifier.speak(storyBodyFor(text), language);
        }
      },
    );
  }
}

final RegExp _storyHeaderPattern = RegExp(r'^\[(.+?)\]\s*');

/// This node's `[CHAPTER N: TITLE]`-style leading header, if present.
String? storyHeaderFor(String text) =>
    _storyHeaderPattern.firstMatch(text)?.group(1);

/// This node's narrative text with any leading `[CHAPTER N: TITLE]`-style
/// header stripped off — used both for on-screen rendering and for what
/// the read-aloud button speaks, so the header isn't read out loud.
String storyBodyFor(String text) {
  final match = _storyHeaderPattern.firstMatch(text);
  return (match != null ? text.substring(match.end) : text).trim();
}

/// Builds the body's [TextSpan]s for quick skim-reading: the opening
/// sentence (the scene's "hook") is bolded so a reader can tell what a
/// passage is about at a glance, and any quoted dialogue is italicized so
/// spoken lines stand out from surrounding narration. Every node's
/// description in this game is one continuous block (no author-inserted
/// paragraph breaks), so this only ever needs to highlight within a single
/// run of text, not across paragraphs.
List<TextSpan> _highlightedSpans(String body, TextStyle baseStyle) {
  if (body.isEmpty) return const [];

  final firstSentenceMatch = RegExp(r'[.!?]+(\s|$)').firstMatch(body);
  final firstSentenceEnd = firstSentenceMatch?.end ?? 0;

  final quoteRanges = <List<int>>[
    for (final m in RegExp('["“][^"”]{3,}["”]').allMatches(body))
      [m.start, m.end],
  ];

  final breakpoints = <int>{0, firstSentenceEnd, body.length};
  for (final range in quoteRanges) {
    breakpoints.addAll(range);
  }
  final sorted = breakpoints.toList()..sort();

  final spans = <TextSpan>[];
  for (var i = 0; i < sorted.length - 1; i++) {
    final start = sorted[i];
    final end = sorted[i + 1];
    if (start >= end) continue;
    final isBold = start < firstSentenceEnd;
    final isDialogue = quoteRanges.any((r) => start >= r[0] && end <= r[1]);
    spans.add(TextSpan(
      text: body.substring(start, end),
      style: baseStyle.copyWith(
        fontWeight: isBold ? FontWeight.w700 : null,
        fontStyle: isDialogue ? FontStyle.italic : null,
      ),
    ));
  }
  return spans;
}

/// Renders a story node's narrative text with a book-like presentation:
/// a leading `[CHAPTER N: TITLE]`-style header (if present) is pulled out
/// and styled as a centered heading with a divider, and the body gets
/// generous spacing, justified alignment, and a soft parchment-like card.
class _StoryText extends StatelessWidget {
  const _StoryText({
    required this.text,
    this.uiTheme,
    this.epilogue,
    this.epilogueHeading = '',
    this.speakerLabel,
    this.aftermath,
    this.aftermathHeading = '',
  });

  final String text;

  /// Who is speaking, for a scene voiced by someone other than the
  /// Narrator -- shown as an eyebrow above the body.
  final String? speakerLabel;

  /// The last fight's aftermath, opening the scene in italics under its
  /// own small heading (see combat_aftermath.dart).
  final String? aftermath;
  final String aftermathHeading;

  /// An alignment-specific closing paragraph (see
  /// [StoryNode.alignmentEpilogues]) set under a small heading after the
  /// body, in italics -- how this road looked from where the character
  /// walked it.
  final String? epilogue;
  final String epilogueHeading;

  /// The current node's `context_taxonomy.ui_theme` (docks, cathedral,
  /// slums, ...) — looked up against [uiThemePalettes] to give a few
  /// locations their own subtle color/type accent. Null, or a value with no
  /// entry, leaves this card looking exactly as it always has.
  final String? uiTheme;

  @override
  Widget build(BuildContext context) {
    final header = storyHeaderFor(text);
    final body = storyBodyFor(text);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = uiThemePaletteFor(uiTheme);
    final accent = resolveUiAccent(colorScheme, palette);

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'serif',
              height: palette?.lineHeight ?? 1.55,
              letterSpacing: palette?.letterSpacing ?? 0.2,
            ) ??
        const TextStyle();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.cardTint.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null && header.isNotEmpty) ...[
            Text(
              header.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: palette?.headerWeight ?? FontWeight.bold,
                    letterSpacing: 1.5,
                    color: accent.text,
                  ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 56,
                height: 2,
                color: accent.text.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (aftermath != null && aftermath!.isNotEmpty) ...[
            Text(
              aftermathHeading.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: accent.text.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              aftermath!,
              textAlign: TextAlign.justify,
              style: baseStyle.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 40,
                height: 1,
                color: accent.text.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (speakerLabel != null && speakerLabel!.isNotEmpty) ...[
            Text(
              '— $speakerLabel',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    fontStyle: FontStyle.italic,
                    color: accent.text.withValues(alpha: 0.85),
                  ),
            ),
            const SizedBox(height: 8),
          ],
          Text.rich(
            TextSpan(children: _highlightedSpans(body, baseStyle)),
            textAlign: TextAlign.justify,
          ),
          if (epilogue != null && epilogue!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 40,
                height: 1,
                color: accent.text.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              epilogueHeading.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: accent.text.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              epilogue!,
              textAlign: TextAlign.justify,
              style: baseStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _EndingView extends ConsumerWidget {
  const _EndingView({
    required this.title,
    required this.message,
    required this.restartLabel,
    required this.onRestart,
    this.session,
    this.onNewGamePlus,
  });

  final String title;
  final String message;
  final String restartLabel;
  final VoidCallback onRestart;

  /// Offered on a genuine story ending: bank this run's legacy and start
  /// the next, harder cycle (see `PlayerSessionNotifier.beginNewGamePlus`).
  final VoidCallback? onNewGamePlus;

  /// When set, a recap card (level/gold/alignment/quests) is shown below
  /// the message — only passed for a genuine story ending, not the "trail
  /// goes cold" data-error state.
  final PlayerSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapSession = session;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (recapSession != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(ref, 'path_summary_label'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                          '${tr(ref, 'final_level_label')}: ${recapSession.level}'),
                      Text(
                          '${tr(ref, 'final_gold_label')}: ${recapSession.gold}'),
                      Text(
                        '${tr(ref, 'final_alignment_label')}: '
                        '${trAlignmentLabel(ref, recapSession.alignmentLabel)} '
                        '(${recapSession.alignmentScore})',
                      ),
                      Text(
                        '${tr(ref, 'quests_completed_label')}: '
                        '${recapSession.completedQuestIds.length}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRestart,
              child: Text(restartLabel),
            ),
            if (onNewGamePlus != null && recapSession != null) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: onNewGamePlus,
                icon: const Icon(Icons.replay_circle_filled_outlined),
                label: Text(
                  '${tr(ref, 'new_game_plus_button')} · '
                  '${tr(ref, 'new_game_plus_cycle_label')} '
                  '${recapSession.newGamePlusCycle + 1}',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(ref, 'new_game_plus_hint'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirms, then banks the finished run as the next cycle's legacy and
/// restarts the story from the top -- character creation picks the legacy
/// up (see `PlayerSessionNotifier.startNewGame`).
Future<void> _startNewGamePlus(BuildContext context, WidgetRef ref) async {
  final lang = ref.read(appLanguageProvider);
  final session = ref.read(playerSessionProvider);
  final nextCycle = session.newGamePlusCycle + 1;
  final bonus = (newGamePlusStep * nextCycle * 100).round();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
          '${trFor(lang, 'new_game_plus_button')} · ${trFor(lang, 'new_game_plus_cycle_label')} $nextCycle'),
      content: Text(
        '${trFor(lang, 'new_game_plus_desc')}\n\n'
        '${trFor(lang, 'new_game_plus_enemies_prefix')} +$bonus% '
        '${trFor(lang, 'new_game_plus_enemies_suffix')}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(trFor(lang, 'cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(trFor(lang, 'new_game_plus_confirm')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await ref.read(playerSessionProvider.notifier).beginNewGamePlus();
  if (!context.mounted) return;
  ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
  showImmersiveNotice(
    context,
    icon: Icons.replay_circle_filled_outlined,
    message: trFor(lang, 'new_game_plus_started_message'),
  );
}

/// Shown once, right after a choice unlocks a shop and/or quest, on the
/// node the player just arrived at — lets them jump straight in instead of
/// only noticing the Play-tab CTA chip.
Future<void> _showDiscoveryModal(
  BuildContext context,
  WidgetRef ref,
  PendingDiscovery discovery, {
  required Map<String, dynamic> shops,
  required Map<String, dynamic> quests,
}) async {
  final lang = ref.read(appLanguageProvider);
  final shopId = discovery.shopId;
  final questId = discovery.questId;
  final shop = shopId != null ? shops[shopId] as Map<String, dynamic>? : null;
  final quest =
      questId != null ? quests[questId] as Map<String, dynamic>? : null;
  final session = ref.read(playerSessionProvider);
  // In play mode a shop is only reachable from the node that unlocked it
  // (see PlayerSession.shopUnlockNodeIds) — walking away without opening it
  // now means it isn't there "later" like the button implies, so don't
  // offer that false promise when a shop is part of the discovery.
  final isPlayMode = ref.read(appModeProvider) == AppMode.inGame;
  final showMaybeLater = !(isPlayMode && shopId != null);

  final questActive =
      questId != null && session.activeQuestIds.contains(questId);
  final questCompleted =
      questId != null && session.completedQuestIds.contains(questId);
  final requiredGold = (quest?['requiredGold'] as num?)?.toInt() ?? 0;
  final requiredFlags =
      (quest?['requiredFlags'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
  final questEligible = questId != null &&
      !questActive &&
      !questCompleted &&
      session.meetsRequirements(reqGold: requiredGold, reqFlags: requiredFlags);

  Future<void> acceptDiscoveredQuest() async {
    await ref.read(playerSessionProvider.notifier).acceptQuest(questId!);
    if (!context.mounted) return;
    showImmersiveNotice(
      context,
      icon: Icons.assignment_turned_in_outlined,
      message:
          '${trFor(lang, 'quest_accepted_prefix')}: ${quest?['questName']?.toString() ?? questId}',
    );
  }

  void viewDiscoveredQuest() {
    final questName = quest?['questName']?.toString() ?? questId!;
    final category = quest?['category']?.toString();
    final dialogue = quest?['npcDialogueText']?.toString() ?? '';
    final rewardGold = (quest?['rewardGold'] as num?)?.toInt() ?? 0;
    final rewardXp = (quest?['rewardXP'] as num?)?.toInt() ?? 0;
    final rewardItemId = quest?['rewardItemID']?.toString() ?? '';
    final rewardDiceId = quest?['rewardDiceID']?.toString() ?? '';

    showDetailDialog(
      context,
      title: questName,
      description: dialogue,
      icon: Icons.assignment,
      closeLabel: trFor(lang, 'close_button'),
      rows: [
        if (category != null && category.isNotEmpty)
          MapEntry(trFor(lang, 'category_label'), category),
        if (requiredGold > 0)
          MapEntry(trFor(lang, 'required_gold_label'), '$requiredGold'),
        if (requiredFlags.isNotEmpty)
          MapEntry(
              trFor(lang, 'required_flags_label'), requiredFlags.join(', ')),
        if (rewardGold > 0)
          MapEntry(trFor(lang, 'reward_gold_label'), '$rewardGold'),
        if (rewardXp > 0) MapEntry(trFor(lang, 'reward_xp_label'), '$rewardXp'),
        if (rewardItemId.isNotEmpty)
          MapEntry(trFor(lang, 'reward_item_label'), rewardItemId),
        if (rewardDiceId.isNotEmpty)
          MapEntry(trFor(lang, 'reward_dice_label'), rewardDiceId),
        MapEntry(
          trFor(lang, 'status_label'),
          questCompleted
              ? trFor(lang, 'status_completed')
              : (questActive
                  ? trFor(lang, 'status_active')
                  : trFor(lang, 'status_available')),
        ),
      ],
      extraActionLabel: questEligible ? trFor(lang, 'accept') : null,
      onExtraAction: questEligible ? () => acceptDiscoveredQuest() : null,
    );
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(trFor(lang, 'discovery_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shopId != null) ...[
            Text(trFor(lang, 'shop_discovered_message')),
            const SizedBox(height: 4),
            Text(
              shop?['shopName']?.toString() ?? shopId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          if (shopId != null && questId != null) const SizedBox(height: 12),
          if (questId != null) ...[
            Text(trFor(lang, 'quest_discovered_message')),
            const SizedBox(height: 4),
            Text(
              quest?['questName']?.toString() ?? questId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      actions: [
        if (showMaybeLater)
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(trFor(lang, 'maybe_later_button')),
          ),
        if (shopId != null && shop != null)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        ShopDetailScreen(shopId: shopId, shop: shop)),
              );
            },
            child: Text(trFor(lang, 'open_shop_button')),
          ),
        if (questId != null)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              viewDiscoveredQuest();
            },
            child: Text(trFor(lang, 'view_quest_button')),
          ),
        if (questEligible)
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              acceptDiscoveredQuest();
            },
            child: Text(trFor(lang, 'accept')),
          ),
      ],
    ),
  );
}

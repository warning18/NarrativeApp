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
import '../data/camp_state.dart';
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
import '../providers/camp_presence_provider.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/finished_story_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/gemini_tts_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_theme_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/settings_providers.dart';
import '../providers/story_providers.dart';
import '../providers/tts_provider.dart';
import '../theme/stitched_ink.dart';
import '../providers/voice_settings_provider.dart';
import '../providers/walk_companion_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/camp_travel.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/quest_tracker.dart';
import '../widgets/walking_companion_strip.dart';
import '../widgets/zone_card.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'expedition_screen.dart';
import 'fight_screen.dart';
import 'journal_screen.dart';
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

/// A town or camp arrival waiting to be announced: shown once the Story tab
/// is the one on screen and nothing (a fight, a dialog, autoplay) covers
/// it, so the pop-up never lands over another tab or another dialog.
final _pendingArrivalProvider = StateProvider<Settlement?>((ref) => null);

/// The text of each town or camp scene as the reader last saw it in full,
/// by node id, this launch: coming back to the place with the same text
/// folds it (see [_HubNarrationFold]).
final _readHubNarrationProvider =
    StateProvider<Map<String, String>>((ref) => const {});

/// Whether the town or camp scene on screen is folded, decided once per
/// visit so it doesn't fold itself the moment it has been read.
final _hubNarrationFoldProvider =
    StateProvider<_HubNarrationFold?>((ref) => null);

class _HubNarrationFold {
  const _HubNarrationFold(this.visitKey,
      {required this.folded, required this.readBefore});

  /// Arriving at the place: folded when this exact text was read before.
  _HubNarrationFold.onArrival(this.visitKey, {String? lastRead, String? now})
      : readBefore = lastRead != null,
        folded = lastRead != null && lastRead == now;

  /// The node and how far into the story the visit is, so each return to
  /// the place is a new visit.
  final String visitKey;
  final bool folded;

  /// Whether the place's scene had been read before this visit (even if
  /// something in it is new), which is what lets it be folded.
  final bool readBefore;
}

/// Whether the "Previously..." recap has been offered this launch.
final _previouslyOfferedProvider = StateProvider<bool>((ref) => false);

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
      final shopsAsync = ref.watch(localizedDbProvider(shopsSchema));
      final questsAsync = ref.watch(localizedDbProvider(questsSchema));
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

    // A story seen through to its ending is remembered, so the main menu
    // offers New Game+ from it even after a new game replaces it.
    if (isStoryEnding(node) && session.raceId.isNotEmpty) {
      final endingId = node.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref
            .read(finishedStoryProvider.notifier)
            .record(ref.read(playerSessionProvider), endingId);
      });
    }

    // Arriving in a town or camp from elsewhere in the story says so, and
    // what the place offers, before anything else happens there.
    if (!playState.isInExcursion &&
        ref.read(_lastStoryNodeIdProvider) != node.id) {
      final previousNodeId = ref.read(_lastStoryNodeIdProvider);
      final arrivedNode = node;
      final historyAtArrival = playState.history;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (ref.read(_lastStoryNodeIdProvider) == arrivedNode.id) return;
        ref.read(_lastStoryNodeIdProvider.notifier).state = arrivedNode.id;
        final settlement = arrivedNode.settlement;
        // The camp says its own welcome: the Camp tab takes over from the
        // story there (see CampScreen).
        if (settlement != null &&
            !settlement.isCamp &&
            isSettlementArrival(arrivedNode.id, previousNodeId,
                history: historyAtArrival)) {
          ref.read(_pendingArrivalProvider.notifier).state = settlement;
        }
      });
    }
    // ModalRoute.of makes this rebuild when a covering route goes away. At
    // the camp the Story tab is closed (the camp stands in its place).
    final storyOnScreen = ref.watch(homeTabIndexProvider) == 0 &&
        !(ref.watch(partyAtCampProvider) &&
            ref.watch(appModeProvider) != AppMode.edit) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    // Picking a saved story back up: a short recap, once per launch.
    if (storyOnScreen &&
        !ref.watch(_previouslyOfferedProvider) &&
        ref.read(storyPlayProvider.notifier).restoredFromAutosave &&
        playState.history.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || ref.read(_previouslyOfferedProvider)) return;
        ref.read(_previouslyOfferedProvider.notifier).state = true;
        showPreviouslyDialog(
          context,
          story: story,
          history: playState.history,
          currentNodeId: playState.currentNodeId,
          session: session,
          quests: ref.read(localizedDbProvider(questsSchema)).value ?? const {},
          lang: language,
        );
      });
    }

    final pendingArrival = ref.watch(_pendingArrivalProvider);
    if (pendingArrival != null && storyOnScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (ref.read(_pendingArrivalProvider) != pendingArrival) return;
        ref.read(_pendingArrivalProvider.notifier).state = null;
        _showSettlementArrival(context, ref, pendingArrival, french);
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
    // On a hub, a finished activity stays on the list, greyed and ticked,
    // so the place reads as a checklist rather than shrinking.
    final doneChoices = isHubNode
        ? node.choices
            .where((c) => c.hideIfFlags.any(session.flags.contains))
            .toList()
        : const <StoryChoice>[];

    // A town or camp's scene, once read, folds to one line when the player
    // comes back to the place, so its shops, people and expeditions get the
    // screen. Text the reader hasn't seen (a new progress line, a
    // companion's remark) shows it in full again, and the last fight's
    // aftermath stays under the folded line.
    final canFoldNarration = isHubNode &&
        node.settlement != null &&
        !playState.isInExcursion &&
        !isStoryEnding(node);
    final hubVisitKey = '${node.id}_${playState.history.length}';
    final storedFold = ref.watch(_hubNarrationFoldProvider);
    final hubFold = !canFoldNarration
        ? null
        : storedFold?.visitKey == hubVisitKey
            ? storedFold!
            : _HubNarrationFold.onArrival(
                hubVisitKey,
                lastRead: ref.read(_readHubNarrationProvider)[node.id],
                now: displayDescription,
              );
    final narrationFolded = (hubFold?.folded ?? false) && !fullscreenReading;
    if (hubFold != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (ref.read(_hubNarrationFoldProvider)?.visitKey != hubVisitKey) {
          ref.read(_hubNarrationFoldProvider.notifier).state = hubFold;
        }
        final read = ref.read(_readHubNarrationProvider);
        if (!narrationFolded && read[node.id] != displayDescription) {
          ref.read(_readHubNarrationProvider.notifier).state = {
            ...read,
            node.id: displayDescription,
          };
        }
      });
    }
    void setNarrationFolded(bool folded) =>
        ref.read(_hubNarrationFoldProvider.notifier).state =
            _HubNarrationFold(hubVisitKey, folded: folded, readBefore: true);

    final isEditMode = ref.watch(appModeProvider) == AppMode.edit;
    final storyTools = <Widget>[
      IconButton(
        icon: const Icon(Icons.menu_book_outlined, size: 20),
        tooltip: tr(ref, 'journal_title'),
        visualDensity: VisualDensity.compact,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JournalScreen()),
        ),
      ),
      _ReadAloudButton(text: displayDescription, language: language),
    ];

    return TutorialTrigger(
      topic: TutorialTopic.story,
      ready: !isEditMode && session.raceId.isNotEmpty,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // One line above the story: the party's numbers, then the
              // journal and read-aloud buttons. Quests, shops, alignment and
              // the rest open from the numbers (see PlayerStatsBar). Scrolling
              // down into the narration folds the numbers into a handle;
              // tapping the handle brings them back.
              if (!fullscreenReading)
                TutorialTarget(
                  id: 'story.stats',
                  child: statusBarCollapsed
                      ? Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => ref
                                    .read(_statusBarCollapsedProvider.notifier)
                                    .state = false,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ...storyTools,
                          ],
                        )
                      : PlayerStatsBar(trailing: storyTools),
                ),
              // The followed quest and the goal it waits on, under the
              // numbers (and folded away with them while reading).
              if (!fullscreenReading && !statusBarCollapsed)
                const QuestTrackerBar(),
              // Edit Mode keeps its own line: back, the node's id and its
              // editor. A reader never sees node ids.
              if (!fullscreenReading && isEditMode)
                Row(
                  children: [
                    if (playState.history.isNotEmpty)
                      TextButton.icon(
                        onPressed: notifier.goBack,
                        icon: const Icon(Icons.arrow_back),
                        label: Text(tr(ref, 'back')),
                      ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        playState.isInExcursion
                            ? tr(ref, 'detour')
                            : '${tr(ref, 'node')} ${node.id}',
                        style: Theme.of(context).textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!playState.isInExcursion) ...[
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
              if (!fullscreenReading) const SizedBox(height: 8),
              // Below the header, the narration and the choices share what is
              // left: the choices never take more than [choiceBudget] of it.
              // The area under the narration doesn't scroll with it, so a long
              // list (a hub, long French lines) scrolls within the cap instead
              // of squeezing the story out or running off a small screen.
              Expanded(
                child: LayoutBuilder(builder: (context, area) {
                  // A folded town scene leaves the rest of the screen to the
                  // place itself.
                  // The companion shrinks on a short screen, and the choices
                  // leave room for it and for a few lines of the story.
                  final companionShown =
                      !fullscreenReading && walkCompanionEnabled;
                  final stripHeight = companionShown && !companionCollapsed
                      ? (area.maxHeight * 0.18).clamp(56.0, 125.0)
                      : 0.0;
                  final choiceBudget = narrationFolded
                      ? area.maxHeight
                      : max(
                          0.0,
                          min(
                              area.maxHeight * 0.6,
                              area.maxHeight -
                                  stripHeight -
                                  (companionShown ? 40 : 0) -
                                  72));
                  Widget fillBelow(Widget child) => narrationFolded
                      ? Expanded(
                          child: Align(
                              alignment: Alignment.topCenter, child: child))
                      : child;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (narrationFolded)
                        _FoldedNarration(
                          key: ValueKey('${node.id}_folded'),
                          label: tr(ref, 'hub_story_unfold'),
                          onOpen: () => setNarrationFolded(false),
                          uiTheme: node.uiTheme,
                          aftermath: pendingAftermath,
                          aftermathHeading: tr(ref, 'aftermath_heading'),
                        )
                      else
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
                              return TutorialTarget(
                                id: 'story.text',
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification
                                            is ScrollUpdateNotification &&
                                        (notification.scrollDelta ?? 0) > 0) {
                                      if (!statusBarCollapsed) {
                                        ref
                                            .read(_statusBarCollapsedProvider
                                                .notifier)
                                            .state = true;
                                      }
                                      if (!companionCollapsed) {
                                        ref
                                            .read(_companionCollapsedProvider
                                                .notifier)
                                            .state = true;
                                      }
                                    }
                                    return false;
                                  },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onDoubleTap: () => ref
                                        .read(
                                            _fullscreenReadingProvider.notifier)
                                        .state = !fullscreenReading,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 320),
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
                                                height: viewportConstraints
                                                    .maxHeight,
                                                child: Center(
                                                  child: _StoryText(
                                                    text: displayDescription,
                                                    uiTheme: node.uiTheme,
                                                    placeLabel: _placeLabel(
                                                        ref, node.uiTheme),
                                                    moodLabel: _moodLabel(
                                                        ref, node.mood),
                                                    epilogue: epilogue,
                                                    speakerLabel: speakerLabel,
                                                    aftermath: pendingAftermath,
                                                    aftermathHeading: tr(ref,
                                                        'aftermath_heading'),
                                                    epilogueHeading: tr(ref,
                                                        'epilogue_heading'),
                                                  ),
                                                ),
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  if (hubFold?.readBefore ??
                                                      false)
                                                    Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: TextButton.icon(
                                                        onPressed: () =>
                                                            setNarrationFolded(
                                                                true),
                                                        icon: const Icon(
                                                            Icons.expand_less),
                                                        label: Text(tr(ref,
                                                            'hub_story_fold')),
                                                      ),
                                                    ),
                                                  if (playState.isInExcursion)
                                                    _DetourContextCard(
                                                      origin: playState
                                                          .excursionOriginFor(
                                                              french),
                                                      note: node.contextNoteFor(
                                                          french),
                                                    ),
                                                  _StoryText(
                                                    text: displayDescription,
                                                    uiTheme: node.uiTheme,
                                                    placeLabel: _placeLabel(
                                                        ref, node.uiTheme),
                                                    moodLabel: _moodLabel(
                                                        ref, node.mood),
                                                    epilogue: epilogue,
                                                    speakerLabel: speakerLabel,
                                                    aftermath: pendingAftermath,
                                                    aftermathHeading: tr(ref,
                                                        'aftermath_heading'),
                                                    epilogueHeading: tr(ref,
                                                        'epilogue_heading'),
                                                  ),
                                                ],
                                              ),
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
                            TutorialTarget(
                              id: 'story.companion',
                              child: WalkingCompanionStrip(
                                height: stripHeight,
                                trigger:
                                    '${node.id}_${playState.isInExcursion}',
                                fightAvailable: node.choices.any(
                                  (c) =>
                                      c.triggersCombat &&
                                      !_isChoiceLocked(c, story, session,
                                          playState.isInExcursion),
                                ),
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
                        fillBelow(TutorialTarget(
                          id: 'story.choices',
                          // Capped here too: the scene fading out keeps the
                          // room it had, which a smaller screen may not have.
                          child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxHeight: choiceBudget),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: _nodeTransition,
                                child: isHubNode && !isStoryEnding(node)
                                    ? KeyedSubtree(
                                        key: ValueKey(
                                            '${node.id}_${playState.isInExcursion}_choices'),
                                        child: _HubSections(
                                          node: node,
                                          choices: visibleChoices,
                                          done: doneChoices,
                                          story: story,
                                          session: session,
                                          currentNodeId:
                                              playState.currentNodeId,
                                          isExcursion: playState.isInExcursion,
                                          french: french,
                                          maxHeight: choiceBudget,
                                        ),
                                      )
                                    : ConstrainedBox(
                                        key: ValueKey(
                                            '${node.id}_${playState.isInExcursion}_choices'),
                                        constraints: BoxConstraints(
                                            maxHeight: choiceBudget),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              if (node.choices.isEmpty ||
                                                  isStoryEnding(node))
                                                _EndingView(
                                                  title: tr(ref, 'the_end'),
                                                  // A written ending (its only way on is "begin
                                                  // again") closes the story; a node with no choice
                                                  // at all is a branch left unfinished.
                                                  message: tr(
                                                      ref,
                                                      isStoryEnding(node)
                                                          ? 'story_end_message'
                                                          : 'branch_end_message'),
                                                  restartLabel:
                                                      isStoryEnding(node)
                                                          ? node.choices.first
                                                              .textFor(french)
                                                          : tr(ref,
                                                              'restart_story'),
                                                  onRestart: () => notifier
                                                      .restart(StoryRepository
                                                          .startNodeId),
                                                  session: session,
                                                  onNewGamePlus: session
                                                          .raceId.isEmpty
                                                      ? null
                                                      : () => _startNewGamePlus(
                                                          context, ref),
                                                )
                                              else
                                                for (var i = 0;
                                                    i < visibleChoices.length;
                                                    i++)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    child: _StaggeredReveal(
                                                      delay: Duration(
                                                          milliseconds: 60 * i),
                                                      child: _ChoiceButton(
                                                        choice:
                                                            visibleChoices[i],
                                                        story: story,
                                                        session: session,
                                                        currentNodeId: playState
                                                            .currentNodeId,
                                                        isExcursion: playState
                                                            .isInExcursion,
                                                        french: french,
                                                      ),
                                                    ),
                                                  ),
                                            ],
                                          ),
                                        ),
                                      ),
                              )),
                        )),
                      ],
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether [choice] is currently unreachable because its target node has
/// requirements the player doesn't meet (shown disabled with its
/// lockedText instead of being selectable).
/// Whether [choice]'s road is still shut for [session] (its next scene
/// asks for gold, alignment, flags or Charisma the character lacks).
bool isStoryChoiceLocked(
        StoryChoice choice, StoryData story, PlayerSession session) =>
    _isChoiceLocked(choice, story, session, false);

/// Takes [choice] from the scene the story is on, exactly as tapping it
/// under the story would: its checks, fights, effects and the road after.
/// The camp's way out uses it (see CampScreen).
Future<void> takeStoryChoice(
    BuildContext context, WidgetRef ref, StoryChoice choice) async {
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
  );
}

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
const int _hubChoiceThreshold = 5;

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
    final chain = await rollRoadEncounter(ref,
        chapter: chapter, fromNodeId: currentNodeId);
    if (!context.mounted) return;
    if (chain != null) {
      playNotifier.startExcursion(chain, choice.nextId,
          origin: choice.text, originFr: choice.textFr);
      return;
    }
  }
  playNotifier.choose(choice.nextId);
}

/// What the road holds on the way on from [fromNodeId] in [chapter]: an
/// alignment event first (a hunter's ambush for a Good or Evil character,
/// a temptation for a Neutral one, see alignment_events.dart), else,
/// sometimes, a detour (see SubNodeEngine); null when the road is quiet.
/// A detour put off by a crisis is taken on the first road after it.
/// Shared by the story's own roads and the trips between the camp and its
/// places (see camp_travel.dart).
Future<List<StoryNode>?> rollRoadEncounter(
  WidgetRef ref, {
  required int chapter,
  required String fromNodeId,
}) async {
  final story = await ref.read(storyDataProvider.future);
  final shops = await loadedGameDb(ref, shopsSchema);
  final enemies = await loadedGameDb(ref, enemiesSchema);
  final quests = await loadedGameDb(ref, questsSchema);
  final session = ref.read(playerSessionProvider);
  final playNotifier = ref.read(storyPlayProvider.notifier);
  final resolvedTheme = ref.read(mapThemeProvider) ??
      mapThemeForUiTheme(story.nodeFor(fromNodeId)?.uiTheme);
  final alignmentEvent = maybeAlignmentEvent(
    alignmentScore: session.alignmentScore,
    activeQuestIds: session.activeQuestIds,
    completedQuestIds: session.completedQuestIds,
    enemies: enemies,
    chapter: chapter,
    random: Random(),
    enabled: ref.read(alignmentHuntersEnabledProvider),
  );
  if (alignmentEvent != null) return alignmentEvent;
  return SubNodeEngine.maybeGenerate(
    random: Random(),
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
    this.done = const [],
    required this.story,
    required this.session,
    required this.currentNodeId,
    required this.isExcursion,
    required this.french,
    required this.maxHeight,
  });

  /// The most height the whole hub block may take (see the story view's
  /// choice budget); its services and its way onward scroll within it.
  final double maxHeight;

  final StoryNode node;
  final List<StoryChoice> choices;

  /// The hub's finished activities (their `hideIfFlags` marker is set):
  /// listed greyed under their section, and counted in the header.
  final List<StoryChoice> done;
  final StoryData story;
  final PlayerSession session;
  final String currentNodeId;
  final bool isExcursion;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local =
        choices.where((c) => isLocalChoice(c, node.id, story)).toList();
    final onward =
        choices.where((c) => !isLocalChoice(c, node.id, story)).toList();
    final doneLocal =
        done.where((c) => isLocalChoice(c, node.id, story)).toList();
    List<StoryChoice> of(_HubCategory? category) =>
        local.where((c) => _hubCategoryFor(c) == category).toList();
    List<StoryChoice> doneOf(Set<_HubCategory?> categories) => doneLocal
        .where((c) => categories.contains(_hubCategoryFor(c)))
        .toList();
    final shopChoices = of(_HubCategory.shop);
    final challenges = of(_HubCategory.challenge);
    final people = [...of(_HubCategory.people), ...of(null)];

    // A town's port: its own shops (those the story isn't offering as a
    // scene right now) and its expeditions.
    final settlement = node.settlement;
    // Once the camp stands, it is where the party sleeps: resting in a town
    // means walking back to it.
    final restsAtCamp = settlement != null &&
        !settlement.isCamp &&
        session.flags.contains(campFoundedFlag);
    final travelsFromHere = !isExcursion &&
        canReturnToCampFrom(node,
            inExcursion: isExcursion, flags: session.flags);
    final travelsOn = travelsFromHere &&
        ref.watch(knownPlacesProvider).any((p) => p.id != node.id);
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final shopsDb = ref.watch(localizedDbProvider(shopsSchema)).value;
    final zones = ref.watch(localizedDbProvider(zonesSchema)).value;
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value ??
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

    Widget doneRow(StoryChoice choice) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.check_circle,
                  size: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  choice.textFor(french),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
              ),
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
      if (shopChoices.isNotEmpty ||
          portShops.isNotEmpty ||
          doneOf({_HubCategory.shop}).isNotEmpty) ...[
        header(tr(ref, 'hub_shops_section'), Icons.storefront_outlined),
        for (final choice in shopChoices) card(choice),
        for (final choice in doneOf({_HubCategory.shop})) doneRow(choice),
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
      if (people.isNotEmpty ||
          doneOf({_HubCategory.people, null}).isNotEmpty) ...[
        header(tr(ref, 'hub_people_section'), Icons.chat_bubble_outline),
        for (final choice in people) card(choice),
        for (final choice in doneOf({_HubCategory.people, null}))
          doneRow(choice),
      ],
      if (challenges.isNotEmpty ||
          doneOf({_HubCategory.challenge}).isNotEmpty) ...[
        header(tr(ref, 'hub_challenges_section'), Icons.gpp_maybe_outlined),
        for (final choice in challenges) card(choice),
        for (final choice in doneOf({_HubCategory.challenge})) doneRow(choice),
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
    final onwardSection = <Widget>[
      if (settlement != null)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
    ];

    // The whole block stays within [maxHeight]: the place's name and Rest
    // on one line, then its services and its way onward, each scrolling
    // within its share, so the way onward is always on screen.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (settlement != null) ...[
                  Icon(
                    settlement.isCamp
                        ? Icons.local_fire_department_outlined
                        : Icons.location_city_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                ],
                // The place's name with the done count under it, so the
                // line keeps its Rest button on a narrow screen.
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (settlement != null)
                        Text(
                          settlement.nameFor(french),
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (doneLocal.isNotEmpty)
                        Text(
                          tr(ref, 'hub_done_count')
                              .replaceAll('{done}', '${doneLocal.length}')
                              .replaceAll('{total}',
                                  '${doneLocal.length + local.length}'),
                          style: Theme.of(context).textTheme.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(playerSessionProvider.notifier)
                        .healPartyToFull();
                    if (!context.mounted) return;
                    showImmersiveNotice(
                      context,
                      icon: Icons.local_fire_department,
                      message: tr(
                          ref,
                          restsAtCamp
                              ? 'party_rested_at_camp_message'
                              : 'party_rested_message'),
                    );
                  },
                  icon: const Icon(Icons.local_fire_department_outlined),
                  label: Text(tr(ref,
                      restsAtCamp ? 'rest_at_camp_button' : 'rest_button')),
                ),
              ],
            ),
            // Once the camp stands, a place is somewhere the party travels
            // to from it: the way back, and on to the other places it knows.
            if (travelsFromHere)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Expanded(child: CampReturnButton()),
                    if (travelsOn) const SizedBox(width: 8),
                    if (travelsOn)
                      OutlinedButton.icon(
                        key: const Key('place_travel_on'),
                        style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => SafeArea(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(tr(ref, 'travel_on_title'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const SizedBox(height: 8),
                                  TravelOnList(fromNodeId: node.id),
                                ],
                              ),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.signpost_outlined, size: 18),
                        label: Text(tr(ref, 'travel_on_button')),
                      ),
                  ],
                ),
              ),
            if (services.isNotEmpty)
              Flexible(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: services,
                  ),
                ),
              ),
            if (onward.isNotEmpty) ...[
              const Divider(height: 16),
              Flexible(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: onwardSection,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The pop-up on reaching a town from elsewhere in the story: where the
/// player is, and that the place's shops, expeditions and people are
/// listed under the story, with the way onward at the bottom. (The camp
/// says its own welcome: see CampScreen.)
void _showSettlementArrival(
  BuildContext context,
  WidgetRef ref,
  Settlement settlement,
  bool french,
) {
  final ports = ref.read(localizedDbProvider(portsSchema)).value;
  final port = settlement.portId == null
      ? null
      : ports?[settlement.portId] as Map<String, dynamic>?;
  final portText = port == null ? '' : portDescriptionFor(port, french);
  final name = settlement.nameFor(french);
  // After the founding, the camp is home: arriving there is coming back,
  // and a town is somewhere away from it.
  final campFounded =
      ref.read(playerSessionProvider).flags.contains(campFoundedFlag);
  final bodyKey = campFounded ? 'arrival_town_away_body' : 'arrival_town_body';
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        // A short screen scrolls the port's description and the guide
        // rather than overflowing.
        scrollable: true,
        icon: const Icon(Icons.location_city, size: 36),
        title: Text(
          tr(ref, 'arrival_town_title').replaceAll('{place}', name),
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
              tr(ref, bodyKey).replaceAll('{place}', name),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr(ref,
                campFounded ? 'arrival_away_button' : 'arrival_town_button')),
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
    final mainQuestShut = _mainQuestShut(ref, choice, isExcursion);
    final locked =
        mainQuestShut || _isChoiceLocked(choice, story, session, isExcursion);
    final lockedLabel = mainQuestShut
        ? tr(ref, 'main_quest_shut_lock')
        : locked
            ? choice.lockedTextFor(french)
            : null;
    final label = (lockedLabel?.isNotEmpty ?? false)
        ? lockedLabel!
        : choice.textFor(french);

    if (choice.triggersCombat) {
      // Keep the enemies database warm so it's ready by the time this
      // card is tapped.
      ref.watch(localizedDbProvider(enemiesSchema));
    }

    final roster = isExcursion
        ? null
        : _fightRosterFor(
            choice, ref.watch(localizedDbProvider(enemiesSchema)).value);
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
    final mainQuestShut = _mainQuestShut(ref, choice, isExcursion);
    final locked =
        mainQuestShut || _isChoiceLocked(choice, story, session, isExcursion);

    final lockedLabel = mainQuestShut
        ? tr(ref, 'main_quest_shut_lock')
        : locked
            ? choice.lockedTextFor(french)
            : null;
    final label = (lockedLabel?.isNotEmpty ?? false)
        ? lockedLabel!
        : choice.textFor(french);

    // A fight is never a surprise behind a plain label ("Return to the
    // stalls"): the button carries crossed swords and who is fought. A
    // detour's own fight button already names them.
    // Watching the enemies database also keeps it warm, so it is ready by
    // the time a fight button is tapped.
    final enemies = choice.triggersCombat
        ? ref.watch(localizedDbProvider(enemiesSchema)).value
        : null;
    final roster = isExcursion ? null : _fightRosterFor(choice, enemies);

    return ElevatedButton(
      style: inkChoiceStyle(context),
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
                : _ChoiceLabel(label: label, choice: choice, locked: locked),
      ),
    );
  }
}

/// A plain choice's text, with what it costs or brings underneath as
/// small tags ("+20 gold", "−10 HP", "Alignment −1").
class _ChoiceLabel extends ConsumerWidget {
  const _ChoiceLabel({
    required this.label,
    required this.choice,
    this.locked = false,
  });

  final String label;
  final StoryChoice choice;

  /// A choice the player can't take yet: its tags fade with the card.
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = InkColors.of(context);
    String signed(int v) => v > 0 ? '+$v' : '\u2212${v.abs()}';
    final tags = [
      if (choice.goldMod != 0)
        InkTag(
          label: '${signed(choice.goldMod)} ${tr(ref, 'gold_label')}',
          color: ink.gold,
        ),
      if (choice.healAmount != 0)
        InkTag(
          label: '${signed(choice.healAmount)} ${tr(ref, 'hp_label')}',
          color: choice.healAmount > 0 ? ink.heal : ink.blood,
        ),
      if (choice.alignmentMod != 0)
        InkTag(
          label: '${tr(ref, 'alignment_label')} ${signed(choice.alignmentMod)}',
          color: ink.voidColor,
        ),
    ];
    if (tags.isEmpty) return Text(label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Opacity(
          opacity: locked ? 0.45 : 1,
          child: Wrap(spacing: 6, runSpacing: 4, children: tags),
        ),
      ],
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

/// A town or camp's scene the reader has already read, folded to one line
/// that opens it again, with the last fight's aftermath under it when
/// there is one -- so the place's own lists get the screen.
class _FoldedNarration extends StatelessWidget {
  const _FoldedNarration({
    super.key,
    required this.label,
    required this.onOpen,
    this.uiTheme,
    this.aftermath,
    this.aftermathHeading = '',
  });

  final String label;
  final VoidCallback onOpen;
  final String? uiTheme;
  final String? aftermath;
  final String aftermathHeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = uiThemePaletteFor(uiTheme);
    final accent = resolveUiAccent(theme.colorScheme, palette);
    return Material(
      color: accent.cardTint.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_outlined,
                      size: 20, color: accent.text),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: accent.text),
                    ),
                  ),
                  Icon(Icons.expand_more, color: accent.text),
                ],
              ),
              if (aftermath != null && aftermath!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  aftermathHeading.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: accent.text.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Text(
                      aftermath!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a story node's narrative text with a book-like presentation:
/// a leading `[CHAPTER N: TITLE]`-style header (if present) is pulled out
/// and styled as a centered heading with a divider, and the body gets
/// generous spacing, justified alignment, and a soft parchment-like card.
class _StoryText extends StatelessWidget {
  const _StoryText({
    required this.text,
    this.uiTheme,
    this.placeLabel,
    this.moodLabel,
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

  /// Where the scene is and how it feels, as tags above the text (null:
  /// no tag).
  final String? placeLabel;
  final String? moodLabel;

  @override
  Widget build(BuildContext context) {
    final header = storyHeaderFor(text);
    final body = storyBodyFor(text);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = uiThemePaletteFor(uiTheme);
    final accent = resolveUiAccent(colorScheme, palette);

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: InkFonts.prose,
              fontSize: 17,
              height: palette?.lineHeight ?? 1.6,
              letterSpacing: palette?.letterSpacing ?? 0.1,
            ) ??
        const TextStyle();

    // The page is sewn along a dashed thread in the colour of where the
    // story is; the prose sits on the bare page beside it.
    return CustomPaint(
      painter: StitchedEdgePainter(color: accent.border),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 4, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (placeLabel != null || moodLabel != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (placeLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: accent.border),
                      ),
                      child: Text(
                        placeLabel!.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: accent.text, letterSpacing: 1),
                      ),
                    ),
                  if (moodLabel != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        moodLabel!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 1),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (header != null && header.isNotEmpty) ...[
              Text(
                header,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: InkFonts.display,
                      letterSpacing: 0.5,
                      height: 1.15,
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
                textAlign: TextAlign.start,
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
              textAlign: TextAlign.start,
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
                textAlign: TextAlign.start,
                style: baseStyle.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
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

/// The tag for a scene's place (`context_taxonomy.ui_theme`), or null for
/// none: only real places get one, not the prologue or the endings.
String? _placeLabel(WidgetRef ref, String? uiTheme) {
  if (uiTheme == null) return null;
  final key = 'place_$uiTheme';
  final label = tr(ref, key);
  return label == key ? null : label;
}

/// The tag for a scene's mood, or null for none (a neutral one has none).
String? _moodLabel(WidgetRef ref, String? mood) {
  if (mood == null) return null;
  final key = 'mood_$mood';
  final label = tr(ref, key);
  return label == key ? null : label;
}

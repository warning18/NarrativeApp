import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../combat/combat_aftermath.dart';
import '../combat/combat_engine.dart' show newGamePlusStep;
import '../combat/encounter.dart';
import '../data/ability_check.dart';
import '../data/alignment_events.dart';
import '../data/approval.dart';
import '../data/ally_acknowledgments.dart';
import '../data/chapter_conditions.dart';
import '../data/chapter_spine.dart';
import '../data/check_outcomes.dart';
import '../data/companion_remarks.dart';
import '../data/echoes.dart';
import '../data/journey_rules.dart';
import '../data/recurring_encounters.dart';
import '../data/road_events.dart';
import '../data/encounter_text.dart';
import '../data/factions.dart' show CoastNews;
import '../data/map_themes.dart';
import '../data/narration_clips.dart';
import '../data/narration_tokens.dart';
import '../data/politics_events.dart';
import '../data/port_helpers.dart';
import '../data/camp_state.dart';
import '../data/quest_hints.dart';
import '../data/settlements.dart';
import '../data/story_repository.dart';
import '../data/turn_in_choices.dart';
import '../data/scene_flow.dart';
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
import '../providers/clans_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/finished_story_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/elevenlabs_tts_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_theme_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import '../providers/road_random_provider.dart';
import '../providers/remark_provider.dart';
import '../providers/story_providers.dart';
import '../providers/tts_provider.dart';
import '../theme/stitched_ink.dart';
import '../providers/voice_settings_provider.dart';
import '../providers/walk_companion_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/road_panel.dart';
import '../widgets/story_ship_battle.dart';
import '../widgets/timed_choice_bar.dart';
import '../widgets/journey_fx.dart';
import '../widgets/moments.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/camp_travel.dart';
import '../widgets/companion_remark_bubble.dart';
import '../widgets/approval_notice.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/narration_recording_dialogs.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/quest_tracker.dart';
import '../widgets/walking_companion_strip.dart';
import '../widgets/zone_card.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'expedition_screen.dart';
import 'fight_screen.dart';
import 'journal_screen.dart';
import 'journey_screen.dart' show journeyTabIndex;
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

/// The reader's own choice this visit to a town or camp: its scene
/// reopened with Reread, or closed with Enter. Without one, the scene is
/// open until it has been read (see PlayerSession.readSceneKeys).
final _hubNarrationFoldProvider =
    StateProvider<_HubNarrationFold?>((ref) => null);

class _HubNarrationFold {
  const _HubNarrationFold(this.visitKey,
      {required this.folded, required this.readBefore});

  /// Arriving at the place: folded when this exact text was read before.
  const _HubNarrationFold.onArrival(this.visitKey,
      {required this.readBefore, required bool readNow})
      : folded = readNow;

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

/// Reads [paragraphs] aloud (see [readAloudParagraphs]): in the recorded
/// ElevenLabs voice when it is on and the scene can be heard in it --
/// already recorded on this device, or an API key to record it with -- and
/// in the device's own text-to-speech voice otherwise.
Future<void> _speakNarration(
    WidgetRef ref, List<String> paragraphs, AppLanguage language) async {
  final voice = ref.read(elevenLabsVoiceSettingsProvider);
  final elevenLabs = ref.read(elevenLabsTtsProvider.notifier);
  if (voice.enabled &&
      NarrationRecordings.supported &&
      (voice.hasApiKey ||
          await elevenLabs.isRecorded(paragraphs,
              settings: voice, language: language))) {
    await ref.read(ttsProvider.notifier).stop();
    return elevenLabs.speak(paragraphs, settings: voice, language: language);
  }
  await elevenLabs.stop();
  return ref
      .read(ttsProvider.notifier)
      .speak(paragraphs.join('\n\n'), language);
}

void _stopAllNarration(WidgetRef ref) {
  ref.read(ttsProvider.notifier).stop();
  ref.read(elevenLabsTtsProvider.notifier).stop();
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
    // The same text less the lines an earlier choice earned: those come
    // after it as echoes, with the choice that earned them.
    final parts = node == null
        ? (text: '', echoes: const <SceneEcho>[])
        : composeNarrationParts(node, session, story, french: french);
    // Plain scenes read on the way here open this one.
    final preludes = ref.watch(pendingPreludeProvider);
    // The echoes shown (theirs too) are remembered for the journal's What
    // changed.
    noteShownEchoes(ref, session, [
      for (final prelude in preludes) ...prelude.echoes,
      ...parts.echoes,
    ]);
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

    // A new chapter reached: the clans' offer it brings (see offers.dart,
    // once a chapter), and its title card, a moment over the story, saying
    // so; the Character tab's badge keeps the offer.
    ref.listen<int>(reachedChapterProvider, (previous, next) async {
      if (previous == null || next <= previous) return;
      final offered = await ref
          .read(playerSessionProvider.notifier)
          .grantChapterOffer(next);
      // The coast moved while the party was away (v1.195): the events the
      // new chapter brings, told on its card. (Gone from the screen, the
      // next day's tick fires them, see HomeShell.)
      if (!context.mounted) return;
      final news = await runCoastEvents(ref, chapter: next);
      if (!context.mounted) return;
      final loop = ref
          .read(chapterLoopsProvider)
          .where((l) => l.chapter == next)
          .firstOrNull;
      if (loop == null || loop.title.isEmpty) return;
      final lang = ref.read(appLanguageProvider);
      showChapterCard(context,
          number: loop.label.isEmpty ? '$next' : loop.label,
          title: loop.title,
          colour: InkColors.of(context).ember,
          note: offered ? tr(ref, 'offer_chapter_note') : null,
          newsTitle: trFor(lang, 'coast_news_title'),
          news: chapterCardNews(news, lang));
    });

    // Kept loaded for the party's reactions to a choice (see approval.dart),
    // and for the name over a companion's remark on it.
    final companionNames =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
    // The Companion Remarks table, kept loaded for the party's words. What
    // they say about the last choice shows over the scene in a speech
    // bubble (see CompanionRemarksTrigger below), and is read aloud with it.
    final remarkBook = ref.watch(remarkBookProvider);
    final pendingRemarks = ref.watch(pendingRemarksProvider);
    final remarks = [
      for (final remark in pendingRemarks)
        if (remark.lineFor(remarkBook, french: french).isNotEmpty)
          (
            speaker: (companionNames[remark.companionId]
                        as Map<String, dynamic>?)?['companionName']
                    ?.toString() ??
                remark.companionId,
            line: remark.lineFor(remarkBook, french: french),
          ),
    ];
    // What the road cost opens the scene with a roll's outcome.
    final roadNote = ref.watch(pendingRoadNoteProvider);
    final rolledOutcome = ref.watch(pendingCheckOutcomeProvider);
    final outcomeLines = [
      if (roadNote != null && roadNote.isNotEmpty) roadNote,
      if (rolledOutcome != null && rolledOutcome.isNotEmpty) rolledOutcome,
    ];
    final checkOutcome =
        outcomeLines.isEmpty ? null : outcomeLines.join('\n\n');
    // What opens the scene before its own text, read aloud with it.
    final opening = [
      if (pendingAftermath != null && pendingAftermath.isNotEmpty)
        pendingAftermath,
      if (checkOutcome != null && checkOutcome.isNotEmpty) checkOutcome,
      for (final prelude in preludes) prelude.text,
      for (final remark in remarks) '${remark.speaker}: ${remark.line}',
    ];
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
    // the camp the Story tab is closed (the camp stands in its place). The
    // Journey tab tells the same scene, so what the story says on arrival
    // shows over it too.
    final storyTab = ref.watch(homeTabIndexProvider);
    final storyOnScreen = (storyTab == 0 ||
            (storyTab == journeyTabIndex &&
                ref.watch(appModeProvider) != AppMode.edit)) &&
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

    // Auto-read: once enabled, speak each scene the moment it appears
    // instead of waiting for a manual tap on the read-aloud button.
    if (ref.watch(autoReadAloudProvider)) {
      final autoReadKey = '${node.id}_${playState.isInExcursion}';
      if (ref.read(_autoReadLastNodeKeyProvider) != autoReadKey) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          ref.read(_autoReadLastNodeKeyProvider.notifier).state = autoReadKey;
          try {
            await _speakNarration(
                ref,
                readAloudParagraphs(node, session,
                    french: french, opening: opening),
                language);
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
    // A choice whose politics gate fails (v1.196) is hidden too, unless
    // it has a locked text to show instead.
    final gateWorld = ref.watch(coastGateWorldProvider);
    final visibleChoices = node.choices
        .where((c) => !choiceHiddenFor(c, session, gateWorld))
        .toList();
    // On a hub, a finished activity stays on the list, greyed and ticked,
    // so the place reads as a checklist rather than shrinking.
    final doneChoices = isHubNode
        ? node.choices
            .where((c) => c.hideIfFlags.any(session.flags.contains))
            .toList()
        : const <StoryChoice>[];

    // A town or camp's scene is read once: on arrival it fills the screen
    // with a single Enter under it, and once entered the place opens
    // straight onto its shops, people and expeditions, then and on every
    // later visit (see PlayerSession.readSceneKeys), the scene a Reread
    // away. Text the reader hasn't seen (a new progress line, a
    // companion's remark) opens it again, and the last fight's aftermath
    // stays under the folded place.
    final canFoldNarration = isHubNode &&
        node.settlement != null &&
        !playState.isInExcursion &&
        !isStoryEnding(node);
    final hubVisitKey = '${node.id}_${playState.history.length}';
    final sceneKey = sceneReadKey(node.id, displayDescription);
    final storedFold = ref.watch(_hubNarrationFoldProvider);
    final hubFold = !canFoldNarration
        ? null
        : storedFold?.visitKey == hubVisitKey
            ? storedFold!
            : _HubNarrationFold.onArrival(
                hubVisitKey,
                readBefore: session.readSceneKeys
                    .any((k) => k.startsWith('${node.id}#')),
                readNow: session.readSceneKeys.contains(sceneKey),
              );
    final narrationFolded = (hubFold?.folded ?? false) && !fullscreenReading;
    // Reading the place's scene: the place waits behind Enter.
    final readingScene = hubFold != null && !narrationFolded;
    void setNarrationFolded(bool folded) =>
        ref.read(_hubNarrationFoldProvider.notifier).state =
            _HubNarrationFold(hubVisitKey, folded: folded, readBefore: true);
    void enterPlace() {
      setNarrationFolded(true);
      ref.read(playerSessionProvider.notifier).markSceneRead(sceneKey);
    }

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
      _ReadAloudButton(
          paragraphs: readAloudParagraphs(node, session,
              french: french, opening: opening),
          language: language),
    ];

    return TutorialTrigger(
      topic: TutorialTopic.story,
      ready: !isEditMode && session.raceId.isNotEmpty,
      child: CompanionRemarksTrigger(
        remarks: pendingRemarks,
        ready: storyOnScreen,
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
                                      .read(
                                          _statusBarCollapsedProvider.notifier)
                                      .state = false,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Center(
                                      child: Container(
                                        width: 36,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant,
                                          borderRadius:
                                              BorderRadius.circular(2),
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
                      if (NarrationRecordings.supported)
                        _RecordSceneButton(
                          paragraphs: {
                            ...readAloudParagraphs(node, session,
                                french: french, opening: opening),
                            ...nodeNarrationScript(node,
                                french: french,
                                personalize: (text) => personalizeFor(
                                    session, text,
                                    french: french)),
                          }.toList(),
                          language: language,
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
                                builder: (_) =>
                                    StoryNodeEditorScreen(node: node),
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
                    // An open town gives the dog's strip to its own lists.
                    final companionShown = !fullscreenReading &&
                        walkCompanionEnabled &&
                        !narrationFolded;
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
                        if (narrationFolded &&
                            (pendingAftermath != null ||
                                preludes.isNotEmpty ||
                                roadNote != null))
                          _FoldedNarration(
                            key: ValueKey('${node.id}_folded'),
                            label: tr(ref, 'hub_story_unfold'),
                            onOpen: () => setNarrationFolded(false),
                            uiTheme: node.uiTheme,
                            aftermath: pendingAftermath,
                            aftermathHeading: tr(ref, 'aftermath_heading'),
                            // What was just done here reads under the
                            // folded place, with a roll's outcome.
                            outcome: [
                              for (final prelude in preludes) prelude.text,
                              if (checkOutcome != null &&
                                  checkOutcome.isNotEmpty)
                                checkOutcome,
                            ].join('\n\n'),
                          )
                        else if (!narrationFolded)
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
                                  child:
                                      NotificationListener<ScrollNotification>(
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
                                          .read(_fullscreenReadingProvider
                                              .notifier)
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
                                                      text: parts.text,
                                                      prelude: preludes,
                                                      echoes: parts.echoes,
                                                      echoCaption: tr(
                                                          ref, 'echo_because'),
                                                      uiTheme: node.uiTheme,
                                                      placeLabel: _placeLabel(
                                                          ref, node.uiTheme),
                                                      moodLabel: _moodLabel(
                                                          ref, node.mood),
                                                      epilogue: epilogue,
                                                      speakerLabel:
                                                          speakerLabel,
                                                      aftermath:
                                                          pendingAftermath,
                                                      aftermathHeading: tr(ref,
                                                          'aftermath_heading'),
                                                      outcome: checkOutcome,
                                                      epilogueHeading: tr(ref,
                                                          'epilogue_heading'),
                                                    ),
                                                  ),
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    if (playState.isInExcursion)
                                                      _DetourContextCard(
                                                        origin: playState
                                                            .excursionOriginFor(
                                                                french),
                                                        note:
                                                            node.contextNoteFor(
                                                                french),
                                                      ),
                                                    _StoryText(
                                                      text: parts.text,
                                                      prelude: preludes,
                                                      echoes: parts.echoes,
                                                      echoCaption: tr(
                                                          ref, 'echo_because'),
                                                      uiTheme: node.uiTheme,
                                                      placeLabel: _placeLabel(
                                                          ref, node.uiTheme),
                                                      moodLabel: _moodLabel(
                                                          ref, node.mood),
                                                      epilogue: epilogue,
                                                      speakerLabel:
                                                          speakerLabel,
                                                      aftermath:
                                                          pendingAftermath,
                                                      aftermathHeading: tr(ref,
                                                          'aftermath_heading'),
                                                      outcome: checkOutcome,
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
                          if (companionShown) ...[
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
                                            playState.isInExcursion,
                                            world: gateWorld),
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
                          // A timed scene's clock (see TimedChoiceBar).
                          if (node.isTimed &&
                              !playState.isInExcursion &&
                              !readingScene &&
                              ref.watch(appModeProvider) != AppMode.edit)
                            TimedChoiceBar(
                              key: ValueKey(
                                  'timer_${node.id}_${playState.history.length}'),
                              scene: timedSceneKey(
                                  node.id, playState.history.length),
                              seconds: node.timeLimit!,
                              active: ref.watch(homeTabIndexProvider) == 0,
                              label: tr(ref, 'timed_choice_hint'),
                              onTimeout: () => takeStoryChoice(
                                  context, ref, node.timeoutChoiceOrNull!),
                            ),
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
                                  child: readingScene
                                      ? _EnterPlaceButton(
                                          key: ValueKey(
                                              '${node.id}_${playState.isInExcursion}_enter'),
                                          place: node.settlement!,
                                          again: hubFold.readBefore,
                                          french: french,
                                          onEnter: enterPlace,
                                        )
                                      : isHubNode && !isStoryEnding(node)
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
                                                isExcursion:
                                                    playState.isInExcursion,
                                                french: french,
                                                maxHeight: choiceBudget,
                                                onReread: hubFold == null
                                                    ? null
                                                    : () => setNarrationFolded(
                                                        false),
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
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    if (node.choices.isEmpty ||
                                                        isStoryEnding(node))
                                                      _EndingView(
                                                        title:
                                                            tr(ref, 'the_end'),
                                                        // A written ending (its only way on is "begin
                                                        // again") closes the story; a node with no choice
                                                        // at all is a branch left unfinished.
                                                        message: tr(
                                                            ref,
                                                            isStoryEnding(node)
                                                                ? 'story_end_message'
                                                                : 'branch_end_message'),
                                                        restartLabel: isStoryEnding(
                                                                node)
                                                            ? node.choices.first
                                                                .textFor(french)
                                                            : tr(ref,
                                                                'restart_story'),
                                                        onRestart: () =>
                                                            notifier.restart(
                                                                StoryRepository
                                                                    .startNodeId),
                                                        session: session,
                                                        onNewGamePlus: session
                                                                .raceId.isEmpty
                                                            ? null
                                                            : () =>
                                                                _startNewGamePlus(
                                                                    context,
                                                                    ref),
                                                      )
                                                    else
                                                      for (var i = 0;
                                                          i <
                                                              visibleChoices
                                                                  .length;
                                                          i++)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 8),
                                                          child:
                                                              _StaggeredReveal(
                                                            delay: Duration(
                                                                milliseconds:
                                                                    60 * i),
                                                            child:
                                                                _ChoiceButton(
                                                              choice:
                                                                  visibleChoices[
                                                                      i],
                                                              story: story,
                                                              session: session,
                                                              currentNodeId:
                                                                  playState
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
      ),
    );
  }
}

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
        {bool isExcursion = false, CoastWorld? world}) =>
    _isChoiceLocked(choice, story, session, isExcursion, world: world);

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
}) {
  // A payment on the road (an offering, a toll, a fine) waits for a purse
  // that holds it, and so does a story choice marked as one (a fee, a
  // bribe, a buy-in). The story's other prices lock through the next
  // scene's gold requirement; gold it takes away unmarked is a loss.
  if (_paymentShort(choice, session.gold, isExcursion)) return true;
  if (isExcursion) return false;
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
  var skipRewardEffects = false;
  // What the choice showed of the player, for the party to remark on.
  RemarkKind? shown;
  // A sneak that works (avoidFightOnSuccess) leaves the fight behind.
  var fightAvoided = false;
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

  final playNotifier = ref.read(storyPlayProvider.notifier);
  var reactions = const <ApprovalChange>[];
  if (choice.hasEffects && !skipRewardEffects) {
    reactions =
        await ref.read(playerSessionProvider.notifier).applyChoiceEffects(
              goldMod: choice.goldMod,
              alignmentMod: choice.alignmentMod,
              healAmount: choice.healAmount,
              flagsToAdd: choice.flagsToAdd,
              questIDToProgress: choice.questIDToProgress,
              bannerPieceId: choice.grantsBannerPieceId,
              itemId: choice.grantItemId,
              loseAllyId: choice.loseAllyId,
              approvalMods: choice.approvalMods,
              companions:
                  ref.read(gameDbProvider(companionsSchema)).value ?? const {},
              // A detour's cache is loot, not greed.
              goldIsProfit: !isExcursion,
            );
    // What the scene put in the pack (see StoryChoice.grantItemId).
    if (choice.grantsItem && context.mounted) {
      final items = ref.read(localizedDbProvider(itemsSchema)).value;
      final name =
          (items?[choice.grantItemId] as Map<String, dynamic>?)?['itemName']
              ?.toString();
      await showImmersiveNotice(
        context,
        icon: Icons.backpack_outlined,
        message: tr(ref, 'item_picked_up')
            .replaceAll('{item}', name ?? choice.grantItemId!),
      );
    }
    // How the party took it, before the story moves on.
    if (reactions.isNotEmpty && context.mounted) {
      await showApprovalReactions(context, ref, reactions);
    }
  }
  // What the choice does to the coast (v1.195), once: taken again, or
  // after going back, it moves nothing.
  if (choice.hasPolitics && !skipRewardEffects && !isExcursion) {
    final index = storyChoiceIndex(story, currentNodeId, choice);
    if (index >= 0) {
      await applyStoryPoliticsNow(ref, choice.politics!,
          nodeId: currentNodeId, key: choicePoliticsKey(currentNodeId, index));
    }
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

  // Landed where the choice goes: the voyage was the way there, with its
  // days and its sea, and no road after it.
  if (travelled) {
    await _arriveAt(ref, story, choice.nextId);
    return;
  }

  // Setting out from one place for another is a step on the road: a
  // ration eaten and part of the day gone (see journey_rules.dart). A
  // choice that travels (the camp's main quest, on foot) is a walk
  // between places, as the camp's own trips are.
  final historyBefore = ref.read(storyPlayProvider).history.length;
  if (!choice.opensCharacterCreation &&
      (choice.travels || isRoadStep(currentNodeId, choice.nextId))) {
    await walkRoadStep(ref, watches: choice.travels ? walkWatches : 1);
    // What waits on this road (see road_events.dart), known before the
    // party set out, takes the place of a detour.
    final event = await roadEventOn(ref, story,
        fromNodeId: currentNodeId,
        toNodeId: choice.nextId,
        historyLength: historyBefore);
    if (!context.mounted) return;
    if (event != null) {
      playNotifier.startExcursion(event, choice.nextId,
          origin: choice.text, originFr: choice.textFr);
      return;
    }
  }

  // A choice that loops back onto its own node (a shop visit at the docks
  // hub, say) is a moment inside the same scene, not a step down the road
  // -- no excursion or alignment event rolls for it.
  // Chapter 1 is the flight from the city: its roads hold nothing, now or
  // later (see SubNodeEngine.firstDetourChapter).
  final spineChapter = chapterForNode(currentNodeId);
  final chapter =
      spineChapter != null && spineChapter >= SubNodeEngine.firstDetourChapter
          ? spineChapter
          : null;
  final atRest = SubNodeEngine.detourAllowedBetweenScenes(
    story.nodeFor(currentNodeId),
    story.nodeFor(choice.nextId),
    chapter: chapter ?? 0,
  );
  if (chapter != null &&
      !choice.opensCharacterCreation &&
      choice.nextId != currentNodeId &&
      !atRest) {
    // A crisis runs on from this scene into the next: whatever the road
    // held waits until it is over.
    if (ref.read(roadRandomProvider)().nextDouble() <
        SubNodeEngine.detourChance) {
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
  await _arriveAt(ref, story, choice.nextId);
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
  final event = roadEventFor(
    story: story,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
    historyLength: historyLength,
    chapter: chapter,
    oddsFactor: condition?.roadEventOdds ?? 1,
    championShare: condition?.championShare ?? 0.4,
    shrineShare: condition?.shrineShare ?? 0.3,
  );
  if (event == null) return null;
  final enemies = await loadedGameDb(ref, enemiesSchema);
  return roadEventChain(
    event,
    chapter: chapter,
    enemyPool: championPoolFor(enemies, chapter),
    seed: stableHash('$fromNodeId>$toNodeId#$historyLength'),
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
  final preludes = <ScenePrelude>[];
  for (var i = 0; i < maxPassThrough; i++) {
    // Each scene read through on the way moves it too.
    await applyEnterPolitics(ref, ref.read(storyPlayProvider).currentNodeId);
    final session = ref.read(playerSessionProvider);
    final node = story.nodeFor(ref.read(storyPlayProvider).currentNodeId);
    if (node == null) break;
    final gateWorld = ref.read(coastGateWorldProvider);
    final way = passThroughChoiceOf(node, session.flags,
        hidden: (c) => choiceHiddenFor(c, session, gateWorld));
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
      final index = storyChoiceIndex(story, node.id, way);
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
/// [chapterCardNewsShown], then how many more the journal keeps.
List<String> chapterCardNews(List<CoastNews> news, AppLanguage lang) {
  final lines = [
    for (final n in news)
      if (n.textFor(lang).isNotEmpty) n.textFor(lang),
  ];
  if (lines.length <= chapterCardNewsShown) return lines;
  return [
    ...lines.take(chapterCardNewsShown),
    trFor(lang, 'coast_news_more')
        .replaceAll('{n}', '${lines.length - chapterCardNewsShown}'),
  ];
}

/// News lines a chapter's card has room for.
const int chapterCardNewsShown = 3;

/// [choice]'s place among [nodeId]'s choices (the key its politics are
/// remembered under, see choicePoliticsKey), -1 when it is none of them.
int storyChoiceIndex(StoryData story, String nodeId, StoryChoice choice) {
  final choices = story.nodeFor(nodeId)?.choices ?? const <StoryChoice>[];
  final same = choices.indexWhere((c) => identical(c, choice));
  if (same >= 0) return same;
  return choices.indexWhere((c) =>
      c.nextId == choice.nextId &&
      c.text == choice.text &&
      c.textFr == choice.textFr);
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
  final dice = ref.read(roadRandomProvider);
  final resolvedTheme = ref.read(mapThemeProvider) ??
      mapThemeForUiTheme(story.nodeFor(fromNodeId)?.uiTheme);
  final alignmentEvent = maybeAlignmentEvent(
    alignmentScore: session.alignmentScore,
    activeQuestIds: session.activeQuestIds,
    completedQuestIds: session.completedQuestIds,
    enemies: enemies,
    chapter: chapter,
    random: dice(),
    enabled: ref.read(alignmentHuntersEnabledProvider),
    rollsSinceAmbush: session.alignmentRollsSinceAmbush,
  );
  await ref.read(playerSessionProvider.notifier).noteAlignmentRoll(
      ambushed: alignmentEvent != null && isHunterAmbushChain(alignmentEvent));
  if (alignmentEvent != null) return alignmentEvent;
  // Now and then, someone met on an earlier road (see
  // recurring_encounters.dart).
  final familiar = maybeRecurringEncounter(
    flags: session.flags.toSet(),
    chapter: chapter,
    random: dice(),
    enemyPool: SubNodeEngine.filterEnemyPool(
        enemies: enemies, unlockedEnemyIds: const [], chapter: chapter),
  );
  if (familiar != null) return familiar;
  return SubNodeEngine.maybeGenerate(
    random: dice(),
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
    notifier.loseAlly(allyId,
        companions:
            ref.read(gameDbProvider(companionsSchema)).value ?? const {});
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
    this.onReread,
  });

  /// Opens the place's scene again (its card's Reread); null when the
  /// place has no scene to fold.
  final VoidCallback? onReread;

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

    Widget portShopTile(String shopId) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              leading: ShopPixelIcon(shopId),
              title: Text((shopsDb![shopId] as Map<String, dynamic>)['shopName']
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
        );

    Widget zoneTile(String zoneId) => ZoneCard(
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
        );

    // The place's activities, a group per kind: each is a tab of its own
    // (see _HubTab), and All lists them one under the other.
    final groups = <_HubGroup>[
      _HubGroup(
        id: 'shops',
        title: tr(ref, 'hub_shops_section'),
        icon: Icons.storefront_outlined,
        open: shopChoices.length + portShops.length,
        items: [
          for (final choice in shopChoices) card(choice),
          for (final shopId in portShops) portShopTile(shopId),
          for (final choice in doneOf({_HubCategory.shop})) doneRow(choice),
        ],
      ),
      _HubGroup(
        id: 'expeditions',
        title: tr(ref, 'hub_expeditions_section'),
        icon: Icons.explore_outlined,
        open: portZones.length,
        items: [for (final zoneId in portZones) zoneTile(zoneId)],
      ),
      _HubGroup(
        id: 'people',
        title: tr(ref, 'hub_people_section'),
        icon: Icons.chat_bubble_outline,
        open: people.length,
        items: [
          for (final choice in people) card(choice),
          for (final choice in doneOf({_HubCategory.people, null}))
            doneRow(choice),
        ],
      ),
      _HubGroup(
        id: 'challenges',
        title: tr(ref, 'hub_challenges_section'),
        icon: Icons.gpp_maybe_outlined,
        open: challenges.length,
        items: [
          for (final choice in challenges) card(choice),
          for (final choice in doneOf({_HubCategory.challenge}))
            doneRow(choice),
        ],
      ),
    ].where((g) => g.items.isNotEmpty).toList();
    final storedTab = ref.watch(_hubTabProvider);
    final tab =
        storedTab?.$1 == node.id && groups.any((g) => g.id == storedTab!.$2)
            ? storedTab!.$2
            : 'all';
    final tabbed = groups.length > 1;

    Widget header(_HubGroup group) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Icon(group.icon, size: 18),
              const SizedBox(width: 6),
              Text(group.title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        );
    final services = <Widget>[
      for (final group in groups)
        if (!tabbed || tab == 'all' || tab == group.id) ...[
          if (!tabbed || tab == 'all')
            header(group)
          else
            const SizedBox(height: 8),
          ...group.items,
        ],
    ];

    Widget tabChip(String id, String label, int count) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            key: Key('hub_tab_$id'),
            label: Text(count > 0 ? '$label $count' : label),
            selected: tab == id,
            showCheckmark: false,
            onSelected: (_) =>
                ref.read(_hubTabProvider.notifier).state = (node.id, id),
          ),
        );

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
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.logout),
            title: Text(tr(ref, 'leave_settlement_title')
                .replaceAll('{place}', settlement.nameFor(french))),
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

    final theme = Theme.of(context);
    final total = doneLocal.length + local.length;
    // The place's card: its name, how much of it is done, Rest and Reread.
    final placeCard = Container(
      key: const Key('hub_place_card'),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          if (settlement != null) ...[
            Icon(
              settlement.isCamp
                  ? Icons.local_fire_department_outlined
                  : Icons.location_city_outlined,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (settlement != null)
                  Text(
                    settlement.nameFor(french),
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (total > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: doneLocal.length / total,
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr(ref, 'hub_done_count')
                            .replaceAll('{done}', '${doneLocal.length}')
                            .replaceAll('{total}', '$total'),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onReread != null)
            IconButton(
              key: const Key('hub_reread'),
              tooltip: tr(ref, 'hub_story_unfold'),
              icon: const Icon(Icons.auto_stories_outlined),
              onPressed: onReread,
            ),
          IconButton(
            key: const Key('hub_rest'),
            tooltip:
                tr(ref, restsAtCamp ? 'rest_at_camp_button' : 'rest_button'),
            icon: const Icon(Icons.local_fire_department_outlined),
            onPressed: () => restTheNight(context, ref,
                message: tr(
                    ref,
                    restsAtCamp
                        ? 'party_rested_at_camp_message'
                        : 'party_rested_message'),
                atCamp: restsAtCamp),
          ),
        ],
      ),
    );

    // The whole block stays within [maxHeight]: the place's card, its tabs,
    // then its activities and its way onward, each scrolling within its
    // share, so the way onward is always on screen.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            placeCard,
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
            if (tabbed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      tabChip('all', tr(ref, 'hub_tab_all'), 0),
                      for (final group in groups)
                        tabChip(group.id, group.title, group.open),
                    ],
                  ),
                ),
              ),
            if (services.isNotEmpty)
              Flexible(
                child: SingleChildScrollView(
                  key: PageStorageKey('hub_services_${node.id}_$tab'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: services,
                  ),
                ),
              ),
            // The way onward takes what it needs (one line while folded),
            // up to two fifths of the block, and the lists the rest.
            if (onward.isNotEmpty) ...[
              const Divider(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight * 0.4),
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

/// One kind of activity in a place (its shops, expeditions, people or
/// challenges): a tab of the place's list.
class _HubGroup {
  const _HubGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.open,
    required this.items,
  });

  final String id;
  final String title;
  final IconData icon;

  /// How many are still to do (the tab's count).
  final int open;
  final List<Widget> items;
}

/// The tab picked in a place's list, by the place's node id: another place
/// opens on All.
final _hubTabProvider = StateProvider<(String, String)?>((ref) => null);

/// Under a town or camp's scene, while it is being read: the one way on,
/// into the place (see the story view's readingScene).
class _EnterPlaceButton extends ConsumerWidget {
  const _EnterPlaceButton({
    super.key,
    required this.place,
    required this.again,
    required this.french,
    required this.onEnter,
  });

  final Settlement place;

  /// The scene was read before (reopened with Reread, or changed since).
  final bool again;
  final bool french;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = place.nameFor(french);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const Key('hub_enter'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: onEnter,
            icon: Icon(place.isCamp
                ? Icons.local_fire_department_outlined
                : Icons.location_city_outlined),
            label: Text(
              tr(ref, again ? 'hub_back_button' : 'hub_enter_button')
                  .replaceAll('{place}', name),
              textAlign: TextAlign.center,
            ),
          ),
          if (!again) ...[
            const SizedBox(height: 6),
            Text(
              tr(ref, 'hub_enter_hint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
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
  // The first place reached in a chapter also says what the region is going
  // through (see chapter_conditions.dart), once.
  final chapter = ref.read(reachedChapterProvider);
  final condition = ref.read(chapterConditionProvider);
  final showCondition = condition != null &&
      !ref
          .read(playerSessionProvider)
          .flags
          .contains(conditionSeenFlag(chapter));
  if (showCondition) {
    ref
        .read(playerSessionProvider.notifier)
        .applyChoiceEffects(flagsToAdd: [conditionSeenFlag(chapter)]);
  }
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
            if (showCondition) ...[
              const Divider(height: 24),
              Row(
                key: const ValueKey('arrival_condition'),
                children: [
                  Icon(Icons.flag_outlined,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(ref, 'condition_line')
                          .replaceAll('{name}', condition.nameFor(french)),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(condition.arrivalFor(french),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic, height: 1.4)),
              const SizedBox(height: 8),
              Text(condition.effectFor(french),
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(tr(ref, 'condition_where'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
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
    final locked = mainQuestShut ||
        _isChoiceLocked(choice, story, session, isExcursion,
            world: ref.watch(coastGateWorldProvider));
    final lockedLabel = locked
        ? storyChoiceLockedText(ref, choice, session,
            isExcursion: isExcursion,
            french: french,
            mainQuestShut: mainQuestShut)
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
    final hint = isExcursion ? '' : choicePoliticsHint(ref, choice);

    return Card(
      child: ListTile(
        leading: Icon(_hubIconFor(choice)),
        title: Text(label),
        subtitle: subtitle == null && hint.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitle != null) Text(subtitle),
                  if (hint.isNotEmpty) _PoliticsHintLine(hint: hint),
                ],
              ),
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
    final locked = mainQuestShut ||
        _isChoiceLocked(choice, story, session, isExcursion,
            world: ref.watch(coastGateWorldProvider));

    final lockedLabel = locked
        ? storyChoiceLockedText(ref, choice, session,
            isExcursion: isExcursion,
            french: french,
            mainQuestShut: mainQuestShut)
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
    // A side job waits a scene or two down this way: say so.
    final workAhead = !isExcursion &&
        !locked &&
        questOfferedAhead(
          choice: choice,
          story: story,
          takenQuestIds: {
            ...session.activeQuestIds,
            ...session.completedQuestIds,
          },
          mainQuestIds: mainQuestIdsOf(
              ref.watch(localizedDbProvider(questsSchema)).value ?? const {}),
        );

    final hint = isExcursion ? '' : choicePoliticsHint(ref, choice);
    final Widget content = roster != null && !choice.hasAbilityCheck
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
            : _ChoiceLabel(
                label: label,
                choice: choice,
                locked: locked,
                workAhead: workAhead,
              );

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
        child: hint.isEmpty
            ? content
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  const SizedBox(height: 4),
                  _PoliticsHintLine(hint: hint),
                ],
              ),
      ),
    );
  }
}

/// What a choice moves among the clans (v1.195, see politicsHint), for the
/// muted line under it: '' when the setting is off, or the choice moves
/// nothing it may say.
String choicePoliticsHint(WidgetRef ref, StoryChoice choice) {
  final politics = choice.politics;
  if (politics == null || !politics.hasHint) return '';
  if (!ref.watch(politicsHintsEnabledProvider)) return '';
  return politicsHint(
      politics, ref.watch(clanDataProvider), ref.watch(appLanguageProvider),
      politics: ref.watch(politicsProvider));
}

/// The muted line under a choice: "Vigil +5 · Dominion −5".
class _PoliticsHintLine extends StatelessWidget {
  const _PoliticsHintLine({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.7,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                hint,
                key: const Key('politics_hint'),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
}

/// A plain choice's text, with what it costs or brings underneath as
/// small tags ("+20 gold", "−10 HP", "Alignment −1").
class _ChoiceLabel extends ConsumerWidget {
  const _ChoiceLabel({
    required this.label,
    required this.choice,
    this.locked = false,
    this.workAhead = false,
  });

  final String label;
  final StoryChoice choice;

  /// A choice the player can't take yet: its tags fade with the card.
  final bool locked;

  /// A side job is on offer down this way (see questOfferedAhead).
  final bool workAhead;

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
      if (choice.grantsItem)
        InkTag(
          label:
              '+ ${(ref.watch(localizedDbProvider(itemsSchema)).value?[choice.grantItemId] as Map<String, dynamic>?)?['itemName'] ?? choice.grantItemId}',
          color: ink.gold,
        ),
      if (workAhead)
        InkTag(label: tr(ref, 'choice_work_ahead'), color: ink.gold),
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

/// Toggles reading the current node's narrative text aloud -- in the
/// recorded ElevenLabs voice when it is on, the device's text-to-speech
/// voice otherwise (see [_speakNarration]) -- in whichever language the
/// app is set to. Tapping again while speaking (or while a paragraph is
/// being recorded) stops it.
class _ReadAloudButton extends ConsumerWidget {
  const _ReadAloudButton({required this.paragraphs, required this.language});

  final List<String> paragraphs;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(elevenLabsTtsProvider);
    final isLoading = voiceState == VoicePlaybackState.loading;
    final isSpeaking =
        voiceState != VoicePlaybackState.idle || ref.watch(ttsProvider);

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
        if (isSpeaking) {
          _stopAllNarration(ref);
          return;
        }
        try {
          await _speakNarration(ref, paragraphs, language);
        } catch (e) {
          if (!context.mounted) return;
          showImmersiveNotice(
            context,
            icon: Icons.error_outline,
            message: '${tr(ref, 'voice_error_prefix')}: $e',
          );
        }
      },
    );
  }
}

/// Edit Mode: records the scene on screen -- every paragraph it can be
/// read in, in the app's language, companions' asides and callbacks
/// included -- so it plays offline and can be pushed to the repository.
/// Lit once the whole scene is recorded.
class _RecordSceneButton extends ConsumerWidget {
  const _RecordSceneButton({required this.paragraphs, required this.language});

  final List<String> paragraphs;
  final AppLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(narrationRecordingsVersionProvider);
    final voice = ref.watch(elevenLabsVoiceSettingsProvider);
    return FutureBuilder<bool>(
      future: ref
          .read(elevenLabsTtsProvider.notifier)
          .isRecorded(paragraphs, settings: voice, language: language),
      builder: (context, snapshot) {
        final recorded = snapshot.data ?? false;
        return IconButton(
          icon: Icon(recorded ? Icons.mic : Icons.mic_none, size: 18),
          color: recorded ? Theme.of(context).colorScheme.primary : null,
          tooltip: tr(ref, recorded ? 'scene_recorded' : 'record_scene'),
          visualDensity: VisualDensity.compact,
          onPressed: () => recordNarration(context, ref, {language: paragraphs},
              confirm: false),
        );
      },
    );
  }
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
    this.outcome,
  });

  final String label;
  final VoidCallback onOpen;
  final String? uiTheme;
  final String? aftermath;
  final String aftermathHeading;

  /// A check's outcome in words (see check_outcomes.dart), kept under the
  /// folded line like the aftermath.
  final String? outcome;

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
              if (outcome != null && outcome!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  outcome!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    height: 1.5,
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
class _StoryWeather extends ConsumerWidget {
  const _StoryWeather();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = ref.watch(reachedChapterProvider);
    return WeatherLayer(weather: journeyWeatherFor(chapter), strength: 0.3);
  }
}

class _StoryText extends StatelessWidget {
  const _StoryText({
    required this.text,
    this.prelude = const [],
    this.echoes = const [],
    this.echoCaption = '',
    this.uiTheme,
    this.placeLabel,
    this.moodLabel,
    this.epilogue,
    this.epilogueHeading = '',
    this.speakerLabel,
    this.aftermath,
    this.aftermathHeading = '',
    this.outcome,
  });

  final String text;

  /// Plain scenes read on the way here (see scene_flow.dart): they open
  /// the page, the scene's own text after a small rule.
  final List<ScenePrelude> prelude;

  /// Lines an earlier choice earned (see echoes.dart), after the scene's
  /// own text, each under the choice that earned it.
  final List<SceneEcho> echoes;

  /// "Because you chose “{choice}”".
  final String echoCaption;

  /// A check's outcome in words (see check_outcomes.dart): the scene
  /// opens with it, after the aftermath, if any. (What the party says
  /// about the last choice shows over the scene in a speech bubble, see
  /// companion_remark_bubble.dart.)
  final String? outcome;

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
    // A chapter's title may come with a scene read on the way into it.
    final header = storyHeaderFor(text) ??
        prelude
            .map((p) => storyHeaderFor(p.text))
            .firstWhere((h) => h != null && h.isNotEmpty, orElse: () => null);
    final body = storyBodyFor(text);
    final colorScheme = Theme.of(context).colorScheme;
    final palette = uiThemePaletteFor(uiTheme);
    final accent = resolveUiAccent(colorScheme, palette);
    final hasAftermath = aftermath != null && aftermath!.isNotEmpty;
    final hasOutcome = outcome != null && outcome!.isNotEmpty;

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: InkFonts.prose,
              fontSize: 17,
              height: palette?.lineHeight ?? 1.6,
              letterSpacing: palette?.letterSpacing ?? 0.1,
            ) ??
        const TextStyle();

    // The page is sewn along a dashed thread in the colour of where the
    // story is; the prose sits on the bare page beside it.
    // The chapter's weather drifts faintly behind the words.
    return Stack(
      children: [
        const Positioned.fill(child: _StoryWeather()),
        CustomPaint(
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
                                ?.copyWith(
                                    color: accent.text, letterSpacing: 1),
                          ),
                        ),
                      if (moodLabel != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            moodLabel!.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                if (hasAftermath || hasOutcome) ...[
                  if (hasAftermath) ...[
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
                  ],
                  if (hasOutcome) ...[
                    if (hasAftermath) const SizedBox(height: 12),
                    Text(
                      outcome!,
                      textAlign: TextAlign.start,
                      style: baseStyle.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
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
                for (final scene in prelude) ...[
                  if (scene.speaker != null && scene.speaker!.isNotEmpty) ...[
                    Text(
                      '— ${scene.speaker}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.2,
                            fontStyle: FontStyle.italic,
                            color: accent.text.withValues(alpha: 0.85),
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text.rich(
                    TextSpan(
                        children: _highlightedSpans(
                            storyBodyFor(scene.body), baseStyle)),
                    textAlign: TextAlign.start,
                  ),
                  for (final echo in scene.echoes) ...[
                    const SizedBox(height: 14),
                    EchoLine(
                      key: ValueKey('echo_${echo.key}'),
                      echo: echo,
                      caption: echoCaption.replaceAll('{choice}', echo.cause),
                      colour: accent.text,
                      style: baseStyle,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '⁂',
                      style: TextStyle(
                          color: accent.text.withValues(alpha: 0.55),
                          fontSize: 14),
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
                for (final echo in echoes) ...[
                  const SizedBox(height: 14),
                  EchoLine(
                    key: ValueKey('echo_${echo.key}'),
                    echo: echo,
                    caption: echoCaption.replaceAll('{choice}', echo.cause),
                    colour: accent.text,
                    style: baseStyle,
                  ),
                ],
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
        ),
      ],
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
  // A crown of gold sparks: the road begins again, harder.
  final middle = MediaQuery.sizeOf(context).center(Offset.zero);
  showBurst(context, at: middle, colour: const Color(0xFFD4A017), count: 28);
  showQuestSeal(context, colour: const Color(0xFFB8860B));
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
    await ref
        .read(playerSessionProvider.notifier)
        .acceptQuest(questId!, quest: quest);
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
        // A quest settled by a choice pays by it (see turn_in_choices.dart).
        if (turnInChoicesOf(quest).isNotEmpty)
          MapEntry(trFor(lang, 'reward_gold_label'), () {
            final golds = [
              for (final c in turnInChoicesOf(quest)) c.goldFor(rewardGold)
            ]..sort();
            return '${golds.first}–${golds.last}';
          }())
        else if (rewardGold > 0)
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

/// A line an earlier choice earned, under a small caption naming the
/// choice ("Because you chose “Spare him”"), set off by a thread in the
/// scene's colour so it reads as the story answering the player.
class EchoLine extends StatelessWidget {
  const EchoLine({
    super.key,
    required this.echo,
    required this.caption,
    required this.colour,
    required this.style,
  });

  final SceneEcho echo;
  final String caption;
  final Color colour;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(color: colour.withValues(alpha: 0.6), width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 14, color: colour),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    caption,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.4,
                          color: colour,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(echo.line, style: style),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../combat/combat_aftermath.dart';
import '../combat/combat_engine.dart' show newGamePlusStep;
import '../combat/encounter.dart';
import '../data/geography.dart' show GeoPlace, Geography;
import '../data/ability_check.dart';
import '../data/feature_unlocks.dart' show trainerGuardFlag, trainerStrikeFlag;
import '../data/clan_crisis.dart' show clanCrisisRoadEvent, isClanCrisisNode;
import '../data/district_attacks.dart'
    show DistrictSiege, buildSiegeNode, isSiegeNode, siegeToMeet;
import '../data/nemesis.dart' show maybeChampionRoad;
import '../data/alignment_events.dart';
import '../data/hunter_mercy.dart';
import '../data/rival_hunters.dart';
import '../data/approval.dart';
import '../data/ally_acknowledgments.dart';
import '../data/chapter_conditions.dart';
import '../data/check_outcomes.dart';
import '../data/companion_remarks.dart';
import '../data/detour_pacing.dart';
import '../data/detour_scenes.dart';
import '../data/echoes.dart';
import '../data/item_origin_here.dart';
import '../data/journey_rules.dart';
import '../data/recurring_encounters.dart';
import '../data/road_events.dart';
import '../data/road_hazards.dart';
import '../data/road_wards.dart' show wardedClansOf;
import '../data/encounter_text.dart';
import '../data/factions.dart' show CoastNews;
import '../data/map_themes.dart';
import '../data/narration_clips.dart';
import '../data/narration_pages.dart';
import '../data/narration_tokens.dart';
import '../data/politics_events.dart';
import '../data/port_helpers.dart';
import '../data/camp_state.dart';
import '../data/choice_shape.dart';
import '../data/quest_hints.dart';
import '../data/scene_lock.dart';
import '../data/quest_tracking.dart' show isMainQuest;
import '../data/settlements.dart';
import '../data/story_repository.dart';
import '../data/story_companions.dart';
import '../data/turn_in_choices.dart';
import '../data/camp_errands.dart' show storyChoiceTarget;
import '../data/scene_flow.dart';
import '../data/place_pools.dart';
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
import '../providers/choice_flow_provider.dart';
import '../providers/city_provider.dart'
    show cityPlanRecordsProvider, lockedStoryWaysProvider;
import '../providers/climate_provider.dart';
import '../data/weather_effects.dart';
import '../providers/clans_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/finished_story_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/place_pools_provider.dart';
import '../providers/elevenlabs_tts_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/map_theme_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import '../providers/road_random_provider.dart';
import '../providers/remark_provider.dart';
import '../providers/story_providers.dart';
import '../providers/story_text_provider.dart'
    show storyTextDoneProvider, storyTextSkipProvider;
import '../providers/tts_provider.dart';
import '../theme/stitched_ink.dart';
import 'epilogue_map_screen.dart';
import '../widgets/creation_fade_route.dart';
import '../widgets/prologue_opening.dart';
import '../widgets/story_text.dart';
import '../providers/voice_settings_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/reward_card.dart';
import '../widgets/reward_cards.dart';
import '../widgets/road_panel.dart';
import '../widgets/story_ship_battle.dart';
import '../widgets/timed_choice_bar.dart';
import '../widgets/journey_fx.dart';
import '../widgets/moments.dart';
import '../widgets/detail_dialog.dart';
import '../widgets/camp_travel.dart';
import '../widgets/companion_remark_bubble.dart';
import '../widgets/approval_notice.dart';
import '../widgets/ability_roll_dialog.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/narration_recording_dialogs.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/quest_tracker.dart';
import '../widgets/zone_card.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'expedition_screen.dart';
import 'fight_screen.dart';
import 'journal_screen.dart';
import 'land_crossing_screen.dart';
import 'race_profession_screen.dart';
import 'shop_detail_screen.dart';
import 'skill_challenge_screen.dart';
import 'story_node_editor_screen.dart';
import '../data/story_markup.dart' show stripStoryMarkup;

part 'story_player/story_choice_flow.dart';
part 'story_player/story_hub.dart';
part 'story_player/story_choice_widgets.dart';
part 'story_player/story_ending.dart';

/// The random stream a story choice's ability check (and a skill
/// challenge's rounds) rolls with: a fresh one each time in play; a test
/// overrides it with a seeded one so a check tapped through the app goes
/// the same way every run (as landCrossingRandomProvider does for a
/// crossing).
final storyCheckRandomProvider = Provider<Random?>((ref) => null);

/// Tracks the id of the last scene auto-read aloud, so the auto-read
/// effect (see [_StoryView.build]) speaks each scene exactly once instead
/// of re-triggering on every rebuild that doesn't actually change the
/// displayed node.
final _autoReadLastNodeKeyProvider = StateProvider<String?>((ref) => null);

/// Whether the status header (level/HP/gold and the quests/shops chips) is
/// collapsed to give the narration more room. Resets on app restart —
/// a per-session reading preference, not a persisted setting.
final _statusBarCollapsedProvider = StateProvider<bool>((ref) => false);

/// What the story text keeps on a small phone before the choices take any
/// more: about four lines of the prose with the card's padding.
const double storyTextMinHeight = 150;

/// Whether the story text is showing in distraction-free fullscreen —
/// toggled by double-tapping the narration itself, hiding everything else
/// (status bar, header row, choices) so only the prose
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
    // A scene reached before reads its revisit text (v1.813).
    final revisit = isRevisit(playState);
    final displayDescription = node == null
        ? ''
        : composeNarration(node, session, french: french, revisit: revisit);
    // The same text less the lines an earlier choice earned: those come
    // after it as echoes, with the choice that earned them.
    final parts = node == null
        ? (text: '', pages: const [''], echoes: const <SceneEcho>[])
        : composeNarrationParts(node, session, story,
            french: french, revisit: revisit);
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
    final statusBarCollapsed = ref.watch(_statusBarCollapsedProvider);
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
      // Out of the frame that moved the chapter: the offer writes the
      // session, which the providers being rebuilt now read.
      await Future<void>.delayed(Duration.zero);
      if (!context.mounted) return;
      final offered = await ref
          .read(playerSessionProvider.notifier)
          .grantChapterOffer(next,
              data: ref.read(clanDataProvider),
              geography: ref.read(geographyProvider));
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
      unawaited(showChapterCard(context,
          number: loop.label.isEmpty ? '$next' : loop.label,
          title: loop.title,
          colour: InkColors.of(context).ember,
          note: offered ? tr(ref, 'offer_chapter_note') : null,
          newsTitle: trFor(lang, 'coast_news_title'),
          news: chapterCardNews(news, lang)));
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
      for (final prelude in preludes) stripStoryMarkup(prelude.text),
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
    // Picking a saved story back up: a short recap, once per launch. A
    // save on a scene that holds the party on its page (scene_lock.dart)
    // has it on the next scene with a map. Only a scene that could lock
    // (every way to take is acted out on the spot) waits for the places
    // and the cities' plans the map lays its ways on; any other shows its
    // recap at once.
    final mayLock = _storyMapPlacementsKnown(ref)
        ? storySceneLocked(ref, node, story)
        : storySceneLocked(ref, node, story, mapped: (_) => false);
    if (storyOnScreen &&
        !ref.watch(_previouslyOfferedProvider) &&
        !mayLock &&
        hasRecapProgress(playState,
            resumed:
                ref.read(storyPlayProvider.notifier).restoredFromAutosave)) {
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
                    french: french, opening: opening, revisit: revisit),
                language);
          } catch (e) {
            // Auto-read fires without the player asking for it, so a
            // failure here must still surface — otherwise it just looks
            // like the voice silently never triggers.
            if (!context.mounted) return;
            unawaited(showImmersiveNotice(
              context,
              icon: Icons.error_outline,
              message: '${tr(ref, 'voice_error_prefix')}: $e',
            ));
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
    // The scene's words write themselves out when it is new (Edit Mode shows
    // them at once); the choices come once they have. A folded place shows
    // no text, so its lists are there from the start.
    final isEditing = ref.watch(appModeProvider) == AppMode.edit;
    // A scene in pages (narration_pages.dart, v1.750) is read a page at a
    // time: Continue turns the page, its choices wait on the last one, and
    // each page writes itself out on its own.
    final pageKey = scenePageKey(playState, node.id);
    final page =
        scenePageOf(ref.watch(scenePageProvider), pageKey, parts.pages.length);
    final firstPage = page == 0;
    final lastPage = page >= parts.pages.length - 1;
    final pageText = parts.pages.length > 1 ? parts.pages[page] : parts.text;
    final revealKey = isEditing
        ? null
        : '${node.id}|${playState.history.length}|${playState.isInExcursion}'
            '${page > 0 ? '#p$page' : ''}';
    final pageWritten = revealKey == null ||
        storyTextShownAtOnce(context) ||
        ref.watch(storyTextDoneProvider).contains(revealKey);
    final choicesReady = narrationFolded || (pageWritten && lastPage);
    // A page before the last: Continue in the choices' place writes it out
    // at once, then turns it.
    final pageContinue = narrationFolded || lastPage
        ? null
        : SizedBox(
            key: ValueKey('page_$pageKey#$page'),
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('story_page_continue'),
              onPressed: () => pageWritten
                  ? ref.read(scenePageProvider.notifier).state =
                      (key: pageKey, page: page + 1)
                  : ref.read(storyTextSkipProvider.notifier).state++,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(tr(ref, 'journey_continue')),
            ),
          );
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
              french: french, opening: opening, revisit: revisit),
          language: language),
    ];

    // The first scene is told as an animation, ending on its choice (see
    // prologue_opening.dart).
    if (!isEditMode &&
        !playState.isInExcursion &&
        parts.text.isNotEmpty &&
        isPrologueOpening(node)) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrologueOpening(
            text: parts.text,
            choices: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final choice in visibleChoices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ChoiceButton(
                      choice: choice,
                      story: story,
                      session: session,
                      currentNodeId: playState.currentNodeId,
                      isExcursion: false,
                      french: french,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // The reader's own tour plays only while it is on screen (v1.201: in
    // play it is pushed over the game for the ending, never a tab).
    return TutorialTrigger(
      topic: TutorialTopic.story,
      ready: !isEditMode && session.raceId.isNotEmpty && storyTab == 0,
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
                                french: french,
                                opening: opening,
                                revisit: revisit),
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
                    // The choices leave room for about four lines of the story
                    // ([storyTextMinHeight]).
                    final choiceBudget = narrationFolded
                        ? area.maxHeight
                        : max(
                            0.0,
                            min(area.maxHeight * 0.6,
                                area.maxHeight - 16 - storyTextMinHeight));
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
                            // Scrolling down into the narration gives the status bar
                            // above no purpose (it'd just be pushed off-screen anyway),
                            // so collapse it automatically the moment the player starts
                            // reading down the page. The manual chevron stays available
                            // to re-expand.
                            child: LayoutBuilder(
                              // Captured here, above the SingleChildScrollView, because
                              // that view gives its child unbounded height on the scroll
                              // axis -- a LayoutBuilder nested inside it would only ever
                              // see infinite height, not the actual viewport size.
                              builder: (context, viewportConstraints) {
                                // The same text card in the centred and the plain layout.
                                final storyText = _StoryText(
                                  revealKey: revealKey,
                                  text: pageText,
                                  prelude: firstPage ? preludes : const [],
                                  echoes: lastPage ? parts.echoes : const [],
                                  echoCaption: tr(ref, 'echo_because'),
                                  uiTheme: node.uiTheme,
                                  placeLabel: _placeLabel(ref, node.uiTheme),
                                  moodLabel: _moodLabel(ref, node.mood),
                                  epilogue: lastPage ? epilogue : null,
                                  speakerLabel: speakerLabel,
                                  aftermath:
                                      firstPage ? pendingAftermath : null,
                                  aftermathHeading:
                                      tr(ref, 'aftermath_heading'),
                                  outcome: firstPage ? checkOutcome : null,
                                  epilogueHeading: tr(ref, 'epilogue_heading'),
                                );
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
                                          // space (status bar, node header,
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
                                                    child: storyText,
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
                                                    storyText,
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
                          const SizedBox(height: 16),
                          // A timed scene's clock (see TimedChoiceBar).
                          if (node.isTimed &&
                              !playState.isInExcursion &&
                              !readingScene &&
                              choicesReady &&
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
                                  child: !choicesReady
                                      ? pageContinue ??
                                          const SizedBox.shrink(
                                              key: ValueKey('choices_waiting'))
                                      : readingScene
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
                                                        : () =>
                                                            setNarrationFolded(
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
                                                        if (node.choices
                                                                .isEmpty ||
                                                            isStoryEnding(node))
                                                          _EndingView(
                                                            title: tr(
                                                                ref, 'the_end'),
                                                            // A written ending (its only way on is "begin
                                                            // again") closes the story; a node with no choice
                                                            // at all is a branch left unfinished.
                                                            message: tr(
                                                                ref,
                                                                isStoryEnding(
                                                                        node)
                                                                    ? 'story_end_message'
                                                                    : 'branch_end_message'),
                                                            restartLabel: isStoryEnding(
                                                                    node)
                                                                ? node.choices
                                                                    .first
                                                                    .textFor(
                                                                        french)
                                                                : tr(ref,
                                                                    'restart_story'),
                                                            onRestart: () =>
                                                                notifier.restart(
                                                                    StoryRepository
                                                                        .startNodeId),
                                                            session: session,
                                                            onNewGamePlus: session
                                                                    .raceId
                                                                    .isEmpty
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
                                                                      bottom:
                                                                          8),
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
                                                                  session:
                                                                      session,
                                                                  currentNodeId:
                                                                      playState
                                                                          .currentNodeId,
                                                                  isExcursion:
                                                                      playState
                                                                          .isInExcursion,
                                                                  french:
                                                                      french,
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

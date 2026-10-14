import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/factions.dart';
import '../data/politics_events.dart';
import '../gamedata/db_schema.dart';
import '../models/story_node.dart';
import 'chapter_loop_provider.dart';
import 'clans_provider.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

/// politics_events.json (v1.195, see politics_events.dart), loaded the way
/// every gamedata table is, read raw: an event picks its language itself.
/// Empty until it has loaded.
final politicsEventsProvider = Provider<Map<String, PoliticsEvent>>((ref) =>
    parsePoliticsEvents(
        ref.watch(gameDbProvider(politicsEventsSchema)).value ?? const {}));

/// The politics events once the table has loaded: for code that acts on
/// them and may be the first to ask.
Future<Map<String, PoliticsEvent>> loadPoliticsEvents(WidgetRef ref) async =>
    parsePoliticsEvents(await ref
        .read(gameDbProvider(politicsEventsSchema).notifier)
        .whenLoaded());

Future<Map<String, dynamic>> _companions(WidgetRef ref) =>
    ref.read(gameDbProvider(companionsSchema).notifier).whenLoaded();

/// The coast a choice's politics gate is read in now (v1.196, see
/// choicePoliticsGate): the clan data and the chapter reached.
final coastGateWorldProvider = Provider<CoastWorld>((ref) => CoastWorld(
      data: ref.watch(clanDataProvider),
      chapter: ref.watch(reachedChapterProvider),
    ));

/// How [choice] stands behind its politics gate for [session] in [world]
/// (see choicePoliticsGate).
ChoiceGate choiceGateFor(
        StoryChoice choice, PlayerSession session, CoastWorld world) =>
    choicePoliticsGate(choice,
        politics: session.politics, flags: session.flags, world: world);

/// Whether [choice] is out of sight for [session]: its flags hide it, or
/// its politics gate fails and it has no locked text to show instead.
bool choiceHiddenFor(
        StoryChoice choice, PlayerSession session, CoastWorld world) =>
    choice.isHiddenFor(session.flags) ||
    choiceGateFor(choice, session, world) == ChoiceGate.hidden;

/// Set when the story has just mustered the Host (v1.196): the home shell
/// shows it ("Your Host"), then clears it.
final hostMusteredNoticeProvider = StateProvider<bool>((ref) => false);

/// Applies a story choice's or a scene's [politics] now, once under [key]
/// (see choicePoliticsKey, enterPoliticsKey), logged under
/// `story:<nodeId>` -- or [cause] when given (a quest's turn-in logs
/// `quest:<questId>`, v1.204) -- in the chapter reached. Returns what
/// changed; a Host mustered is shown (see [hostMusteredNoticeProvider]).
Future<CoastChange> applyStoryPoliticsNow(
  WidgetRef ref,
  StoryPolitics politics, {
  required String nodeId,
  required String key,
  String? cause,
}) async {
  final data = await loadClanData(ref);
  final events = await loadPoliticsEvents(ref);
  final companions = await _companions(ref);
  final change =
      await ref.read(playerSessionProvider.notifier).applyStoryPolitics(
            politics,
            nodeId: nodeId,
            key: key,
            cause: cause,
            data: data,
            events: events,
            companions: companions,
            chapter: ref.read(reachedChapterProvider),
          );
  if (change.applied && change.mustered) {
    ref.read(hostMusteredNoticeProvider.notifier).state = true;
  }
  return change;
}

/// Edit Mode's Throne tab (v1.196): [politics] (a claim, a pledge, the
/// Throne, the muster) applied now, every time.
Future<CoastChange> applyThroneEditNow(
    WidgetRef ref, StoryPolitics politics) async {
  final data = await loadClanData(ref);
  final events = await loadPoliticsEvents(ref);
  return ref.read(playerSessionProvider.notifier).applyThroneEdit(politics,
      data: data, events: events, chapter: ref.read(reachedChapterProvider));
}

/// The politics scene [nodeId] carries on entry (StoryNode.politicsOnEnter),
/// applied once: entering it again, or coming back to it, does nothing.
Future<void> applyEnterPolitics(WidgetRef ref, String nodeId) async {
  final node = ref.read(storyDataProvider).value?.nodeFor(nodeId);
  final politics = node?.politicsOnEnter;
  if (politics == null || politics.isEmpty) return;
  if (ref.read(playerSessionProvider).politics.applied(
        enterPoliticsKey(nodeId),
      )) {
    return;
  }
  await applyStoryPoliticsNow(ref, politics,
      nodeId: nodeId, key: enterPoliticsKey(nodeId));
}

/// Fires the politics events due in [chapter] (the chapter reached when
/// null, at least the world clock's) and today: on a chapter change and a
/// day's tick. Returns the news they told, oldest first.
Future<List<CoastNews>> runCoastEvents(WidgetRef ref, {int? chapter}) async {
  final events = await loadPoliticsEvents(ref);
  if (events.isEmpty) return const [];
  final data = await loadClanData(ref);
  final companions = await _companions(ref);
  final notifier = ref.read(playerSessionProvider.notifier);
  final int reached = chapter ?? ref.read(reachedChapterProvider);
  final int clock = ref.read(playerSessionProvider).clockChapter;
  final change = await notifier.runPoliticsEvents(
    data: data,
    events: events,
    companions: companions,
    chapter: max(1, max(reached, clock)),
  );
  return change.news;
}

/// Edit Mode's "Fire now": [eventId] fires at once, in the chapter
/// reached.
Future<CoastChange> fireCoastEventNow(WidgetRef ref, String eventId) async {
  final events = await loadPoliticsEvents(ref);
  final data = await loadClanData(ref);
  final companions = await _companions(ref);
  return ref.read(playerSessionProvider.notifier).firePoliticsEvent(
        eventId,
        data: data,
        events: events,
        companions: companions,
        chapter: ref.read(reachedChapterProvider),
      );
}

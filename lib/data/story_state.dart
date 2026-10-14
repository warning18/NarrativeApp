// The state of the story in one reading (v1.199): where the party stands,
// what is happening now, the threads open, who is along and how the
// clans stand, and the earlier choices that still matter. The story so
// far page, the strip under the Journey map and the Previously… dialog
// all read it.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/clans_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import 'chapter_grid_layout.dart';
import 'echoes.dart';
import 'factions.dart';
import 'journal.dart';
import 'narration_tokens.dart';
import 'quest_tracking.dart';
import 'world_map.dart';

/// One open thread: a quest in progress, with its goal.
class StoryThread {
  const StoryThread({
    required this.id,
    required this.name,
    required this.goal,
    required this.main,
    required this.followed,
    required this.ready,
  });

  final String id;
  final String name;

  /// The goal it waits on ("Defeat the smuggler (0/1)"), or '' when the
  /// quest has none.
  final String goal;
  final bool main;
  final bool followed;
  final bool ready;
}

/// A clan the player has a standing with, and its tier.
class StoryStanding {
  const StoryStanding(this.factionId, this.name, this.tier, this.colour);
  final String factionId;
  final String name;
  final StandingTier tier;
  final int colour;
}

/// An earlier choice and the line it earned later.
class StoryEcho {
  const StoryEcho({required this.cause, required this.line, this.place});
  final String cause;
  final String line;
  final String? place;
}

class StorySoFarState {
  const StorySoFarState({
    required this.day,
    required this.chapter,
    required this.chapterTitle,
    required this.placeName,
    required this.placeSub,
    required this.now,
    required this.threads,
    required this.party,
    required this.standings,
    required this.echoes,
    required this.recent,
  });

  final int day;
  final int chapter;
  final String chapterTitle;

  /// Where the party stands, and the lands above it with the land's
  /// ruler and biome.
  final String placeName;
  final String placeSub;

  /// What is happening now, in a few sentences.
  final String now;
  final List<StoryThread> threads;

  /// The companions along, by name.
  final List<String> party;
  final List<StoryStanding> standings;
  final List<StoryEcho> echoes;

  /// The last scenes read, oldest first, for the Previously… dialog.
  final List<JournalEntry> recent;

  /// The first sentence of [now], for a strip.
  String get nowLine {
    final end = now.indexOf('. ');
    return end < 0 ? now : now.substring(0, end + 1);
  }

  static const empty = StorySoFarState(
    day: 1,
    chapter: 0,
    chapterTitle: '',
    placeName: '',
    placeSub: '',
    now: '',
    threads: [],
    party: [],
    standings: [],
    echoes: [],
    recent: [],
  );
}

/// The story's state now, from everything the app already keeps; read
/// in a widget's build (it watches what it reads).
StorySoFarState readStorySoFar(WidgetRef ref) {
  final story = ref.watch(storyDataProvider).value;
  if (story == null) return StorySoFarState.empty;
  final play = ref.watch(storyPlayProvider);
  final session = ref.watch(playerSessionProvider);
  final lang = ref.watch(appLanguageProvider);
  final french = lang == AppLanguage.fr;
  final world = ref.watch(geographyProvider);
  final loop = ref.watch(currentLoopProvider);
  final quests = ref.watch(localizedDbProvider(questsSchema)).value ?? const {};
  final companions =
      ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
  final politics = ref.watch(politicsProvider);
  final clanData = ref.watch(clanDataProvider);
  final factions = ref.watch(factionsProvider);

  String personal(String text) => personalizeNarration(
        text,
        name: session.characterName,
        raceId: session.raceId,
        professionId: session.professionId,
        french: french,
      );

  final node = story.nodeFor(play.currentNodeId);
  final chapter = chapterOfNode(play.currentNodeId);
  final mapChapter = mapChapters.where((c) => c.number == chapter).firstOrNull;
  final chapterTitle = loop?.title.isNotEmpty == true
      ? loop!.title
      : mapChapter == null
          ? ''
          : () {
              final title = mapChapter.title(lang);
              final split = title.indexOf(':');
              return split < 0 ? title : title.substring(split + 1).trim();
            }();

  // Where the party stands.
  final landmark = currentLandmark(play.currentNodeId, play.history) ??
      landmarkOfScene(play.currentNodeId);
  final place = world.placeOfNode(node) ?? world.placeOfLandmark(landmark?.id);
  final placeName = node?.settlement?.nameFor(french) ??
      place?.nameFor(french) ??
      landmark?.name(lang) ??
      '';
  final path = world.pathOf(place?.id);
  final country = world.countryOf(place?.id);
  final biome = world.biomeOf(place?.id);
  final subParts = <String>[
    for (final p in path.reversed)
      if (p.id != place?.id && p.level.name != 'continent') p.nameFor(french),
    if (country != null && country.ruler.isNotEmpty)
      if (factions[country.ruler] case final ruler?)
        trFor(lang, 'sofar_now_land')
            .replaceAll('{land}', french ? ruler.shortFr : ruler.short),
    if (biome != null) biome.nameFor(french).toLowerCase(),
  ];

  // The threads: each quest in progress, the main one and the followed
  // one first.
  final followed = followedQuestIdOf(session);
  final mainId =
      loop == null ? null : _mainQuestId(loop.mainQuestTitle, quests);
  final ids = <String>{
    if (mainId != null && session.activeQuestIds.contains(mainId)) mainId,
    if (followed != null) followed,
    ...session.activeQuestIds,
  };
  final threads = <StoryThread>[];
  for (final id in ids) {
    final quest = quests[id];
    if (quest is! Map<String, dynamic>) continue;
    final name = quest['questName']?.toString() ?? id;
    final goal = questGoalFor(id, quest, session);
    threads.add(StoryThread(
      id: id,
      name: name,
      goal: goal.ready ? trFor(lang, 'quest_goal_ready') : goal.label,
      main: id == mainId,
      followed: id == followed,
      ready: goal.ready,
    ));
  }

  // Who is along.
  final party = <String>[
    for (final id in session.activeAllyIds)
      if (companions[id] case final Map<String, dynamic> c)
        (c['companionName']?.toString() ?? id),
  ];

  // The clans the player stands somewhere with.
  final standings = <StoryStanding>[
    for (final entry in factions.entries)
      if (politics.tierOf(entry.key, clanData) case final tier
          when tier != StandingTier.unknown)
        StoryStanding(
            entry.key,
            french ? entry.value.shortFr : entry.value.short,
            tier,
            entry.value.patron.color),
  ];

  // The echoes met so far, the latest first.
  final echoes = <StoryEcho>[
    for (final key in session.seenEchoKeys.reversed.take(3))
      if (echoForKey(story, key, french: french) case final echo?)
        StoryEcho(
          cause: personal(echo.cause),
          line: personal(echo.line),
          place: landmarkOfScene(echo.nodeId)?.name(lang),
        ),
  ];

  // Now: the chapter's hint, where the party came from and with whom,
  // and the last choice made.
  final entries =
      storySoFar(story, play.history, play.currentNodeId, french: french);
  final recent =
      entries.length <= 3 ? entries : entries.sublist(entries.length - 3);
  JournalEntry? lastChosen;
  for (final entry in entries.reversed) {
    if (entry.choiceText != null) {
      lastChosen = entry;
      break;
    }
  }
  final from = <String>{
    for (final id in play.history.reversed.take(12))
      if (landmarkOfScene(id) case final l? when l.id != landmark?.id)
        l.name(lang),
  }.take(1);
  final sentences = <String>[];
  if (placeName.isNotEmpty) {
    var where = from.isEmpty
        ? trFor(lang, 'sofar_now_at').replaceAll('{place}', placeName)
        : trFor(lang, 'sofar_now_came')
            .replaceAll('{from}', from.first)
            .replaceAll('{place}', placeName);
    if (party.isNotEmpty) {
      where += trFor(lang, 'sofar_now_with')
          .replaceAll('{party}', _joined(party, french));
    }
    sentences.add('$where.');
  }
  if (loop != null && loop.mainQuestHint.isNotEmpty) {
    sentences.add(loop.mainQuestHint);
  }
  if (lastChosen?.choiceText case final choice?) {
    sentences.add(
        trFor(lang, 'sofar_now_last').replaceAll('{choice}', personal(choice)));
  }

  return StorySoFarState(
    day: session.day,
    chapter: chapter,
    chapterTitle: chapterTitle,
    placeName: placeName,
    placeSub: subParts.join(' · '),
    now: sentences.join(' '),
    threads: threads,
    party: party,
    standings: standings,
    echoes: echoes,
    recent: recent,
  );
}

/// The quest whose name is the chapter's main quest, if one is.
String? _mainQuestId(String title, Map<String, dynamic> quests) {
  if (title.isEmpty) return null;
  for (final entry in quests.entries) {
    final quest = entry.value;
    if (quest is Map<String, dynamic> &&
        (quest['questName']?.toString() == title ||
            quest['questName_fr']?.toString() == title)) {
      return entry.key;
    }
  }
  return null;
}

String _joined(List<String> names, bool french) {
  if (names.length == 1) return names.single;
  final and = french ? ' et ' : ' and ';
  return '${names.sublist(0, names.length - 1).join(', ')}$and${names.last}';
}

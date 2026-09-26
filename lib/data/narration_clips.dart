import 'dart:convert';

import '../models/story_node.dart';
import '../providers/player_session_provider.dart';
import 'ally_acknowledgments.dart';
import 'chapter_grid_layout.dart';
import 'chapter_spine.dart';
import 'narration_tokens.dart';

/// Recorded narration is kept one clip per paragraph, so a scene the story
/// assembles differently for each player (a companion's aside, a callback
/// to an earlier choice, a race or profession sentence -- see
/// `composeNarration`) still plays from clips most players share: only the
/// paragraphs that actually differ need a recording of their own.

final RegExp _storyHeaderPattern = RegExp(r'^\[(.+?)\]\s*');

/// This node's `[CHAPTER N: TITLE]`-style leading header, if present.
String? storyHeaderFor(String text) =>
    _storyHeaderPattern.firstMatch(text)?.group(1);

/// This node's narrative text with any leading `[CHAPTER N: TITLE]`-style
/// header stripped off -- used both for on-screen rendering and for what
/// the read-aloud button speaks, so the header isn't read out loud.
String storyBodyFor(String text) {
  final match = _storyHeaderPattern.firstMatch(text);
  return (match != null ? text.substring(match.end) : text).trim();
}

/// [text] split into the paragraphs read aloud one clip each: on blank
/// lines, trimmed, empty ones dropped.
List<String> narrationParagraphs(String text) => [
      for (final paragraph in text.split(RegExp(r'\n\s*\n')))
        if (paragraph.trim().isNotEmpty) paragraph.trim(),
    ];

/// A stable id for the clip of [text] spoken by [voiceId] with [modelId]:
/// the file name a recording is stored under, so the same paragraph is
/// only ever recorded once per voice. Two 32-bit FNV-1a hashes over the
/// UTF-8 bytes, kept inside 32 bits at every step so the web build (where
/// ints are doubles) computes the same id.
String narrationClipId({
  required String text,
  required String voiceId,
  required String modelId,
}) {
  final bytes = utf8.encode('$modelId|$voiceId|$text');
  int fnv(int seed) {
    var hash = seed;
    for (final byte in bytes) {
      hash ^= byte;
      // hash * 16777619 (the FNV prime, 2^24 + 0x193) modulo 2^32, split
      // so no intermediate result passes 2^53.
      hash = (hash * 0x193 + (hash & 0xff) * 0x1000000) & 0xffffffff;
    }
    return hash;
  }

  String hex(int value) => value.toRadixString(16).padLeft(8, '0');
  return '${hex(fnv(0x811c9dc5))}${hex(fnv(0x050c5d1f))}';
}

/// Fills a player's `{name}`/`{race}`/... tokens the way the story screen
/// does (see `composeNarration`).
String personalizeFor(PlayerSession session, String text,
    {required bool french}) {
  String? capitalized(String? id) => id == null || id.isEmpty
      ? null
      : '${id[0].toUpperCase()}${id.substring(1)}';
  return personalizeNarration(
    text,
    name: session.characterName,
    raceId: session.raceId,
    professionId: session.professionId,
    companionName: capitalized(
        session.activeAllyIds.isEmpty ? null : session.activeAllyIds.first),
    lostCompanionName: capitalized(
        session.lostAllyIds.isEmpty ? null : session.lostAllyIds.last),
    french: french,
  );
}

/// The paragraphs [node] is read aloud in, one clip each, for this
/// player: the same words `composeNarration` shows, with the companion's
/// aside as a clip of its own rather than run on to the scene's last
/// paragraph, so the scene itself is recorded once whoever walks with the
/// character.
List<String> readAloudParagraphs(StoryNode node, PlayerSession session,
    {required bool french}) {
  String personal(String text) => personalizeFor(session, text, french: french);
  final aside = allyAcknowledgmentFor(node.id,
      activeAllyIds: session.activeAllyIds, french: french);
  final progress = node.hubProgressLineFor(session.flags, french);
  final extras = [
    if (aside != null) aside,
    if (progress != null) progress,
    ...node.callbacksFor(session.flags, french),
    ...node.personaLinesFor(
      raceId: session.raceId,
      professionId: session.professionId,
      french: french,
    ),
  ];
  return [
    ...narrationParagraphs(storyBodyFor(personal(node.descriptionFor(french)))),
    for (final extra in extras) ...narrationParagraphs(personal(extra)),
  ];
}

/// The kinds of scene the recording page (Edit Mode) sorts the story
/// into, so a part of it can be recorded on its own.
enum NarrationCategory {
  /// The fixed beats every playthrough passes through (see
  /// [isMainBeatNode]).
  mainStory,

  /// Camps, towns, villages and sites (see [StoryNode.settlement]).
  places,

  /// Everything else the story visits: quests, recruitments, branches.
  sideScenes,

  /// The story's endings (see [isStoryEnding]).
  endings,
}

NarrationCategory narrationCategoryOf(StoryNode node) {
  if (isStoryEnding(node)) return NarrationCategory.endings;
  if (isMainBeatNode(node.id)) return NarrationCategory.mainStory;
  if (node.settlement != null) return NarrationCategory.places;
  return NarrationCategory.sideScenes;
}

/// The chapter [node] is filed under on the recording page: 0 is the
/// prologue (see [chapterOfNode]).
int narrationChapterOf(StoryNode node) => chapterOfNode(node.id);

/// Every paragraph [node] can be read aloud in, for recording it ahead of
/// time: the scene itself and, with [variations], each companion's aside
/// and every hub, callback and persona line it can add -- personalized
/// with [personalize] and split the way [readAloudParagraphs] splits them,
/// so the recordings match what the read-aloud button asks for.
List<String> nodeNarrationScript(
  StoryNode node, {
  required bool french,
  required String Function(String text) personalize,
  bool variations = true,
}) {
  final script = <String>{
    ...narrationParagraphs(
        storyBodyFor(personalize(node.descriptionFor(french)))),
  };
  if (variations) {
    final extras = [
      ...allyAcknowledgmentVariantsFor(node.id, french: french),
      for (final line in node.hubProgress?.lines ?? const <HubProgressLine>[])
        line.line.textFor(french),
      for (final callback in node.flagCallbacks) callback.line.textFor(french),
      for (final line in node.personaVariants.values) line.textFor(french),
    ];
    for (final extra in extras) {
      script.addAll(narrationParagraphs(personalize(extra)));
    }
  }
  return script.toList();
}

/// Every paragraph the story can read aloud to this player, for recording
/// the whole story ahead of time (see [nodeNarrationScript]).
/// Insertion-ordered (story order), without duplicates.
List<String> narrationScript(
  Iterable<StoryNode> nodes, {
  required bool french,
  required String Function(String text) personalize,
  bool variations = true,
}) {
  return {
    for (final node in nodes)
      ...nodeNarrationScript(node,
          french: french, personalize: personalize, variations: variations),
  }.toList();
}

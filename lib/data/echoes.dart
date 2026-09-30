import '../data/story_repository.dart';
import '../models/story_node.dart';
import 'origin_stories.dart';
import 'scene_flow.dart';

/// Echoes: a scene's lines that are there because of an earlier choice.
///
/// Every flag-callback line a scene shows (see StoryNode.flagCallbacks)
/// answers a flag, and most flags are set by one choice of the story. An
/// echo is such a line with the choice that earned it, so the story can
/// say so ("Because you chose ...") instead of the line reading as if it
/// had always been there.
class SceneEcho {
  const SceneEcho({
    required this.nodeId,
    required this.flag,
    required this.line,
    required this.cause,
  });

  /// The scene the line is in.
  final String nodeId;

  /// The flag the line answers.
  final String flag;

  /// The line, as the player reads it.
  final String line;

  /// The choice that set [flag], in the player's language.
  final String cause;

  /// How the save remembers the player has seen this echo.
  String get key => echoKey(nodeId, flag);
}

/// The save's key for the echo of [flag] in scene [nodeId].
String echoKey(String nodeId, String flag) => '$nodeId|$flag';

/// The scene id and flag of a saved echo [key].
(String nodeId, String flag) splitEchoKey(String key) {
  final at = key.indexOf('|');
  return at < 0 ? (key, '') : (key.substring(0, at), key.substring(at + 1));
}

final Expando<Map<String, StoryChoice>> _setters = Expando();

/// The choice that sets each flag in [story] (the first one found, in
/// story order), for the echoes' "because". A flag set on the way out of
/// a scene the story reads straight through (see scene_flow.dart) is
/// credited to the choice that led into that scene: the one the player
/// pressed.
Map<String, StoryChoice> flagSetters(StoryData story) {
  final known = _setters[story];
  if (known != null) return known;
  final ledInto = <String, StoryChoice>{};
  for (final node in story.nodes.values) {
    for (final choice in node.choices) {
      if (choice.nextId != node.id) {
        ledInto.putIfAbsent(choice.nextId, () => choice);
      }
    }
  }
  final setters = <String, StoryChoice>{};
  for (final node in story.nodes.values) {
    final readThrough = passThroughChoiceOf(node, const []);
    for (final choice in node.choices) {
      final pressed =
          identical(choice, readThrough) ? ledInto[node.id] ?? choice : choice;
      for (final flag in choice.flagsToAdd) {
        setters.putIfAbsent(flag, () => pressed);
      }
    }
  }
  return _setters[story] = setters;
}

/// The choice that set [flag] in [story] -- or, for a formative memory's
/// flag (origin_stories.dart), the answer given -- or null when nothing
/// the player chose does (a flag set by an expedition, a house, a quest).
StoryChoice? echoCause(StoryData story, String flag) =>
    flagSetters(story)[flag] ?? _originCause(flag);

final Map<String, StoryChoice?> _originCauses = {};

StoryChoice? _originCause(String flag) => _originCauses.putIfAbsent(flag, () {
      final found = originAnswerForFlag(flag);
      if (found == null) return null;
      return StoryChoice(
        text: found.answer.en,
        textFr: found.answer.fr,
        nextId: '',
      );
    });

/// A saved echo (see [SceneEcho.key]) as the journal lists it: the scene,
/// its line and the choice that earned it, in the player's language with
/// tokens still to fill; null when the story no longer has it.
({String nodeId, String line, String cause})? echoForKey(
    StoryData story, String key,
    {required bool french}) {
  final (nodeId, flag) = splitEchoKey(key);
  final node = story.nodeFor(nodeId);
  final cause = echoCause(story, flag);
  if (node == null || cause == null) return null;
  for (final callback in node.flagCallbacks) {
    if (callback.flag != flag) continue;
    return (
      nodeId: nodeId,
      line: callback.line.textFor(french),
      cause: cause.textFor(french),
    );
  }
  return null;
}

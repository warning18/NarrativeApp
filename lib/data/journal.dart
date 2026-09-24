import '../models/story_node.dart';
import 'chapter_grid_layout.dart';
import 'story_repository.dart';

/// One step of the story so far: the scene's opening line and the choice
/// that left it (null for the scene the player stands in, or when the
/// next step came some other way, such as a jump).
class JournalEntry {
  const JournalEntry({
    required this.nodeId,
    required this.chapter,
    required this.opening,
    this.choiceText,
  });

  final String nodeId;
  final int chapter;
  final String opening;
  final String? choiceText;
}

final RegExp _chapterHeading = RegExp(r'^\s*\[[^\]]*\]\s*');

/// A scene's first sentence, without its chapter heading, cut to
/// [maxLength] characters.
String openingLine(String description, {int maxLength = 200}) {
  final text = description.replaceFirst(_chapterHeading, '').trim();
  if (text.isEmpty) return '';
  final end = RegExp(r'[.!?…](["»”’]?)(\s|$)').firstMatch(text);
  var sentence = end == null ? text : text.substring(0, end.end).trim();
  if (sentence.length > maxLength) {
    final cut = sentence.lastIndexOf(' ', maxLength);
    sentence = '${sentence.substring(0, cut > 0 ? cut : maxLength)}…';
  }
  return sentence;
}

/// The story so far, oldest first: every scene in [history] and then the
/// current one, each with the choice that led on from it -- read off the
/// graph, since the choice whose way on reached the next scene is the one
/// that was taken.
List<JournalEntry> storySoFar(
  StoryData story,
  List<String> history,
  String currentNodeId, {
  required bool french,
}) {
  final path = [...history, currentNodeId];
  final entries = <JournalEntry>[];
  for (var i = 0; i < path.length; i++) {
    final node = story.nodeFor(path[i]);
    if (node == null) continue;
    final next = i + 1 < path.length ? path[i + 1] : null;
    StoryChoice? taken;
    if (next != null) {
      for (final choice in node.choices) {
        if (choice.nextId == next ||
            choice.failNextId == next ||
            choice.loseNextId == next) {
          taken = choice;
          break;
        }
      }
    }
    entries.add(JournalEntry(
      nodeId: node.id,
      chapter: chapterOfNode(node.id),
      opening: openingLine(node.descriptionFor(french)),
      choiceText: taken?.textFor(french),
    ));
  }
  return entries;
}

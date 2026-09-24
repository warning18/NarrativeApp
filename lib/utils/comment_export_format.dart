import '../models/story_node.dart';

/// Renders [nodes] (each expected to have [StoryNode.authoringComment] set)
/// as plain text, one `[id] (Chapter N)` header per node followed by its
/// comment -- the original export format from before JSON/CSV existed.
String asCommentExportText(
    List<StoryNode> nodes, int Function(String) chapterOfNode) {
  final b = StringBuffer();
  for (final node in nodes) {
    b.writeln('[${node.id}] (Chapter ${chapterOfNode(node.id)})');
    b.writeln(node.authoringComment);
    b.writeln();
  }
  return b.toString().trim();
}

/// A minimal, LLM-prompt-friendly JSON array -- just enough per node (id,
/// chapter, comment) to paste directly into a prompt without a repo
/// checkout, since the full node text/choices are already covered by
/// sharing the repository itself.
String asCommentExportJson(
    List<StoryNode> nodes, int Function(String) chapterOfNode) {
  final b = StringBuffer('[\n');
  for (var i = 0; i < nodes.length; i++) {
    final node = nodes[i];
    b.write('  {"id": ${_jsonString(node.id)}, '
        '"chapter": ${chapterOfNode(node.id)}, '
        '"comment": ${_jsonString(node.authoringComment!)}}');
    b.writeln(i == nodes.length - 1 ? '' : ',');
  }
  b.write(']');
  return b.toString();
}

String _jsonString(String value) {
  final escaped = value
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '');
  return '"$escaped"';
}

String asCommentExportCsv(
    List<StoryNode> nodes, int Function(String) chapterOfNode) {
  final b = StringBuffer('id,chapter,comment\r\n');
  for (final node in nodes) {
    b.write(_csvField(node.id));
    b.write(',');
    b.write(chapterOfNode(node.id));
    b.write(',');
    b.write(_csvField(node.authoringComment!));
    b.write('\r\n');
  }
  return b.toString();
}

String _csvField(String value) => '"${value.replaceAll('"', '""')}"';

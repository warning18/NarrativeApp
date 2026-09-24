// Coverage for the pure comment-export formatters used by
// StoryCommentsReviewScreen's export menu -- kept as plain `test()` calls
// against comment_export_format.dart rather than a widget test, since
// driving the screen's real export button touches path_provider's native
// file I/O, which isn't available under `flutter test`.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/utils/comment_export_format.dart';

int _chapterOne(String id) => 1;

const _fixtureComment = 'Pacing feels "off" here, needs, a beat';

final _nodes = [
  const StoryNode(
    id: '100',
    description: 'A commented node.',
    choices: [],
    authoringComment: _fixtureComment,
  ),
];

void main() {
  test('asCommentExportJson produces a valid, correctly escaped JSON array',
      () {
    final decoded =
        jsonDecode(asCommentExportJson(_nodes, _chapterOne)) as List;

    expect(decoded, hasLength(1));
    expect(decoded.single['id'], '100');
    expect(decoded.single['chapter'], 1);
    expect(decoded.single['comment'], _fixtureComment);
  });

  test('asCommentExportCsv produces a header row plus one escaped row', () {
    final lines = asCommentExportCsv(_nodes, _chapterOne).split('\r\n')
      ..removeWhere((l) => l.isEmpty);

    expect(lines.first, 'id,chapter,comment');
    expect(lines[1], '"100",1,"Pacing feels ""off"" here, needs, a beat"');
  });

  test('asCommentExportText keeps the original bracketed-header format', () {
    final text = asCommentExportText(_nodes, _chapterOne);

    expect(text, contains('[100] (Chapter 1)'));
    expect(text, contains(_fixtureComment));
  });

  test('empty node list produces an empty JSON array and a header-only CSV',
      () {
    expect(asCommentExportJson(const [], _chapterOne), '[\n]');
    expect(asCommentExportCsv(const [], _chapterOne), 'id,chapter,comment\r\n');
  });
}

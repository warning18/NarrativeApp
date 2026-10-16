// A chapter can recommend a level (chapters.json `recommendedLevel`): the
// simulator found chapter 4 is a "get stronger first" gate, so its row
// names 9, and the camp and the Journey say so while the party is still
// in chapter 3 and under it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart'
    show frenchOverlay;

Map<String, dynamic> _loadJson(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $relative');
}

void main() {
  final loops = chapterLoopsFrom(_loadJson('assets/gamedata/chapters.json'));

  group('parsing', () {
    test('chapter 4 recommends level 9; chapter 3 recommends none', () {
      expect(recommendedLevelFor(4, loops), 9);
      expect(recommendedLevelFor(3, loops), isNull);
      expect(recommendedLevelFor(99, loops), isNull);
    });

    test('an absent, empty or nonsense field is no recommendation', () {
      ChapterLoop? read(Object? level) => ChapterLoop.fromJson('x', {
            'chapter': 4,
            'campNodeId': 'c',
            if (level != null) 'recommendedLevel': level,
          });
      expect(read(null)!.recommendedLevel, isNull);
      expect(read(0)!.recommendedLevel, isNull);
      expect(read('')!.recommendedLevel, isNull);
      expect(read('9')!.recommendedLevel, 9);
      expect(read(9.0)!.recommendedLevel, 9);
      expect(read(null)!.recommendedLevelNote, '');
    });

    test('the note is read, in French when it is filled in', () {
      final rows = {
        'ch4': {
          'chapter': 4,
          'campNodeId': '4999_camp',
          'recommendedLevel': 9,
          'recommendedLevelNote': 'Get stronger.',
          'recommendedLevelNote_fr': 'Devenez plus fort.',
        },
      };
      expect(
          chapterLoopsFrom(rows).single.recommendedLevelNote, 'Get stronger.');
      expect(chapterLoopsFrom(frenchOverlay(rows)).single.recommendedLevelNote,
          'Devenez plus fort.');
    });
  });

  group('advice', () {
    test('under the recommended level is below, by how many levels', () {
      final advice =
          chapterLevelAdvice(chapter: 4, playerLevel: 6, loops: loops)!;
      expect(advice.chapter, 4);
      expect(advice.recommendedLevel, 9);
      expect(advice.playerLevel, 6);
      expect(advice.below, isTrue);
      expect(advice.levelsShort, 3);
    });

    test('at or over it is not below', () {
      for (final level in [9, 12]) {
        final advice =
            chapterLevelAdvice(chapter: 4, playerLevel: level, loops: loops)!;
        expect(advice.below, isFalse, reason: 'level $level');
        expect(advice.levelsShort, 0);
      }
    });

    test('a chapter without a recommendation gives no advice', () {
      expect(
          chapterLevelAdvice(chapter: 3, playerLevel: 1, loops: loops), isNull);
      expect(chapterLevelAdvice(chapter: 4, playerLevel: 1, loops: const []),
          isNull);
    });

    test('in chapter 3 the advice is for chapter 4, the one ahead', () {
      final ahead = nextChapterLevelAdvice(
          currentChapter: 3, playerLevel: 7, loops: loops)!;
      expect(ahead.chapter, 4);
      expect(ahead.below, isTrue);
      // Once in chapter 4, chapter 5 recommends nothing (yet).
      expect(
          nextChapterLevelAdvice(
              currentChapter: 4, playerLevel: 7, loops: loops),
          isNull);
    });
  });
}

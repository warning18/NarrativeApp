// Every enemy a story choice fights exists in enemies.json: a choice naming
// one that doesn't (Lysa's arc named brother_clement before it was added)
// is caught here, and the simulator counts such a fight as lost.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';

void main() {
  test('every enemy a story choice fights is in enemies.json', () {
    final enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final missing = <String>[
      for (final e in raw.entries)
        for (final choice
            in StoryNode.fromJson(e.key, e.value as Map<String, dynamic>)
                .choices)
          for (final id in choice.allTriggerEnemyIds)
            // `@first_ally` resolves in play (story_player_screen.dart).
            if (!id.startsWith('@') && !enemies.containsKey(id))
              '${e.key}: $id',
    ];
    expect(missing, isEmpty);
  });
}

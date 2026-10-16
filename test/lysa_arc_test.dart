// Lysa's arc, Core's part (v1.413, docs/proposals/lysa-arc.md): Brother
// Clement, the Black Hold's torturer, a chapter-5 boss met only in the
// story; and the Dominion's hunt as her fate turns it: fiercer when she is
// taken by force or given to the Shroud, over when you swear to the
// Lantern for her.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart' show isBossEnemy;
import 'package:narrative_data_app/data/alignment_events.dart'
    show isHunterEnemy;
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/rival_hunters.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final enemies = _table('enemies');

  test('Brother Clement: a chapter-5 boss of the story only', () {
    final clement = enemies['brother_clement'] as Map<String, dynamic>;
    expect(isBossEnemy('brother_clement', clement), isTrue);
    // Never drawn on the roads or in a hunt pool.
    expect(isHunterEnemy(clement), isTrue);
    expect(clement['hunterClan'], isNull);
    expect(clement['minChapter'], 5);
    expect(clement['alignment'], -40);
    expect(clement['kind'], 'person');
    for (final key in ['enemyName', 'battleCry', 'defeat', 'description']) {
      expect(clement[key], isNotEmpty, reason: key);
      expect(clement['${key}_fr'], isNotEmpty, reason: key);
    }
    expect(clement['battleCry_fr'], startsWith('« '));
  });

  test('taken by force or given to the Shroud: the hunt turns fierce', () {
    for (final flag in dominionFiercerFlags) {
      final fierce = updateNemesis(PoliticsState.storyStart, data,
          chapter: 5, flags: [flag]);
      expect(fierce.nemesis, 'dominion', reason: flag);
      expect(fierce.isStoryNemesis, isFalse, reason: flag);
      expect(rivalHunts(fierce, data), {'dominion': rivalHunterChanceHunted});
    }
    // Keld comes sooner.
    final politics = PoliticsState.empty.copyWith(nemesis: 'dominion');
    int met(List<String> flags) => [
          for (var i = 0; i < 400; i++)
            maybeChampionRoad(
                politics: politics,
                activeQuestIds: const ['q_nemesis_dominion'],
                enemies: enemies,
                chapter: 5,
                random: Random(i),
                flags: [trailFlagOf('dominion'), ...flags])
        ].nonNulls.length;
    expect(met(const []), inInclusiveRange(100, 180));
    expect(met(const ['lysa_rescued_force']), inInclusiveRange(200, 280));
  });

  test('sworn to the Lantern for her: the hunt is over', () {
    final sworn = updateNemesis(PoliticsState.storyStart, data,
        chapter: 5, flags: const ['lysa_sworn_for']);
    expect(sworn.nemesis, '');
    expect(sworn.news.last.eventId, 'nemesis_end:dominion');
  });
}

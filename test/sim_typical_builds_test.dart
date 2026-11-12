// The typical player's builds (docs/simulation/typical-player-builds.json,
// sim_snapshot.dart) are saves QA loads to replay the deadliest fights: each
// must load as the game loads a save, with its die's faces under its die.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

void main() {
  test('every typical build loads as a PlayerSession, faces by die', () {
    final builds = jsonDecode(File('docs/simulation/typical-player-builds.json')
        .readAsStringSync()) as Map<String, dynamic>;
    var count = 0;
    for (final MapEntry(key: fight, value: entry) in builds.entries) {
      final byProfession = (entry as Map)['byProfession'] as Map;
      for (final MapEntry(key: profession, value: build)
          in byProfession.entries) {
        final save = (build as Map)['save'] as Map<String, dynamic>;
        final session = PlayerSession.fromJson(save);
        expect(session.professionId, profession, reason: '$fight $profession');
        for (final MapEntry(key: die, value: faces)
            in session.diceSkillAssignments.entries) {
          expect(die, save['equippedDiceId'], reason: '$fight $profession');
          expect(faces, isNotEmpty, reason: '$fight $profession');
        }
        count++;
      }
    }
    expect(count, 25);
  });
}

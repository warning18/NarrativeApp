// The gates and adventure-node tables and the three always-0 enemy move
// thresholds are gone (v1.742). Data written before still loads: an old
// edit of a removed table is ignored, and an old enemies edit still carrying
// the removed move fields reads as before.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/gamedata/game_db_repository.dart';
import 'package:narrative_data_app/providers/github_push_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the removed tables are no longer offered', () {
    final ids = gameDbSchemas.map((s) => s.id).toSet();
    expect(ids, isNot(contains('gates')));
    expect(ids, isNot(contains('adventure_nodes')));
  });

  test('an old edit of a removed table is left alone', () async {
    SharedPreferences.setMockInitialValues({
      'gamedb_gates': '{"slums_gate": {"gateID": "slums_gate"}}',
      'gamedb_adventure_nodes': '{"n1": {"nodeID": "n1"}}',
    });
    final edits = await collectLocalDataEdits();
    expect(edits, isEmpty);
  });

  test('an old enemies edit with the removed move fields still loads',
      () async {
    SharedPreferences.setMockInitialValues({
      'gamedb_enemies': '{"old_foe": {"enemyName": "Old", "skillMoves": ['
          '{"skillID": "slash", "condition": "Always", "chance": 100, '
          '"healthThreshold": 0, "attackCountRequirement": 0, '
          '"playerPatternThreshold": 0, "blockThreshold": 0, '
          '"priority": 1}]}}',
    });
    final records = await GameDbRepository(enemiesSchema).loadRecords();
    final moves = records['old_foe']!['skillMoves'] as List;
    expect((moves.single as Map)['skillID'], 'slash');
  });
}

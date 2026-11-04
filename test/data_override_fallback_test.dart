// A broken edited copy of a table or of the story never empties it (issue
// #696): the failure is reported and the bundled file is read instead.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/gamedata/game_db_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<FlutterErrorDetails> reported;
  late FlutterExceptionHandler? previous;
  setUp(() {
    reported = [];
    previous = FlutterError.onError;
    FlutterError.onError = reported.add;
  });
  tearDown(() => FlutterError.onError = previous);

  test('a broken edited table is reported; the bundled one is read', () async {
    SharedPreferences.setMockInitialValues({'gamedb_enemies': '{broken'});
    final records = await GameDbRepository(enemiesSchema).loadRecords();
    expect(records, isNotEmpty);
    expect(records.containsKey('slum_thug'), isTrue);
    expect(reported, hasLength(1));
  });

  test('a broken edited story is reported; the bundled one is read', () async {
    SharedPreferences.setMockInitialValues({'story_nodes_override': '[1,'});
    final story = await StoryRepository().load();
    expect(story.nodeFor(StoryRepository.startNodeId), isNotNull);
    expect(reported, hasLength(1));
  });

  test('a good edited table is still read, with nothing reported', () async {
    SharedPreferences.setMockInitialValues(
        {'gamedb_enemies': '{"only_one": {"name": "Only"}}'});
    final records = await GameDbRepository(enemiesSchema).loadRecords();
    expect(records.keys, ['only_one']);
    expect(reported, isEmpty);
  });
}

// Save slots, ironman and safe loading: three slots with a summary each,
// the old single save carried into slot 1, a death under permadeath
// taking every save, and a session that cannot be read kept aside instead
// of being written over.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/save_game_provider.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 200));

PlayerSession _session({String name = 'Ada', int level = 4}) =>
    PlayerSession.fromJson({
      'characterName': name,
      'raceId': 'human',
      'professionId': 'warrior',
      'level': level,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('save slots', () {
    test('a save fills its slot with a summary; load and delete work',
        () async {
      SharedPreferences.setMockInitialValues({});
      final saves = SavedGamesNotifier();
      await _settle();
      expect(saves.state, everyElement(isNull));

      await saves.save(
          slot: 2,
          session: _session(),
          currentNodeId: '2015',
          history: const ['0', '100']);
      final summary = saves.state[1]!;
      expect(summary.characterName, 'Ada');
      expect(summary.level, 4);
      expect(summary.nodeId, '2015');
      expect(summary.savedAt, isNotNull);
      expect(saves.state[0], isNull);

      final loaded = await saves.load(2);
      expect(loaded!.session.characterName, 'Ada');
      expect(loaded.currentNodeId, '2015');
      expect(loaded.history, ['0', '100']);

      await saves.delete(2);
      expect(saves.state, everyElement(isNull));
      expect(await saves.load(2), isNull);
    });

    test('the single save of earlier versions becomes slot 1', () async {
      SharedPreferences.setMockInitialValues({
        'saved_game_session': json.encode(_session(name: 'Old').toJson()),
        'saved_game_story':
            json.encode({'currentNodeId': '891', 'history': <String>[]}),
      });
      final saves = SavedGamesNotifier();
      await _settle();
      expect(saves.state[0]!.characterName, 'Old');
      expect(saves.state[0]!.nodeId, '891');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('saved_game_session'), isFalse);
    });

    test('ironman: a death deletes every slot', () async {
      SharedPreferences.setMockInitialValues({});
      final saves = SavedGamesNotifier();
      await _settle();
      for (var slot = 1; slot <= saveSlotCount; slot++) {
        await saves.save(
            slot: slot,
            session: _session(),
            currentNodeId: '100',
            history: const []);
      }
      await saves.deleteAll();
      expect(saves.state, everyElement(isNull));
    });

    test('an unreadable slot shows as empty and is never deleted', () async {
      SharedPreferences.setMockInitialValues({'saved_game_slot_3': '{broken'});
      final saves = SavedGamesNotifier();
      await _settle();
      expect(saves.state[2], isNull);
      expect(await saves.load(3), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('saved_game_slot_3'), '{broken');
    });
  });

  group('safe loading', () {
    test('every save carries its format version', () {
      expect(_session().toJson()['saveVersion'], playerSessionSaveVersion);
    });

    test('a session that cannot be read is kept aside, not written over',
        () async {
      SharedPreferences.setMockInitialValues({'player_session': '{"level": '});
      final notifier = PlayerSessionNotifier();
      await _settle();
      expect(notifier.loadFailed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(unreadableSessionBackupPrefsKey), '{"level": ');
    });

    test('nothing is written before the save has been read', () async {
      SharedPreferences.setMockInitialValues({
        'player_session':
            json.encode(_session(name: 'Kept', level: 9).toJson()),
      });
      final notifier = PlayerSessionNotifier();
      // A change in the first moment after launch, on the placeholder.
      final early = notifier.setCharacterName('Placeholder');
      await _settle();
      await early;
      final prefs = await SharedPreferences.getInstance();
      final stored = json.decode(prefs.getString('player_session')!)
          as Map<String, dynamic>;
      expect(stored['level'], 9);
      expect(notifier.state.level, 9);
    });
  });
}

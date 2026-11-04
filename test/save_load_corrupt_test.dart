// A save that can't be read never strands the player (issue #693): a
// corrupt autosave keeps the scene it names, a corrupt old two-key save
// doesn't stop the slots from reading, and corrupt new-game defaults fall
// back to the shipped ones (for a fresh session and for a new character).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/save_game_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 200));

String _slot(String name) => json.encode({
      'session': PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'characterName': name
      }).toJson(),
      'currentNodeId': '2015',
      'history': ['0', '100'],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a corrupt autosave', () {
    test('keeps the scene it names when its history is unreadable', () async {
      SharedPreferences.setMockInitialValues({
        'autosave_story_node': '300',
        'autosave_story_history': '{broken',
        'autosave_story_visited': '["0","300"]',
      });
      final story = StoryPlayNotifier('0');
      await _settle();
      expect(story.state.currentNodeId, '300');
      expect(story.state.history, isEmpty);
      expect(story.state.visitedNodeIds, containsAll(['0', '300']));
    });

    test('rebuilds what it has read when its visited set is unreadable',
        () async {
      SharedPreferences.setMockInitialValues({
        'autosave_story_node': '300',
        'autosave_story_history': '["0","100","250"]',
        'autosave_story_visited': 'not json',
      });
      final story = StoryPlayNotifier('0');
      await _settle();
      expect(story.state.currentNodeId, '300');
      expect(story.state.history, ['0', '100', '250']);
      expect(story.state.visitedNodeIds, {'0', '100', '250', '300'});
    });
  });

  test('a corrupt old two-key save is kept, and the slots still read',
      () async {
    SharedPreferences.setMockInitialValues({
      'saved_game_session': '{"level": 3}',
      'saved_game_story': '{broken',
      'saved_game_slot_2': _slot('Bea'),
    });
    final saves = SavedGamesNotifier();
    await _settle();
    expect(saves.state[1]?.characterName, 'Bea');
    final prefs = await SharedPreferences.getInstance();
    // Never deleted: a later version may still read it.
    expect(prefs.getString('saved_game_story'), '{broken');
    expect(prefs.getString('saved_game_session'), '{"level": 3}');
  });

  group('corrupt new-game defaults (the editor\'s game config)', () {
    test('a fresh session falls back to the shipped defaults', () async {
      SharedPreferences.setMockInitialValues({'gamedb_game_config': '{bro'});
      final notifier = PlayerSessionNotifier();
      await _settle();
      expect(notifier.isLoaded, isTrue);
      expect(notifier.state.gold, 100);
      expect(notifier.state.potionCount, 3);
    });

    test('a new character is still made, from the shipped defaults', () async {
      SharedPreferences.setMockInitialValues({'gamedb_game_config': '{bro'});
      final notifier = PlayerSessionNotifier();
      await _settle();
      await notifier.startNewGame(
          raceId: 'human',
          race: const {},
          professionId: 'warrior',
          profession: const {});
      expect(notifier.state.professionId, 'warrior');
      expect(notifier.state.gold, 100);
    });
  });
}

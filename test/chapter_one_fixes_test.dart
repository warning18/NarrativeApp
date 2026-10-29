// The chapter 1 review's fixes (docs/qa/chapter1-core.md, v1.608): Vica
// joins on the path a save walked (R1), the rat matriarch is a chapter 1
// foe (R6), and the forced boarding prices take a wound for the gold a
// poor purse lacks (#583).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/story_companions.dart';
import 'package:narrative_data_app/data/story_prices.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('R1: Vica joins on the path a save walked, not on its fog of war', () {
    final companions = _json('assets/gamedata/companions.json');
    // A save from before her scene, loaded after a run that went past it:
    // the run's visited set still holds 1150_vica and 1200.
    final path = walkedScenes(const ['0', '100', '891'], '960_lift');
    expect(path, isNot(contains('1200')));
    expect(storyRecruitsDue(companions, visited: path, recruited: const []),
        isEmpty);
    expect(
        storyRecruitsDue(companions,
            visited: walkedScenes(const ['1140'], '1150_vica'),
            recruited: const []),
        ['vica']);
  });

  test('R6: the rat matriarch, a chapter 1 fight, is a chapter 1 foe', () {
    final enemies = _json('assets/gamedata/enemies.json');
    expect((enemies['rat_matriarch'] as Map)['minChapter'], 1);
  });

  group('#583: a forced price a poor purse cannot make', () {
    test('the gold missing is taken as a wound', () {
      expect(shortfallWound(gold: 10, goldMod: -40), -30);
      expect(shortfallWound(gold: 40, goldMod: -40), 0);
      expect(shortfallWound(gold: 100, goldMod: -25), 0);
      expect(shortfallWound(gold: 0, goldMod: 10), 0);
    });

    test('both boarding prices are forced prices', () {
      final raw = _json(StoryRepository.assetPath);
      for (final id in ['896_failed', '897_failed']) {
        final node = StoryNode.fromJson(id, raw[id] as Map<String, dynamic>);
        expect(node.choices, hasLength(1), reason: id);
        expect(node.choices.single.shortfallWounds, isTrue, reason: id);
        expect(node.choices.single.pays, isFalse,
            reason: '$id is the only way on: it never shuts');
        expect(node.choices.single.goldMod, lessThan(0), reason: id);
      }
    });

    test(
        'the session pays what the purse holds and bleeds the rest, never '
        'the last point', () async {
      SharedPreferences.setMockInitialValues({});
      final n = PlayerSessionNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await n.loadSession(PlayerSession.fromJson(
          {'gold': 10, 'maxHealth': 30, 'currentHealth': 30}));
      await n.applyChoiceEffects(goldMod: -40, shortfallWounds: true);
      expect(n.state.gold, 0);
      expect(n.state.currentHealth, 1, reason: "30 missing on 30 health");
      await n.loadSession(PlayerSession.fromJson(
          {'gold': 30, 'maxHealth': 30, 'currentHealth': 30}));
      await n.applyChoiceEffects(goldMod: -25, shortfallWounds: true);
      expect(n.state.gold, 5);
      expect(n.state.currentHealth, 30);
      await n.loadSession(PlayerSession.fromJson(
          {'gold': 20, 'maxHealth': 30, 'currentHealth': 30}));
      await n.applyChoiceEffects(goldMod: -25, shortfallWounds: true);
      expect(n.state.gold, 0);
      expect(n.state.currentHealth, 25);
      // Without the flag a short purse just empties (the old soft price).
      await n.loadSession(PlayerSession.fromJson(
          {'gold': 20, 'maxHealth': 30, 'currentHealth': 30}));
      await n.applyChoiceEffects(goldMod: -25);
      expect(n.state.currentHealth, 30);
    });
  });
}

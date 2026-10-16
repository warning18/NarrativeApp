// The feature ladder (feature_unlocks.dart, docs/proposals/feature-ladder.md):
// a new game brings the features one by one; a save from before the
// ladder has them all; a past chapter opens its own; the trainer teaches a
// strike or a guard; the clans' offers wait for Saltmouth.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart' show ClanData;
import 'package:narrative_data_app/data/feature_unlocks.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

LadderState _at(List<String> flags, {int level = 1, int chapter = 1}) =>
    (flags: [featureLadderFlag, ...flags], level: level, chapter: chapter);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('off the ladder, everything is open and nothing is new', () {
    const old = (flags: <String>[], level: 1, chapter: 0);
    expect(unlockedFeatures(old), GameFeature.values);
    expect(newlyUnlockedFeatures(old, const []), isEmpty);
  });

  test('on the ladder, each feature waits for its flag or its deed', () {
    expect(unlockedFeatures(_at(const [])), isEmpty);
    expect(
        featureUnlocked(GameFeature.levelUp, _at(const [], level: 2)), isTrue);
    for (final f in GameFeature.values) {
      if (f.flag.isEmpty) continue;
      expect(featureUnlocked(f, _at([f.flag])), isTrue, reason: f.id);
    }
    // Every flag is its own.
    final flags = [
      for (final f in GameFeature.values)
        if (f.flag.isNotEmpty) f.flag
    ];
    expect(flags.toSet(), hasLength(flags.length));
  });

  test('a story past a feature\'s chapter opens it', () {
    final two = unlockedFeatures(_at(const [], chapter: 2));
    expect(two, containsAll([GameFeature.quests, GameFeature.skills]));
    expect(two, isNot(contains(GameFeature.clans)));
    expect(unlockedFeatures(_at(const [], chapter: 3)), GameFeature.values);
  });

  test('a won fight: the chest, then the place rules; the lesson nothing', () {
    expect(ladderFlagsForWin([featureLadderFlag], tutorial: true), isEmpty);
    expect(ladderFlagsForWin([featureLadderFlag], tutorial: false),
        ['feat_chest']);
    expect(
        ladderFlagsForWin([featureLadderFlag, 'feat_chest'], tutorial: false),
        ['feat_place_rules']);
    expect(ladderFlagsForWin(const [], tutorial: false), isEmpty);
  });

  test('what is new, and told of once', () {
    final state = _at(const ['feat_quests', 'feat_inventory']);
    expect(newlyUnlockedFeatures(state, const []),
        [GameFeature.quests, GameFeature.inventory]);
    expect(newlyUnlockedFeatures(state, const ['quests']),
        [GameFeature.inventory]);
  });

  test('the trainer teaches a strike or a guard of the character\'s trees', () {
    final trees = _table('skill_trees');
    final skills = _table('skills');
    for (final profession in ['warrior', 'mage', 'rogue', 'cleric', 'ranger']) {
      final strike = trainerSkillFor(
          professionId: profession,
          strike: true,
          trees: trees,
          skills: skills)!;
      final guard = trainerSkillFor(
          professionId: profession,
          strike: false,
          trees: trees,
          skills: skills)!;
      expect((skills[strike] as Map)['damageMod'], greaterThan(0),
          reason: profession);
      expect(strike, isNot(guard), reason: profession);
      // A skill known is not taught twice.
      expect(
          trainerSkillFor(
              professionId: profession,
              strike: true,
              trees: trees,
              skills: skills,
              known: [strike]),
          isNot(strike),
          reason: profession);
    }
    expect(
        trainerSkillFor(
            professionId: 'warrior',
            strike: true,
            trees: trees,
            skills: skills),
        'warrior_shield_bash');
  });

  group('the session', () {
    late PlayerSessionNotifier notifier;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      notifier = PlayerSessionNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });

    test('the clans\' offers wait on the ladder', () async {
      await notifier.loadSession(baseSession().copyWith(
        flags: const [featureLadderFlag],
        level: 2,
        pendingOffers: const [OfferTicket(source: OfferSource.level)],
      ));
      expect(notifier.state.featureOpen(GameFeature.clans), isFalse);
      // The offer is not drawn: ensureOffer returns before any table.
      expect(
          await notifier.ensureOffer(const OfferTables(data: ClanData.empty)),
          isNull);
      expect(notifier.state.pendingOffers, hasLength(1));
    });

    test('a won fight, the trainer, a card acknowledged', () async {
      await notifier.loadSession(
          baseSession().copyWith(flags: const [featureLadderFlag]));
      await notifier.noteFightWonOnLadder(tutorial: true);
      expect(notifier.state.featureOpen(GameFeature.chest), isFalse);
      await notifier.noteFightWonOnLadder(tutorial: false);
      expect(notifier.state.featureOpen(GameFeature.chest), isTrue);
      final learned = await notifier.learnTrainerSkill(
          strike: false,
          trees: _table('skill_trees'),
          skills: _table('skills'));
      expect(notifier.state.unlockedSkillIds, contains(learned));
      await notifier.acknowledgeFeature('chest');
      await notifier.acknowledgeFeature('chest');
      expect(notifier.state.acknowledgedFeatures, ['chest']);
      // Saved and read back.
      final back = PlayerSession.fromJson(
          jsonDecode(jsonEncode(notifier.state.toJson())));
      expect(back.acknowledgedFeatures, ['chest']);
      expect(back.featureOpen(GameFeature.chest), isTrue);
    });

    test('a save from before the ladder has everything open', () {
      final old = PlayerSession.fromJson({'raceId': 'human'});
      expect(GameFeature.values.every(old.featureOpen), isTrue);
    });
  });
}

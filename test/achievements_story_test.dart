// The story's achievements: each is a plain function of what a save already
// holds (flags, banner pieces, politics, the New Game+ cycle), so a save
// that has the thing unlocks it the next time achievements are checked.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession, notifierWith;

Future<List<String>> newlyFor(PlayerSession session) async =>
    (await notifierWith(session)).checkAchievements();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final achievements =
      jsonDecode(File('assets/gamedata/achievements.json').readAsStringSync())
          as Map<String, dynamic>;
  final intrigues =
      jsonDecode(File('assets/gamedata/intrigues.json').readAsStringSync())
          as Map<String, dynamic>;

  PlayerSession withFlags(List<String> flags) =>
      baseSession().copyWith(flags: flags);

  test('every achievement is written in both languages', () {
    for (final entry in achievements.entries) {
      final row = entry.value as Map<String, dynamic>;
      expect(row['achievementID'], entry.key);
      for (final field in [
        'achievementName',
        'description',
        'achievementName_fr',
        'description_fr',
      ]) {
        expect(row[field]?.toString() ?? '', isNotEmpty,
            reason: '${entry.key} $field');
      }
    }
  });

  test('the intrigue count matches intrigues.json', () {
    expect(intrigues.length, intrigueCount);
  });

  test('the throne, the banner and New Game+ unlock from the save', () async {
    expect(await newlyFor(withFlags(['on_throne'])), contains('on_the_throne'));
    expect(
        await newlyFor(withFlags(['banner_whole'])), contains('whole_cloth'));
    expect(await newlyFor(baseSession(bannerPiecesCollected: ['a', 'b'])),
        isNot(contains('half_a_banner')));
    expect(await newlyFor(baseSession(bannerPiecesCollected: ['a', 'b', 'c'])),
        contains('half_a_banner'));
    expect(await newlyFor(baseSession().copyWith(newGamePlusCycle: 1)),
        contains('time_turned'));
    expect(await newlyFor(baseSession()), isNot(contains('time_turned')));
  });

  test('a settled intrigue is a thread; eight make the web', () async {
    final ids = intrigues.keys.toList();
    expect(await newlyFor(withFlags(['intrigue_${ids[0]}_stage_2'])),
        isNot(contains('first_thread')));
    final one = await newlyFor(withFlags(['intrigue_${ids[0]}_outcome_1']));
    expect(one, contains('first_thread'));
    expect(one, isNot(contains('whole_web')));
    final seven = [for (final id in ids.skip(1)) 'intrigue_${id}_outcome_0'];
    expect(await newlyFor(withFlags(seven)), isNot(contains('whole_web')));
    final all = [for (final id in ids) 'intrigue_${id}_outcome_0'];
    expect(await newlyFor(withFlags(all)), contains('whole_web'));
  });

  test('clan standing unlocks sworn, hunted and trusted by four', () async {
    PlayerSession withStandings(Map<String, double> standings,
            {String sworn = ''}) =>
        baseSession().copyWith(
            politics:
                PoliticsState(standings: standings, swornFactionId: sworn));
    expect(await newlyFor(withStandings({'vigil': 70}, sworn: 'vigil')),
        contains('sworn_to_a_clan'));
    expect(await newlyFor(withStandings({'vigil': 70})),
        isNot(contains('sworn_to_a_clan')));
    expect(await newlyFor(withStandings({'crows': -80})),
        contains('hunted_by_a_clan'));
    expect(await newlyFor(withStandings({'crows': -30})),
        isNot(contains('hunted_by_a_clan')));
    Map<String, double> trustedBy(int n) =>
        {for (final id in coastClanIds.take(n)) id: 80.0};
    expect(await newlyFor(withStandings(trustedBy(4))),
        contains('friend_of_four_clans'));
    expect(await newlyFor(withStandings(trustedBy(6))),
        contains('friend_of_four_clans'));
    expect(await newlyFor(withStandings(trustedBy(3))),
        isNot(contains('friend_of_four_clans')));
    // "Without swearing to any": an oath sworn takes the achievement away.
    expect(await newlyFor(withStandings(trustedBy(4), sworn: 'dominion')),
        isNot(contains('friend_of_four_clans')));
    // A friend (19 to 25) is not yet Trusted (26 and up).
    expect(
        await newlyFor(withStandings({
          ...trustedBy(3),
          coastClanIds[3]: 20.0,
        })),
        isNot(contains('friend_of_four_clans')));
  });

  test('a story choice that only adds a flag unlocks it at once', () async {
    final notifier = await notifierWith(baseSession());
    expect(notifier.state.unlockedAchievementIds, isEmpty);
    await notifier.applyChoiceEffects(flagsToAdd: const ['on_throne']);
    expect(notifier.state.unlockedAchievementIds, contains('on_the_throne'));
    await notifier.applyChoiceEffects(
        flagsToAdd: const ['intrigue_hooded_lantern_outcome_0']);
    expect(notifier.state.unlockedAchievementIds, contains('first_thread'));
    await notifier.applyChoiceEffects(
        bannerPieceId: 'a', flagsToAdd: const ['banner_whole']);
    expect(notifier.state.unlockedAchievementIds, contains('whole_cloth'));
  });

  test('a tribe at Hunted is not a clan hunting you', () async {
    final tribe = baseSession()
        .copyWith(politics: const PoliticsState(standings: {'giants': -80.0}));
    expect(await newlyFor(tribe), isNot(contains('hunted_by_a_clan')));
  });

  test('finding a village unlocks its achievement', () async {
    expect(
        await newlyFor(withFlags(['found_3200'])), contains('akagiri_found'));
    expect(await newlyFor(withFlags(['found_5200'])),
        contains('kindly_hill_found'));
    expect(await newlyFor(withFlags(['found_6200'])),
        contains('highhearth_found'));
    expect(await newlyFor(withFlags(['found_6200'])),
        isNot(contains('akagiri_found')));
  });
}

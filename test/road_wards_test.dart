// Warding the road (road_wards.dart, docs/proposals/wave16-core.md §2): the
// Warding Cairn's Banish wards a hunting clan (a sworn clan's rival at
// Hostile or Hunted, or the nemesis) for 3 / 6 / 9 roads at rest for 1 / 2 /
// 3 charges; its hunter roll is skipped meanwhile, nothing else is; the ward
// counts down on roads at rest, ends with a news line, and is saved as a
// RollBan `on: road`.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_rolls.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/rival_hunters.dart';
import 'package:narrative_data_app/data/road_wards.dart';
import 'package:narrative_data_app/data/sim_rolls.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enemies = _table('enemies');
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  PoliticsState at(Map<String, num> standings, [PoliticsState? from]) {
    var state = from ?? PoliticsState.empty;
    for (final e in standings.entries) {
      state = setStandingValue(state, e.key, e.value, 'edit', data: data).state;
    }
    return state;
  }

  // The Compact, the nemesis: it hunts sworn or not.
  final hunted = updateNemesis(at({'compact': -40}), data, chapter: 3);

  Future<PlayerSessionNotifier> notifierWith(
      {List<String> built = const ['warding_cairn'],
      int charges = 3,
      PoliticsState? politics}) async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.loadSession(PlayerSession.fromJson({
      ...baseSession(builtHouseIds: built).toJson(),
      'banishCharges': charges,
    }).copyWith(politics: politics ?? hunted));
    return notifier;
  }

  group('the targets', () {
    test('the clans hunting you: a rival Hostile or Hunted, the nemesis', () {
      expect(wardTargets(PoliticsState.empty, data), isEmpty);
      // Not sworn, a clan merely disliked: nobody.
      expect(wardTargets(at({'vigil': -40}), data), isEmpty);
      expect(hunted.nemesis, 'compact');
      expect(wardTargets(hunted, data), ['compact']);
      // Sworn, a rival at Hostile hunts too.
      final sworn = at({'dominion': 70});
      final rival = rivalsOf('dominion', sworn, data).first;
      final state = at({rival: -40}, sworn);
      expect(wardTargets(state, data), contains(rival));
      // A friend is never one.
      expect(wardTargets(state, data), isNot(contains('dominion')));
    });
  });

  group('the price', () {
    test('1 / 2 / 3 charges for 3 / 6 / 9 roads', () {
      expect(wardLengths, [3, 6, 9]);
      expect([for (final r in wardLengths) wardCostOf(r)], [1, 2, 3]);
      expect(wardCostOf(4), 0);
      expect(
          [for (final o in wardOptions(2)) o.affordable], [true, true, false]);
      expect(wardOptions(0).any((o) => o.affordable), isFalse);
    });
  });

  group('the hunt skipped', () {
    test('a warded clan has no roll; the others keep theirs', () {
      expect(rivalHunts(hunted, data, warded: {'compact'}), isEmpty);
      expect(rivalHunterChance(hunted, data, warded: {'compact'}), 0);
      for (var i = 0; i < 400; i++) {
        expect(
            maybeRivalHunter(
                politics: hunted,
                data: data,
                enemies: enemies,
                chapter: 3,
                random: Random(i),
                warded: {'compact'}),
            isNull);
      }
      // Two clans hunting, one warded: only the other's hunters come.
      final sworn = at({'dominion': 70});
      final rival =
          rivalsOf('dominion', sworn, data).firstWhere((r) => r != 'compact');
      final both = updateNemesis(at({rival: -80, 'compact': -80}, sworn), data,
          chapter: 3);
      expect(rivalHunts(both, data).keys, containsAll([rival]));
      final ward = both.nemesis.isNotEmpty ? both.nemesis : rival;
      final other = rivalHunts(both, data, warded: {ward});
      expect(other.keys, isNot(contains(ward)));
      expect(other, isNotEmpty);
      final roads = [
        for (var i = 0; i < 400; i++)
          maybeRivalHunter(
              politics: both,
              data: data,
              enemies: enemies,
              chapter: 4,
              random: Random(i),
              warded: {ward}),
      ].whereType<List<StoryNode>>();
      expect(roads, isNotEmpty);
      for (final road in roads) {
        final id = road.single.choices.single.triggerEnemyId!;
        expect((enemies[id] as Map)['hunterClan'], isNot(ward));
      }
    });

    test('only the hunters: a ward is no ban on the draws, nor peace',
        () async {
      final bans = withWard(const [], 'compact', 6);
      expect(bannedIdsOf(bans, RollBanOn.pick), isEmpty);
      expect(bannedIdsOf(bans, RollBanOn.offer), isEmpty);
      // The draws' countdowns leave it be.
      final drawn = afterFreshDraw(
          on: RollBanOn.offer,
          bans: bans,
          raiseBuilt: false,
          raise: 0,
          raiseProgress: 0);
      expect(drawn.bans, bans);
      // Standing does not move.
      final n = await notifierWith();
      final before = n.state.politics.standingOf('compact', data);
      expect(await n.wardRoad('compact', 6, data), isTrue);
      expect(n.state.politics.standingOf('compact', data), before);
      expect(n.state.politics.nemesis, 'compact');
    });
  });

  group('the ward set', () {
    test(
        'spends its charges; refused without the cairn, the charges, a '
        'length or a hunter', () async {
      final n = await notifierWith();
      expect(await n.wardRoad('compact', 4, data), isFalse);
      // Not hunting.
      expect(await n.wardRoad('vigil', 3, data), isFalse);
      expect(n.state.banishCharges, 3);
      expect(await n.wardRoad('compact', 6, data), isTrue);
      expect(n.state.banishCharges, 1);
      expect(
          roadWardsOf(n.state.rollBans), [(clanId: 'compact', roadsLeft: 6)]);
      // One charge left: 6 roads cost 2.
      expect(await n.wardRoad('compact', 6, data), isFalse);
      // Set again for less: the longer kept.
      expect(await n.wardRoad('compact', 3, data), isTrue);
      expect(n.state.banishCharges, 0);
      expect(wardedClansOf(n.state.rollBans), {'compact'});
      expect(roadWardsOf(n.state.rollBans).single.roadsLeft, 6);

      final bare = await notifierWith(built: const []);
      expect(await bare.wardRoad('compact', 3, data), isFalse);
    });

    test('counts down on roads at rest and ends with the news', () async {
      final n = await notifierWith();
      await n.wardRoad('compact', 3, data);
      final news = n.state.politics.news.length;
      expect(await n.tickRoadWards(data: data, chapter: 3), isEmpty);
      expect(await n.tickRoadWards(data: data, chapter: 3), isEmpty);
      expect(roadWardsOf(n.state.rollBans).single.roadsLeft, 1);
      expect(await n.tickRoadWards(data: data, chapter: 3), ['compact']);
      expect(n.state.rollBans, isEmpty);
      final ended = n.state.politics.news.last;
      expect(n.state.politics.news.length, news + 1);
      expect(ended.eventId, 'ward_end:compact');
      expect(
          ended.text,
          'The ward on the Cinder Compact’s hunters has worn '
          'off.');
      expect(ended.textFr,
          'La garde contre la chasse du Pacte des Cendres s’est dissipée.');
      expect(ended.read, isFalse);
      // Nothing warded: nothing to count.
      expect(await n.tickRoadWards(data: data), isEmpty);
    });

    test('the pure countdown leaves the draws\' bans alone', () {
      var bans = [
        const RollBan(on: RollBanOn.pick, id: 'p', left: 2),
        ...withWard(const [], 'vigil', 3),
      ];
      final ended = <String>[];
      for (var i = 0; i < 3; i++) {
        final next = afterRoadAtRest(bans);
        bans = next.bans;
        ended.addAll(next.ended);
      }
      expect(ended, ['vigil']);
      expect(bans, [const RollBan(on: RollBanOn.pick, id: 'p', left: 2)]);
    });
  });

  group('the save', () {
    test('a ward round-trips; an old save loads with none', () async {
      final n = await notifierWith();
      await n.wardRoad('compact', 9, data);
      final back = PlayerSession.fromJson(
          jsonDecode(jsonEncode(n.state.toJson())) as Map<String, dynamic>);
      expect(back.rollBans, n.state.rollBans);
      expect(back.rollBans.single.toJson(),
          {'on': 'road', 'id': 'compact', 'left': 9});
      // Before wards: only draws' bans, or none at all.
      final old = PlayerSession.fromJson({
        ...baseSession().toJson(),
        'rollBans': [
          {'on': 'pick', 'id': 'p', 'left': 3},
        ],
      });
      expect(roadWardsOf(old.rollBans), isEmpty);
      expect(
          roadWardsOf(PlayerSession.fromJson(baseSession().toJson()).rollBans),
          isEmpty);
    });
  });

  group('the lines', () {
    test('Narrative\'s, the clan named in each language', () {
      expect(
          wardSetLine('compact', AppLanguage.en, data: data, nemesis: 'vigil'),
          'The cairn hides your trail from the Cinder Compact.');
      expect(
          wardSetLine('compact', AppLanguage.fr,
              data: data, nemesis: 'compact'),
          'Le cairn cache votre piste aux chasseurs du Pacte des Cendres ; '
          'son champion, lui, vous trouvera.');
      expect(
          wardSetLine('crows', AppLanguage.en, data: data, nemesis: 'crows'),
          'The cairn hides your trail from the Salt Crows’ ordinary hunters; '
          'its champion still comes.');
      // A plural's possessive.
      expect(
          wardLine('ward_ended', AppLanguage.en, clanId: 'crows', data: data),
          'The ward on the Salt Crows’ hunters has worn off.');
      expect(
          wardLine('ward_mark', AppLanguage.fr,
              clanId: 'dominion', data: data, n: 4),
          'Protection contre la chasse du Dominion de la Lanterne : 4 routes');
      expect(wardLine('ward_length', AppLanguage.en, roads: 6, cost: 2),
          '6 roads · 2 charges');
    });
  });

  group('the simulator', () {
    test('wards the nemesis with 2 charges or more, while it hunts', () {
      final rolls = SimRolls(Random(1))..build(RollPower.banish);
      expect(rolls.banish, 3);
      // Not hunting: no ward.
      rolls.wardNemesis('compact', const []);
      expect(rolls.warded, isEmpty);
      rolls.wardNemesis('compact', const ['compact']);
      expect(rolls.warded, {'compact'});
      expect(rolls.banish, 3 - wardCostOf(simWardRoads));
      expect(rolls.used['wards'], 1);
      for (var i = 0; i < simWardRoads; i++) {
        rolls.roadAtRest();
      }
      expect(rolls.warded, isEmpty);
      // One charge left: none.
      rolls.wardNemesis('compact', const ['compact']);
      expect(rolls.warded, isEmpty);
    });
  });
}

// Clans (v1.193) in the session: standing, marks and relations change
// through the notifier, dated by chapter and day; they survive the save
// file (an old save starts where every faction starts); and a permadeath,
// a New Game+ and a new game start the world over, while the signs'
// favour stays. Shops of a faction price by the tier.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/shop_pricing.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final ClanData _data = ClanData.fromTables(
  factions: _json('factions'),
  subclans: _json('subclans'),
  relations: _json('relations'),
  titles: _json('titles'),
  intrigues: _json('intrigues'),
);

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the notifier changes standing, marks and relations, dated', () async {
    final notifier =
        await _notifierWith(baseSession().copyWith(day: 14, clockChapter: 3));
    final result = await notifier.changeStanding('penitents', 6,
        data: _data, cause: 'offer', chapter: 4);
    // The Penitents' ally, the Vigil, a quarter; their rivals half.
    expect(result.deltas['penitents'], 6);
    expect(result.deltas['vigil'], 1.5);
    expect(result.deltas['dominion'], -3);
    expect(result.deltas['mire'], -3);
    expect(result.deltas['compact'], -3);
    expect(result.deltas.containsKey('crows'), isFalse, reason: 'indifferent');
    var politics = notifier.state.politics;
    expect(politics.standingOf('dominion', _data), -13, reason: 'from -10');
    final entry = politics.standingLog.single;
    expect([entry.chapter, entry.day, entry.cause], [4, 14, 'offer']);

    expect(
        await notifier.setSubclanMark('inquisition', SubclanMark.foe,
            data: _data, cause: 'intrigue'),
        isTrue);
    politics = notifier.state.politics;
    expect(politics.markOf('inquisition'), SubclanMark.foe);
    expect(politics.standingLog.last.chapter, 3, reason: 'the clock\'s');

    expect(
        await notifier.shiftRelation('dominion', 'vigil', -1,
            data: _data, cause: 'intrigue', chapter: 5),
        isTrue);
    politics = notifier.state.politics;
    expect(politics.relationStep('vigil', 'dominion', _data), 2);
    expect(politics.relationSnapshots.keys, [5]);

    await notifier.setStandingForEdit('crows', 70, data: _data);
    politics = notifier.state.politics;
    expect(politics.swornFactionId, 'crows');
    expect(politics.standingLog.last.cause, 'edit');

    await notifier.resetPolitics();
    expect(notifier.state.politics.isEmpty, isTrue);
  });

  test('the save keeps it all; an old save starts where they start', () {
    var politics = applyStandingChange(
            PoliticsState.empty, 'vigil', 30, 'quest',
            data: _data, chapter: 2, day: 9)
        .state;
    politics = setSubclanMark(
            politics, 'stitchers', SubclanMark.friend, 'favour',
            data: _data)
        .state;
    politics =
        shiftRelation(politics, 'compact', 'mire', 1, 'story', data: _data)
            .state;
    final session = baseSession().copyWith(politics: politics);
    final back =
        PlayerSession.fromJson(jsonDecode(jsonEncode(session.toJson())));
    expect(back.politics.standings, politics.standings);
    expect(back.politics.markOf('stitchers'), SubclanMark.friend);
    expect(back.politics.relationStep('mire', 'compact', _data), 7);
    expect(back.politics.standingLog, hasLength(2));
    expect(back.politics.relationsLog, hasLength(1));

    final old = session.toJson()..remove('politics');
    final fromOld = PlayerSession.fromJson(old);
    expect(fromOld.politics.isEmpty, isTrue);
    expect(fromOld.politics.standingOf('dominion', _data), -10);
    expect(fromOld.politics.standingOf('vigil', _data), 0);
    expect(fromOld.politics.tierOf('dominion', _data), StandingTier.wary);
  });

  group('the world starts over', () {
    Future<PlayerSessionNotifier> involved() async {
      final notifier = await _notifierWith(baseSession(level: 5).copyWith(
        patronFavour: const {'vigil': 4},
        patronsMet: const ['vigil'],
      ));
      await notifier.changeStanding('vigil', 40, data: _data, cause: 'quest');
      await notifier.setSubclanMark('stitchers', SubclanMark.foe,
          data: _data, cause: 'intrigue');
      await notifier.shiftRelation('vigil', 'crows', 2,
          data: _data, cause: 'story');
      expect(notifier.state.politics.isEmpty, isFalse);
      return notifier;
    }

    test('a permadeath resets the politics; the favour stays', () async {
      final notifier = await involved();
      await notifier.applyPermadeath(race: const {}, profession: const {});
      expect(notifier.state.politics.isEmpty, isTrue);
      expect(notifier.state.patronFavour, {'vigil': 4});
      expect(notifier.state.level, 5);
    });

    test('New Game+ and a new character start the world over', () async {
      final notifier = await involved();
      await notifier.beginNewGamePlus();
      await notifier.resetSession();
      expect(notifier.state.politics.isEmpty, isTrue);
      expect(notifier.state.patronFavour, {'vigil': 4});
      await notifier.changeStanding('vigil', 10, data: _data, cause: 'quest');
      await notifier.startNewGame(
        raceId: 'human',
        race: const {},
        professionId: 'warrior',
        profession: const {},
      );
      expect(notifier.state.politics.isEmpty, isTrue);
      expect(notifier.state.patronsMet, ['vigil']);
    });
  });

  group('prices by tier', () {
    test('Hostile +40% ... Sworn -25%, Hunted no trade', () {
      expect(factionPriceFor(100, null), 100);
      expect(factionPriceFor(100, StandingTier.hostile), 140);
      expect(factionPriceFor(100, StandingTier.wary), 115);
      expect(factionPriceFor(100, StandingTier.unknown), 100);
      expect(factionPriceFor(100, StandingTier.known), 95);
      expect(factionPriceFor(100, StandingTier.trusted), 85);
      expect(factionPriceFor(100, StandingTier.sworn), 75);
      expect(factionPriceFor(1, StandingTier.sworn), 1, reason: 'never 0');
      expect(factionPriceFor(0, StandingTier.hostile), 0);
      expect(factionPriceFor(100, StandingTier.hunted), isNull);
      expect(shopRefusesTrade(StandingTier.hunted), isTrue);
      expect(shopRefusesTrade(StandingTier.hostile), isFalse);
      expect(shopRefusesTrade(null), isFalse);
    });

    test('the shipped shops name real factions', () {
      final shops = _json('shops');
      final owned = {
        for (final e in shops.entries)
          if (shopFactionId(e.value as Map<String, dynamic>).isNotEmpty)
            e.key: shopFactionId(e.value as Map<String, dynamic>),
      };
      expect(owned['smugglers_vault'], 'crows');
      expect(owned.length, greaterThanOrEqualTo(6));
      for (final faction in owned.values) {
        expect(_data.factions, contains(faction));
      }
      expect(shopFactionId(shops['blind_beggar_stall']), '');
    });
  });
}

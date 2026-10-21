// The temple (docs/proposals/temple-service.md, temple.dart): Mending and
// the blessing, priced by the standing with the ruling clan, refused when
// Hunted; the save fields; the town pin opening it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/temple.dart';
import 'package:narrative_data_app/data/town_rulers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final ClanData _data = ClanData.fromTables(
  factions: _table('factions'),
  relations: _table('relations'),
);

Future<PlayerSessionNotifier> _notifier(Map<String, dynamic> json) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(
      {'raceId': 'human', 'professionId': 'warrior', ...json}));
  return notifier;
}

PoliticsState _at(String clan, num standing) =>
    setStandingValue(PoliticsState.storyStart, clan, standing, 'test',
            data: _data)
        .state;

TempleOffer _offer(String clan,
        {num standing = 0,
        int chapter = 4,
        int gold = 1000,
        int day = 3,
        int mendDay = 0,
        int blessingFights = 0,
        int alignment = 0,
        Map<String, int> standingChapters = const {},
        bool busy = false}) =>
    templeOfferFor(
      clanId: clan,
      data: _data,
      politics: clan.isEmpty ? PoliticsState.storyStart : _at(clan, standing),
      chapter: chapter,
      day: day,
      gold: gold,
      alignment: alignment,
      templeMendDay: mendDay,
      blessingFights: blessingFights,
      standingChapters: standingChapters,
      busy: busy,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prices', () {
    test('base prices by chapter', () {
      expect([2, 4, 6, 8].map(templeMendPrice), [40, 80, 120, 160]);
      expect([1, 2, 4, 6, 8].map(templeBlessingPrice), [60, 90, 150, 210, 270]);
    });

    test('follow the standing tier with the ruling clan, like its shops', () {
      expect(_offer('vigil').mendPrice, 80);
      expect(_offer('vigil').blessingPrice, 150);
      // Hostile x1.40, Sworn x0.75.
      expect(_offer('vigil', standing: -40).mendPrice, 112);
      expect(_offer('vigil', standing: -40).blessingPrice, 210);
      expect(_offer('vigil', standing: -40).refused, isFalse);
      final sworn = _offer('vigil', standing: 100);
      expect(sworn.tier, StandingTier.sworn);
      expect(sworn.mendPrice, 60);
      expect(sworn.blessingPrice, 113);
      // A neutral temple charges the list price.
      expect(_offer('').mendPrice, 80);
      expect(_offer('').tier, isNull);
    });

    test('a Hunted character is refused both services', () {
      final o = _offer('vigil', standing: -80);
      expect(o.refused, isTrue);
      expect(o.canMend, isFalse);
      expect(o.canBless, isFalse);
      expect(o.blessingBlock, TempleBlock.hunted);
      expect(o.blessingStanding, isFalse);
    });

    test('blocked when busy, too poor, or already mended today', () {
      expect(_offer('vigil', busy: true).mendBlock, TempleBlock.busy);
      expect(_offer('vigil', gold: 100).mendBlock, isNull);
      expect(_offer('vigil', gold: 100).blessingBlock, TempleBlock.poor);
      expect(_offer('vigil', mendDay: 3).mendBlock, TempleBlock.mendedToday);
      expect(_offer('vigil', mendDay: 2).mendBlock, isNull);
      expect(_offer('vigil', chapter: 1).mendOffered, isFalse);
      expect(_offer('vigil', chapter: 1).canMend, isFalse);
      expect(_offer('vigil', chapter: 1).canBless, isTrue);
    });
  });

  group('the blessing', () {
    test("the clan's Host kit and the ward; a neutral temple's health", () {
      final vigil = templeBlessingEffects('vigil', _data);
      expect(vigil, containsAll(_data.faction('vigil')!.host!.effects));
      final ward = vigil.where((e) => e.kind == SignEffectKind.partyStartBlock);
      expect(ward.single.value, templeWardBlock);
      final neutral = templeBlessingEffects('', _data);
      expect(neutral.map((e) => (e.kind, e.value)), [
        (SignEffectKind.partyMaxHealthPercent, templeNeutralHealthPercent),
        (SignEffectKind.partyStartBlock, templeWardBlock),
      ]);
      final fx = signEffectsFor(const [], const {},
          alignment: 0, extra: templeBlessingEffects('', _data));
      expect(fx.partyStartBlock, 1);
      expect(fx.partyMaxHealthPercent, 3);
      expect(
          activeBlessingEffects(
              blessingFights: 0, blessingClan: 'vigil', data: _data),
          isEmpty);
    });

    test('+1 standing once a chapter per clan, not from an opposite clan', () {
      expect(_offer('vigil').blessingStanding, isTrue);
      expect(_offer('vigil', standingChapters: {'vigil': 4}).blessingStanding,
          isFalse);
      expect(_offer('vigil', standingChapters: {'vigil': 3}).blessingStanding,
          isTrue);
      // The Vigil leans +1: an Evil character is blessed, not warmed to.
      expect(_offer('vigil', alignment: -50).blessingStanding, isFalse);
      expect(_offer('vigil', alignment: -50).canBless, isTrue);
      expect(_offer('').blessingStanding, isFalse);
    });

    test('blesses for 3 fights, replaces, then ends', () async {
      final n = await _notifier({'gold': 1000, 'day': 3});
      final before = n.state.politics.standingOf('vigil', _data);
      expect(await n.templeBless('vigil', data: _data, chapter: 4), isTrue);
      expect(n.state.gold, 850);
      expect(n.state.blessingFights, templeBlessingFights);
      expect(n.state.blessingClan, 'vigil');
      expect(n.state.politics.standingOf('vigil', _data), greaterThan(before));
      expect(n.state.templeStandingChapters, {'vigil': 4});
      final after = n.state.politics.standingOf('vigil', _data);
      // Again this chapter: replaces, no more standing.
      expect(n.templeOffer('vigil', data: _data, chapter: 4).blessingReplaces,
          isTrue);
      await n.spendBlessingFight();
      expect(await n.templeBless('vigil', data: _data, chapter: 4), isTrue);
      expect(n.state.blessingFights, templeBlessingFights);
      expect(n.state.politics.standingOf('vigil', _data), after);
      // A neutral temple's replaces the clan's.
      expect(await n.templeBless('', data: _data, chapter: 4), isTrue);
      expect(n.state.blessingClan, '');
      expect(n.state.blessingFights, templeBlessingFights);
      for (var i = 0; i < templeBlessingFights; i++) {
        await n.spendBlessingFight();
      }
      expect(n.state.blessingFights, 0);
      await n.spendBlessingFight();
      expect(n.state.blessingFights, 0);
      expect(
          activeBlessingEffects(
              blessingFights: n.state.blessingFights,
              blessingClan: n.state.blessingClan,
              data: _data),
          isEmpty);
    });

    test('refused when Hunted, and too poor', () async {
      final n = await _notifier({'gold': 1000});
      await n.setStandingForEdit('vigil', -80, data: _data);
      expect(await n.templeBless('vigil', data: _data, chapter: 4), isFalse);
      expect(await n.templeMend('vigil', data: _data, chapter: 4), isFalse);
      expect(n.state.gold, 1000);
      final poor = await _notifier({'gold': 10});
      expect(await poor.templeBless('', data: _data, chapter: 4), isFalse);
      expect(poor.state.blessingFights, 0);
    });
  });

  group('Mending', () {
    test('heals all, keeps mana, passes no day, once a day, from chapter 2',
        () async {
      final n = await _notifier({
        'gold': 500,
        'day': 5,
        'watch': 2,
        'currentHealth': 10,
        'maxHealth': 100,
        'mana': 1,
        'maxMana': 20,
      });
      expect(await n.templeMend('', data: _data, chapter: 1), isFalse);
      expect(await n.templeMend('', data: _data, chapter: 3), isTrue);
      expect(n.state.currentHealth, 100);
      expect(n.state.mana, 1);
      expect(n.state.day, 5);
      expect(n.state.watch, 2);
      expect(n.state.gold, 440);
      expect(n.state.templeMendDay, 5);
      expect(await n.templeMend('', data: _data, chapter: 3), isFalse);
      expect(n.state.gold, 440);
      // A night's rest opens it again.
      await n.restNight(chapter: 3);
      expect(await n.templeMend('', data: _data, chapter: 3), isTrue);
    });
  });

  group('the save', () {
    test('round-trips, and leaves defaults out', () {
      final s = PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'blessingFights': 2,
        'blessingClan': 'mire',
        'templeMendDay': 7,
        'templeStandingChapters': {'mire': 3},
      });
      final back = PlayerSession.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.blessingFights, 2);
      expect(back.blessingClan, 'mire');
      expect(back.templeMendDay, 7);
      expect(back.templeStandingChapters, {'mire': 3});
    });

    test('an old save has no blessing', () {
      final s = PlayerSession.fromJson(
          const {'raceId': 'human', 'professionId': 'warrior'});
      expect(s.blessingFights, 0);
      expect(s.blessingClan, '');
      expect(s.templeMendDay, 0);
      expect(s.templeStandingChapters, isEmpty);
      final json = s.toJson();
      for (final key in [
        'blessingFights',
        'blessingClan',
        'templeMendDay',
        'templeStandingChapters',
      ]) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
    });
  });

  test("a temple's keeper: its district's ruler, else its town's", () {
    const ruler = TownRuler(
        placeId: 'town',
        cityId: 'town',
        clanId: 'mire',
        source: TownRulerSource.own,
        color: 0,
        accent: 0);
    expect(templeClanAt('town', {'town': ruler}), 'mire');
    expect(templeClanAt('nowhere', {'town': ruler}, parent: 'town'), 'mire');
    expect(templeClanAt('nowhere', {'town': ruler}), '');
  });

  test('every clan with a Host kit has its temple texts', () {
    for (final f in _data.factions.values) {
      if (f.host == null || f.host!.effects.isEmpty) continue;
      expect(f.templeName, isNotEmpty, reason: f.id);
      expect(f.templeNameFr, isNotEmpty, reason: f.id);
      expect(f.templeLineHunted, isNotEmpty, reason: f.id);
      expect(f.blessingGrants, isNotEmpty, reason: f.id);
    }
  });
}

// Wave 18 step 1 (docs/proposals/wave18-core.md): locked districts and
// clan influence in Saltmouth's districts.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/data/district_influence.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _alleys = 'saltmouth_lantern_alleys';
const _tern = 'saltmouth_tern_row';
const _yard = 'saltmouth_yard';
const _wharf = 'saltmouth_wharf';

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final geoRaw = _table('geography');
  final geo = Geography.parse(geography: geoRaw, biomes: _table('biomes'));
  final quests = _table('quests');
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });

  group('locks', () {
    test('every lock names a quest of quests.json', () {
      var locks = 0;
      for (final place in geo.places.values) {
        if (!place.hasLock) continue;
        locks++;
        expect(quests.containsKey(place.lockQuest), isTrue,
            reason: '${place.id} locks on ${place.lockQuest}');
        expect(place.level, GeoLevel.district);
        expect(place.lockedText, isNotEmpty, reason: place.id);
        expect(place.lockedTextFr, isNotEmpty, reason: place.id);
        expect([geoLockOpensOnAccepted, geoLockOpensOnDone],
            contains(place.lockOpensOn));
      }
      expect(locks, greaterThanOrEqualTo(2));
    });

    test('the Alleys and Tern Row open when their quest is done', () {
      expect(geo.place(_alleys)!.lockQuest, 'q_ch2_informants_tip');
      expect(geo.place(_tern)!.lockQuest, 'q_ch2_terns_toll');
      expect(districtLocked(geo, _alleys, const [], const []), isTrue);
      expect(districtLocked(geo, _tern, const [], const []), isTrue);
      // Taken is not enough: they open on done.
      expect(
          districtLocked(geo, _alleys,
              [questAcceptedFlag('q_ch2_informants_tip')], const []),
          isTrue);
      expect(districtLocked(geo, _alleys, const [], ['q_ch2_informants_tip']),
          isFalse);
      expect(districtLocked(geo, _wharf, const [], const []), isFalse);
      expect(lockedDistrictsOf(geo, 'saltmouth', const [], const []),
          [_tern, _alleys]);
    });

    test('opensOn accepted opens on the _accepted flag', () {
      final g = Geography.parse(geography: {
        'town': {'level': 'location', 'kind': 'city', 'name': 'Town'},
        'gate': {
          'level': 'district',
          'parent': 'town',
          'name': 'Gate',
          'lock': {'quest': 'q_x', 'opensOn': 'accepted'},
        },
      }, biomes: const {});
      expect(districtLocked(g, 'gate', const [], const []), isTrue);
      expect(
          districtLocked(g, 'gate', const ['q_x_accepted'], const []), isFalse);
      expect(districtLocked(g, 'gate', const [], const ['q_x']), isFalse);
    });

    test('a locked district is never found, and its story ways are known', () {
      Set<String> found(List<String> done) => foundDistricts(geo, story,
          cityId: 'saltmouth',
          visitedNodeIds: const ['2015', '2015_bazaar'],
          currentNodeId: '2015',
          flags: [districtFoundFlag(_alleys), districtFoundFlag(_tern)],
          completedQuestIds: done);
      expect(found(const []), {_wharf});
      expect(found(const ['q_ch2_informants_tip']), {_wharf, _alleys});
      final hub = story.nodeFor('2015')!;
      final locked = lockedWays(geo, story, hub, const [], const []);
      expect(locked, containsAll(waysInDistrict(geo, story, hub, _alleys)));
      expect(locked, containsAll(waysInDistrict(geo, story, hub, _tern)));
      expect(
          lockedWays(geo, story, hub, const [],
              const ['q_ch2_informants_tip', 'q_ch2_terns_toll']),
          isEmpty);
    });

    testWidgets('the party cannot walk into a locked district', (tester) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef ref;
      await tester.pumpWidget(ProviderScope(
        overrides: [storyDataProvider.overrideWith((ref) async => story)],
        child: Consumer(builder: (context, r, _) {
          ref = r;
          r.watch(partyDistrictProvider);
          r.watch(lockedDistrictsProvider);
          return const SizedBox.shrink();
        }),
      ));
      await tester.runAsync(() async {
        ref.read(playerSessionProvider.notifier);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        ref.read(storyPlayProvider.notifier).jumpTo('2015');
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      expect(ref.read(partyDistrictProvider), _wharf);
      expect(ref.read(lockedDistrictsProvider), {_alleys, _tern});
      late bool walked;
      await tester
          .runAsync(() async => walked = await walkToDistrict(ref, _alleys));
      await tester.pump();
      expect(walked, isFalse);
      expect(ref.read(partyDistrictProvider), _wharf);
      expect(ref.read(playerSessionProvider).flags,
          isNot(contains(districtFoundFlag(_alleys))));
      expect(ref.read(foundDistrictsProvider), isNot(contains(_alleys)));
    });
  });

  group('holders', () {
    test("each of Saltmouth's six districts has a holder", () {
      final holders = {
        for (final d in districtsOfCity(geo, 'saltmouth'))
          d.id: holderOf(d.id, geo, PoliticsState.empty),
      };
      expect(holders, {
        'saltmouth_landward_gate': 'dominion',
        _tern: 'tidekin',
        _wharf: 'crows',
        _yard: 'compact',
        _alleys: 'mire',
        'saltmouth_card_row': 'crows',
      });
    });
  });

  group('influence', () {
    Map<String, dynamic> side({String faction = 'dominion'}) => {
          'category': 'Side',
          'district': _yard,
          'faction': faction,
        };

    InfluenceResult done(PoliticsState state, Map<String, dynamic> quest,
            {String? city = 'saltmouth',
            List<String> flags = const [],
            StoryPolitics? picked}) =>
        applyQuestInfluence(state, quest,
            flags: flags,
            data: data,
            geography: geo,
            picked: picked,
            cityHere: city);

    test('the holder starts at 20, others at 0', () {
      expect(influenceIn(PoliticsState.empty, geo, _yard, 'compact'),
          holderStartInfluence);
      expect(influenceIn(PoliticsState.empty, geo, _yard, 'dominion'), 0);
    });

    test('a quest done in town adds its influence; outside town, none', () {
      final r = done(PoliticsState.empty, side());
      expect(r.counted, isTrue);
      expect(r.amount, sideQuestInfluence);
      expect(influenceIn(r.state, geo, _yard, 'dominion'), 15);
      expect(influenceIn(r.state, geo, _yard, 'compact'), 20);
      expect(done(PoliticsState.empty, side(), city: null).counted, isFalse);
      expect(
          done(PoliticsState.empty, side(), city: 'alster').counted, isFalse);
      // A Main quest brings more; `influence` overrides.
      expect(done(PoliticsState.empty, {...side(), 'category': 'Main'}).amount,
          mainQuestInfluence);
      expect(done(PoliticsState.empty, {...side(), 'influence': 7}).amount, 7);
      // No district of its own: the party's.
      final here = applyQuestInfluence(
          PoliticsState.empty, {'category': 'Side', 'faction': 'mire'},
          flags: const [],
          data: data,
          geography: geo,
          cityHere: 'saltmouth',
          partyDistrict: 'saltmouth_landward_gate');
      expect(
          influenceIn(here.state, geo, 'saltmouth_landward_gate', 'mire'), 15);
    });

    test('the clan favoured at the turn-in takes it over the fixed clan', () {
      final r = done(PoliticsState.empty, side(),
          picked: StoryPolitics(standing: const {'mire': 5, 'crows': 2}));
      expect(r.clanId, 'mire');
      expect(influenceIn(r.state, geo, _yard, 'mire'), 15);
      expect(influenceIn(r.state, geo, _yard, 'dominion'), 0);
    });

    test('a district flips 15 over the holder: news, flag, held flags', () {
      var state = PoliticsState.empty;
      var flags = <String>['held_breath'];
      for (var i = 0; i < 2; i++) {
        final r = done(state, side(), flags: flags);
        state = r.state;
        flags = r.flags;
        expect(r.flipped, isNull);
      }
      expect(holderOf(_yard, geo, state), 'compact');
      expect(flags, contains(heldFlag(_yard, 'compact')));
      final r = done(state, side(), flags: flags);
      expect(influenceIn(r.state, geo, _yard, 'dominion'), 45);
      expect(r.flipped?.placeId, _yard);
      expect(r.flipped?.from, 'compact');
      expect(r.flipped?.to, 'dominion');
      expect(r.flipped?.cause, 'influence');
      expect(holderOf(_yard, geo, r.state), 'dominion');
      expect(r.flags, contains(districtFlippedFlag(_yard)));
      expect(r.flags, contains(heldFlag(_yard, 'dominion')));
      expect(r.flags, isNot(contains(heldFlag(_yard, 'compact'))));
      expect(r.flags, contains('held_breath'));
      final news =
          r.state.news.firstWhere((n) => n.eventId == 'territory:$_yard');
      final yardName = geo.place(_yard)!.name;
      expect(
          news.text,
          trFor(AppLanguage.en, 'district_flipped')
              .replaceAll('{district}', yardName)
              .replaceAll(
                  '{clan}', data.faction('dominion')!.nameFor(AppLanguage.en))
              .replaceAll(
                  '{from}', data.faction('compact')!.nameFor(AppLanguage.en)));
      expect(news.textFr, contains(geo.place(_yard)!.nameFr));
      expect(
          r.state.relationStep('compact', 'dominion', data),
          (PoliticsState.empty.relationStep('compact', 'dominion', data) ?? 4) -
              1);
    });

    test('a seat never flips by influence', () {
      var state = PoliticsState.empty;
      for (var i = 0; i < 6; i++) {
        state = addInfluence(state, _wharf, 'dominion', 15,
                flags: const [], data: data, geography: geo)
            .state;
      }
      expect(influenceIn(state, geo, _wharf, 'dominion'), 90);
      expect(holderOf(_wharf, geo, state), 'crows');
    });

    test('a flip fires the district_flipped remark kind', () {
      expect(remarkTriggerOptions, contains('districtFlipped'));
      expect(remarkTriggerOptions, contains('districtAttacked'));
      final book = RemarkBook({
        'r': {
          'companionID': 'sable',
          'trigger': RemarkKind.districtFlipped.name,
          'lines': ['New banners.'],
        },
      });
      final said = momentRemark(book, const RemarkMemory(), const ['sable'],
          RemarkKind.districtFlipped);
      expect(said.remark?.kind, RemarkKind.districtFlipped);
    });

    test('a clan holding 4 of 6 takes the town; below, it loses it', () {
      // The Crows hold the Wharf and Card Row: the Alleys make three, the
      // Yard four.
      expect(holderOf('saltmouth', geo, PoliticsState.empty), '');
      final three = addInfluence(PoliticsState.empty, _alleys, 'crows', 35,
          flags: const [], data: data, geography: geo);
      expect(three.flipped?.to, 'crows');
      expect(three.townTakenBy, '');
      expect(three.state.control.containsKey('saltmouth'), isFalse);
      final r = addInfluence(three.state, _yard, 'crows', 35,
          flags: three.flags, data: data, geography: geo);
      expect(r.flipped?.to, 'crows');
      expect(r.townTakenBy, 'crows');
      expect(holderOf('saltmouth', geo, r.state), 'crows');
      expect(r.state.control['saltmouth'], 'crows');
      // The Yard won back by the Compact: three again, the town lost.
      final back = addInfluence(r.state, _yard, 'compact', 60,
          flags: r.flags, data: data, geography: geo);
      expect(holderOf(_yard, geo, back.state), 'compact');
      expect(back.state.control.containsKey('saltmouth'), isFalse);
      expect(back.flags, contains(heldFlag(_yard, 'compact')));
    });

    test('influence is saved and loaded with the politics', () {
      final r = done(PoliticsState.empty, side());
      final loaded = PoliticsState.fromJson(
          jsonDecode(jsonEncode(r.state.toJson())) as Map<String, dynamic>);
      expect(loaded.influence, r.state.influence);
      expect(loaded.influence[_yard], {'compact': 20, 'dominion': 15});
      expect(
          PoliticsState.fromJson(
                  jsonDecode(jsonEncode(PoliticsState.empty.toJson())))
              .influence,
          isEmpty);
    });
  });

  group('held flags', () {
    test('one per held district, kept in sync', () {
      final flags = syncHeldFlags(
          const ['held_breath', 'held_saltmouth_yard_mire'],
          geo,
          PoliticsState.empty);
      expect(flags, contains('held_breath'));
      expect(flags, isNot(contains('held_saltmouth_yard_mire')));
      for (final d in districtsOfCity(geo, 'saltmouth')) {
        final h = holderOf(d.id, geo, PoliticsState.empty);
        expect(flags, contains(heldFlag(d.id, h)));
        expect(flags.where((f) => f.startsWith('held_${d.id}_')), hasLength(1));
      }
      // In sync already: the same list back.
      expect(identical(syncHeldFlags(flags, geo, PoliticsState.empty), flags),
          isTrue);
      // A place given in war: the flag follows.
      final war = givePlace(PoliticsState.empty, _yard, 'vigil',
          cause: 'war', data: data, geography: geo);
      final after = syncHeldFlags(flags, geo, war);
      expect(after, contains(heldFlag(_yard, 'vigil')));
      expect(after, isNot(contains(heldFlag(_yard, 'compact'))));
    });
  });

  test('camp errands may be an attack alert', () {
    final node = StoryNode.fromJson('x', {
      'description': 'They come.',
      'campErrand': 'attack',
      'campErrandText': 'Riders at the gate',
    });
    expect(node.campErrand, isTrue);
    expect(node.campErrandKind, campErrandAttack);
    expect(node.toJson()['campErrand'], 'attack');
    final plain = StoryNode.fromJson('y', {'campErrand': true});
    expect(plain.campErrand, isTrue);
    expect(plain.campErrandKind, '');
    expect(plain.toJson()['campErrand'], true);
  });
}

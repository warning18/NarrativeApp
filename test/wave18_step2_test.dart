// Wave 18 step 2, items 2 to 5: the Ashen Quarter's and the Black
// Reliquary's holders and the Spire Stair's lock (Narrative's answers,
// docs/proposals/wave18-step2-text.md), the throne's backing and the
// Host's draw from the districts, clan roads, and the epilogue's holdings.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/district_influence.dart';
import 'package:narrative_data_app/data/epilogue.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/data/throne.dart';
import 'package:narrative_data_app/data/town_rulers.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  const empty = PoliticsState.empty;

  group('the big towns (item 2)', () {
    test('the Ashen Quarter and the Reliquary hold as Narrative set them', () {
      expect({
        for (final d in [
          'ashen_quarter_gate',
          'ashen_quarter_ash_market',
          'ashen_quarter_wall_of_names',
          'ashen_quarter_cinder_row',
          'ashen_quarter_spire_stair',
          'reliquary_quarter',
          'reliquary_chapels',
          'reliquary_last_lantern',
          'reliquary_frost_line',
          'dead_heart',
        ])
          d: holderOf(d, geo, empty)
      }, {
        'ashen_quarter_gate': 'vigil',
        'ashen_quarter_ash_market': 'compact',
        'ashen_quarter_wall_of_names': 'penitents',
        'ashen_quarter_cinder_row': 'compact',
        'ashen_quarter_spire_stair': 'dominion',
        'reliquary_quarter': 'dominion',
        'reliquary_chapels': 'compact',
        'reliquary_last_lantern': 'penitents',
        'reliquary_frost_line': 'vigil',
        'dead_heart': '',
      });
      // Both start open: the Compact leads the Quarter, the Reliquary ties.
      final rulers = townRulers(geo, empty, const {});
      expect(rulers['ashen_quarter']!.clanId, 'compact');
      expect(rulers['black_reliquary']!.clanId, '');
    });

    test('the Dead Heart is never held, by war, event or influence', () {
      expect(geo.place('dead_heart')!.unheld, isTrue);
      for (final cause in ['war', 'event', 'influence']) {
        final next = givePlace(empty, 'dead_heart', 'vigil',
            cause: cause, data: data, geography: geo);
        expect(holderOf('dead_heart', geo, next), '', reason: cause);
      }
      final pushed = addInfluence(empty, 'dead_heart', 'vigil', 100,
          flags: const [], data: data, geography: geo);
      expect(holderOf('dead_heart', geo, pushed.state), '');
    });

    test('the Spire Stair opens on taking the Ashen Oath', () {
      final stair = geo.place('ashen_quarter_spire_stair')!;
      expect(stair.lockQuest, 'q_ch3_ashen_oath');
      expect(stair.lockOpensOn, geoLockOpensOnAccepted);
      expect(stair.lockedTextFor(false), contains('Ashen Oath'));
      expect(stair.lockedTextFor(true), contains('Serment de Cendres'));
    });

    test('three of the Quarter\'s districts take the town', () {
      var state = empty;
      for (final d in ['ashen_quarter_gate', 'ashen_quarter_ash_market']) {
        state = givePlace(state, d, 'vigil',
            cause: 'influence', data: data, geography: geo);
      }
      // The Gate is the Vigil's already: the Ash-Market makes two.
      expect(
          townTurn(state, 'ashen_quarter', data: data, geography: geo).takenBy,
          '');
      state = givePlace(state, 'ashen_quarter_cinder_row', 'vigil',
          cause: 'influence', data: data, geography: geo);
      expect(
          townTurn(state, 'ashen_quarter', data: data, geography: geo).takenBy,
          'vigil');
    });
  });

  group('influence pays off (item 3)', () {
    final sworn = empty.copyWith(swornFactionId: 'compact');

    test('a seat war\'s backing: districts of the main clan and allies', () {
      // The Compact holds 3 districts at the start (Saltmouth's Yard, the
      // Ash-Market and Cinder Row, the Chapels).
      final own = holdings(geo, sworn)
          .entries
          .where((e) =>
              e.value == 'compact' &&
              geo.place(e.key)?.level == GeoLevel.district)
          .length;
      expect(seatBacking(sworn, 'compact', data: data, geography: geo),
          own.clamp(0, seatBackingMax));
      // Not the main clan: nothing.
      expect(seatBacking(sworn, 'vigil', data: data, geography: geo), 0);
      // An ally's districts count, up to the cap.
      final allied = sworn.copyWith(relationSteps: {
        relationKey('compact', 'dominion'): maxRelationStep,
        relationKey('compact', 'vigil'): maxRelationStep,
      });
      expect(seatBacking(allied, 'compact', data: data, geography: geo),
          seatBackingMax);
    });

    test('the backing takes a seat the main clan could not otherwise', () {
      // The Crows down to their seat, the Wharf; the Compact 18 stronger,
      // at war, in chapter 6. Sworn to it, its districts back it.
      PoliticsState base(String sworn) =>
          empty.copyWith(swornFactionId: sworn, control: {
            'alster_lower_town': 'mire',
            'saltmouth_card_row': 'compact'
          }, power: {
            'compact': 58,
            'crows': 40
          }, helped: [
            'compact',
            'crows'
          ], relationSteps: {
            relationKey('compact', 'crows'): warStep
          });
      bool took(String sworn) =>
          territoryTurn(base(sworn), data: data, geography: geo, chapter: 6)
              .changes
              .any((c) => c.placeId == 'saltmouth_wharf' && c.to == 'compact');
      expect(took('compact'), isTrue);
      expect(took('vigil'), isFalse);
    });

    test('the Penitents\' seat is guarded, as Candlehold', () {
      expect(seatGuarded('penitents'), isTrue);
      var state = empty.copyWith(power: {'dominion': 90, 'penitents': 5});
      for (var chapter = 2; chapter <= 8; chapter++) {
        state =
            territoryTurn(state, data: data, geography: geo, chapter: chapter)
                .state;
      }
      expect(holderOf('ashen_quarter_wall_of_names', geo, state), 'penitents');
      expect(state.fallen, isNot(contains('penitents')));
    });

    test('the Host draws on the clans holding the most districts', () {
      final most = districtHostClans(empty, geo);
      expect(most, isNotEmpty);
      for (final clan in most) {
        expect(
            hostFor(politics: empty, data: data).allies, isNot(contains(clan)));
        expect(hostFor(politics: empty, data: data, geography: geo).allies,
            contains(clan));
      }
      // Hostile or worse, it stays away.
      final hated = empty.copyWith(standings: {for (final c in most) c: -100});
      for (final clan in most) {
        expect(hostFor(politics: hated, data: data, geography: geo).allies,
            isNot(contains(clan)));
      }
    });
  });

  group('clan roads (item 5)', () {
    final route =
        landRouteFor(_table('land_routes'), 'stair_to_court')!; // 1 in 3
    final both = empty.copyWith(
        control: {'drowned_cloister': 'mire', 'hollow_court': 'mire'});

    test('a road both of whose ends one clan holds is its road', () {
      expect(clanRoadOf(route, geo, both), 'mire');
      final road = crossingRuler(route, geo, both, data);
      expect(road.clanRoad, isTrue);
      expect(road.clanId, 'mire');
      expect(road.route.rulerOneIn, clanRoadOneIn);
      // The two ends held by two clans (the cloister is the Mire's by its
      // district): the route as it is.
      final one = empty.copyWith(control: {'hollow_court': 'vigil'});
      expect(clanRoadOf(route, geo, one), '');
      expect(crossingRuler(route, geo, one, data).route.rulerOneIn,
          route.rulerOneIn);
    });

    test('a route that never meets its ruler still never does', () {
      final cliffs = landRouteFor(_table('land_routes'), 'lantern_cliffs')!;
      expect(cliffs.rulerOneIn, 0);
      final held = empty.copyWith(control: {
        geo.placeOfLandmark(cliffs.from)!.id: 'dominion',
        geo.placeOfLandmark(cliffs.to)!.id: 'dominion',
      });
      expect(crossingRuler(cliffs, geo, held, data).route.rulerOneIn, 0);
    });

    test(
        'on its own road a clan is friendly from Friend, hard from '
        'Unfriendly', () {
      expect(clanRoadBandFor(StandingTier.friend), RulerBand.friend);
      expect(clanRoadBandFor(StandingTier.friendly), RulerBand.neutral);
      expect(clanRoadBandFor(StandingTier.wary), RulerBand.neutral);
      expect(clanRoadBandFor(StandingTier.unfriendly), RulerBand.hostile);
      // Elsewhere, Unfriendly is still the toll.
      expect(rulerBandFor(StandingTier.unfriendly), RulerBand.neutral);
    });
  });

  group('the epilogue (item 4)', () {
    EpilogueTown town(PoliticsState state, String id) =>
        epilogueHoldings(state, geo).singleWhere((t) => t.townId == id);

    test('at the start: seats, and the Reliquary no one\'s', () {
      final towns = epilogueHoldings(empty, geo);
      expect([for (final t in towns) t.townId], epilogueTowns);
      expect(town(empty, 'ashen_quarter').how, EpilogueHow.seat);
      expect(town(empty, 'ashen_quarter').clanId, 'compact');
      final reliquary = town(empty, 'black_reliquary');
      expect(reliquary.how, EpilogueHow.none);
      expect(reliquary.districts['reliquary_frost_line'], 'vigil');
      expect(epilogueLine(reliquary, data, AppLanguage.en),
          'No clan holds The Black Reliquary. It answers to no one.');
    });

    test('a town taken by influence, or by war, says so', () {
      var state = empty;
      for (final d in [
        'ashen_quarter_ash_market',
        'ashen_quarter_cinder_row',
      ]) {
        state = givePlace(state, d, 'vigil',
            cause: 'influence', data: data, geography: geo);
      }
      final won = town(state, 'ashen_quarter');
      expect(won.clanId, 'vigil');
      expect(won.how, EpilogueHow.influence);
      expect(epilogueLine(won, data, AppLanguage.en),
          'The Grey Vigil took the Ashen Quarter by being the one who stayed.');
      expect(
          epilogueLine(won, data, AppLanguage.fr),
          'La Veille Grise a pris le Quartier des Cendres en étant celui qui '
          'est resté.');

      state = givePlace(empty, 'ashen_quarter_ash_market', 'mire',
          cause: 'war', data: data, geography: geo);
      state = givePlace(state, 'ashen_quarter_cinder_row', 'mire',
          cause: 'war', data: data, geography: geo);
      final taken = town(state, 'ashen_quarter');
      expect(taken.how, EpilogueHow.war);
      expect(
          epilogueLine(taken, data, AppLanguage.fr),
          'Les Cours du Marais ont pris le Quartier des Cendres à même la '
          'cendre.');
    });

    test('a seat kept reads in French with the clan\'s « à » form', () {
      final kept = town(empty, 'ashen_quarter');
      expect(epilogueLine(kept, data, AppLanguage.en),
          'The Ashen Quarter was the Cinder Compact’s own, and it kept it.');
      expect(epilogueLine(kept, data, AppLanguage.fr),
          'Le Quartier des Cendres était au Pacte des Cendres, qui l’a gardé.');
    });

    test('the territory log keeps the place and how, saved and loaded', () {
      final state = givePlace(empty, 'ashen_quarter_gate', 'mire',
          cause: 'war', data: data, geography: geo);
      final entry = state.standingLog.last;
      expect(entry.placeId, 'ashen_quarter_gate');
      expect(entry.how, 'war');
      final loaded = StandingLogEntry.fromJson(
          jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>);
      expect(loaded.placeId, 'ashen_quarter_gate');
      expect(loaded.how, 'war');
    });
  });
}

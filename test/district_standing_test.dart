// The Town view of wave 18 (v1.572): shut districts, holders' flags and
// influence (lib/widgets/district_standing.dart, the chart's lock and crest).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_districts.dart';
import 'package:narrative_data_app/data/district_influence.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/widgets/district_standing.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _tern = 'saltmouth_tern_row';
const _alleys = 'saltmouth_lantern_alleys';
const _yard = 'saltmouth_yard';
const _wharf = 'saltmouth_wharf';

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final ids = [for (final d in districtsOfCity(geo, 'saltmouth')) d.id];

  Map<String, DistrictStanding> standings({
    PoliticsState politics = PoliticsState.empty,
    List<String> flags = const [],
    List<String> done = const [],
    String? cityId = 'saltmouth',
    AppLanguage language = AppLanguage.en,
  }) =>
      districtStandingsOf(
        districtIds: ids,
        cityId: cityId,
        geography: geo,
        politics: politics,
        flags: flags,
        completedQuestIds: done,
        data: data,
        rulers: const {},
        language: language,
      );

  group('districtStandingsOf', () {
    test('the shut districts carry their reason and quest, no holder', () {
      final s = standings();
      for (final id in [_tern, _alleys]) {
        expect(s[id]!.locked, isTrue, reason: id);
        expect(s[id]!.lockedText, isNotEmpty, reason: id);
        expect(s[id]!.lockQuest, isNotEmpty, reason: id);
        expect(s[id]!.held, isFalse, reason: id);
        expect(s[id]!.crest, isNull, reason: id);
      }
      expect(s[_tern]!.lockedText, geo.place(_tern)!.lockedText);
      expect(standings(language: AppLanguage.fr)[_tern]!.lockedText,
          geo.place(_tern)!.lockedTextFr);
    });

    test('a quest done opens its district', () {
      final s = standings(done: ['q_ch2_terns_toll']);
      expect(s[_tern]!.locked, isFalse);
      expect(s[_tern]!.holderId, 'tidekin');
      expect(s[_alleys]!.locked, isTrue);
    });

    test('the others show their holder and its influence', () {
      final s = standings();
      expect(s[_yard]!.holderId, 'compact');
      expect(s[_yard]!.influence, holderStartInfluence);
      expect(s[_yard]!.rivalId, isEmpty);
      expect(s[_wharf]!.holderId, 'crows');
      expect(s[_yard]!.flipped, isFalse);
    });

    test(
        'the strongest other clan is the rival; the flip mark follows the flag',
        () {
      var state = PoliticsState.empty;
      state = addInfluence(state, _yard, 'dominion', 15,
              flags: const [], data: data, geography: geo)
          .state;
      state = addInfluence(state, _yard, 'crows', 5,
              flags: const [], data: data, geography: geo)
          .state;
      final s = standings(politics: state);
      expect(s[_yard]!.holderId, 'compact');
      expect(s[_yard]!.rivalId, 'dominion');
      expect(s[_yard]!.rivalInfluence, 15);
      expect(s[_yard]!.crest!.rival, 15 / maxInfluence);
      expect(s[_yard]!.crest!.hold, holderStartInfluence / maxInfluence);
      expect(standings(flags: [districtFlippedFlag(_yard)])[_yard]!.flipped,
          isTrue);
    });

    test('the flip tick sits where the rival would take the district', () {
      final c = standings()[_yard]!.crest!;
      expect(c.flipAt, (holderStartInfluence + flipMargin) / maxInfluence);
    });

    test('influence is counted in every town, not outside one', () {
      // Wave 18 step 2: any town (step 1 counted it in Saltmouth only).
      expect(standings(cityId: 'ashen_quarter')[_yard]!.influence,
          holderStartInfluence);
      final s = standings(cityId: null);
      expect(s[_yard]!.influence, isNull);
      expect(s[_yard]!.crest?.hold, isNull);
    });
  });

  group('the list rows', () {
    Widget host(Widget child) => ProviderScope(
          child: MaterialApp(home: Scaffold(body: child)),
        );

    testWidgets('a shut district gives its reason in two lines',
        (tester) async {
      final s = standings()[_tern]!;
      await tester.pumpWidget(host(DistrictStandingLine(s)));
      expect(
          find.byKey(const Key('district_locked_text_$_tern')), findsOneWidget);
      expect(find.text(s.lockedText), findsOneWidget);
      expect(find.byKey(const Key('district_influence_$_tern')), findsNothing);
    });

    testWidgets('a held district shows the holder and the bar', (tester) async {
      final s = standings()[_yard]!;
      await tester.pumpWidget(host(DistrictStandingLine(s)));
      expect(find.byKey(const Key('district_holder_$_yard')), findsOneWidget);
      expect(
          find.byKey(const Key('district_influence_$_yard')), findsOneWidget);
      expect(find.textContaining('$holderStartInfluence'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('a district that changed hands says so', (tester) async {
      final s = standings(flags: [districtFlippedFlag(_yard)])[_yard]!;
      await tester.pumpWidget(host(DistrictStandingLine(s)));
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(
          find.textContaining(trFor(AppLanguage.en, 'district_changed_hands')),
          findsOneWidget);
    });

    testWidgets('the lead is a padlock when shut, the plain marker else',
        (tester) async {
      const plain = SizedBox(key: Key('plain'), width: 12, height: 12);
      final all = standings();
      await tester.pumpWidget(host(DistrictLead(all[_tern]!, plain: plain)));
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byKey(const Key('plain')), findsNothing);
      // A clan without a flag keeps the row's own marker.
      await tester.pumpWidget(
          host(DistrictLead(const DistrictStanding(id: 'x'), plain: plain)));
      expect(find.byKey(const Key('plain')), findsOneWidget);
    });
  });

  test('the new strings exist in both languages', () {
    for (final k in ['district_changed_hands', 'district_locked_by']) {
      expect(trFor(AppLanguage.en, k), isNot(k));
      expect(trFor(AppLanguage.fr, k), isNot(k));
    }
    expect(trFor(AppLanguage.en, 'district_locked_by'), contains('{quest}'));
    expect(trFor(AppLanguage.fr, 'district_locked_by'), contains('{quest}'));
  });
}

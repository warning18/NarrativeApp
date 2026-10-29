// A clan at a glance (v1.576): the standing sign has its own disc for each of
// the eleven steps, and a clan's banner wears it where the offer, the clan
// card, the ring, the Throne room and the Clans list draw it. (How strong a
// clan is is the rank plate's, clan_rank.dart.)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/widgets/clan_glance.dart';
import 'package:narrative_data_app/widgets/standing_sign.dart';

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

  group('the eleven discs', () {
    test('every step has its own shape and its own colour', () {
      expect(standingGlyphs.keys.toSet(), StandingTier.values.toSet());
      final shapes = {
        for (final t in StandingTier.values) standingGlyphs[t]!.join('/'),
      };
      expect(shapes, hasLength(StandingTier.values.length));
      final colours = {
        for (final t in StandingTier.values) standingSignColor(t).toARGB32(),
      };
      expect(colours, hasLength(StandingTier.values.length));
      for (final t in StandingTier.values) {
        expect(standingSignColor(t), Color(tierColor(t)), reason: t.name);
      }
    });

    test('a shape is seven rows of seven pixels with something lit', () {
      for (final t in StandingTier.values) {
        final rows = standingGlyphs[t]!;
        expect(rows, hasLength(7), reason: t.name);
        for (final row in rows) {
          expect(row, matches(RegExp(r'^[.#]{7}$')), reason: t.name);
        }
        expect(rows.join().contains('#'), isTrue, reason: t.name);
      }
    });

    test('no two shapes are alike even when one is mirrored', () {
      String mirror(List<String> rows) =>
          rows.map((r) => r.split('').reversed.join()).join('/');
      for (final a in StandingTier.values) {
        for (final b in StandingTier.values) {
          if (a == b) continue;
          expect(
              standingGlyphs[a]!.join('/'), isNot(mirror(standingGlyphs[b]!)),
              reason: '${a.name} / ${b.name}');
        }
      }
    });

    testWidgets('each tier draws its own sign', (tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(children: [
          for (final t in StandingTier.values) StandingSign(t, size: 24),
        ]),
      ));
      for (final t in StandingTier.values) {
        expect(find.byKey(Key('standing_sign_${t.name}')), findsOneWidget,
            reason: t.name);
      }
    });
  });

  group('on a banner', () {
    Widget host(PoliticsState politics, Widget child) => ProviderScope(
          overrides: [
            clanDataProvider.overrideWithValue(data),
            politicsProvider.overrideWithValue(politics),
          ],
          child: Directionality(
              textDirection: TextDirection.ltr, child: Center(child: child)),
        );

    testWidgets('a clan wears the disc of its standing', (tester) async {
      const id = 'vigil';
      final politics = PoliticsState.empty.copyWith(
        standings: {...PoliticsState.empty.standings, id: 30},
      );
      await tester.pumpWidget(host(
          politics,
          const ClanMarks(
              factionId: id, child: SizedBox(width: 64, height: 128))));
      expect(find.byKey(const Key('clan_marks_vigil')), findsOneWidget);
      final tier = politics.tierOf(id, data);
      expect(find.byKey(Key('standing_sign_${tier.name}')), findsOneWidget);
      // No power on the banner: that is the rank plate's.
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('a faction not on file keeps its banner as it was',
        (tester) async {
      await tester.pumpWidget(host(
          PoliticsState.empty,
          const ClanMarks(
              factionId: 'nobody',
              child: SizedBox(key: Key('plain'), width: 64, height: 128))));
      expect(find.byKey(const Key('plain')), findsOneWidget);
      expect(find.byType(StandingSign), findsNothing);
    });
  });
}

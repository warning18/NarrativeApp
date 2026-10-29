// A clan at a glance (v1.576): the standing sign has its own disc for each of
// the eleven steps, and a clan's banner wears the sign and the power cloth
// where the offer, the clan card, the ring, the Throne room and the Clans
// list draw it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
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

  group('the power cloth', () {
    test('a quarter of the cloth for each tier', () {
      expect([for (final t in PowerTier.values) powerClothShare(t)],
          [0.25, 0.5, 0.75, 1.0]);
    });

    testWidgets('it darkens above the level, with a hairline unless full',
        (tester) async {
      Future<void> show(PowerTier tier) => tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 64,
                height: 128,
                child: PowerCloth(
                    tier: tier,
                    child: const ColoredBox(color: Color(0xFFAA3333))),
              ),
            ),
          ));
      for (final tier in PowerTier.values) {
        await show(tier);
        expect(find.byKey(Key('power_cloth_${tier.name}')), findsOneWidget);
        // The banner is drawn once, whatever the tier.
        expect(find.byType(ColoredBox), findsWidgets);
        final full = tier == PowerTier.ascendant;
        expect(find.byType(ShaderMask), full ? findsNothing : findsOneWidget,
            reason: tier.name);
        // A hairline marks the level, except when the cloth is full.
        final hair = find.byWidgetPredicate(
            (w) => w is Container && w.color == const Color(0xFFF2C14E));
        expect(hair, full ? findsNothing : findsOneWidget, reason: tier.name);
        if (!full) {
          final top = tester.getTopLeft(hair).dy -
              tester.getTopLeft(find.byType(PowerCloth)).dy;
          expect(top, closeTo(128 * (1 - powerClothShare(tier)), 0.5),
              reason: tier.name);
        }
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

    testWidgets(
        'a clan wears the disc of its standing and the cloth of its power',
        (tester) async {
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
      final power = powerTierFor(powerOf(politics, id, data));
      expect(find.byKey(Key('power_cloth_${power.name}')), findsOneWidget);
    });

    testWidgets('the disc alone when the cloth is not asked for',
        (tester) async {
      await tester.pumpWidget(host(
          PoliticsState.empty,
          const ClanMarks(
              factionId: 'vigil',
              cloth: false,
              child: SizedBox(width: 64, height: 128))));
      expect(find.byType(StandingSign), findsOneWidget);
      expect(find.byType(PowerCloth), findsNothing);
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
      expect(find.byType(PowerCloth), findsNothing);
    });
  });
}

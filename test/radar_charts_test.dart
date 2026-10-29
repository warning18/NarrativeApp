// The radars (v1.224, see widgets/radar_chart.dart and ability_radar.dart):
// the geometry, the elemental points off real items, the abilities as one
// shape with its changes, and the four views of the elements.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/element_points.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/widgets/ability_radar.dart';
import 'package:narrative_data_app/widgets/radar_chart.dart';

String t(String key) => trFor(AppLanguage.en, key);

Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: Center(child: child))),
    );

void main() {
  group('geometry', () {
    test('the first axis is straight up and the rest go clockwise', () {
      const c = Offset(100, 100);
      expect(radarPoint(c, 50, 0, 8).dx, closeTo(100, 1e-9));
      expect(radarPoint(c, 50, 0, 8).dy, closeTo(50, 1e-9));
      expect(radarPoint(c, 50, 2, 8).dx, closeTo(150, 1e-9));
      expect(radarPoint(c, 50, 2, 8).dy, closeTo(100, 1e-9));
      // Opposite axes mirror each other.
      final a = radarPoint(c, 50, 1, 8), b = radarPoint(c, 50, 5, 8);
      expect((a + b).dx / 2, closeTo(100, 1e-9));
      expect((a + b).dy / 2, closeTo(100, 1e-9));
    });

    test('the scale is a round number that fits the highest value', () {
      expect(chartScaleFor(4, floor: 6, step: 3), 6);
      expect(chartScaleFor(7, floor: 6, step: 3), 9);
      expect(chartScaleFor(17, floor: 10, step: 5), 20);
      expect(chartScaleFor(0, floor: 10, step: 5), 10);
    });
  });

  group('elemental points', () {
    final items =
        jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
            as Map<String, dynamic>;

    test('a kit adds up each element\'s damage and resistance', () {
      final kit = elementPointsFor([
        'staff_t6', // fire +3
        'plate_emberproof', // fire resist 3
        'cloak_frostward', // ice resist 3
        'circlet_radiance', // light +3
        'void_banner', // 1 / 1 in six elements
      ], items);
      expect(kit.isEmpty, isFalse);
      expect(kit.damage['Fire'], 4);
      expect(kit.resist['Fire'], 4);
      expect(kit.damage['Light'], 3);
      expect(kit.resist['Light'], 0);
      expect(kit.damage['Ice'], 0);
      expect(kit.resist['Ice'], 3);
      expect(kit.damage['Electricity'], 1);
      expect(kit.highest, 4);
      expect(kit.damageInOrder().length, 8);
      expect(elementChartOrder.first, 'Fire');
      // Opposites sit across.
      expect(elementChartOrder[4], 'Ice');
    });

    test('nothing equipped is empty', () {
      expect(elementPointsFor(const [], items).isEmpty, isTrue);
      expect(elementPointsFor(['no_such_item'], items).isEmpty, isTrue);
    });
  });

  testWidgets('a chart narrower than its size shrinks to fit', (tester) async {
    tester.view.physicalSize = const Size(300, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: AbilityRadar(
            size: 320,
            t: t,
            values: {'strength': 3, 'luck': 5},
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(
        tester.getSize(find.byType(RadarChart)).width, lessThanOrEqualTo(268));
  });

  group('the abilities as one shape', () {
    const values = {
      'strength': 4,
      'dexterity': 4,
      'constitution': 2,
      'intelligence': 2,
      'wisdom': 0,
      'perception': 4,
      'luck': 3,
      'charisma': 0,
    };

    testWidgets('each corner shows its short name and value', (tester) async {
      await tester.pumpWidget(host(const AbilityRadar(values: values, t: t)));
      for (final label in [
        'STR',
        'DEX',
        'CON',
        'INT',
        'WIS',
        'PER',
        'LUCK',
        'CHA'
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('4'), findsNWidgets(3));
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      // Read aloud as a list.
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('Strength 4, Dexterity 4')),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('what changed shows at its corner, with a legend',
        (tester) async {
      // `const` would make 'dexterity' a duplicate key of the const `values`.
      // ignore: prefer_const_constructors
      await tester.pumpWidget(host(AbilityRadar(
        values: {...values, 'dexterity': 5, 'wisdom': 1},
        before: values,
        beforeLabel: 'Before',
        nowLabel: 'Your memories',
        t: t,
      )));
      expect(find.text('+1'), findsNWidgets(2));
      expect(find.text('Before'), findsOneWidget);
      expect(find.text('Your memories'), findsOneWidget);
    });
  });

  group('the elements', () {
    final items =
        jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
            as Map<String, dynamic>;
    final kit = elementPointsFor([
      'staff_t6',
      'plate_emberproof',
      'cloak_frostward',
      'circlet_radiance',
      'void_banner'
    ], items);

    testWidgets('four views of the same points', (tester) async {
      tester.view.physicalSize = const Size(420, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(ElementsCard(points: kit, t: t)));
      expect(find.byKey(const Key('elements_view_0')), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('FIRE'), findsOneWidget);
      expect(find.text('ELEC'), findsOneWidget);
      for (final (label, key) in [
        ('Split', 'elements_view_1'),
        ('Rose', 'elements_view_2'),
        ('Rows', 'elements_view_3'),
        ('Radar', 'elements_view_0'),
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byKey(Key(key)), findsOneWidget, reason: label);
        expect(tester.takeException(), isNull, reason: label);
      }
      await tester.tap(find.text('Rows'));
      await tester.pumpAndSettle();
      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
    });

    testWidgets('nothing equipped says so instead of drawing nothing',
        (tester) async {
      await tester.pumpWidget(host(
          ElementsCard(points: elementPointsFor(const [], const {}), t: t)));
      expect(find.byKey(const Key('elements_empty')), findsOneWidget);
      expect(find.text(t('elements_empty')), findsOneWidget);
      expect(find.byType(SegmentedButton<int>), findsNothing);
    });

    testWidgets('the strings exist in both languages', (tester) async {
      for (final key in [
        'luck_abbrev',
        'cha_abbrev',
        'radar_before_label',
        'radar_memories_label',
        'elements_title',
        'elements_hint',
        'elements_empty',
        'elements_damage',
        'elements_resist',
        'elements_view_radar',
        'elements_view_split',
        'elements_view_rose',
        'elements_view_rows',
      ]) {
        expect(trFor(AppLanguage.en, key), isNotEmpty, reason: key);
        expect(trFor(AppLanguage.fr, key), isNotEmpty, reason: key);
      }
      expect(sqrt(4), 2); // keep dart:math used
    });
  });
}

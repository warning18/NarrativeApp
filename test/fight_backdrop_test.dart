// The place a fight happens in, drawn in code (v1.241): every stage and
// every anomaly paints at any moment, the widget swells an anomaly in as its
// omen turns into the thing, and holds still when animations are off.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/screens/fight_screen.dart'
    show anomalyEffectText, anomalyIcon, anomalyVfxStyle;
import 'package:narrative_data_app/widgets/fight_backdrop.dart';

void _paint(FightStage stage, WeatherKind? sky, String? anomaly, double t,
    double level) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  paintFightBackdrop(canvas, const ui.Size(360, 640),
      stage: stage, sky: sky, anomalyId: anomaly, t: t, level: level);
  recorder.endRecording().dispose();
}

Widget _host(Widget child, {bool still = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: still),
        child: Scaffold(body: SizedBox(width: 360, height: 640, child: child)),
      ),
    );

void main() {
  group('painting', () {
    test('every stage paints under every sky, at any moment', () {
      for (final stage in FightStage.values) {
        for (final sky in [null, ...WeatherKind.values]) {
          for (final t in [0.0, 1.7, 33.3, 1000.0]) {
            _paint(stage, sky, null, t, 0);
          }
        }
      }
    });

    test('every anomaly paints on every stage, at every level', () {
      for (final anomaly in fieldAnomalies) {
        for (final stage in FightStage.values) {
          for (final level in [0.3, 0.65, 1.0]) {
            _paint(stage, WeatherKind.rain, anomaly.id, 12.3 + level, level);
          }
        }
      }
    });

    test('an anomaly nobody drew still paints something calm', () {
      _paint(FightStage.fields, null, 'not_an_anomaly', 3, 1);
    });

    test('an empty canvas paints nothing and does not fail', () {
      final recorder = ui.PictureRecorder();
      paintFightBackdrop(ui.Canvas(recorder), ui.Size.zero,
          stage: FightStage.hall,
          sky: null,
          anomalyId: 'blaze',
          t: 1,
          level: 1);
      recorder.endRecording().dispose();
    });

    test('every stage has its own colours', () {
      final skies = {
        for (final stage in FightStage.values) FightScenery.of(stage).skyTop,
      };
      expect(skies, hasLength(FightStage.values.length));
    });

    test('an anomaly shows as its phase asks', () {
      expect(anomalyLevelOf(AnomalyPhase.quiet), 0);
      expect(anomalyLevelOf(AnomalyPhase.over), 0);
      expect(anomalyLevelOf(AnomalyPhase.omen), inExclusiveRange(0, 1));
      expect(anomalyLevelOf(AnomalyPhase.active), 1);
    });
  });

  group('the widget', () {
    testWidgets('draws a stage and swells an anomaly in over the omen',
        (tester) async {
      final sandstorm = fieldAnomalyById('sandstorm')!;
      await tester.pumpWidget(_host(FightBackdrop(
        stage: FightStage.dunes,
        sky: WeatherKind.dust,
        anomaly: sandstorm,
        phase: AnomalyPhase.omen,
      )));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(_host(FightBackdrop(
        stage: FightStage.dunes,
        sky: WeatherKind.dust,
        anomaly: sandstorm,
        phase: AnomalyPhase.active,
      )));
      await tester.pump(const Duration(seconds: 2));
      // It is the one thing on screen to touch nothing: a painted layer.
      expect(find.byType(FightBackdrop), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('changing the stage, the sky and the anomaly redraws',
        (tester) async {
      await tester.pumpWidget(_host(const FightBackdrop(
        stage: FightStage.fields,
      )));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(_host(FightBackdrop(
        stage: FightStage.hall,
        sky: WeatherKind.snow,
        anomaly: fieldAnomalyById('blaze'),
        phase: AnomalyPhase.active,
      )));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('holds still with animations off, the anomaly in at once',
        (tester) async {
      await tester.pumpWidget(_host(
        FightBackdrop(
          stage: FightStage.snow,
          sky: WeatherKind.snow,
          anomaly: fieldAnomalyById('whiteout'),
          phase: AnomalyPhase.active,
        ),
        still: true,
      ));
      // No ticker is running to draw the next frame.
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('the anomaly\'s words', () {
    test('every anomaly says what it does, in both languages', () {
      for (final anomaly in fieldAnomalies) {
        for (final side in [
          if (anomaly.shared)
            AnomalySide.both
          else ...[AnomalySide.party, AnomalySide.enemies],
        ]) {
          final plan = FieldAnomalyPlan(
              anomaly: anomaly, side: side, onset: 2, rounds: 2);
          for (final lang in AppLanguage.values) {
            final lines = anomalyEffectText(plan, lang);
            expect(lines, isNotEmpty, reason: '${anomaly.id} ${lang.name}');
            for (final line in lines) {
              expect(line, isNotEmpty);
              expect(line, isNot(contains('{')), reason: line);
              expect(line, isNot(contains('anomaly_')), reason: line);
              expect(line, isNot(contains('element_name_')), reason: line);
            }
          }
        }
      }
    });

    test('French keeps its non-breaking space before % and :', () {
      for (final anomaly in fieldAnomalies) {
        final plan = FieldAnomalyPlan(
            anomaly: anomaly,
            side: anomaly.shared ? AnomalySide.both : AnomalySide.party,
            onset: 2,
            rounds: 2);
        for (final line in anomalyEffectText(plan, AppLanguage.fr)) {
          expect(line, isNot(contains(' %')), reason: line);
          expect(line, isNot(contains(' :')), reason: line);
        }
      }
    });

    test('a sandstorm reads as its numbers', () {
      final plan = FieldAnomalyPlan(
          anomaly: fieldAnomalyById('sandstorm')!,
          side: AnomalySide.both,
          onset: 2,
          rounds: 2);
      final lines = anomalyEffectText(plan, AppLanguage.en);
      expect(lines, contains('Wind +25%, Fire +10%, Water −15%'));
      expect(lines, contains('Perception −4'));
      expect(lines.last, contains('3'));
      expect(lines.last, contains('health each round'));
    });

    test('the log lines and omens carry their blanks', () {
      for (final lang in AppLanguage.values) {
        for (final family in AnomalyFamily.values) {
          expect(
              trFor(lang, 'anomaly_omen_${family.name}'), contains('{name}'));
        }
        expect(trFor(lang, 'anomaly_hurts_line'), contains('{who}'));
        expect(trFor(lang, 'anomaly_hurts_line'), contains('{n}'));
        expect(trFor(lang, 'anomaly_mends_line'), contains('{hp}'));
        expect(trFor(lang, 'anomaly_over'), contains('{name}'));
      }
    });

    test('every anomaly has an icon and an effect to play', () {
      for (final anomaly in fieldAnomalies) {
        expect(anomalyIcon(anomaly.family), isA<IconData>());
        expect(anomalyVfxStyle(anomaly), isNotNull);
      }
    });
  });
}

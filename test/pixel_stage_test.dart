// The fight's stages in pixel style (fight_pixel_stage.dart): every stage
// paints at any size, hour and sky; the eight new ones have their names and
// their borrowed anomalies; and open country has a few faces, picked by place.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/context_rules.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/widgets/fight_backdrop.dart';
import 'package:narrative_data_app/widgets/fight_pixel_stage.dart';

void main() {
  test('every stage paints in pixels at any size and any hour', () {
    for (final stage in FightStage.values) {
      for (final size in const [
        ui.Size(360, 640),
        ui.Size(412, 890),
        ui.Size(800, 480),
        ui.Size(120, 60),
      ]) {
        for (final (stars, lit) in const [(0, false), (8, true), (34, true)]) {
          final canvas = ui.Canvas(ui.PictureRecorder());
          paintPixelStage(canvas, size, stage, stars: stars);
          paintPixelLights(canvas, size, stage, lit: lit);
        }
      }
    }
  });

  test('a fight backdrop paints every stage under every sky and light', () {
    for (final stage in FightStage.values) {
      for (final sky in [null, ...WeatherKind.values]) {
        for (final light in const [1.0, 0.75, 0.45, 0.15]) {
          final canvas = ui.Canvas(ui.PictureRecorder());
          paintFightBackdrop(canvas, const ui.Size(360, 640),
              stage: stage,
              sky: sky,
              anomalyId: null,
              t: 3.2,
              level: 0,
              light: light);
        }
      }
    }
  });

  test('the new stages are named in both languages and borrow a kin\'s rules',
      () {
    const added = [
      FightStage.ruins,
      FightStage.woods,
      FightStage.ford,
      FightStage.burntFields,
      FightStage.oasis,
      FightStage.caravanRoad,
      FightStage.quay,
      FightStage.pass,
    ];
    for (final stage in added) {
      for (final lang in AppLanguage.values) {
        expect(
            trFor(lang, 'stage_${stage.name}'), isNot('stage_${stage.name}'));
      }
      expect(added, isNot(contains(stage.kin)), reason: stage.name);
      expect(stage.kin, isNot(stage));
    }
    // An older stage is its own kin, and the place rule follows the kin.
    expect(FightStage.dunes.kin, FightStage.dunes);
    expect(contextRuleFor(stage: FightStage.oasis),
        contextRuleFor(stage: FightStage.dunes));
    expect(contextRuleFor(stage: FightStage.quay),
        contextRuleFor(stage: FightStage.waves));
  });

  group('open country\'s faces', () {
    test('a place keeps its face, and every face turns up somewhere', () {
      for (final place in ['alster', 'alster_vale', 'the_cove']) {
        expect(poolStageOf(FightStage.fields, place),
            poolStageOf(FightStage.fields, place));
      }
      final seen = {
        for (var i = 0; i < 60; i++) poolStageOf(FightStage.fields, 'place_$i'),
      };
      expect(seen, containsAll(temperatePool));
      expect(seen.difference(temperatePool.toSet()), isEmpty);
    });

    test('other stages, and a fight with no place, stay as they are', () {
      for (final stage
          in FightStage.values.where((s) => s != FightStage.fields)) {
        expect(poolStageOf(stage, 'alster'), stage);
      }
      expect(poolStageOf(FightStage.fields, null), FightStage.fields);
      expect(poolStageOf(FightStage.fields, ''), FightStage.fields);
    });
  });
}

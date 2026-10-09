// What the sky does to the play (v1.208, see weather_effects.dart): rain
// and snow dampen fire and feed water, ice and lightning; dust and ash
// feed fire and wind; fog, dust and snow take from the party's read of an
// enemy; bad weather makes the road likelier to hold something; a clear
// or merely cloudy sky changes nothing in a fight; and the day's weather
// is the same all day.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/climate.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/weather_effects.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/providers/climate_provider.dart';

void main() {
  test('rain and snow dampen fire; dust and ash feed it', () {
    expect(WeatherEffects.of(WeatherKind.rain).factorFor('Fire'), 0.7);
    expect(WeatherEffects.of(WeatherKind.snow).factorFor('Fire'), 0.75);
    expect(WeatherEffects.of(WeatherKind.fog).factorFor('Fire'), 0.9);
    expect(WeatherEffects.of(WeatherKind.dust).factorFor('Fire'), 1.15);
    expect(WeatherEffects.of(WeatherKind.ash).factorFor('Fire'), 1.2);
    expect(WeatherEffects.of(WeatherKind.rain).factorFor('Water'), 1.2);
    expect(WeatherEffects.of(WeatherKind.rain).factorFor('Electricity'), 1.2);
    expect(WeatherEffects.of(WeatherKind.snow).factorFor('Ice'), 1.25);
    expect(WeatherEffects.of(WeatherKind.dust).factorFor('Wind'), 1.15);
    // An element the sky says nothing about, and a plain blow, are as
    // they were.
    expect(WeatherEffects.of(WeatherKind.rain).factorFor('Earth'), 1);
    expect(WeatherEffects.of(WeatherKind.rain).factorFor('None'), 1);
  });

  test('a hit is scaled and rounded; nothing scales to nothing', () {
    final rain = WeatherEffects.of(WeatherKind.rain);
    expect(rain.damage(10, 'Fire'), 7);
    expect(rain.damage(9, 'Fire'), 6);
    expect(rain.damage(10, 'Water'), 12);
    expect(rain.damage(10, 'None'), 10);
    expect(rain.damage(0, 'Fire'), 0);
    expect(rain.damage(-3, 'Fire'), -3);
    expect(WeatherEffects.of(WeatherKind.ash).damage(10, 'Fire'), 12);
  });

  test('fog, dust and snow take from the party\'s read', () {
    expect(WeatherEffects.of(WeatherKind.fog).perceptionPenalty, 5);
    expect(WeatherEffects.of(WeatherKind.dust).perceptionPenalty, 3);
    expect(WeatherEffects.of(WeatherKind.ash).perceptionPenalty, 3);
    expect(WeatherEffects.of(WeatherKind.snow).perceptionPenalty, 2);
    expect(WeatherEffects.of(WeatherKind.rain).perceptionPenalty, 1);
    expect(WeatherEffects.of(WeatherKind.clear).perceptionPenalty, 0);
  });

  test('bad weather makes the road likelier to hold something', () {
    expect(WeatherEffects.of(WeatherKind.snow).roadOdds, 1.4);
    expect(WeatherEffects.of(WeatherKind.fog).roadOdds, 1.3);
    expect(WeatherEffects.of(WeatherKind.rain).roadOdds, 1.25);
    expect(WeatherEffects.of(WeatherKind.cloud).roadOdds, 1.05);
    expect(WeatherEffects.of(WeatherKind.clear).roadOdds, 1);
    expect(WeatherEffects.of(null).roadOdds, 1);
  });

  test('a clear or cloudy sky, or none, changes nothing in a fight', () {
    for (final kind in [WeatherKind.clear, WeatherKind.cloud, null]) {
      final effects = WeatherEffects.of(kind);
      expect(effects.touchesFights, isFalse, reason: '$kind');
      expect(effects.effectKey, isNull, reason: '$kind');
      expect(effects.elementTags, isEmpty, reason: '$kind');
      expect(effects.damage(10, 'Fire'), 10, reason: '$kind');
    }
    expect(
        WeatherEffects.of(WeatherKind.rain).effectKey, 'weather_effect_rain');
    expect(WeatherEffects.of(WeatherKind.rain).elementTags,
        containsAll([('Fire', -30), ('Water', 20), ('Electricity', 20)]));
    expect(WeatherEffects.of(WeatherKind.fog).touchesFights, isTrue);
  });

  test('the day\'s weather is the same all day', () {
    final chart = chartOf(MapShape.archipelago);
    final at = chart.of(worldMapLandmarks.firstWhere((l) => l.id == 'beggar'));
    final here = SkyHere(climate: ChartClimate.of(chart), at: at, day: 12);
    final a = here.today();
    final b = here.today();
    expect(a.kind, b.kind);
    expect(a.cloud, b.cloud);
    // Another day may differ; over a season some day surely does.
    final kinds = {
      for (var day = 1; day < 60; day++)
        SkyHere(climate: ChartClimate.of(chart), at: at, day: day).today().kind,
    };
    expect(kinds.length, greaterThan(1));
  });
}

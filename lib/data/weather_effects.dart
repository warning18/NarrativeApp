// What the sky does to the play (v1.208, see climate.dart): rain and snow
// dampen fire and feed water and ice, the dry dust and ash feed fire and
// wind, fog and dust hide what an enemy is about to do, and bad weather
// makes the road likelier to hold something. The day's weather decides,
// not the moment's, so a fight or a road reads the same whenever it is
// looked at that day.
import 'climate.dart';

class WeatherEffects {
  const WeatherEffects._({
    required this.kind,
    required this.factors,
    required this.perceptionPenalty,
    required this.roadOdds,
  });

  final WeatherKind kind;

  /// How much a hit of each element deals, by the element as skills.json
  /// spells it ('Fire', 'Ice', 'Water', 'Electricity', 'Wind'…); 1 for
  /// any element not named.
  final Map<String, double> factors;

  /// Taken off the party's Perception when it reads an enemy's telegraph.
  final int perceptionPenalty;

  /// Multiplies the odds that a road holds an event.
  final double roadOdds;

  static const _none = WeatherEffects._(
      kind: WeatherKind.clear, factors: {}, perceptionPenalty: 0, roadOdds: 1);

  static WeatherEffects of(WeatherKind? kind) => switch (kind) {
        WeatherKind.rain => const WeatherEffects._(
            kind: WeatherKind.rain,
            factors: {'Fire': 0.7, 'Water': 1.2, 'Electricity': 1.2},
            perceptionPenalty: 1,
            roadOdds: 1.25),
        WeatherKind.snow => const WeatherEffects._(
            kind: WeatherKind.snow,
            factors: {'Fire': 0.75, 'Ice': 1.25},
            perceptionPenalty: 2,
            roadOdds: 1.4),
        WeatherKind.fog => const WeatherEffects._(
            kind: WeatherKind.fog,
            factors: {'Fire': 0.9},
            perceptionPenalty: 5,
            roadOdds: 1.3),
        WeatherKind.dust => const WeatherEffects._(
            kind: WeatherKind.dust,
            factors: {'Fire': 1.15, 'Wind': 1.15, 'Water': 0.85},
            perceptionPenalty: 3,
            roadOdds: 1.3),
        WeatherKind.ash => const WeatherEffects._(
            kind: WeatherKind.ash,
            factors: {'Fire': 1.2, 'Wind': 1.1},
            perceptionPenalty: 3,
            roadOdds: 1.2),
        WeatherKind.cloud => const WeatherEffects._(
            kind: WeatherKind.cloud,
            factors: {},
            perceptionPenalty: 0,
            roadOdds: 1.05),
        _ => _none,
      };

  /// Whether this weather changes anything in a fight.
  bool get touchesFights => factors.isNotEmpty || perceptionPenalty > 0;

  double factorFor(String element) => factors[element] ?? 1;

  /// [damage] under this sky for a hit of [element].
  int damage(int damage, String element) {
    final factor = factorFor(element);
    if (factor == 1 || damage <= 0) return damage;
    return (damage * factor).round();
  }

  /// The string key of the line the fight log and the chip read: what this
  /// weather does ('weather_effect_rain'…), or null for nothing.
  String? get effectKey => touchesFights ? 'weather_effect_${kind.name}' : null;

  /// The short tags of the element factors, '−30 % Fire' style, in the
  /// elements' file spelling for the caller to translate.
  List<(String, int)> get elementTags => [
        for (final entry in factors.entries)
          (entry.key, ((entry.value - 1) * 100).round()),
      ];
}

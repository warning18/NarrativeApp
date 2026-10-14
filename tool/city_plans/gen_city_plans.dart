// Lays out the cities' plans (lib/data/city_plan_generator.dart) and
// writes them to assets/gamedata/city_plans.json, keeping the building
// names already there. Run from the repository's root:
//   dart run tool/city_plans/gen_city_plans.dart
import 'dart:convert';
import 'dart:io';

import 'package:narrative_data_app/data/city_plan_generator.dart';

const _out = 'assets/gamedata/city_plans.json';

/// Where each of a city's districts lies on its plan.
const _cities = {
  'saltmouth': (
    seed: 1203,
    districts: [
      DistrictSeed('saltmouth_landward_gate', P(380, 230)),
      DistrictSeed('saltmouth_lantern_alleys', P(570, 240)),
      DistrictSeed('saltmouth_card_row', P(760, 300)),
      DistrictSeed('saltmouth_tern_row', P(330, 520)),
      DistrictSeed('saltmouth_wharf', P(650, 580)),
      DistrictSeed('saltmouth_yard', P(150, 700), outside: true),
    ],
  ),
};

void main() {
  final story =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final file = File(_out);
  final old = file.existsSync()
      ? jsonDecode(file.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};
  final out = <String, Object?>{};
  for (final MapEntry(key: city, value: c) in _cities.entries) {
    final ids = {for (final d in c.districts) d.id};
    final scenes = <String, List<String>>{};
    for (final MapEntry(:key, :value) in story.entries) {
      if (value is! Map) continue;
      final at = value['location']?.toString() ?? '';
      if (ids.contains(at)) (scenes[at] ??= []).add(key);
    }
    final record = generateCityPlan(CityPlanSpec(
      cityId: city,
      seed: c.seed,
      districts: c.districts,
      scenesByDistrict: scenes,
    ));
    // Narrative's names stay.
    record['names'] = (old[city] as Map?)?['names'] ?? <String, Object?>{};
    out[city] = record;
  }
  file.writeAsStringSync(_encode(out));
  stdout.writeln('wrote $_out');
}

/// Indented JSON with every point ([x, y]) kept on one line.
String _encode(Object? value) {
  final text = const JsonEncoder.withIndent('  ').convert(value);
  return '${text.replaceAllMapped(RegExp(r'\[\s+(-?\d+),\s+(-?\d+)\s+\]'), (m) => '[${m[1]}, ${m[2]}]')}\n';
}

// Turns each stored plan in assets/gamedata/city_plans.json so its sea
// lies on its side of the coast (citySeaSides, proposal F), without laying
// the plan out again: the plans keep every hand edit (names, anchors,
// services). gen_city_plans.dart does the same for a plan it lays out
// anew. A plan already on its side is left as it is. Run from the
// repository's root:
//
//   dart run tool/city_plans/turn_city_plans.dart
import 'dart:convert';
import 'dart:io';

import 'city_plan_generator.dart';
import 'town_service_pins.dart';

const String _out = 'assets/gamedata/city_plans.json';

void main() {
  final file = File(_out);
  final plans = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final out = <String, Object?>{
    for (final MapEntry(key: city, value: record) in plans.entries)
      city: turnCityPlan(
          record as Map<String, Object?>, citySeaSides[city] ?? SeaSide.south),
  };
  file.writeAsStringSync(encodeCityPlans(out));
  stdout.writeln('wrote $_out');
}

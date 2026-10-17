// Pins each town's services (the notice board, the market, the tavern, the
// temple, the forge, the harbour) on its stored plan, without laying the
// plan out again: writes each record's `services` in
// assets/gamedata/city_plans.json (see lib/data/town_service_pins.dart).
// gen_city_plans.dart does the same for a plan it lays out anew. Run from
// the repository's root:
//
//   dart run tool/city_plans/place_services.dart
import 'dart:convert';
import 'dart:io';

import 'package:narrative_data_app/data/town_service_pins.dart';

const String _out = 'assets/gamedata/city_plans.json';

void main() {
  final file = File(_out);
  final plans = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  for (final MapEntry(key: city, value: record) in plans.entries) {
    final map = record as Map<String, dynamic>;
    map['services'] = placeTownServices(city, map);
  }
  file.writeAsStringSync(encodeCityPlans(plans));
  stdout.writeln('wrote $_out');
}

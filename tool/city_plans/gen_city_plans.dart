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

/// Where Narrative seats the hub's ways (docs/proposals/city-districts.md
/// on claude/narrative), until the story's scenes carry these districts as
/// their `location`: each way by its scene, and the building its pin stands
/// on (English, French). A way's follow-ups ([_followUps]) stand at its
/// building.
const _seating = <String, List<(String, String, String)>>{
  'saltmouth_landward_gate': [
    ('2015_dominion_blades', 'The customs steps', 'Les marches de la douane'),
    ('2015_kelda', 'The barrel barricade', 'La barricade de tonneaux'),
    ('2015_informant', 'The queue at the gate', 'La file de la porte'),
    (
      '2015_house_salt_ledger',
      'The tithe-clerk’s scales',
      'Les balances du clerc de la dîme'
    ),
    ('2015_bundle', 'The water-barrels', 'Les tonneaux d’eau'),
    ('2015_house_keyholders', 'The unopened door', 'La porte jamais ouverte'),
  ],
  'saltmouth_tern_row': [
    (
      '2015_ternrow',
      'The paper-boat footbridge',
      'La passerelle aux bateaux de papier'
    ),
    (
      '2015_child_tongue',
      'The end of Fisherman’s Row',
      'Le bout de la rue des Pêcheurs'
    ),
    ('2015_survivor', 'The White Fleet bench', 'Le banc de la Flotte blanche'),
    (
      '2015_house_drowned_debt',
      'The debtor’s bollard',
      'La bitte d’amarrage du débiteur'
    ),
    (
      '2015_drawer',
      'The sign-painter’s door',
      'La porte du peintre d’enseignes'
    ),
  ],
  'saltmouth_wharf': [
    ('2015_smuggler', 'The captain’s moorings', 'L’amarrage du capitaine'),
    (
      '2015_dockside',
      'The harbor master’s office',
      'Le bureau du maître de port'
    ),
    ('2015_bandits', 'The bounty door', 'La porte des primes'),
    (
      '2015_route_sold',
      'The Crow tout’s corner',
      'Le coin du rabatteur des Corbeaux'
    ),
    ('2015_rats', 'The spoiled-cargo crate', 'La caisse de cargaison avariée'),
  ],
  'saltmouth_yard': [
    ('2015_dorran', 'The foreman’s scaffold', 'L’échafaudage du contremaître'),
    ('2015_scaffold_clerk', 'The pay strongbox', 'Le coffre de la paie'),
    ('2015_liora', 'The collapsed rooftop', 'Le toit effondré'),
    ('2015_hound', 'The rotting hulk', 'La carcasse pourrie'),
  ],
  'saltmouth_lantern_alleys': [
    ('2015_bazaar', 'The Arcane Bazaar', 'Le Bazar arcanique'),
    ('2015_apothecary', 'Apothecary Row', 'La rue des Apothicaires'),
    ('2015_vess', 'The shadowed turning', 'Le tournant dans l’ombre'),
  ],
  'saltmouth_card_row': [
    ('2015_cards', 'The card barrel', 'Le tonneau de jeu'),
    ('2015_cards_won', 'The winner’s seat', 'La place du gagnant'),
    ('2015_sable', 'The corner table', 'La table du coin'),
  ],
};

const _followUps = <String, String>{
  '2015_informant_exposed': '2015_informant',
  '2015_informant_trap': '2015_informant',
  '2015_informant_caught': '2015_informant',
  '2015_house_keyholders_turned': '2015_house_keyholders',
  '2015_scaffold_clerk_fight': '2015_scaffold_clerk',
  '2015_liora_won': '2015_liora',
  '2015_liora_refused': '2015_liora',
  '2015_cards_lost': '2015_cards',
  '2015_sable_bought': '2015_sable',
  '2015_sable_lifted': '2015_sable',
  '2015_sable_caught': '2015_sable',
  '2015_sable_talk_failed': '2015_sable',
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
    // Each scene where Narrative seats it, else where the story puts it.
    final seatOf = <String, String>{
      for (final MapEntry(key: d, value: ways) in _seating.entries)
        for (final w in ways) w.$1: d,
    };
    for (final MapEntry(key: f, value: lead) in _followUps.entries) {
      if (seatOf[lead] case final d?) seatOf[f] = d;
    }
    final scenes = <String, List<String>>{};
    for (final MapEntry(:key, :value) in story.entries) {
      if (value is! Map) continue;
      final at = seatOf[key] ?? value['location']?.toString() ?? '';
      if (ids.contains(at)) (scenes[at] ??= []).add(key);
    }
    // The seated ways first, in Narrative's order: they take the halls.
    for (final MapEntry(key: d, value: ways) in _seating.entries) {
      final list = scenes[d];
      if (list == null) continue;
      final first = [for (final w in ways) w.$1];
      scenes[d] = [...first, ...list.where((s) => !first.contains(s))];
    }
    final record = generateCityPlan(CityPlanSpec(
      cityId: city,
      seed: c.seed,
      districts: c.districts,
      scenesByDistrict: scenes,
      followUps: _followUps,
    ));
    // Each seated way's building takes Narrative's name; names already in
    // the file (Narrative's own edits) stay over them.
    final anchors = record['anchors'] as Map<String, String>;
    record['names'] = {
      for (final ways in _seating.values)
        for (final (scene, en, fr) in ways)
          if (anchors[scene] case final b?) b: {'en': en, 'fr': fr},
      ...?((old[city] as Map?)?['names'] as Map?),
    };
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

// Lays out the cities' plans (lib/data/city_plan_generator.dart) and
// writes them to assets/gamedata/city_plans.json, keeping the building
// names already there. Run from the repository's root:
//   dart run tool/city_plans/gen_city_plans.dart
import 'dart:convert';
import 'dart:io';

import 'package:narrative_data_app/data/city_plan_generator.dart';

const _out = 'assets/gamedata/city_plans.json';

/// Where each of a city's districts lies on its plan, and what shapes the
/// town (see CityPlanSpec): its shore, river, wall and lots.
final _cities = <String, CityPlanSpec Function(Map<String, List<String>>)>{
  'saltmouth': (scenes) => CityPlanSpec(
        cityId: 'saltmouth',
        seed: 1203,
        districts: const [
          DistrictSeed('saltmouth_landward_gate', P(380, 230)),
          DistrictSeed('saltmouth_lantern_alleys', P(570, 240)),
          DistrictSeed('saltmouth_card_row', P(760, 300)),
          DistrictSeed('saltmouth_tern_row', P(330, 520)),
          DistrictSeed('saltmouth_wharf', P(650, 580)),
          DistrictSeed('saltmouth_yard', P(150, 700), outside: true),
        ],
        scenesByDistrict: scenes,
        followUps: _followUps,
      ),
  // A river city inland: the river through the walls, its island under the
  // stone bridge, the high quay on the east bank.
  'alster': (scenes) => CityPlanSpec(
        cityId: 'alster',
        seed: 2207,
        districts: const [
          DistrictSeed('alster_lower_town', P(250, 520)),
          DistrictSeed('alster_stone_bridge', P(450, 680)),
          DistrictSeed('alster_black_hold', P(720, 260)),
          DistrictSeed('alster_undercroft', P(730, 640)),
          DistrictSeed('alster_high_quay', P(520, 380)),
        ],
        scenesByDistrict: scenes,
        followUps: _autoFollowUps(scenes),
        shoreY: null,
        riverX: 360,
        centre: const P(520, 480),
        wallRadius: 340,
      ),
  // Burned and walled at the Spire's foot: no river, no sea, a third of
  // its lots ash; the stair climbs out of its north side.
  'ashen_quarter': (scenes) => CityPlanSpec(
        cityId: 'ashen_quarter',
        seed: 3011,
        districts: const [
          DistrictSeed('ashen_quarter_gate', P(230, 560)),
          DistrictSeed('ashen_quarter_ash_market', P(500, 520)),
          DistrictSeed('ashen_quarter_wall_of_names', P(770, 520)),
          DistrictSeed('ashen_quarter_cinder_row', P(480, 790)),
          DistrictSeed('ashen_quarter_spire_stair', P(520, 250)),
        ],
        scenesByDistrict: scenes,
        followUps: _autoFollowUps(scenes),
        shoreY: null,
        riverX: null,
        centre: const P(500, 520),
        wallRadius: 340,
        arena: false,
        lotKeep: 0.62,
      ),
  // Flooded, on the fen: black water to the south, a river and long
  // channels cutting into the cloister, no wall; the Mire Court on the
  // fen's edge.
  'drowned_cloister': (scenes) => CityPlanSpec(
        cityId: 'drowned_cloister',
        seed: 5023,
        districts: const [
          DistrictSeed('drowned_cloister_stair', P(520, 170)),
          DistrictSeed('drowned_cloister_nave', P(560, 380)),
          DistrictSeed('drowned_cloister_ossuary', P(790, 360)),
          DistrictSeed('mire_court', P(200, 560), outside: true),
        ],
        scenesByDistrict: scenes,
        followUps: _autoFollowUps(scenes),
        shoreY: 600,
        riverX: 300,
        centre: const P(560, 360),
        wallRadius: 300,
        walled: false,
        arena: false,
        canalXs: const [470, 620, 700, 840],
        canalLength: 200,
        bayDepth: 60,
      ),
  // On the frost road: a walled city on its river, the dead heart where the
  // tear opened at its north end.
  'black_reliquary': (scenes) => CityPlanSpec(
        cityId: 'black_reliquary',
        seed: 6037,
        districts: const [
          DistrictSeed('reliquary_quarter', P(560, 600)),
          DistrictSeed('dead_heart', P(600, 200)),
        ],
        scenesByDistrict: scenes,
        followUps: _autoFollowUps(scenes),
        shoreY: null,
        riverX: 280,
        centre: const P(540, 470),
        wallRadius: 360,
        arena: false,
      ),
  // A shore of beached hulls: an open town above the harbour, the hulls
  // drawn up on the beach outside it.
  'white_anchorage': (scenes) => CityPlanSpec(
        cityId: 'white_anchorage',
        seed: 7109,
        districts: const [
          DistrictSeed('white_anchorage_chapel', P(450, 290)),
          DistrictSeed('white_anchorage_quay', P(640, 470)),
          DistrictSeed('white_anchorage_hulls', P(170, 640), outside: true),
        ],
        scenesByDistrict: scenes,
        followUps: _autoFollowUps(scenes),
        shoreY: 680,
        riverX: null,
        centre: const P(580, 400),
        wallRadius: 300,
        walled: false,
        arena: false,
        canalXs: const [],
      ),
  // On the cliffs: white walls climbing from a deep harbour, no river, no
  // canals in the rock, the Lantern Hall at the top.
  'candlehold': (scenes) => CityPlanSpec(
        cityId: 'candlehold',
        seed: 7507,
        districts: const [
          DistrictSeed('candlehold_gates', P(560, 620)),
          DistrictSeed('candlehold_lantern_hall', P(560, 240)),
        ],
        scenesByDistrict: scenes,
        followUps: _autoFollowUps(scenes),
        shoreY: 820,
        riverX: null,
        centre: const P(560, 440),
        wallRadius: 340,
        arena: false,
        canalXs: const [],
        bayDepth: 130,
      ),
};

/// The words a scene's id ends in when it is how another scene turns out
/// (a fight, a failure, what was found): it stands at that scene's building.
const _outcomes = {
  'fight',
  'failed',
  'lost',
  'won',
  'refused',
  'caught',
  'seen',
  'hammer',
  'breach',
  'dawn',
  'argued',
  'lit',
  'bolt',
  'through',
  'words',
  'hymn',
  'found',
  'searched',
  'talked',
  'bought',
  'lifted',
  'exposed',
  'trap',
  'turned',
  'after',
};

/// The follow-ups of a city laid out from the story alone: a scene whose
/// id is another scene's of the same district plus an outcome word (see
/// [_outcomes]) stands at that scene's building (followed back to the
/// first scene of the chain).
Map<String, String> _autoFollowUps(Map<String, List<String>> scenes) {
  final out = <String, String>{};
  for (final list in scenes.values) {
    final own = list.toSet();
    String? leadOf(String id) {
      final parts = id.split('_');
      if (!_outcomes.contains(parts.last)) return null;
      for (var i = parts.length - 1; i > 1; i--) {
        final lead = parts.sublist(0, i).join('_');
        if (own.contains(lead)) return lead;
      }
      return null;
    }

    for (final id in list) {
      var lead = leadOf(id);
      while (lead != null && leadOf(lead) != null) {
        lead = leadOf(lead);
      }
      if (lead != null) out[id] = lead;
    }
  }
  return out;
}

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
  final geo =
      jsonDecode(File('assets/gamedata/geography.json').readAsStringSync())
          as Map<String, dynamic>;
  final file = File(_out);
  final old = file.existsSync()
      ? jsonDecode(file.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};
  final out = <String, Object?>{};
  for (final MapEntry(key: city, value: specOf) in _cities.entries) {
    final ids = {for (final d in specOf(const {}).districts) d.id};
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
      var at = seatOf[key] ?? value['location']?.toString() ?? '';
      // A place inside a district (a tavern, a cellar) is in that district.
      for (var hops = 0; hops < 8 && !ids.contains(at); hops++) {
        final parent = (geo[at] as Map?)?['parent']?.toString();
        if (parent == null) break;
        at = parent;
      }
      if (ids.contains(at)) (scenes[at] ??= []).add(key);
    }
    // The seated ways first, in Narrative's order: they take the halls.
    for (final MapEntry(key: d, value: ways) in _seating.entries) {
      final list = scenes[d];
      if (list == null) continue;
      final first = [for (final w in ways) w.$1];
      scenes[d] = [...first, ...list.where((s) => !first.contains(s))];
    }
    final record = generateCityPlan(specOf(scenes));
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

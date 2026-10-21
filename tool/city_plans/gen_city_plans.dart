// Lays out the cities' plans (lib/data/city_plan_generator.dart) and
// writes them to assets/gamedata/city_plans.json, keeping the building
// names already there. Run from the repository's root:
//   dart run tool/city_plans/gen_city_plans.dart
import 'dart:convert';
import 'dart:io';

import 'package:narrative_data_app/data/city_plan_generator.dart';
import 'package:narrative_data_app/data/town_service_pins.dart';

const _out = 'assets/gamedata/city_plans.json';

/// Where Narrative seats the scenes of the towns it gave districts to
/// (docs/proposals/town-districts.json, v1.426), by the place the story
/// puts them in now and then by district: a scene still tagged with that
/// place stands in its district here, until the story's own `location`
/// names the district (then the story's wins).
const _seats = 'tool/city_plans/district_seats.json';

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
        // The trainer stands where 891 does (v1.422).
        followUps: {..._autoFollowUps(scenes), '890_trainer': '891'},
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
  // tear opened at its north end, the frost line and the last lit street
  // between it and the quarter, the chapels in the middle.
  'black_reliquary': (scenes) => CityPlanSpec(
        cityId: 'black_reliquary',
        seed: 6037,
        districts: const [
          DistrictSeed('reliquary_quarter', P(560, 680)),
          DistrictSeed('dead_heart', P(600, 180)),
          DistrictSeed('reliquary_last_lantern', P(770, 340)),
          DistrictSeed('reliquary_chapels', P(560, 450)),
          DistrictSeed('reliquary_frost_line', P(420, 290)),
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
  // canals in the rock, the Lantern Hall at the top and the Lantern Cliff
  // behind it. The cliff's seed lies above the hall's, so the Gates keep
  // their shape and their buildings (the rest before the Hall, 7515_rest,
  // stands on 7510_seen's building, candlehold_b003).
  'candlehold': (scenes) => CityPlanSpec(
        cityId: 'candlehold',
        seed: 7507,
        districts: const [
          DistrictSeed('candlehold_gates', P(560, 620)),
          DistrictSeed('candlehold_lantern_hall', P(560, 240)),
          DistrictSeed('candlehold_lantern_cliff', P(620, 120)),
        ],
        scenesByDistrict: scenes,
        followUps: {..._autoFollowUps(scenes), '7515_rest': '7510_seen'},
        shoreY: 820,
        riverX: null,
        centre: const P(560, 440),
        wallRadius: 340,
        arena: false,
        canalXs: const [],
        bayDepth: 130,
      ),
  // The villages, halts and camps (v1.426): small, open, loosely built.
  // A pilgrims' halt on the frost road: no water, half its lots empty, the
  // ridge post above it to the north and the road in from the south.
  'rimewell': (scenes) => _village(
        'rimewell',
        seed: 6101,
        scenes: scenes,
        districts: const [
          DistrictSeed('rimewell_bell_square', P(520, 470)),
          DistrictSeed('rimewell_pilgrims_road', P(440, 650)),
          DistrictSeed('rimewell_ridge_post', P(580, 300)),
          DistrictSeed('rimewell_choir_well', P(340, 420)),
        ],
        lotKeep: 0.8,
      ),
  // A fishing village on the grey shore: the shingle outside it on the
  // beach, the moorings by the water, the watch stones above.
  'greyhithe': (scenes) => _village(
        'greyhithe',
        seed: 7201,
        scenes: scenes,
        districts: const [
          DistrictSeed('greyhithe_net_lofts', P(470, 420)),
          DistrictSeed('greyhithe_watch_stones', P(560, 260)),
          DistrictSeed('greyhithe_moorings', P(640, 560)),
          DistrictSeed('greyhithe_shingle', P(220, 640), outside: true),
        ],
        shoreY: 700,
        bayDepth: 50,
      ),
  // Hull-houses under the cliffs: the quay on the water, the lamp path up
  // the cliff to the north.
  'wracks_end': (scenes) => _village(
        'wracks_end',
        seed: 5101,
        scenes: scenes,
        districts: const [
          DistrictSeed('wracks_end_hull_houses', P(460, 500)),
          DistrictSeed('wracks_end_lamp_path', P(600, 290)),
          DistrictSeed('wracks_end_quay', P(650, 620)),
        ],
        shoreY: 720,
        bayDepth: 70,
      ),
  // The camp on the cove's shingle, behind its palisade: the landing on
  // the beach outside it.
  'cove_camp': (scenes) => _village(
        'cove_camp',
        seed: 1101,
        scenes: scenes,
        districts: const [
          DistrictSeed('cove_camp_fireside', P(500, 450)),
          DistrictSeed('cove_camp_palisade', P(540, 280)),
          DistrictSeed('cove_camp_sail_loft', P(670, 540)),
          DistrictSeed('cove_camp_landing', P(230, 630), outside: true),
        ],
        shoreY: 700,
        walled: true,
        radius: 210,
        lotSpacing: 46,
      ),
  // A green hill in the fen: the fen's water to the south (drawn as the
  // Drowned Cloister's is, a shore), the hall on the hill above it.
  'kindly_hill': (scenes) => _village(
        'kindly_hill',
        seed: 5301,
        scenes: scenes,
        districts: const [
          DistrictSeed('kindly_hill_hall', P(520, 350)),
          DistrictSeed('kindly_hill_fen_edge', P(500, 600)),
        ],
        shoreY: 760,
        bayDepth: 40,
      ),
  // The giants' hold under the Frost Quarry: walled against the frost,
  // its buildings three times the size, the quarry to the north.
  'highhearth': (scenes) => _village(
        'highhearth',
        seed: 6201,
        scenes: scenes,
        districts: const [
          DistrictSeed('highhearth_moot_hall', P(520, 450)),
          DistrictSeed('highhearth_quarry', P(560, 250)),
          DistrictSeed('highhearth_long_houses', P(480, 640)),
        ],
        walled: true,
        radius: 250,
        lotSpacing: 58,
      ),
  // Kilns in a hollow of the slag heaps: no water, a share of its lots
  // slag, the well square in the middle.
  'emberwick': (scenes) => _village(
        'emberwick',
        seed: 4401,
        scenes: scenes,
        districts: const [
          DistrictSeed('emberwick_well_square', P(560, 480)),
          DistrictSeed('emberwick_kilns', P(380, 430)),
          DistrictSeed('emberwick_smithy_lane', P(640, 320)),
        ],
        lotKeep: 0.8,
      ),
  // The oni's terraces above the hot springs: the springs below, the forge
  // terrace at the top.
  'akagiri': (scenes) => _village(
        'akagiri',
        seed: 4701,
        scenes: scenes,
        districts: const [
          DistrictSeed('akagiri_brewhouse', P(480, 450)),
          DistrictSeed('akagiri_springs', P(500, 640)),
          DistrictSeed('akagiri_forge_terrace', P(540, 280)),
        ],
      ),
  // An oasis in the dunes: clay huts round the pool, the caravans' ring
  // round them.
  'white_wells': (scenes) => _village(
        'white_wells',
        seed: 1201,
        scenes: scenes,
        districts: const [
          DistrictSeed('white_wells_pool', P(500, 440)),
          DistrictSeed('white_wells_caravan_ring', P(560, 620)),
        ],
        radius: 200,
        lotKeep: 0.85,
      ),
};

/// A village's plan (CityPlanSpec.village): open (unless [walled], a
/// palisade), inland unless it has a [shoreY], no river, no arena, no
/// canals, on a small footprint ([radius]) with loose lots.
CityPlanSpec _village(
  String id, {
  required int seed,
  required Map<String, List<String>> scenes,
  required List<DistrictSeed> districts,
  double? shoreY,
  double bayDepth = 90,
  bool walled = false,
  double radius = 220,
  double lotSpacing = 42,
  double lotKeep = 1,
}) =>
    CityPlanSpec(
      cityId: id,
      seed: seed,
      districts: districts,
      scenesByDistrict: scenes,
      followUps: _autoFollowUps(scenes),
      shoreY: shoreY,
      riverX: null,
      centre: const P(520, 460),
      wallRadius: radius,
      walled: walled,
      arena: false,
      canalXs: const [],
      bayDepth: bayDepth,
      lotSpacing: lotSpacing,
      lotKeep: lotKeep,
      village: true,
    );

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
  // Lysa's line is spoken at the smuggler's moorings (v1.414).
  '2015_lysa_line': '2015_smuggler',
  // So is the Crows' offer (v1.422).
  '2015_crow_offer': '2015_smuggler',
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
  final seats = <String, Map<String, String>>{
    for (final MapEntry(key: place, value: districts)
        in (jsonDecode(File(_seats).readAsStringSync()) as Map).entries)
      place as String: {
        for (final MapEntry(key: d, value: list) in (districts as Map).entries)
          for (final s in list as List) s as String: d as String,
      },
  };
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
      final location = value['location']?.toString() ?? '';
      var at = seatOf[key] ?? seats[location]?[key] ?? location;
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
    final lots = _joinBuildings(story, geo, anchors);
    record['names'] = {
      for (final ways in _seating.values)
        for (final (scene, en, fr) in ways)
          if (anchors[scene] case final b?) b: {'en': en, 'fr': fr},
      ...?((old[city] as Map?)?['names'] as Map?),
      // A building of the geography is named on its lot as it is there.
      ...lots.named,
    }..removeWhere((b, _) => lots.freed.contains(b));
    // The town's services, pinned on the plan as laid (wave 14).
    record['services'] = placeTownServices(
        city, jsonDecode(jsonEncode(record)) as Map<String, dynamic>);
    out[city] = record;
  }
  file.writeAsStringSync(encodeCityPlans(out));
  stdout.writeln('wrote $_out');
}

/// The scenes inside one building of the geography (a story `location` of
/// level `building`: the Blind Beggar, the family house) stand on one lot,
/// the first of them's in the story's order (the scene-or-map rule,
/// docs/proposals/scene-vs-map-flow.md: a building is one stop). Moves
/// [anchors] in place, after the plan is laid out, so no other scene's lot
/// changes; gives the lots taken the building's names, and the lots left
/// with no scene (`freed`) lose the names they had.
({Map<String, Object> named, Set<String> freed}) _joinBuildings(
    Map<String, dynamic> story,
    Map<String, dynamic> geo,
    Map<String, String> anchors) {
  final lotOf = <String, String>{};
  final named = <String, Object>{};
  final freed = <String>{};
  for (final MapEntry(:key, :value) in story.entries) {
    if (value is! Map) continue;
    final at = value['location']?.toString() ?? '';
    final place = geo[at];
    if (place is! Map || place['level'] != 'building') continue;
    final lot = anchors[key];
    if (lot == null) continue;
    final first = lotOf.putIfAbsent(at, () => lot);
    final name = place['name']?.toString() ?? at;
    named[first] = {'en': name, 'fr': place['name_fr']?.toString() ?? name};
    if (first != lot) {
      freed.add(lot);
      anchors[key] = first;
    }
  }
  freed.removeAll(anchors.values);
  return (named: named, freed: freed);
}

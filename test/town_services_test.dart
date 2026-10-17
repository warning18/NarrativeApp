// A town's services on its plan (wave 14): fixed pins for the notice
// board, the market, the tavern, the temple, the forge and the harbour, on
// a real square or lot of the town's record, and what each opens (a shop, the
// bounty board, a night's rest, a port), from the story.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/town_service_pins.dart';
import 'package:narrative_data_app/data/town_services.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/choice_flow_provider.dart';
import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/town_services_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final rawPlans = _table('city_plans');
  final plans = cityPlanRecordsFrom(rawPlans);
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final geography =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final stops = StoryStops.of(
    story: story,
    geography: geography,
    cityPlans: plans,
    ports: _table('ports'),
  );

  /// The square or the lot of [plan] that [p] stands on: 'square:<kind>' or
  /// 'lot:<kind>', or null.
  String? groundOf(CityPlanRecord plan, Offset p) {
    for (final s in plan.squares) {
      if (pointInPolygonOffsets(p, s.shape)) return 'square:${s.kind}';
    }
    for (final b in plan.buildings) {
      if (pointInPolygonOffsets(p, b.shape)) return 'lot:${b.kind}';
    }
    return null;
  }

  test('every town with a plan pins its services on a square or a lot', () {
    expect(plans, hasLength(greaterThanOrEqualTo(16)));
    for (final plan in plans.values) {
      final city = plan.cityId;
      final kinds = [for (final s in plan.services) s.kind];
      expect(kinds.toSet(), hasLength(kinds.length), reason: city);
      expect(kinds, containsAll(['notice_board', 'market', 'tavern', 'temple']),
          reason: city);
      expect(
          kinds.contains('harbour'), plan.squares.any((s) => s.kind == 'quay'),
          reason: '$city: a harbour where the plan has a quay');
      expect(kinds.contains('forge'), townForgeDistricts.containsKey(city),
          reason: city);
      for (final s in plan.services) {
        final why = '$city ${s.id}';
        expect(s.id, '${city}_${s.kind}', reason: why);
        expect(townServiceKinds, contains(s.kind), reason: why);
        expect(plan.districts.keys, contains(s.district), reason: why);
        expect(plan.districtAt(s.at), s.district, reason: why);
        final ground = groundOf(plan, s.at);
        expect(ground, isNotNull, reason: '$why at ${s.at} is on no lot');
        switch (s.kind) {
          case 'market':
            expect(ground, 'square:market', reason: why);
          case 'harbour':
            expect(ground, 'square:quay', reason: why);
          case 'notice_board':
            expect(ground, anyOf('square:plaza', 'square:market'), reason: why);
          case 'temple':
            expect(ground, 'lot:temple', reason: why);
          case 'forge':
            expect(ground, startsWith('lot:'), reason: why);
            expect(s.district, townForgeDistricts[city], reason: why);
          default:
            expect(ground, startsWith('lot:'), reason: why);
        }
      }
      // Two services never share a lot.
      final spots = {for (final s in plan.services) s.at};
      expect(spots, hasLength(plan.services.length), reason: city);
    }
  });

  test('the stored pins are what the plan lays out', () {
    for (final MapEntry(:key, :value) in rawPlans.entries) {
      final record = value as Map<String, dynamic>;
      expect(jsonEncode(record['services']),
          jsonEncode(placeTownServices(key, record)),
          reason: '$key: run dart run tool/city_plans/place_services.dart');
    }
  });

  test('Saltmouth: shops at the market and the forge, its port, a rest', () {
    final salt = {
      for (final s in townServicesOf(plans['saltmouth']!, stops,
          unlockedShopIds: {'arcane_bazaar'}))
        s.kind: s,
    };
    final market = salt['market']!.opens;
    expect(market.map((o) => o.id),
        containsAll(['arcane_bazaar', 'apothecary_row', 'black_market_docks']));
    expect(market.every((o) => o.action == TownServiceAction.shop), isTrue);
    expect(market.firstWhere((o) => o.id == 'arcane_bazaar').unlocked, isTrue);
    expect(
        market.firstWhere((o) => o.id == 'apothecary_row').unlocked, isFalse);
    expect(salt['forge']!.opens.map((o) => o.id),
        containsAll(['weaponsmith_forge', 'shieldwrights_hall']));
    expect(salt['forge']!.pin.district, 'saltmouth_wharf');
    expect(salt['harbour']!.opens.single, (
      action: TownServiceAction.port,
      id: 'port_smugglers_wharf',
      unlocked: true
    ));
    expect(salt['tavern']!.opens.single.action, TownServiceAction.rest);
    expect(salt['notice_board']!.opens.single.action,
        TownServiceAction.bountyBoard);
    // No temple screen yet.
    expect(salt['temple']!.opens, isEmpty);
    expect(salt['temple']!.opensSomething, isFalse);
  });

  test('a village with no shop: its market and forge open nothing yet', () {
    final ember = {
      for (final s in townServicesOf(plans['emberwick']!, stops)) s.kind: s,
    };
    expect(ember['market']!.opens, isEmpty);
    expect(ember['forge']!.opens, isEmpty);
    expect(ember['forge']!.pin.district, 'emberwick_smithy_lane');
    expect(ember['tavern']!.opensSomething, isTrue);
    // With no story, only the board and the rest open.
    final bare = townServicesOf(plans['saltmouth']!, null);
    expect([
      for (final s in bare)
        if (s.opens.isNotEmpty) s.kind
    ], [
      'notice_board',
      'tavern'
    ]);
  });

  test('the provider gives a town\'s services from the stored plans', () async {
    final container = ProviderContainer(overrides: [
      cityPlanRecordsProvider.overrideWith((ref) async => plans),
      storyStopsProvider.overrideWithValue(stops),
    ]);
    addTearDown(container.dispose);
    expect(container.read(townServicesProvider('saltmouth')), isEmpty);
    await container.read(cityPlanRecordsProvider.future);
    final services = container.read(townServicesProvider('saltmouth'));
    expect(services.map((s) => s.kind), contains('harbour'));
    expect(container.read(townServicesProvider('nowhere')), isEmpty);
    // The saved session loads before the container goes.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
}

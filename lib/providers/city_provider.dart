import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/city_districts.dart';
import '../data/city_plan_record.dart';
import 'geography_provider.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

/// Where the cities' plans are stored (laid out by
/// tool/city_plans/gen_city_plans.dart).
const String cityPlansAssetPath = 'assets/gamedata/city_plans.json';

/// Every city's plan (board 15, see city_plan_record.dart), by city id;
/// empty if the file is missing.
final cityPlanRecordsProvider =
    FutureProvider<Map<String, CityPlanRecord>>((ref) async {
  try {
    final raw = await rootBundle.loadString(cityPlansAssetPath);
    return cityPlanRecordsFrom(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return const {};
  }
});

/// The district the party walked to (free walking, board 15) and the scene
/// it walked from: it holds while the story stays at that scene; the story
/// moving on puts the party where the new scene is.
final walkedDistrictProvider =
    StateProvider<({String nodeId, String districtId})?>((ref) => null);

/// The city the story stands in, when it has districts (its geography id),
/// else null.
final currentCityProvider = Provider<String?>((ref) {
  final geo = ref.watch(geographyProvider);
  final story = ref.watch(storyDataProvider).value;
  final nodeId = ref.watch(storyPlayProvider.select((p) => p.currentNodeId));
  final city = geo.locationOfNode(story?.nodeFor(nodeId));
  if (city == null || districtsOfCity(geo, city.id).isEmpty) return null;
  return city.id;
});

/// The district the party stands in: the one it walked to from this scene,
/// else the scene's own; null outside a city with districts.
final partyDistrictProvider = Provider<String?>((ref) {
  final geo = ref.watch(geographyProvider);
  final story = ref.watch(storyDataProvider).value;
  final nodeId = ref.watch(storyPlayProvider.select((p) => p.currentNodeId));
  final city = ref.watch(currentCityProvider);
  if (city == null) return null;
  final walked = ref.watch(walkedDistrictProvider);
  if (walked != null &&
      walked.nodeId == nodeId &&
      geo.locationOf(walked.districtId)?.id == city) {
    return walked.districtId;
  }
  return districtOfNode(geo, story?.nodeFor(nodeId))?.id;
});

/// The districts of the party's city it has found (see foundDistricts);
/// the rest are fogged. Empty outside a city with districts.
final foundDistrictsProvider = Provider<Set<String>>((ref) {
  final city = ref.watch(currentCityProvider);
  final story = ref.watch(storyDataProvider).value;
  if (city == null || story == null) return const {};
  final play = ref.watch(storyPlayProvider);
  return foundDistricts(
    ref.watch(geographyProvider),
    story,
    cityId: city,
    visitedNodeIds: play.visitedNodeIds,
    currentNodeId: play.currentNodeId,
    flags: ref.watch(playerSessionProvider.select((s) => s.flags)),
  );
});

/// The ways of the scene the story is at that lead into the party's
/// district (indices into its choices, see waysInDistrict); every way
/// outside a city with districts.
final partyDistrictWaysProvider = Provider<List<int>>((ref) {
  final story = ref.watch(storyDataProvider).value;
  final nodeId = ref.watch(storyPlayProvider.select((p) => p.currentNodeId));
  final node = story?.nodeFor(nodeId);
  if (node == null) return const [];
  final district = ref.watch(partyDistrictProvider);
  if (district == null) {
    return [for (var i = 0; i < node.choices.length; i++) i];
  }
  return waysInDistrict(ref.watch(geographyProvider), story!, node, district);
});

/// Free walking (board 15): the party walks to [districtId] of the city it
/// is in, with no story choice, no time and no road. A district not found
/// yet is found by walking in (and stays found, see districtFoundFlag).
/// Nothing happens for a district of another city.
Future<void> walkToDistrict(WidgetRef ref, String districtId) async {
  final city = ref.read(currentCityProvider);
  final geo = ref.read(geographyProvider);
  if (city == null || geo.locationOf(districtId)?.id != city) return;
  final nodeId = ref.read(storyPlayProvider).currentNodeId;
  ref.read(walkedDistrictProvider.notifier).state =
      (nodeId: nodeId, districtId: districtId);
  final flag = districtFoundFlag(districtId);
  if (!ref.read(playerSessionProvider).flags.contains(flag)) {
    await ref
        .read(playerSessionProvider.notifier)
        .applyChoiceEffects(flagsToAdd: [flag], goldIsProfit: false);
  }
}

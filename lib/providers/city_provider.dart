import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/city_districts.dart';
import '../data/city_plan_record.dart';
import '../data/way_places.dart';
import 'choice_flow_provider.dart';
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
    completedQuestIds:
        ref.watch(playerSessionProvider.select((s) => s.completedQuestIds)),
  );
});

/// The locked districts of the party's city (wave 18, see districtLocked):
/// shown on the plan with their lock and lockedText, never found, never
/// walked into. Empty outside a city with districts.
final lockedDistrictsProvider = Provider<Set<String>>((ref) {
  final city = ref.watch(currentCityProvider);
  if (city == null) return const {};
  return lockedDistrictsOf(
    ref.watch(geographyProvider),
    city,
    ref.watch(playerSessionProvider.select((s) => s.flags)),
    ref.watch(playerSessionProvider.select((s) => s.completedQuestIds)),
  ).toSet();
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

/// The districts the party can walk into from its own (see
/// CityPlanRecord.neighboursOf): the Journey offers a walk to each when no
/// way of the scene stands in the party's district. Empty outside a city
/// with a stored plan.
final partyDistrictNeighboursProvider = Provider<List<String>>((ref) {
  final city = ref.watch(currentCityProvider);
  final here = ref.watch(partyDistrictProvider);
  if (city == null || here == null) return const [];
  final record = ref.watch(cityPlanRecordsProvider).value?[city];
  // A locked district (wave 18) is no way to walk: its open neighbours, or
  // the nearest open district when all of them are locked.
  return record?.walkableFrom(here, ref.watch(lockedDistrictsProvider)) ??
      const [];
});

/// Free walking (board 15): the party walks to [districtId] of the city it
/// is in, with no story choice, no time and no road. A district not found
/// yet is found by walking in (and stays found, see districtFoundFlag).
/// Nothing happens for a district of another city, or a locked one (wave
/// 18, see districtLocked). Returns whether the party walked.
Future<bool> walkToDistrict(WidgetRef ref, String districtId) async {
  final city = ref.read(currentCityProvider);
  final geo = ref.read(geographyProvider);
  if (city == null || geo.locationOf(districtId)?.id != city) return false;
  final session = ref.read(playerSessionProvider);
  if (districtLocked(
      geo, districtId, session.flags, session.completedQuestIds)) {
    return false;
  }
  final nodeId = ref.read(storyPlayProvider).currentNodeId;
  ref.read(walkedDistrictProvider.notifier).state =
      (nodeId: nodeId, districtId: districtId);
  final flag = districtFoundFlag(districtId);
  if (!ref.read(playerSessionProvider).flags.contains(flag)) {
    await ref
        .read(playerSessionProvider.notifier)
        .applyChoiceEffects(flagsToAdd: [flag], goldIsProfit: false);
  }
  return true;
}

/// The place of the district the party stands at (v1.580, see
/// way_places.dart): picked from the district's list and walked to, it
/// holds while the story stays at that scene and the party in that
/// district; the story moving on, or a walk to another district, puts the
/// party back at the list. Not saved: a game picked back up opens on the
/// list of places.
final standingAtPlaceProvider =
    StateProvider<({String nodeId, String districtId, String placeId})?>(
        (ref) => null);

/// The id of the place (WayPlace.id) the party stands at in its district
/// (see [standingAtPlaceProvider]), or null when it is at the list.
final partyPlaceProvider = Provider<String?>((ref) {
  final standing = ref.watch(standingAtPlaceProvider);
  if (standing == null) return null;
  final nodeId = ref.watch(storyPlayProvider.select((p) => p.currentNodeId));
  final district = ref.watch(partyDistrictProvider);
  if (standing.nodeId != nodeId || standing.districtId != district) {
    return null;
  }
  return standing.placeId;
});

/// The party walks to the place [placeId] of its district (the list's
/// entry, see way_places.dart): no story choice, no time. Nothing happens
/// outside a city with districts.
void standAtPlace(WidgetRef ref, String placeId) {
  final district = ref.read(partyDistrictProvider);
  if (district == null) return;
  ref.read(standingAtPlaceProvider.notifier).state = (
    nodeId: ref.read(storyPlayProvider).currentNodeId,
    districtId: district,
    placeId: placeId,
  );
}

/// The party back at the district's list of places.
void leavePlace(WidgetRef ref) =>
    ref.read(standingAtPlaceProvider.notifier).state = null;

/// The list under the district's map (v1.580, see districtPlaces): the
/// scene's ways in the party's district, one entry per place, `here`
/// first. Empty outside a city with a stored plan.
final districtPlacesProvider = Provider<List<WayPlaceEntry>>((ref) {
  final city = ref.watch(currentCityProvider);
  final district = ref.watch(partyDistrictProvider);
  if (city == null || district == null) return const [];
  final record = ref.watch(cityPlanRecordsProvider).value?[city];
  final story = ref.watch(storyDataProvider).value;
  final nodeId = ref.watch(storyPlayProvider.select((p) => p.currentNodeId));
  final node = story?.nodeFor(nodeId);
  if (record == null || node == null) return const [];
  final geo = ref.watch(geographyProvider);
  final session = ref.watch(playerSessionProvider);
  return districtPlaces(
    node,
    story: story!,
    geography: geo,
    record: record,
    stops: ref.watch(storyStopsProvider),
    ways: ref.watch(partyDistrictWaysProvider),
    lockedWays:
        lockedWays(geo, story, node, session.flags, session.completedQuestIds)
            .toSet(),
  );
});

/// A party arriving in a district (v1.580): the district, and how many
/// arrivals came before it ([count] tells two arrivals in the same district
/// apart). The district view's camera eases in on one (see city_camera.dart).
typedef DistrictArrival = ({String districtId, int count});

/// The party's last arrival in a district: a new value each time
/// [partyDistrictProvider] changes to a district (a walk, the story moving
/// the party, a city entered), the first district the party stands in
/// counting as one. Walking between the places of a district is no arrival.
final districtArrivalProvider =
    NotifierProvider<DistrictArrivalNotifier, DistrictArrival?>(
        DistrictArrivalNotifier.new);

class DistrictArrivalNotifier extends Notifier<DistrictArrival?> {
  @override
  DistrictArrival? build() {
    ref.listen<String?>(partyDistrictProvider, (previous, next) {
      if (next == null || next == previous) return;
      state = (districtId: next, count: (state?.count ?? 0) + 1);
    });
    final here = ref.read(partyDistrictProvider);
    return here == null ? null : (districtId: here, count: 1);
  }
}

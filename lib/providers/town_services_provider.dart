import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/town_services.dart';
import 'choice_flow_provider.dart';
import 'city_provider.dart';
import 'player_session_provider.dart';

/// The services of the town [cityId] (a city_plans.json id), each with its
/// pin on the plan and what it opens (see town_services.dart); empty for a
/// town with no plan, or before the plans load.
final townServicesProvider =
    Provider.family<List<TownService>, String>((ref, cityId) {
  final record = ref.watch(cityPlanRecordsProvider).value?[cityId];
  if (record == null) return const [];
  final unlocked = ref
      .watch(playerSessionProvider.select((s) => s.unlockedShopIds.join('|')));
  return townServicesOf(
    record,
    ref.watch(storyStopsProvider),
    unlockedShopIds: unlocked.isEmpty ? const {} : unlocked.split('|').toSet(),
  );
});

/// The services of the town the story stands in (currentCityProvider);
/// empty outside a town with a plan.
final currentTownServicesProvider = Provider<List<TownService>>((ref) {
  final city = ref.watch(currentCityProvider);
  return city == null ? const [] : ref.watch(townServicesProvider(city));
});

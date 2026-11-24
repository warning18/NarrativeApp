// Who holds a region (the world map's Clans layer tints a whole region in
// its holder's colour): the clans holding the places in it (holdings,
// clan_power.dart), strongest first, each with its share against the
// strongest (1 for it; 1 for a second clan holding as many: contested).
//
// The same shape as ChartZone.influence (map_charts.dart), so a layer that
// reads one reads the other: tinted by the first, striped by a second at
// 0.45 or more.
import 'clan_power.dart' show holdings;
import 'factions.dart' show PoliticsState;
import 'geography.dart';
import 'map_charts.dart';

/// A region's holders: (clan id, share), strongest first; empty when no
/// clan holds a place in it.
typedef RegionHolders = List<(String, double)>;

RegionHolders _rank(Map<String, int> counts, List<String> order) {
  if (counts.isEmpty) return const [];
  final clans = counts.keys.toList()
    ..sort((a, b) => counts[a] != counts[b]
        ? counts[b]!.compareTo(counts[a]!)
        : order.indexOf(a).compareTo(order.indexOf(b)));
  final top = counts[clans.first]!;
  return [for (final c in clans) (c, counts[c]! / top)];
}

/// The [RegionHolders] of each of [chart]'s zones (its lands), in
/// [ChartGeography.zones]' order: a held place counts in the zone its
/// location (the city or town it is in) stands in on [chart]. A place
/// whose location [chart] doesn't show counts nowhere.
List<RegionHolders> chartZoneHolders(
    ChartGeography chart, Geography geography, PoliticsState politics) {
  final held = holdings(geography, politics);
  final order = held.values.toSet().toList();
  final counts = [for (final _ in chart.zones) <String, int>{}];
  for (final e in held.entries) {
    final at = chart.places[geography.locationOf(e.key)?.id];
    if (at == null) continue;
    final i = chart.zones.indexWhere((z) => pointInPolygon(at, z.polygon));
    if (i < 0) continue;
    counts[i][e.value] = (counts[i][e.value] ?? 0) + 1;
  }
  return [for (final c in counts) _rank(c, order)];
}

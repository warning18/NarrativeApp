// A town changing hands (wave 16, item 4): the world chart remembers who
// ruled each town when the player last looked (the save's seenTownRulers);
// a town whose ruler is another now has changed hands since, and the chart
// fades its tint to the new colour and says so in a toast. Pure parts here;
// journey_world_map.dart draws the fade and shows the toast.
import '../data/town_rulers.dart';

/// One town that changed hands: [fromClan] ruled it when last seen, [toClan]
/// rules it now ('' for no one).
class TownHandover {
  const TownHandover(this.townId, this.fromClan, this.toClan);

  final String townId;
  final String fromClan;
  final String toClan;

  @override
  String toString() => 'TownHandover($townId: $fromClan -> $toClan)';
}

/// Who rules each town of [rulers] (town id -> clan id, '' for no one); the
/// districts are left out.
Map<String, String> townRulerIds(Map<String, TownRuler> rulers) => {
      for (final e in rulers.entries)
        if (!e.value.isDistrict) e.key: e.value.clanId,
    };

/// The towns of [rulers] whose ruler is not the one in [seen]. A save that
/// has seen none (an old save, or the first look) has nothing changed, and
/// a town it never saw has not changed hands either.
List<TownHandover> townHandovers(
    Map<String, String> seen, Map<String, TownRuler> rulers) {
  if (seen.isEmpty) return const [];
  return [
    for (final e in townRulerIds(rulers).entries)
      if (seen.containsKey(e.key) && seen[e.key] != e.value)
        TownHandover(e.key, seen[e.key]!, e.value),
  ];
}

/// The colours a town takes while it fades from [fromClan]'s to its new
/// ruler's: the old clan's fill and its darker outline; null when the old
/// ruler was no one (the tint fades in from nothing).
({int fill, int accent})? handoverFromColours(
    TownHandover handover, Map<String, int> clanColours) {
  if (handover.fromClan.isEmpty) return null;
  final fill = clanColours[handover.fromClan];
  if (fill == null) return null;
  return (fill: fill, accent: shadeColor(fill));
}

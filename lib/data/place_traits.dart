// What a place is like, beyond where it is and what grows there (v1.242):
// how dangerous, in what light, held by whom, of what kind, and how long a
// walk to it takes -- the fields geography.json gives a place (see
// GeoPlace) and the few rules that read them. Pure numbers: the screens ask
// the Geography for the values and these turn them into odds.

/// How much likelier or rarer the roads to a place of [danger] are to hold
/// an event: a safe camp is quiet, a deadly pit is not.
double dangerRoadFactor(int danger) => switch (danger) {
      <= 0 => 0.5,
      1 => 1.0,
      2 => 1.3,
      _ => 1.6,
    };

/// How much likelier or rarer a fight in a place of [danger] is to meet a
/// ground anomaly (see field_anomaly.dart).
double dangerAnomalyFactor(int danger) => switch (danger) {
      <= 0 => 0.5,
      1 => 1.0,
      2 => 1.3,
      _ => 1.7,
    };

/// How much of the day's light is left in a place lit as [light] ('day',
/// 'dusk', 'night', 'dark', or '' for the day's): 1 is full day, 0 pitch
/// dark. The backdrop dims by what is missing.
double lightLevel(String light) => switch (light) {
      'dusk' => 0.75,
      'night' => 0.45,
      'dark' => 0.15,
      _ => 1.0,
    };

/// [shopFaction] is the faction a shop belongs to ('' for none): the shop's
/// own, else the faction that holds the place the party is at ([heldBy],
/// '' for none written), so a faction's grip on a district shows in what its
/// shops ask.
String shopFactionHere(String shopFaction, String heldBy) =>
    shopFaction.isNotEmpty ? shopFaction : heldBy;

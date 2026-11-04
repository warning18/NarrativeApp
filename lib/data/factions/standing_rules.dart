part of '../factions.dart';

// The standing rules: allies and rivals, applyStandingChange with its
// ripple and banner, loyalty's price, and the Edit Mode and claim setters.

// --- The rules ------------------------------------------------------------

/// [factionId]'s allies now: every faction it stands with on step
/// [_allyMinStep] or above (Trade, Allies), in the data's order.
List<String> alliesOf(String factionId, PoliticsState state, ClanData data) =>
    _related(factionId, state, data, (step) => step >= _allyMinStep);

/// [factionId]'s rivals now: every faction it stands with on step
/// [_rivalMaxStep] or below (Blood feud, War, Hostile).
List<String> rivalsOf(String factionId, PoliticsState state, ClanData data) =>
    _related(factionId, state, data, (step) => step <= _rivalMaxStep);

List<String> _related(String factionId, PoliticsState state, ClanData data,
    bool Function(int step) matches) {
  final others = <String>{
    for (final p in data.relations.pairs)
      if (p.a == factionId) p.b else if (p.b == factionId) p.a,
    for (final key in state.relationSteps.keys)
      if (key.split('|').contains(factionId))
        key.split('|').firstWhere((id) => id != factionId, orElse: () => ''),
  }..remove('');
  final ordered = [
    for (final id in data.factions.keys)
      if (others.contains(id)) id,
    for (final id in others)
      if (!data.factions.containsKey(id)) id,
  ];
  return [
    for (final other in ordered)
      if (other != factionId &&
          matches(state.relationStep(factionId, other, data) ?? 4))
        other,
  ];
}

/// What [applyStandingChange] (or another rule) did: the [state] after,
/// every faction's change in [deltas], and the [entry] it logged (null
/// when nothing moved).
class StandingResult {
  const StandingResult({
    required this.state,
    this.deltas = const {},
    this.entry,
  });

  final PoliticsState state;
  final Map<String, double> deltas;
  final StandingLogEntry? entry;

  bool get changed => entry != null;

  /// The faction the character became sworn to by it, '' for none.
  String get swore => entry?.swore ?? '';

  /// The faction it stopped being sworn to, '' for none.
  String get released => entry?.released ?? '';
}

double _clampStanding(double value) =>
    value.clamp(minStanding.toDouble(), maxStanding.toDouble());

bool _swornLevel(double value) => standingTierFor(value) == StandingTier.sworn;

/// Whether [factionId] may ever be the sworn faction: only a clan (the
/// Dominion and the five clans) can. The Choir, the Pit and the tribes
/// never are, and never stand past [swornOthersCap] (see [_applyBanner]).
bool canBeSworn(String factionId, ClanData data) =>
    data.faction(factionId)?.isClan ?? false;

/// The banner's rules over [values] (standing by faction, every faction of
/// [data] in it), with [sworn] the faction sworn before the change (''
/// for none) and [preferred] the one the change was made with:
/// - only a clan can be sworn (see [canBeSworn]): any other faction stops
///   at [swornOthersCap], so it never reaches the Sworn tier;
/// - the sworn faction falling under [swornThreshold] is released;
/// - with none sworn, one reaching it is sworn (the [preferred] one
///   first, then the highest), and costs each of its rivals
///   [_swornRivalCost] ([chargeRivals]);
/// - while one is sworn, its rivals stop at [swornRivalCap] and every
///   other faction at [swornOthersCap].
/// Returns the faction sworn after, and those sworn and released.
({String sworn, String swore, String released}) _applyBanner(
  Map<String, double> values, {
  required String sworn,
  required String preferred,
  required PoliticsState state,
  required ClanData data,
  bool chargeRivals = true,
}) {
  var current = sworn;
  var swore = '';
  var released = '';
  for (final id in values.keys.toList()) {
    if (!canBeSworn(id, data) && values[id]! > swornOthersCap) {
      values[id] = swornOthersCap.toDouble();
    }
  }
  if (current.isNotEmpty &&
      (!values.containsKey(current) ||
          !canBeSworn(current, data) ||
          !_swornLevel(values[current]!))) {
    released = current;
    current = '';
  }
  // Of a fallen clan (clan_crisis.dart), no new oath until a banner of
  // one's own.
  if (current.isEmpty && state.fallenOf.isEmpty) {
    final candidates = [
      for (final e in values.entries)
        if (canBeSworn(e.key, data) && _swornLevel(e.value)) e.key,
    ];
    if (candidates.isNotEmpty) {
      current = candidates.contains(preferred)
          ? preferred
          : (candidates
                ..sort((x, y) {
                  final byValue = values[y]!.compareTo(values[x]!);
                  return byValue != 0 ? byValue : x.compareTo(y);
                }))
              .first;
      swore = current;
      if (chargeRivals) {
        for (final rival in rivalsOf(current, state, data)) {
          if (!values.containsKey(rival)) continue;
          values[rival] = _clampStanding(values[rival]! - _swornRivalCost);
        }
      }
    }
  }
  if (current.isNotEmpty) {
    final rivals = rivalsOf(current, state, data).toSet();
    for (final id in values.keys.toList()) {
      if (id == current) continue;
      final cap = rivals.contains(id) ? swornRivalCap : swornOthersCap;
      if (values[id]! > cap) values[id] = cap.toDouble();
    }
  }
  return (sworn: current, swore: swore, released: released);
}

/// [state] with [values] (every faction's standing) kept where they
/// differ from [before], logged as one entry when anything moved.
StandingResult _commit(
  PoliticsState state,
  Map<String, double> before,
  Map<String, double> values, {
  required String sworn,
  required String swore,
  required String released,
  required String factionId,
  required String cause,
  required int chapter,
  required int day,
}) {
  final deltas = <String, double>{};
  final after = <String, double>{};
  final standings = {...state.standings};
  for (final id in values.keys) {
    final old = before[id]!;
    final now = _tidy(values[id]!);
    if (_same(old, now)) continue;
    deltas[id] = _tidy(now - old);
    after[id] = now;
    standings[id] = now;
  }
  if (deltas.isEmpty && swore.isEmpty && released.isEmpty) {
    return StandingResult(state: state);
  }
  final entry = StandingLogEntry(
    chapter: chapter,
    day: day,
    cause: cause,
    factionId: factionId,
    deltas: deltas,
    after: after,
    swore: swore,
    released: released,
  );
  return StandingResult(
    state: state.copyWith(
      standings: standings,
      swornFactionId: sworn,
      standingLog:
          _appendCapped(state.standingLog, entry, maxStandingLogEntries),
    ),
    deltas: deltas,
    entry: entry,
  );
}

/// [state] with [entry] logged (a line that moves no standing: the
/// patron's gifts, see patron_stats.dart).
PoliticsState withStandingLogEntry(
        PoliticsState state, StandingLogEntry entry) =>
    state.copyWith(
        standingLog:
            _appendCapped(state.standingLog, entry, maxStandingLogEntries));

List<T> _appendCapped<T>(List<T> list, T entry, int cap) {
  final next = [...list, entry];
  return next.length <= cap ? next : next.sublist(next.length - cap);
}

Map<String, double> _allStandings(PoliticsState state, ClanData data) => {
      for (final id in data.factions.keys) id: state.standingOf(id, data),
    };

/// Moves standing with [factionId] by [delta], for [cause] (see
/// [standingCauseLabel]), on [chapter]'s [day]:
/// - **the ripple:** each of its allies ([alliesOf]) moves by a quarter
///   of [delta], gain or loss; on a gain, each of its rivals ([rivalsOf])
///   loses half of it; on a loss, the rivals don't move;
/// - **the banner:** reaching [swornThreshold] with no faction sworn
///   swears the character to it, which costs each of its rivals
///   [_swornRivalCost]; while it is sworn its rivals stop at
///   [swornRivalCap] and every other faction at [swornOthersCap]; falling
///   under the threshold releases them;
/// - every standing stays within [minStanding]..[maxStanding].
///
/// Relations are read as they stand now, so the same gift can cost more
/// in a later chapter. Returns the state after, each faction's change and
/// the log entry (none, and the state unchanged, when nothing moved or
/// [factionId] is no faction of [data]).
StandingResult applyStandingChange(
  PoliticsState state,
  String factionId,
  num delta,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (delta == 0 ||
      !data.factions.containsKey(factionId) ||
      data.factions[factionId]!.isLost) {
    return StandingResult(state: state);
  }
  final before = _allStandings(state, data);
  final values = {...before};
  final change = delta.toDouble();
  void move(String id, double by) {
    if (!values.containsKey(id)) return;
    values[id] = _clampStanding(values[id]! + by);
  }

  move(factionId, change);
  for (final ally in alliesOf(factionId, state, data)) {
    move(ally, change * _allyRippleShare);
  }
  if (change > 0) {
    for (final rival in rivalsOf(factionId, state, data)) {
      move(rival, -change * _rivalRippleShare);
    }
  }
  final banner = _applyBanner(values,
      sworn: state.swornFactionId,
      preferred: factionId,
      state: state,
      data: data);
  return _commit(state, before, values,
      sworn: banner.sworn,
      swore: banner.swore,
      released: banner.released,
      factionId: factionId,
      cause: cause,
      chapter: chapter,
      day: day);
}

// --- Loyalty's price (v5.2 step 3) ------------------------------------------

/// The relation step of two factions that are tense: neither rivals nor
/// allies, but not at peace either (Tense).
const int _tenseStep = 4;

/// What each new chapter costs a patron's neighbours (see
/// [applyLoyaltyDrift]): its rivals while you are Trusted with it; its
/// rivals, its tense neighbours and (a gain) its allies while you are
/// sworn to it.
const int trustedRivalDrift = -2;
const int swornRivalDrift = -4;
const int swornTenseDrift = -2;
const int swornAllyDrift = 1;

/// [factionId]'s tense neighbours now: every faction it stands with on
/// [_tenseStep].
List<String> tenseWith(String factionId, PoliticsState state, ClanData data) =>
    _related(factionId, state, data, (step) => step == _tenseStep);

/// The clan the character is loyal to, whose favour cools its rivals: the
/// sworn one, else the clan stood highest with at Trusted or above (the
/// first in the data on a tie); '' for none.
String loyaltyPatron(PoliticsState state, ClanData data) {
  if (state.swornFactionId.isNotEmpty) return state.swornFactionId;
  var best = '';
  var bestValue = double.negativeInfinity;
  for (final id in data.factions.keys) {
    if (!canBeSworn(id, data)) continue;
    final value = state.standingOf(id, data);
    if (!standingTierFor(value).isAtLeast(StandingTier.trusted)) continue;
    if (value > bestValue) {
      best = id;
      bestValue = value;
    }
  }
  return best;
}

/// What a new chapter's drift ([applyLoyaltyDrift]) moves, by faction:
/// - the patron ([loyaltyPatron]) at Trusted: its rivals
///   [trustedRivalDrift];
/// - sworn to it: its rivals [swornRivalDrift], its tense neighbours
///   [swornTenseDrift], its allies [swornAllyDrift];
/// - none, or Friend and below: nothing.
Map<String, int> loyaltyDrift(PoliticsState state, ClanData data) {
  final patron = loyaltyPatron(state, data);
  if (patron.isEmpty) return const {};
  final sworn = state.isSworn(patron);
  bool counts(String id) =>
      id != patron &&
      data.factions.containsKey(id) &&
      !data.factions[id]!.isLost;
  return {
    for (final id in rivalsOf(patron, state, data))
      if (counts(id)) id: sworn ? swornRivalDrift : trustedRivalDrift,
    if (sworn) ...{
      for (final id in tenseWith(patron, state, data))
        if (counts(id)) id: swornTenseDrift,
      for (final id in alliesOf(patron, state, data))
        if (counts(id)) id: swornAllyDrift,
    },
  };
}

/// A new chapter's price of loyalty: [loyaltyDrift] applied, with no
/// ripple, logged as `loyalty:<patron>` on [chapter]'s [day]. The banner's
/// caps still hold. Nothing moves (and nothing is logged) without a
/// patron at Trusted or above.
StandingResult applyLoyaltyDrift(
  PoliticsState state, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  final drift = loyaltyDrift(state, data);
  if (drift.isEmpty) return StandingResult(state: state);
  final patron = loyaltyPatron(state, data);
  final before = _allStandings(state, data);
  final values = {...before};
  for (final MapEntry(:key, :value) in drift.entries) {
    if (!values.containsKey(key)) continue;
    values[key] = _clampStanding(values[key]! + value);
  }
  final banner = _applyBanner(values,
      sworn: state.swornFactionId,
      preferred: patron,
      state: state,
      data: data,
      chargeRivals: false);
  return _commit(state, before, values,
      sworn: banner.sworn,
      swore: banner.swore,
      released: banner.released,
      factionId: patron,
      cause: 'loyalty:$patron',
      chapter: chapter,
      day: day);
}

/// What [applyStandingChange] would move, faction by faction, without
/// doing it: an offer card's "+6 Compact · +1.5 Mire · −3 Penitents".
Map<String, double> standingPreview(
  PoliticsState state,
  String factionId,
  num delta, {
  required ClanData data,
}) =>
    applyStandingChange(state, factionId, delta, '', data: data).deltas;

/// Edit Mode's slider: standing with [factionId] set to [value] (within
/// [minStanding]..[maxStanding]), with no ripple. The banner still holds:
/// a sworn faction set under the threshold is released, one set to it
/// with none sworn is sworn (without the rivals' cost), and while one is
/// sworn the caps hold -- the value set included.
StandingResult setStandingValue(
  PoliticsState state,
  String factionId,
  num value,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (!data.factions.containsKey(factionId) ||
      data.factions[factionId]!.isLost) {
    return StandingResult(state: state);
  }
  final before = _allStandings(state, data);
  final values = {...before};
  values[factionId] = _clampStanding(value.toDouble());
  final banner = _applyBanner(values,
      sworn: state.swornFactionId,
      preferred: factionId,
      state: state,
      data: data,
      chargeRivals: false);
  return _commit(state, before, values,
      sworn: banner.sworn,
      swore: banner.swore,
      released: banner.released,
      factionId: factionId,
      cause: cause,
      chapter: chapter,
      day: day);
}

/// A claim taken (v1.196, see throne.dart): standing with [factionId]
/// raised to at least [swornThreshold], with no ripple, and the banner
/// theirs -- the clan the character heads is the one they are sworn to,
/// so any other faction sworn is released and the caps hold for the
/// rest (no rival pays the swearing's cost: the caps already take it).
/// A faction that can never be sworn (a tribe, the Choir, the Pit, the
/// Open Hand) moves nothing here.
StandingResult raiseToClaim(
  PoliticsState state,
  String factionId,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (!canBeSworn(factionId, data)) return StandingResult(state: state);
  final before = _allStandings(state, data);
  final values = {...before};
  values[factionId] = max(values[factionId]!, swornThreshold.toDouble());
  final banner = _applyBanner(values,
      sworn: '',
      preferred: factionId,
      state: state,
      data: data,
      chargeRivals: false);
  final previous = state.swornFactionId;
  return _commit(state, before, values,
      sworn: banner.sworn,
      swore: banner.sworn != previous ? banner.sworn : '',
      released: previous.isNotEmpty && previous != banner.sworn ? previous : '',
      factionId: factionId,
      cause: cause,
      chapter: chapter,
      day: day);
}

/// What [setSubclanMark] did: the [state] after and its log [entry]
/// (null when the mark was already that).

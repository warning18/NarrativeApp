// The stat ledger (docs/proposals/stat-scale.md §7b): what raised a stat
// that the data can't tell afterwards -- a pick, a tome's pick, the
// patron's gifts, the formative memories. The race, the profession, the
// levels, the perks, the gear, the signs, the title and the Sworn boon are
// worked out again from the session and the tables (see stat_breakdown.dart).
//
// Pure: PlayerSession keeps the ledger (statSources) and writes it through
// PlayerSession.withSourcedGains; stat_breakdown.dart reads it.

/// The stats a breakdown covers: the eight abilities and the body's three.
const List<String> breakdownStats = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'perception',
  'luck',
  'charisma',
  'maxHealth',
  'baseDamage',
  'baseArmor',
];

/// The kinds the ledger records, in the order a breakdown lists them.
const String ledgerOrigin = 'origin';
const String ledgerPick = 'pick';
const String ledgerTome = 'tome';
const String ledgerPatron = 'patron';

/// A clan's curse (risky_gifts.dart): `curse:<clan>`, its points taken
/// away while it lasts, given back when it ends.
const String ledgerCurse = 'curse';
const List<String> ledgerKinds = [
  ledgerOrigin,
  ledgerPick,
  ledgerTome,
  ledgerPatron,
  ledgerCurse,
];

/// The ledger's id of the patron gift that the open hand adds (a banner
/// raised, see patron_stats.dart): the strongest ability's extra point.
const String openHandSourceId = 'open_hand';

/// The ledger's key for [kind] and [id]: `kind:id`.
String ledgerKey(String kind, String id) => '$kind:$id';

/// The kind and the id of a ledger [key] (see [ledgerKey]).
({String kind, String id}) ledgerKeyParts(String key) {
  final i = key.indexOf(':');
  return i < 0
      ? (kind: key, id: '')
      : (kind: key.substring(0, i), id: key.substring(i + 1));
}

/// [ledger] with [amounts] (stat -> points, zeros left out) added under
/// [kind] and [id]. The same map when there is nothing to add.
Map<String, Map<String, int>> ledgerWith(
  Map<String, Map<String, int>> ledger,
  String kind,
  String id,
  Map<String, int> amounts,
) {
  final added = {
    for (final e in amounts.entries)
      if (e.value != 0) e.key: e.value
  };
  if (added.isEmpty) return ledger;
  final key = ledgerKey(kind, id);
  final row = {...?ledger[key]};
  for (final e in added.entries) {
    final v = (row[e.key] ?? 0) + e.value;
    if (v == 0) {
      row.remove(e.key);
    } else {
      row[e.key] = v;
    }
  }
  return {
    for (final e in ledger.entries)
      if (e.key != key) e.key: e.value,
    if (row.isNotEmpty) key: row,
  };
}

/// A saved ledger (see PlayerSession.toJson): an old save, without one,
/// reads as empty; anything malformed is skipped.
Map<String, Map<String, int>> ledgerFromJson(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final MapEntry(:key, :value) in raw.entries)
      if (value is Map)
        key.toString(): {
          for (final MapEntry(key: stat, value: v) in value.entries)
            if (v is num && v.toInt() != 0) stat.toString(): v.toInt(),
        },
  }..removeWhere((_, v) => v.isEmpty);
}

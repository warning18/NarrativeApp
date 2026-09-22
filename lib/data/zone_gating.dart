import 'dart:math';

/// Pure helpers for the gating fields zones.json and houses.json share
/// (`requiredFlags`, plus a zone's `tier` and `isMainZone`), used by Town
/// Hub, Camp, the expedition screen and their tests. A required flag is
/// usually another zone's `rewardFlag`, so "clear Cinder Row first" is
/// data, not code.
List<String> requiredFlagsOf(Map<String, dynamic> record) =>
    (record['requiredFlags'] as List?)
        ?.map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList() ??
    const [];

/// True when every one of [record]'s required flags is in [flags].
bool meetsRequiredFlags(Map<String, dynamic> record, Iterable<String> flags) {
  final have = flags.toSet();
  return requiredFlagsOf(record).every(have.contains);
}

/// A zone's tier, never below 1 (see zoneTierMultiplier).
int zoneTier(Map<String, dynamic> zone) =>
    max(1, (zone['tier'] as num?)?.toInt() ?? 1);

bool zoneIsMain(Map<String, dynamic> zone) => zone['isMainZone'] == true;

/// The level a zone's card advises before setting out (advice, never a
/// gate), never below 1.
int zoneRecommendedLevel(Map<String, dynamic> zone) =>
    max(1, (zone['recommendedLevel'] as num?)?.toInt() ?? 1);

/// What a locked record is waiting on, for its card's lock line: the name
/// of the zone whose `rewardFlag` is the first missing flag, else that
/// flag's id; null when nothing is missing.
String? lockRequirementName(
  Map<String, dynamic> record,
  Iterable<String> flags,
  Map<String, dynamic> zones,
) {
  final have = flags.toSet();
  for (final flag in requiredFlagsOf(record)) {
    if (have.contains(flag)) continue;
    for (final entry in zones.entries) {
      final zone = entry.value;
      if (zone is Map<String, dynamic> &&
          zone['rewardFlag']?.toString() == flag) {
        return zone['zoneName']?.toString() ?? entry.key;
      }
    }
    return flag;
  }
  return null;
}

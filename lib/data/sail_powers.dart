import 'dart:math';

import 'sea_events.dart';

/// The painted sail: one sigil on the Rusty Eel's canvas, worn the way
/// power is worn everywhere in this world (a banner-knot, an elven
/// painting, a dwarven mark, orcish ink, the tear's own mark), read off
/// the installed ship part's `sailPower` (see ship_parts.json). A sail
/// painted in the character's own people's medium holds twice as strong.
enum SailPower {
  /// The Eel lifts: storms and raiders pass beneath her keel.
  flight,

  /// Tomorrow's weather is shown, and the enemy's first volley is seen
  /// coming.
  foresight,

  /// Every day at sea heals the crew and mends the hull.
  hearth,

  /// A shorter crossing, and richer wrecks.
  windknot,

  /// A void volley in battle, and storms that do not bite.
  voidmark,
}

SailPower? sailPowerOf(Map<String, dynamic> part) {
  final raw = part['sailPower']?.toString() ?? '';
  for (final power in SailPower.values) {
    if (power.name == raw) return power;
  }
  return null;
}

/// The race whose medium the sigil is painted in (ship_parts.json
/// `sailMedium`), or '' for an unpainted part.
String sailMediumOf(Map<String, dynamic> part) =>
    part['sailMedium']?.toString() ?? '';

/// The one painted sail aboard, if any.
({String partId, SailPower power, String medium})? installedSail(
  Map<String, dynamic> parts,
  List<String> installedPartIds,
) {
  for (final id in installedPartIds) {
    final part = parts[id] as Map<String, dynamic>?;
    if (part == null) continue;
    final power = sailPowerOf(part);
    if (power != null) {
      return (partId: id, power: power, medium: sailMediumOf(part));
    }
  }
  return null;
}

/// Every painted sail aboard, one of each power (the first of a power
/// counts), in the order they were fitted: a bigger hull carries several
/// sail slots, so several sigils at once.
List<({String partId, SailPower power, String medium})> installedSails(
  Map<String, dynamic> parts,
  List<String> installedPartIds,
) {
  final seen = <SailPower>{};
  final out = <({String partId, SailPower power, String medium})>[];
  for (final id in installedPartIds) {
    final part = parts[id] as Map<String, dynamic>?;
    if (part == null) continue;
    final power = sailPowerOf(part);
    if (power == null || !seen.add(power)) continue;
    out.add((partId: id, power: power, medium: sailMediumOf(part)));
  }
  return out;
}

/// What the painted sails aboard give a sea battle.
class BattleSails {
  const BattleSails({
    this.foresight = false,
    this.windKnot = false,
    this.voidPartId,
    this.voidStrength = 1,
  });

  /// The enemy's aim is shown.
  final bool foresight;

  /// A crosswind is a tailwind.
  final bool windKnot;

  /// The part whose void volley is stronger, and by how much it is
  /// painted (see [voidVolleyBonus]).
  final String? voidPartId;
  final int voidStrength;
}

/// The battle's share of the sails in [installedPartIds], for a character
/// of [raceId].
BattleSails battleSailsOf(
  Map<String, dynamic> parts,
  List<String> installedPartIds,
  String raceId,
) {
  var out = const BattleSails();
  for (final sail in installedSails(parts, installedPartIds)) {
    final strength = sailStrength(sail.medium, raceId);
    out = BattleSails(
      foresight: out.foresight || sail.power == SailPower.foresight,
      windKnot: out.windKnot || sail.power == SailPower.windknot,
      voidPartId:
          sail.power == SailPower.voidmark ? sail.partId : out.voidPartId,
      voidStrength:
          sail.power == SailPower.voidmark ? strength : out.voidStrength,
    );
  }
  return out;
}

/// 2 when the sigil is painted the character's own people's way, else 1.
int sailStrength(String medium, String raceId) =>
    medium.isNotEmpty && medium == raceId ? 2 : 1;

/// Flight: the storms and raiders of a voyage pass beneath the keel. A
/// voyage never empties -- if every day was weather, the last day stays.
List<SeaEvent> applyFlight(List<SeaEvent> events) {
  final kept = events
      .where(
          (e) => e.kind != SeaEventKind.storm && e.kind != SeaEventKind.raider)
      .toList();
  if (kept.isEmpty && events.isNotEmpty) return [events.last];
  return kept;
}

/// Wind-knot: the crossing is [strength] days shorter, never under one.
int windknotLength(int length, int strength) => max(1, length - strength);

/// Wind-knot: salvage pays half again (twice, painted the right way).
int windknotSalvage(int gold, int strength) =>
    strength >= 2 ? gold * 2 : gold + gold ~/ 2;

/// Hearth: the share of max health the crew regains each day at sea.
int hearthHealPercent(int strength) => 10 * strength;

/// Hearth: hull mended each day at sea.
int hearthHullRepair(int strength) => 6 * strength;

/// Foresight: how many days ahead the sail can see.
int foresightDays(int strength) => strength;

/// Foresight: the share of the enemy's first volley that still lands.
double firstVolleyFactor(int strength) => strength >= 2 ? 0.0 : 0.5;

/// Void mark: what a storm's hull loss becomes (halved, or nothing when
/// the mark was set by a void-marked hand).
int voidmarkStormLoss(int loss, int strength) => strength >= 2 ? 0 : loss ~/ 2;

/// Void mark: the volley's damage on top of the part's own record.
int voidVolleyBonus(int strength) => strength >= 2 ? 10 : 0;

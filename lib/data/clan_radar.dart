// A clan's radar (Wave 7 D, the clan gift popin and the clan tab): what its
// gifts lean on, on five axes, and where it stands with the other clans.
// The orientation counts the effects of the clan's signs (signs.json, the
// patron's) and of its sworn boon, each effect kind on one axis; the
// relations are the live steps (politics), else relations.json's.
import 'factions.dart';
import 'signs.dart';

/// The radar's axes, in drawing order.
enum RadarAxis { might, guard, mending, arcana, fortune }

/// The axis [kind] counts on.
RadarAxis radarAxisOf(SignEffectKind kind) => switch (kind) {
      SignEffectKind.strikeDamagePercent ||
      SignEffectKind.strikeFlat ||
      SignEffectKind.strikeElement ||
      SignEffectKind.strikeStatus ||
      SignEffectKind.strikeKeyword ||
      SignEffectKind.critChance ||
      SignEffectKind.lowHealthDamagePercent ||
      SignEffectKind.firstRoundDamagePercent ||
      SignEffectKind.startMomentum ||
      SignEffectKind.allyDamagePercent ||
      SignEffectKind.compactEdge ||
      SignEffectKind.poisonExtraTurns ||
      SignEffectKind.stat =>
        RadarAxis.might,
      SignEffectKind.guardBlockPercent ||
      SignEffectKind.guardFlat ||
      SignEffectKind.guardRetaliate ||
      SignEffectKind.guardStatus ||
      SignEffectKind.armor ||
      SignEffectKind.maxHealth ||
      SignEffectKind.dodgeChance ||
      SignEffectKind.thorns ||
      SignEffectKind.partyStartBlock ||
      SignEffectKind.partyMaxHealthPercent ||
      SignEffectKind.writFace ||
      SignEffectKind.intentLookahead ||
      SignEffectKind.shipHullPercent =>
        RadarAxis.guard,
      SignEffectKind.guardHeal ||
      SignEffectKind.mendPercent ||
      SignEffectKind.mendParty ||
      SignEffectKind.mendShield ||
      SignEffectKind.mendCleanse ||
      SignEffectKind.lifestealPercent ||
      SignEffectKind.secondWind ||
      SignEffectKind.potionBonus ||
      SignEffectKind.killHeal ||
      SignEffectKind.afterFightHealPercent ||
      SignEffectKind.emberFace =>
        RadarAxis.mending,
      SignEffectKind.manaFlat ||
      SignEffectKind.spellDamagePercent ||
      SignEffectKind.spellCostLess ||
      SignEffectKind.spellStatus ||
      SignEffectKind.manaOnHit ||
      SignEffectKind.maxMana =>
        RadarAxis.arcana,
      SignEffectKind.goldPercent ||
      SignEffectKind.xpPercent ||
      SignEffectKind.crowsPrice ||
      SignEffectKind.shipGunPercent ||
      SignEffectKind.voyageCalm =>
        RadarAxis.fortune,
    };

/// A clan's radar.
class ClanRadar {
  const ClanRadar({this.orientation = const {}, this.relations = const {}});

  /// Each axis from 0 to 1, the clan's strongest at 1; every axis is
  /// there (0 when nothing counts on it).
  final Map<RadarAxis, double> orientation;

  /// The step (relations.json's 1 = blood feud … 7 = allies) with each
  /// other faction that has one, by faction id.
  final Map<String, int> relations;
}

/// [factionId]'s radar: the orientation of its [signs] and sworn boon,
/// and its steps with the others ([relationSteps], the live ones, by
/// [relationKey]; relations.json's where they say nothing).
ClanRadar clanRadarOf(
  String factionId, {
  required ClanData data,
  required Map<String, SignDef> signs,
  Map<String, int> relationSteps = const {},
}) {
  final counts = {for (final axis in RadarAxis.values) axis: 0.0};
  for (final sign in signs.values) {
    if (sign.patronId != factionId) continue;
    for (final effect in sign.effects) {
      counts[radarAxisOf(effect.kind)] = counts[radarAxisOf(effect.kind)]! + 1;
    }
  }
  for (final effect
      in data.faction(factionId)?.sworn?.effects ?? const <SignEffect>[]) {
    counts[radarAxisOf(effect.kind)] = counts[radarAxisOf(effect.kind)]! + 1;
  }
  final top = counts.values.fold<double>(0, (a, b) => a > b ? a : b);
  final base = data.relations.baseSteps;
  return ClanRadar(
    orientation: {
      for (final MapEntry(:key, :value) in counts.entries)
        key: top == 0 ? 0 : value / top,
    },
    relations: {
      for (final other in data.factions.keys)
        if (other != factionId)
          if (relationSteps[relationKey(factionId, other)] ??
                  base[relationKey(factionId, other)]
              case final int step)
            other: step,
    },
  );
}

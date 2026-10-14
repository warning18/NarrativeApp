import 'status_effect.dart';

/// The rules a skill can carry beyond damage, heal, mana and one status
/// (v1.245): a shield, several strikes, a hit on the rest of the pack, a
/// status laid on every enemy, a second status, a wound dealt back to
/// whoever strikes the shield, a cleanse, a heal for the whole party, a
/// piercing blow, damage drawn from armor, a built-up momentum and a free
/// reroll next round. Every field is optional in skills.json; a skill that
/// names none reads as [SkillExtras.none].
class SkillExtras {
  const SkillExtras({
    this.block = 0,
    this.strikes = 1,
    this.splashShare = 0,
    this.splashTargets = 0,
    this.statusAll = false,
    this.secondStatus,
    this.reflect,
    this.cleanse = '',
    this.healAll = false,
    this.pierces = false,
    this.damageFromArmor = 0,
    this.chargesMomentum = false,
    this.bonusRolls = 0,
  });

  /// Shield the skill raises, as a Defend face does.
  final int block;

  /// Separate blows the skill strikes. Its damage fields are per blow; the
  /// result carries the total, which the fight shares out between them.
  /// 1 is a single hit.
  final int strikes;

  /// Share of each blow that falls on the other enemies standing, and how
  /// many of them (0 = all of them).
  final double splashShare;
  final int splashTargets;

  /// The skill's status lands on every enemy, not just the one struck.
  final bool statusAll;

  /// A second status laid beside the first (Winter's Hush stuns and
  /// weakens).
  final StatusEffect? secondStatus;

  /// The status the shield lays on an enemy that connects with it.
  final StatusEffect? reflect;

  /// 'Poison' clears that status from whoever cast it, 'All' every
  /// affliction.
  final String cleanse;

  /// The skill's heal reaches every party member standing.
  final bool healAll;

  /// The blow goes through a raised guard and an Armored hide.
  final bool pierces;

  /// Extra damage per point of the caster's armor.
  final double damageFromArmor;

  /// The party's momentum is filled: the next strike the player picks is a
  /// guaranteed critical.
  final bool chargesMomentum;

  /// Rerolls granted to the next round's roll.
  final int bonusRolls;

  bool get isNone =>
      block == 0 &&
      strikes <= 1 &&
      splashShare == 0 &&
      !statusAll &&
      secondStatus == null &&
      reflect == null &&
      cleanse.isEmpty &&
      !healAll &&
      !pierces &&
      damageFromArmor == 0 &&
      !chargesMomentum &&
      bonusRolls == 0;

  static const SkillExtras none = SkillExtras();

  /// Reads the extras off a skills.json record.
  factory SkillExtras.fromRecord(Map<String, dynamic> record) {
    int intOf(String key) => (record[key] as num?)?.toInt() ?? 0;
    StatusEffect? status(String type, String duration, String magnitude) {
      final kind = statusEffectTypeFromString(record[type]?.toString());
      final turns = intOf(duration);
      if (kind == null || turns <= 0) return null;
      return StatusEffect(
          type: kind, remainingTurns: turns, magnitude: intOf(magnitude));
    }

    return SkillExtras(
      block: intOf('blockAmount'),
      strikes: intOf('strikes') < 1 ? 1 : intOf('strikes'),
      splashShare: (record['splashShare'] as num?)?.toDouble() ?? 0,
      splashTargets: intOf('splashTargets'),
      statusAll: record['statusAll'] == true,
      secondStatus:
          status('inflictsStatus2', 'statusDuration2', 'statusMagnitude2'),
      reflect: status('reflectStatus', 'reflectDuration', 'reflectMagnitude'),
      cleanse: record['cleanse']?.toString() ?? '',
      healAll: record['healAll'] == true,
      pierces: record['pierces'] == true,
      damageFromArmor: (record['damageFromArmor'] as num?)?.toDouble() ?? 0,
      chargesMomentum: record['chargesMomentum'] == true,
      bonusRolls: intOf('bonusRolls'),
    );
  }

  /// [effects] without the afflictions [cleanse] names.
  List<StatusEffect> cleansed(List<StatusEffect> effects) {
    if (cleanse == 'All') return const [];
    if (cleanse == 'Poison') {
      return [
        for (final e in effects)
          if (e.type != StatusEffectType.poison) e,
      ];
    }
    return effects;
  }
}

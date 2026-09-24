import 'dart:math';

import '../l10n/app_locale.dart';
import 'combat_engine.dart' show scaledDamage, scaledMaxHealth;
import 'status_effect.dart';

/// Whom a spell (spells.json) lands on -- see `spellTargetOptions` in
/// `lib/gamedata/db_schema.dart`.
enum SpellTarget { enemy, allEnemies, ally, party, self }

/// What a spell does -- see `spellEffectOptions`. A [damage] spell may also
/// carry a status (Frost Bind: damage plus a Stun); a [status] spell only
/// carries the status.
enum SpellEffectKind { damage, heal, block, status, cleanse }

SpellTarget _targetFromString(String? value) => switch (value) {
      'AllEnemies' => SpellTarget.allEnemies,
      'Ally' => SpellTarget.ally,
      'Party' => SpellTarget.party,
      'Self' => SpellTarget.self,
      _ => SpellTarget.enemy,
    };

SpellEffectKind _effectFromString(String? value) => switch (value) {
      'Heal' => SpellEffectKind.heal,
      'Block' => SpellEffectKind.block,
      'Status' => SpellEffectKind.status,
      'Cleanse' => SpellEffectKind.cleanse,
      _ => SpellEffectKind.damage,
    };

/// The mana every character has before any Intelligence or Wisdom -- see
/// [maxManaFor].
const int baseMana = 4;

/// A character's mana pool: [baseMana] plus half of whichever is higher,
/// Intelligence or Wisdom -- a starting Mage or Cleric (4 in their stat)
/// has 6, a Warrior 4. Mana carries over between fights like health does,
/// refills on a rest, and comes back mid-fight through a die's `Mana`
/// faces (see `resolvePlayerFace`).
int maxManaFor({required int intelligence, required int wisdom}) =>
    baseMana + max(intelligence, wisdom) ~/ 2;

/// One spell record from spells.json, parsed once so combat and the shop
/// never read raw map fields.
class SpellSpec {
  const SpellSpec({
    required this.id,
    required this.name,
    required this.nameFr,
    required this.description,
    required this.descriptionFr,
    required this.professionId,
    required this.manaCost,
    required this.effect,
    required this.target,
    required this.amount,
    required this.scalingStat,
    this.damageMultiplier = 1.0,
    required this.element,
    required this.battleMessage,
    required this.battleMessageFr,
    this.vfx = '',
    this.status,
  });

  factory SpellSpec.fromJson(String id, Map<String, dynamic> json) {
    final statusType =
        statusEffectTypeFromString(json['inflictsStatus']?.toString());
    final duration = (json['statusDuration'] as num?)?.toInt() ?? 0;
    return SpellSpec(
      id: json['spellID']?.toString() ?? id,
      name: json['spellName']?.toString() ?? id,
      nameFr: json['spellName_fr']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      descriptionFr: json['description_fr']?.toString() ?? '',
      professionId: json['professionID']?.toString() ?? '',
      manaCost: max(0, (json['manaCost'] as num?)?.toInt() ?? 0),
      effect: _effectFromString(json['effect']?.toString()),
      target: _targetFromString(json['target']?.toString()),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      scalingStat: json['scalingStat']?.toString() ?? '',
      damageMultiplier: (json['damageMultiplier'] as num?)?.toDouble() ?? 1.0,
      element: json['element']?.toString() ?? 'None',
      battleMessage: json['battleMessage']?.toString() ?? '',
      battleMessageFr: json['battleMessage_fr']?.toString() ?? '',
      vfx: json['vfx']?.toString() ?? '',
      status: statusType == null || duration <= 0
          ? null
          : StatusEffect(
              type: statusType,
              remainingTurns: duration,
              magnitude: (json['statusMagnitude'] as num?)?.toInt() ?? 0,
            ),
    );
  }

  final String id;

  /// The on-screen effect the spell plays (a skill_vfx.dart style id).
  final String vfx;
  final String name;
  final String nameFr;
  final String description;
  final String descriptionFr;

  /// The one profession that can learn this spell, or '' for any.
  final String professionId;
  final int manaCost;
  final SpellEffectKind effect;
  final SpellTarget target;

  /// Flat damage added on top of the caster's own before
  /// [damageMultiplier], or the base healing / block -- see
  /// [spellAmountFor].
  final int amount;

  /// 'intelligence' / 'wisdom' / '' -- half of it is added to [amount].
  final String scalingStat;

  /// What a Damage spell multiplies `(caster damage + amount + stat/2)` by
  /// -- the same shape as a skill's `damageMultiplier`, so a spell keeps
  /// pace with gear and levels instead of fading to a flat number.
  final double damageMultiplier;
  final String element;
  final String battleMessage;
  final String battleMessageFr;

  /// The status this spell lands on its enemy target, if any.
  final StatusEffect? status;

  String nameFor(AppLanguage language) =>
      language == AppLanguage.fr && nameFr.isNotEmpty ? nameFr : name;

  String descriptionFor(AppLanguage language) =>
      language == AppLanguage.fr && descriptionFr.isNotEmpty
          ? descriptionFr
          : description;

  String battleMessageFor(AppLanguage language) =>
      language == AppLanguage.fr && battleMessageFr.isNotEmpty
          ? battleMessageFr
          : battleMessage;

  /// True for a spell aimed at enemies (one or all).
  bool get hitsEnemies =>
      target == SpellTarget.enemy || target == SpellTarget.allEnemies;

  /// True when the caster has to pick exactly one enemy.
  bool get needsEnemyPick => target == SpellTarget.enemy;

  /// True when the caster has to pick exactly one party member.
  bool get needsAllyPick => target == SpellTarget.ally;
}

/// Parses a whole spells.json table.
Map<String, SpellSpec> parseSpells(Map<String, dynamic> db) => {
      for (final entry in db.entries)
        if (entry.value is Map<String, dynamic>)
          entry.key: SpellSpec.fromJson(
              entry.key, entry.value as Map<String, dynamic>),
    };

/// A spell's damage / heal / block amount as it lands right now. A Damage
/// spell reads like a skill: `(casterDamage + amount + stat/2) x
/// damageMultiplier`, where [casterDamage] is the same total the caster's
/// dice faces hit with (base, gear, stat scaling, the spell's element
/// bonus). Healing and block are `amount + stat/2` grown with [level] at
/// the enemies' own health curve (see `scaledMaxHealth`), so a heal that
/// was worth a third of a level-1 pool is still worth something at level
/// 15. Spells never crit, are never Weakened and ignore the Armored affix
/// -- their appeal is that the number on the button is the number that
/// lands. Zero for a Status or Cleanse spell.
int spellAmountFor(
  SpellSpec spell, {
  required int intelligence,
  required int wisdom,
  int level = 1,
  int casterDamage = 0,
}) {
  final score = switch (spell.scalingStat) {
    'intelligence' => intelligence,
    'wisdom' => wisdom,
    _ => 0,
  };
  final base = spell.amount + score ~/ 2;
  return switch (spell.effect) {
    SpellEffectKind.damage =>
      max(0, ((casterDamage + base) * spell.damageMultiplier).round()),
    SpellEffectKind.heal ||
    SpellEffectKind.block =>
      max(0, scaledMaxHealth(base, level)),
    SpellEffectKind.status || SpellEffectKind.cleanse => 0,
  };
}

/// The status a spell lands at [level] -- a Poison's per-turn damage grows
/// with level like an enemy's own damage does (see `scaledDamage`), so a
/// hex learned in chapter 2 still bites in chapter 5; Stun and Weaken are
/// unchanged (a skipped turn is a skipped turn, Weaken is a percentage).
/// Null for a spell with no status.
StatusEffect? spellStatusFor(SpellSpec spell, {int level = 1}) {
  final status = spell.status;
  if (status == null) return null;
  if (status.type != StatusEffectType.poison) return status;
  return StatusEffect(
    type: status.type,
    remainingTurns: status.remainingTurns,
    magnitude: scaledDamage(status.magnitude, level),
  );
}

/// Whether a character of [professionId] who already knows [knownSpellIds]
/// can learn [spell] from a spellbook -- never a spell they already know,
/// and never another profession's.
bool canLearnSpell(
  SpellSpec spell, {
  required String professionId,
  required List<String> knownSpellIds,
}) {
  if (knownSpellIds.contains(spell.id)) return false;
  return spell.professionId.isEmpty || spell.professionId == professionId;
}

/// The spell a Spellbook-type item teaches (its `teachesSpellId`), or null
/// for any other item.
String? spellbookSpellIdFor(Map<String, dynamic>? item) {
  if (item?['itemType']?.toString() != 'Spellbook') return null;
  final id = item?['teachesSpellId']?.toString() ?? '';
  return id.isEmpty ? null : id;
}

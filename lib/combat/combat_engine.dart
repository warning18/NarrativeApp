import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'status_effect.dart';

/// Reads a skill or enemy-move record's `inflictsStatus`/`statusDuration`/
/// `statusMagnitude` fields into a [StatusEffect], or null if the record
/// doesn't inflict anything (the common case — most skills are plain
/// damage/heal). Shared by [resolvePlayerFace]'s Skill case and
/// [resolveEnemyMove] so both sides read the same three field names the
/// same way.
StatusEffect? _inflictedStatusFrom(Map<String, dynamic> record) {
  final type = statusEffectTypeFromString(record['inflictsStatus']?.toString());
  if (type == null) return null;
  final duration = (record['statusDuration'] as num?)?.toInt() ?? 0;
  if (duration <= 0) return null;
  return StatusEffect(
    type: type,
    remainingTurns: duration,
    magnitude: (record['statusMagnitude'] as num?)?.toInt() ?? 0,
  );
}

/// Maps an `element` value (as used on dice faces, skills, and enemy
/// moves — see [elementOptions] in `lib/gamedata/db_schema.dart`, kept in
/// sync with this map by hand since the schema layer deliberately doesn't
/// depend on gameplay code) to the item-field prefix items.json already
/// stores elemental gear bonuses under (e.g. `fireDmgBonus`/`fireResist`).
/// 'None' has no entry — it never earns a bonus or suffers a resist.
const Map<String, String> elementFieldPrefixes = {
  'Fire': 'fire',
  'Wind': 'wind',
  'Earth': 'earth',
  'Water': 'water',
  'Electricity': 'elec',
  'Void': 'void',
  'Ice': 'ice',
  'Light': 'light',
};

class DiceFaceResult {
  const DiceFaceResult({
    required this.faceIndex,
    required this.faceName,
    required this.type,
    required this.value,
    required this.linkedSkillID,
    required this.element,
  });

  final int faceIndex;
  final String faceName;
  final String type;
  final int value;
  final String linkedSkillID;
  final String element;

  DiceFaceResult withLinkedSkillID(String linkedSkillID) => DiceFaceResult(
        faceIndex: faceIndex,
        faceName: faceName,
        type: type,
        value: value,
        linkedSkillID: linkedSkillID,
        element: element,
      );
}

DiceFaceResult rollDie(List<Map<String, dynamic>> faces, Random random) {
  final weights =
      faces.map((f) => (f['weight'] as num?)?.toDouble() ?? 1.0).toList();
  final totalWeight = weights.fold<double>(0, (sum, w) => sum + w);

  var roll = totalWeight <= 0 ? 0.0 : random.nextDouble() * totalWeight;
  for (var i = 0; i < faces.length; i++) {
    roll -= weights[i];
    if (roll <= 0) {
      return _faceFromJson(faces[i], i);
    }
  }
  return _faceFromJson(faces.last, faces.length - 1);
}

DiceFaceResult _faceFromJson(Map<String, dynamic> face, int index) {
  return DiceFaceResult(
    faceIndex: index,
    faceName: face['faceName']?.toString() ?? '',
    type: face['type']?.toString() ?? 'Empty',
    value: (face['value'] as num?)?.toInt() ?? 0,
    linkedSkillID: face['linkedSkillID']?.toString() ?? '',
    element: face['element']?.toString() ?? 'None',
  );
}

class PlayerActionResult {
  const PlayerActionResult({
    required this.damageDealt,
    required this.healingDone,
    required this.blockAmount,
    required this.message,
    this.inflictedStatus,
    this.isCritical = false,
    this.manaGained = 0,
  });

  final int damageDealt;
  final int healingDone;
  final int blockAmount;
  final String message;

  /// Mana a `Mana` face restores to the party's pool (see
  /// `maxManaFor` in spells.dart) -- 0 for every other face type.
  final int manaGained;

  /// A status effect this face's skill inflicts on the enemy, if any —
  /// only Skill faces can carry one (see the skill's own
  /// `inflictsStatus`/`statusDuration`/`statusMagnitude` fields).
  final StatusEffect? inflictedStatus;

  /// True when [criticalChanceFor] rolled a hit on this face's damage --
  /// always false for a face that dealt no damage (a pure heal/block, or a
  /// fizzled skill), so it never surfaces on something with nothing to
  /// amplify.
  final bool isCritical;
}

/// Critical-hit chance (0-100) for an attacker with the given Luck score --
/// a flat 5% baseline (everyone gets the occasional lucky hit) plus 1.5
/// points per Luck, capped at 35% so even a heavily luck-built character
/// still lands a normal hit more often than not.
double criticalChanceFor(int luck) => min(35, 5 + luck * 1.5);

/// Dodge chance (0-100) for a defender with the given Dexterity score --
/// same shape as [criticalChanceFor], capped a little lower (30%) since a
/// dodge blocks 100% of the incoming hit rather than just adding a bonus.
double dodgeChanceFor(int dexterity) => min(30, 5 + dexterity * 1.5);

/// A critical hit multiplies the face's already-computed damage by this
/// much -- shared by every damaging face type so a crit means the same
/// thing everywhere it can happen.
const double _criticalDamageMultiplier = 1.5;

int _withCritical(int damage, int luck, Random? random) {
  if (damage <= 0 || random == null) return damage;
  if (random.nextDouble() * 100 >= criticalChanceFor(luck)) return damage;
  return criticalDamage(damage);
}

/// [damage] as a critical hit -- what [_withCritical] deals when the Luck
/// roll lands, exposed so a guaranteed crit (see FightScreen's momentum)
/// hits for exactly the same amount a lucky one would.
int criticalDamage(int damage) =>
    damage <= 0 ? damage : (damage * _criticalDamageMultiplier).round();

/// Damage/heal multiplier a skill gets from the wielder's alignment: a
/// skill tagged `alignment: 'Good'` or `'Evil'` in skills.json is
/// [alignedSkillMultiplier] times stronger in the hands of a character of
/// that alignment and [opposedSkillMultiplier] times weaker in the hands
/// of the opposite one; a Neutral character, or an untagged skill, gets
/// 1.0. The player's own alignment stands for the whole party (allies
/// don't track one), exactly as the skills screen's alignment gate does.
const double alignedSkillMultiplier = 1.25;
const double opposedSkillMultiplier = 0.75;

double alignmentSkillMultiplier(
    Map<String, dynamic>? skill, String alignmentLabel) {
  final skillAlignment = skill?['alignment']?.toString() ?? '';
  if (skillAlignment.isEmpty || alignmentLabel == 'Neutral') return 1.0;
  if (skillAlignment == alignmentLabel) return alignedSkillMultiplier;
  if ((skillAlignment == 'Good' && alignmentLabel == 'Evil') ||
      (skillAlignment == 'Evil' && alignmentLabel == 'Good')) {
    return opposedSkillMultiplier;
  }
  return 1.0;
}

PlayerActionResult resolvePlayerFace(
  DiceFaceResult face,
  Map<String, dynamic> skills,
  int baseDamage, {
  AppLanguage language = AppLanguage.en,
  List<StatusEffect> activeEffects = const [],
  int wisdomHealBonus = 0,
  int luck = 0,
  Random? random,
  bool forceCritical = false,
  String alignmentLabel = 'Neutral',
}) {
  String t(String key) => trFor(language, key);
  int withCrit(int rawDamage) => forceCritical
      ? criticalDamage(rawDamage)
      : _withCritical(rawDamage, luck, random);
  switch (face.type) {
    case 'Attack':
      final rawDamage = applyWeaken(baseDamage + face.value, activeEffects);
      final damage = withCrit(rawDamage);
      final crit = damage != rawDamage;
      return PlayerActionResult(
        damageDealt: damage,
        healingDone: 0,
        blockAmount: 0,
        isCritical: crit,
        message: '${face.faceName}: ${t('you_deal_prefix')} $damage '
            '${t('damage_word')}${crit ? ' ${t('critical_hit_suffix')}' : ''}.',
      );
    case 'Defend':
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: face.value,
        message:
            '${face.faceName}: ${t('you_brace_prefix')} ${face.value} ${t('block_word')}.',
      );
    case 'Skill':
      final effectiveSkillId =
          face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;
      final skill = skills[effectiveSkillId] as Map<String, dynamic>?;
      if (skill == null) {
        return PlayerActionResult(
          damageDealt: 0,
          healingDone: 0,
          blockAmount: 0,
          message: t('skill_fizzles'),
        );
      }
      final damageMod = (skill['damageMod'] as num?)?.toInt() ?? 0;
      final multiplier = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
      final alignmentMultiplier =
          alignmentSkillMultiplier(skill, alignmentLabel);
      final baseHealAmount = (skill['healAmount'] as num?)?.toInt() ?? 0;
      final healAmount = baseHealAmount > 0
          ? ((baseHealAmount + wisdomHealBonus) * alignmentMultiplier).round()
          : 0;
      final rawDamage = applyWeaken(
        ((baseDamage + damageMod) * multiplier * alignmentMultiplier).round(),
        activeEffects,
      );
      final damage = withCrit(rawDamage);
      final crit = damage != rawDamage;
      final flavor = skill['battleMessage']?.toString() ?? '${face.faceName}!';
      // Standard dice faces (Attack/Defend/Heal) always spell out the exact
      // numbers in their preview message; skill faces should be no
      // different, on top of whatever flavor text the skill defines.
      final statParts = <String>[
        if (damage > 0)
          '${t('you_deal_prefix')} $damage ${t('damage_word')}'
              '${crit ? ' ${t('critical_hit_suffix')}' : ''}',
        if (healAmount > 0)
          '${t('you_recover_prefix')} $healAmount ${t('hp_label')}',
      ];
      final message =
          statParts.isEmpty ? flavor : '$flavor ${statParts.join(', ')}.';
      return PlayerActionResult(
        damageDealt: damage,
        healingDone: healAmount,
        blockAmount: 0,
        isCritical: crit,
        message: message,
        inflictedStatus: _inflictedStatusFrom(skill),
      );
    case 'Heal':
      final healAmount = face.value + wisdomHealBonus;
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: healAmount,
        blockAmount: 0,
        message:
            '${face.faceName}: ${t('you_recover_prefix')} $healAmount ${t('hp_label')}.',
      );
    case 'Mana':
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: 0,
        manaGained: face.value,
        message:
            '${face.faceName}: ${t('you_recover_prefix')} ${face.value} ${t('mana_label')}.',
      );
    case 'Empty':
    default:
      return PlayerActionResult(
        damageDealt: 0,
        healingDone: 0,
        blockAmount: 0,
        message:
            '${face.faceName.isEmpty ? t('miss_label') : face.faceName}: ${t('nothing_happens')}',
      );
  }
}

class EnemyMoveResult {
  const EnemyMoveResult({
    required this.damage,
    required this.message,
    this.inflictedStatus,
    this.element = 'None',
    this.healAmount = 0,
  });

  final int damage;
  final String message;

  /// A status effect this move inflicts on its target, if any — read from
  /// the referenced skill's own `inflictsStatus` fields; a move with no
  /// `skillID` (a plain attack) never inflicts one.
  final StatusEffect? inflictedStatus;

  /// The element this move hits with — the referenced skill's own
  /// `element` field, or 'None' for a plain base attack. Lets the caller
  /// apply the target's matching `<prefix>Resist` gear bonus the same way
  /// it already applies armor/block.
  final String element;

  /// The referenced skill's own `healAmount` field (self-heal), if any —
  /// read here purely so a telegraph preview (see [categoryFor]) can tell
  /// a self-heal move apart from a plain attack.
  final int healAmount;
}

EnemyMoveResult resolveEnemyMove({
  required Map<String, dynamic> enemy,
  required Map<String, dynamic> skills,
  required int enemyCurrentHealth,
  required int enemyMaxHealth,
  required Random random,
  AppLanguage language = AppLanguage.en,
  List<StatusEffect> activeEffects = const [],
  Set<String> elementsHitThisRound = const {},
}) {
  String t(String key) => trFor(language, key);
  final moves =
      (enemy['skillMoves'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final healthPercent =
      enemyMaxHealth <= 0 ? 100.0 : (enemyCurrentHealth / enemyMaxHealth) * 100;
  final enemyName = enemy['enemyName']?.toString() ?? t('the_enemy_label');
  final baseDamage = (enemy['damage'] as num?)?.toInt() ?? 0;

  final sortedMoves = [...moves]..sort((a, b) {
      final priorityA = (a['priority'] as num?)?.toInt() ?? 0;
      final priorityB = (b['priority'] as num?)?.toInt() ?? 0;
      return priorityB.compareTo(priorityA);
    });

  for (final move in sortedMoves) {
    final condition = move['condition']?.toString() ?? 'Always';
    final chance = (move['chance'] as num?)?.toDouble() ?? 100;
    final healthThreshold = (move['healthThreshold'] as num?)?.toDouble() ?? 0;

    bool matches;
    switch (condition) {
      case 'Always':
        matches = true;
        break;
      case 'Chance':
        matches = random.nextDouble() * 100 <= chance;
        break;
      case 'OnLowHealth':
        // The health gate opens the move; `chance` (authored 40-60 on
        // every current entry) then decides whether it fires this turn,
        // same as a plain Chance move -- otherwise a wounded enemy nukes
        // every single turn regardless of what its data says.
        matches = healthPercent <= healthThreshold &&
            random.nextDouble() * 100 <= chance;
        break;
      case 'OnHitByElement':
        matches = elementsHitThisRound
            .contains(move['requiredElement']?.toString() ?? '');
        break;
      default:
        matches = false;
        break;
    }

    if (!matches) continue;

    final skillId = move['skillID']?.toString() ?? '';
    if (skillId.isNotEmpty && skills.containsKey(skillId)) {
      final skill = skills[skillId] as Map<String, dynamic>;
      final damageMod = (skill['damageMod'] as num?)?.toInt() ?? 0;
      final multiplier = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
      final damage = applyWeaken(
        (baseDamage + (damageMod * multiplier)).round(),
        activeEffects,
      );
      return EnemyMoveResult(
        damage: damage,
        message: skill['battleMessage']?.toString() ??
            '$enemyName ${t('attacks_suffix')}',
        inflictedStatus: _inflictedStatusFrom(skill),
        element: skill['element']?.toString() ?? 'None',
        healAmount: (skill['healAmount'] as num?)?.toInt() ?? 0,
      );
    }
    break;
  }

  return EnemyMoveResult(
      damage: applyWeaken(baseDamage, activeEffects),
      message: '$enemyName ${t('attacks_suffix')}');
}

/// Enemies excluded from both the Elite-promotion roll (see
/// `fight_screen.dart`'s `_eliteChance`) and any multi-enemy pack draw (see
/// `SubNodeEngine`'s pack rolling) — the game's tuned "wall" bosses
/// (`inquisition_high_warden`, `hollow_court_zealot`, `void_manifestation`,
/// all three regression-tested by `test/boss_balance_test.dart`) plus the
/// two other individually-tuned uniques (`kroll_the_branded`,
/// `void_stalker`). These fights stay exactly as tuned -- solo, never
/// reskinned, never diluted into a pack -- so their win-rate bands hold.
const Set<String> soloOnlyEnemyIds = {
  'inquisition_high_warden',
  'hollow_court_zealot',
  'void_manifestation',
  'kroll_the_branded',
  'void_stalker',
  'hollow_court_inquisitor',
  'void_archon',
  'void_sovereign',
};

/// How much detail the party can currently see into an enemy's telegraphed
/// next move -- a hard threshold on `effectivePerception`, not a percentage
/// chance like [criticalChanceFor]/[dodgeChanceFor]: whether a telegraph is
/// visible is always yes/no, never a coinflip.
enum TelegraphTier {
  /// effectivePerception < 1 -- no telegraph UI at all for this enemy.
  none,

  /// 1-4 -- WHO the enemy will target, nothing else.
  target,

  /// 5-9 -- WHO, plus a broad category of the incoming move (see
  /// [MoveCategory]) -- an icon-level hint, not the exact skill or element.
  category,

  /// >=10 -- WHO, the move's real flavor/name, its element, and roughly
  /// what it does.
  full,
}

/// The detail tier the party can currently read one enemy's telegraphed
/// next move at, from [perception] (the highest Perception among currently
/// conscious party members -- see `FightScreen`'s `_bestPartyPerception`)
/// and that enemy's own [guile]. `effectivePerception = max(0, perception -
/// guile)`, bucketed into [TelegraphTier]. Pure and RNG-free -- every enemy
/// in a pack can sit at a different tier at once, since each has its own
/// Guile.
TelegraphTier telegraphTierFor(int perception, int guile) {
  final effectivePerception = max(0, perception - guile);
  if (effectivePerception < 1) return TelegraphTier.none;
  if (effectivePerception < 5) return TelegraphTier.target;
  if (effectivePerception < 10) return TelegraphTier.category;
  return TelegraphTier.full;
}

/// Broad category an enemy's move falls into, for a [TelegraphTier.category]
/// preview -- coarser than the move's real effect, matching what a
/// mid-Perception read can actually tell. A status-inflicting move always
/// reads as [statusDebuff], even if it also deals damage (the debuff is the
/// scarier, more decision-relevant half of "roughly what it does");
/// otherwise a positive [EnemyMoveResult.healAmount] with no damage reads
/// as [healSelf]; everything else is a plain [attack].
enum MoveCategory { attack, healSelf, statusDebuff }

MoveCategory categoryFor(EnemyMoveResult move) {
  if (move.inflictedStatus != null) return MoveCategory.statusDebuff;
  if (move.healAmount > 0 && move.damage <= 0) return MoveCategory.healSelf;
  return MoveCategory.attack;
}

/// Skill tiers run 0 (just unlocked, base numbers) through [maxSkillTier]
/// (fully upgraded). Each tier above 0 costs [skillTierUpgradeCost] essence.
const int maxSkillTier = 3;

/// Cost, in skill essence, to go from [currentTier] to `currentTier + 1`.
/// Rising cost per tier (3/6/9) makes maxing out one skill a real
/// commitment rather than something every skill gets by mid-run.
int skillTierUpgradeCost(int currentTier) => (currentTier + 1) * 3;

/// Returns a copy of [skill] with its combat numbers boosted for [tier] —
/// +25% damageMod/healAmount and +0.1 damageMultiplier per tier. Never
/// mutates the shared skills-db record itself (enemies read from the same
/// table via their own skillID references), so callers apply this to a
/// per-actor copy right before resolving a face, not to the db in place.
Map<String, dynamic> applySkillTier(Map<String, dynamic> skill, int tier) {
  if (tier <= 0) return skill;
  final damageMod = (skill['damageMod'] as num?)?.toInt() ?? 0;
  final healAmount = (skill['healAmount'] as num?)?.toInt() ?? 0;
  final multiplier = (skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0;
  return {
    ...skill,
    'damageMod': (damageMod * (1 + 0.25 * tier)).round(),
    'healAmount': (healAmount * (1 + 0.25 * tier)).round(),
    'damageMultiplier': multiplier + 0.1 * tier,
  };
}

int scaledMaxHealth(int base, int playerLevel) {
  return (base * (1 + 0.12 * (playerLevel - 1))).round();
}

int scaledDamage(int base, int playerLevel) {
  return (base * (1 + 0.08 * (playerLevel - 1))).round();
}

int scaledReward(int base, int playerLevel) {
  return (base * (1 + 0.10 * (playerLevel - 1))).round();
}

/// Per-chapter step of the chapter difficulty curve (see
/// [chapterDifficultyMultiplier]).
const double chapterDifficultyStep = 0.12;

/// Enemy max-health multiplier by story chapter, applied on top of the
/// player-level scaling above and before the Elite/pack multipliers.
/// Level scaling alone let a chapter-5 boss meet a level-10 party as a
/// slightly larger chapter-1 thug; the curve keeps each chapter's enemies
/// a step ahead of the gear and levels the previous one handed out
/// (chapter 1 ×1.0, chapter 3 ×1.24, chapter 6 ×1.6). Damage climbs half
/// as fast (see [damageShareOf]): more health makes a fight longer, more
/// damage makes it lethal, and a 40-run simulation showed a full-rate
/// damage curve turning tuned chapter-2 fights from sure wins into
/// coin flips.
double chapterDifficultyMultiplier(int chapter) =>
    1 + chapterDifficultyStep * (max(1, chapter) - 1);

/// The damage multiplier that goes with a health multiplier from the
/// chapter curve or a zone's tier: half the excess (×1.24 health → ×1.12
/// damage).
double damageShareOf(double healthMultiplier) => 1 + (healthMultiplier - 1) / 2;

/// Gold/XP multiplier by chapter -- a lighter curve than the difficulty
/// one, so later chapters pay more but never enough to outrun their own
/// enemies (chapter 1 ×1.0, chapter 6 ×1.5).
double chapterRewardMultiplier(int chapter) => 1 + 0.10 * (max(1, chapter) - 1);

/// Max-health multiplier for a zone's `tier` (zones.json): each tier past
/// the first is a tenth harder than the chapter's story fights (damage
/// again half that, see [damageShareOf]), so a chapter's zones climb toward
/// its main zone (tier 1 ×1.0, tier 3 ×1.2).
double zoneTierMultiplier(int tier) => 1 + 0.10 * (max(1, tier) - 1);

/// Percentage-point drop-rate bonus (same units as the flat luck bonus a
/// win's loot roll already adds) for a loot item whose own `scalingStat`
/// matches the player's profession's `preferredScalingStat` — a Mage sees
/// noticeably more staves than a Warrior would off the exact same enemy,
/// without any single drop ever becoming guaranteed. 0 for a non-matching
/// item, an item with no scalingStat, or a profession with no affinity
/// (e.g. Cleric, whose dominant stat is Wisdom, which nothing scales
/// with).
int professionLootAffinityBonus(
  Map<String, dynamic>? item,
  String preferredScalingStat,
) {
  if (preferredScalingStat.isEmpty) return 0;
  final itemScalingStat = item?['scalingStat']?.toString() ?? '';
  return itemScalingStat == preferredScalingStat ? 20 : 0;
}

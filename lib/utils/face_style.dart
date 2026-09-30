import 'package:flutter/material.dart';

import '../combat/dice_faces.dart';
import '../combat/face_keywords.dart';
import '../combat/status_effect.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'game_icons.dart';

/// What a die face does, read at a glance: one colour per effect, the same
/// on the battle tray, the face sheet, the dice loadout and the skill list.
/// Red hits, steel guards, pink heals, blue fills the mana pool, and a
/// skill that lays a status wears that status's colour (poison green,
/// stun amber, weaken purple).
enum FaceKind { attack, defend, heal, mana, poison, stun, weaken, empty }

extension FaceKindStyle on FaceKind {
  Color get color => switch (this) {
        FaceKind.attack => const Color(0xFFE53935),
        FaceKind.defend => const Color(0xFF607D8B),
        FaceKind.heal => const Color(0xFFEC407A),
        FaceKind.mana => manaColor,
        FaceKind.poison => const Color(0xFF43A047),
        FaceKind.stun => const Color(0xFFFFA000),
        FaceKind.weaken => const Color(0xFF8E24AA),
        FaceKind.empty => Colors.grey,
      };

  IconData get icon => switch (this) {
        FaceKind.attack => Icons.bolt,
        FaceKind.defend => Icons.shield,
        FaceKind.heal => Icons.favorite,
        FaceKind.mana => manaIcon,
        FaceKind.poison => Icons.coronavirus,
        FaceKind.stun => Icons.flash_on,
        FaceKind.weaken => Icons.trending_down,
        FaceKind.empty => Icons.remove_circle_outline,
      };

  String get labelKey => switch (this) {
        FaceKind.attack => 'face_kind_attack',
        FaceKind.defend => 'face_kind_defend',
        FaceKind.heal => 'face_kind_heal',
        FaceKind.mana => 'face_kind_mana',
        FaceKind.poison => 'face_kind_poison',
        FaceKind.stun => 'face_kind_stun',
        FaceKind.weaken => 'face_kind_weaken',
        FaceKind.empty => 'face_kind_empty',
      };
}

/// A skill's rarity as the player reads it: a name and a colour, grey
/// through green, blue and purple to orange.
extension SkillRarityStyle on SkillRarity {
  Color get color => switch (this) {
        SkillRarity.common => const Color(0xFF9E9E9E),
        SkillRarity.uncommon => const Color(0xFF43A047),
        SkillRarity.rare => const Color(0xFF1E88E5),
        SkillRarity.epic => const Color(0xFF8E24AA),
        SkillRarity.legendary => const Color(0xFFFB8C00),
      };

  String get labelKey => 'skill_rarity_$name';
}

/// What [skill] does, as a [FaceKind]: the status it lays if any, then
/// mana, then damage, then healing. An unknown skill reads as an attack
/// (an open Skill face falls back to Heavy Blow).
FaceKind skillKind(Map<String, dynamic>? skill) {
  if (skill == null) return FaceKind.attack;
  switch (statusEffectTypeFromString(skill['inflictsStatus']?.toString())) {
    case StatusEffectType.poison:
      return FaceKind.poison;
    case StatusEffectType.stun:
      return FaceKind.stun;
    case StatusEffectType.weaken:
      return FaceKind.weaken;
    case null:
      break;
  }
  if (((skill['manaGain'] as num?)?.toInt() ?? 0) > 0) return FaceKind.mana;
  final damage = ((skill['damageMod'] as num?)?.toInt() ?? 0) > 0 ||
      ((skill['damageMultiplier'] as num?)?.toDouble() ?? 1.0) > 1.0;
  if (damage) return FaceKind.attack;
  if (((skill['healAmount'] as num?)?.toInt() ?? 0) > 0) return FaceKind.heal;
  return FaceKind.attack;
}

/// A face's [FaceKind] from its `type`; a Skill face reads the skill it
/// resolves to (see [skillKind]).
FaceKind faceKind(String type, {Map<String, dynamic>? skill}) {
  switch (type) {
    case 'Attack':
      return FaceKind.attack;
    case 'Defend':
      return FaceKind.defend;
    case 'Heal':
      return FaceKind.heal;
    case 'Mana':
      return FaceKind.mana;
    case 'Skill':
      return skillKind(skill);
    default:
      return FaceKind.empty;
  }
}

/// The colour key for dice: one small chip per effect, so the colours on
/// the faces read without guessing.
class FaceColorLegend extends StatelessWidget {
  const FaceColorLegend({super.key, required this.language});

  final AppLanguage language;

  static const List<FaceKind> kinds = [
    FaceKind.attack,
    FaceKind.defend,
    FaceKind.heal,
    FaceKind.mana,
    FaceKind.poison,
    FaceKind.stun,
    FaceKind.weaken,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final kind in kinds)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: kind.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kind.color.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(kind.icon, size: 12, color: kind.color),
                const SizedBox(width: 3),
                Text(
                  trFor(language, kind.labelKey),
                  style: TextStyle(
                      fontSize: 11,
                      color: kind.color,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A face keyword's icon and colour (v1.182, see face_keywords.dart): the
/// small badge on a die tile, in the face sheet and on the loadout.
extension FaceKeywordStyle on FaceKeyword {
  IconData get icon => switch (this) {
        FaceKeyword.cleave => Icons.call_split,
        FaceKeyword.pierce => Icons.arrow_forward,
        FaceKeyword.growth => Icons.trending_up,
        FaceKeyword.echo => Icons.repeat,
        FaceKeyword.pain => Icons.water_drop,
        FaceKeyword.steady => Icons.anchor,
      };

  Color get color => switch (this) {
        FaceKeyword.cleave => const Color(0xFFE65100),
        FaceKeyword.pierce => const Color(0xFF6D4C41),
        FaceKeyword.growth => const Color(0xFF2E7D32),
        FaceKeyword.echo => const Color(0xFF6A1B9A),
        FaceKeyword.pain => const Color(0xFFC62828),
        FaceKeyword.steady => const Color(0xFF455A64),
      };
}

/// A row of keyword badges, [size] each -- nothing for a face without one.
class FaceKeywordBadges extends StatelessWidget {
  const FaceKeywordBadges(this.keywords, {super.key, this.size = 11});

  final Iterable<FaceKeyword> keywords;
  final double size;

  @override
  Widget build(BuildContext context) {
    final list = keywords.toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final keyword in list)
          Padding(
            padding: const EdgeInsets.only(right: 1),
            child: Icon(keyword.icon, size: size, color: keyword.color),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

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

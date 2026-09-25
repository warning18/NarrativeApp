part of '../fight_screen.dart';

Color _logColor(BuildContext context, _LogKind kind) {
  switch (kind) {
    case _LogKind.info:
      return Theme.of(context).colorScheme.onSurfaceVariant;
    case _LogKind.playerDamage:
      return _attackColor;
    case _LogKind.playerHeal:
      return _healColor;
    case _LogKind.playerBlock:
      return _defendColor;
    case _LogKind.enemyDamage:
      return InkColors.of(context).blood;
    case _LogKind.victory:
      return InkColors.of(context).gold;
    case _LogKind.defeat:
      return Theme.of(context).colorScheme.error;
    case _LogKind.banter:
      return InkColors.of(context).ash;
    case _LogKind.mana:
      return manaColor;
    case _LogKind.phase:
      return _skillColor;
  }
}

IconData _logIcon(_LogKind kind) {
  switch (kind) {
    case _LogKind.info:
      return Icons.info_outline;
    case _LogKind.playerDamage:
      return Icons.bolt;
    case _LogKind.playerHeal:
      return Icons.favorite;
    case _LogKind.playerBlock:
      return Icons.shield;
    case _LogKind.enemyDamage:
      return Icons.warning_amber_rounded;
    case _LogKind.victory:
      return Icons.emoji_events;
    case _LogKind.defeat:
      return Icons.heart_broken;
    case _LogKind.banter:
      return Icons.chat_bubble_outline;
    case _LogKind.mana:
      return manaIcon;
    case _LogKind.phase:
      return Icons.change_circle_outlined;
  }
}

/// Icon for a die face's own type — distinct from [_logIcon], which is
/// about a resolved log line's category.
IconData _faceTypeIcon(String type) {
  switch (type) {
    case 'Attack':
      return Icons.bolt;
    case 'Defend':
      return Icons.shield;
    case 'Heal':
      return Icons.favorite;
    case 'Skill':
      return Icons.auto_awesome;
    case 'Mana':
      return manaIcon;
    default:
      return Icons.remove_circle_outline;
  }
}

// A die face's colour says what it does, the same everywhere in the app:
// ember for attacks, steel for guarding, green for healing, tide for
// mana and the Void's purple for techniques. Mid-tones, legible on both
// the dark page and the parchment one.
const Color _attackColor = Color(0xFFD9692A);
const Color _defendColor = Color(0xFF7F92A6);
const Color _healColor = Color(0xFF5FA64C);
const Color _skillColor = Color(0xFF9270DA);

Color _faceTypeColor(String type) {
  switch (type) {
    case 'Attack':
      return _attackColor;
    case 'Defend':
      return _defendColor;
    case 'Heal':
      return _healColor;
    case 'Mana':
      return manaColor;
    case 'Skill':
      return _skillColor;
    default:
      return Colors.grey;
  }
}

/// A small pill showing one active status effect's icon and how many
/// rounds it has left — the visual half of the status-effect system,
/// paired with the log lines [_FightScreenState] writes when one is
/// inflicted or ticks.
class _StatusEffectChip extends StatelessWidget {
  const _StatusEffectChip({required this.effect});

  final StatusEffect effect;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (effect.type) {
      StatusEffectType.poison => (Icons.coronavirus, Colors.green),
      StatusEffectType.stun => (Icons.flash_on, Colors.amber),
      StatusEffectType.weaken => (Icons.trending_down, Colors.purple),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '${effect.remainingTurns}',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// The setup screen's one-line note for a special encounter.
String _encounterNoteKey(EncounterModifiers modifiers) {
  if (modifiers.isHunt) return 'hunt_fight_note';
  if (modifiers.isZoneBoss) return 'zone_boss_fight_note';
  return 'hunter_fight_note';
}

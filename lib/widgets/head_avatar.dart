// A character's head, wherever a card needs a face (the fight's slots, the
// "Qui combat ?" card, the scene vignette, a spell's target list, an NPC's
// page): a crop of its sprite (assets/visuals/heads, made by
// tool/gen_fight_heads.py), found for the hero, Vica, every enemy (the ones
// that borrow another's icon wear that icon's head) and every NPC that is
// one; or, when there is none, its initial on a disc. One place to say which
// head a name gets, so a card never shows a letter where art exists.
import 'package:flutter/material.dart';

import '../utils/pixel_icons/enemy_icons.dart';

/// Heads of figures that have a sprite of their own though their enemy
/// record borrows another icon (the borrowed one would be the wrong face).
const Set<String> _ownHeads = {'aurel_vane'};

/// The head image of character [id] (hero, a companion, an enemy, an NPC),
/// or null when none can exist (the asset may still be missing: the widget
/// falls back to the letter then).
String headAssetOf(String id) {
  if (id.isEmpty) return '';
  final name = _ownHeads.contains(id)
      ? id
      : EnemyIcons.pathFor(id).split('/').last.replaceAll('.png', '');
  return 'assets/visuals/heads/$name.png';
}

class HeadAvatar extends StatelessWidget {
  const HeadAvatar({
    super.key,
    required this.id,
    required this.name,
    this.size = 36,
    this.accent,
    this.dim = false,
    this.fallback,
  });

  /// The character's id (see [headAssetOf]).
  final String id;

  /// The name, for the initial when there is no head.
  final String name;
  final double size;

  /// The disc's colour behind the initial (the primary colour by default).
  final Color? accent;
  final bool dim;

  /// Shown instead of the initial when there is no head (an NPC's kind
  /// icon, a voice).
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final letter = Center(
      child: fallback ??
          Container(
            width: size * 0.74,
            height: size * 0.74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: accent ?? scheme.primary),
            child: Text(initial,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold)),
          ),
    );
    final asset = headAssetOf(id);
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Container(
        key: Key('head_$id'),
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: asset.isEmpty
            ? letter
            : Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
                errorBuilder: (_, __, ___) => letter,
              ),
      ),
    );
  }
}

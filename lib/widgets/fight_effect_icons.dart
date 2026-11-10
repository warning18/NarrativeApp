// The small effect icons on a fighter's card (combat redesign, A'): what is
// acting on a fighter (a poison, a block, a Fury at 3...) as a 9 x 9 pixel
// icon in one colour, a corner number for the turns left or the value, and a
// pop-in that explains it on a tap. Drawn in code: no image to ship.
import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// What an icon can stand for.
enum FightEffect {
  poison,
  stun,
  weaken,
  block,
  parry,
  shelter,
  fury,
  watchfire,
  target,
  guard,
  windUp,
  staggered,
  rally,
  flee,
  info,
}

const Map<FightEffect, List<String>> _bitmaps = {
  FightEffect.poison: [
    '....#....',
    '....#....',
    '...###...',
    '..#####..',
    '.#######.',
    '.#######.',
    '.#######.',
    '..#####..',
    '...###...',
  ],
  FightEffect.stun: [
    '.....###.',
    '....###..',
    '...###...',
    '..#####..',
    '....##...',
    '...##....',
    '..##.....',
    '.##......',
    '.#.......',
  ],
  FightEffect.weaken: [
    '...###...',
    '...###...',
    '...###...',
    '...###...',
    '#########',
    '.#######.',
    '..#####..',
    '...###...',
    '....#....',
  ],
  FightEffect.block: [
    '#########',
    '#########',
    '#########',
    '#########',
    '.#######.',
    '.#######.',
    '..#####..',
    '...###...',
    '....#....',
  ],
  FightEffect.parry: [
    '#########',
    '##.######',
    '###.#####',
    '####.####',
    '.####.##.',
    '.#####.#.',
    '..#####..',
    '...###...',
    '....#....',
  ],
  FightEffect.shelter: [
    '....#....',
    '...###...',
    '..#####..',
    '.#######.',
    '#########',
    '.##...##.',
    '.##...##.',
    '.##...##.',
    '.#######.',
  ],
  FightEffect.fury: [
    '....#....',
    '....##...',
    '...###...',
    '..####.#.',
    '.#######.',
    '.#######.',
    '.#######.',
    '..#####..',
    '...###...',
  ],
  FightEffect.watchfire: [
    '....#....',
    '...##....',
    '..###.#..',
    '..#####..',
    '.#######.',
    '.#######.',
    '.#######.',
    '..#####..',
    '...###...',
  ],
  FightEffect.target: [
    '....#....',
    '..#####..',
    '.#..#..#.',
    '.#..#..#.',
    '#########',
    '.#..#..#.',
    '.#..#..#.',
    '..#####..',
    '....#....',
  ],
  FightEffect.guard: [
    '.#######.',
    '#########',
    '#########',
    '#########',
    '#########',
    '.#######.',
    '..#####..',
    '...###...',
    '....#....',
  ],
  FightEffect.windUp: [
    '#########',
    '.#######.',
    '..#####..',
    '...###...',
    '....#....',
    '...###...',
    '..#####..',
    '.#######.',
    '#########',
  ],
  FightEffect.staggered: [
    '.##......',
    '..##.....',
    '...##....',
    '..##.....',
    '.##......',
    '..##.....',
    '...##....',
    '..##.....',
    '.##......',
  ],
  FightEffect.rally: [
    '.#.......',
    '.###.....',
    '.#####...',
    '.#######.',
    '.#####...',
    '.###.....',
    '.#.......',
    '.#.......',
    '.#.......',
  ],
  FightEffect.flee: [
    '....#....',
    '.....#...',
    '......#..',
    '#########',
    '......#..',
    '.....#...',
    '....#....',
    '.........',
    '.........',
  ],
  FightEffect.info: [
    '...###...',
    '...###...',
    '.........',
    '..####...',
    '...###...',
    '...###...',
    '...###...',
    '..#####..',
    '..#####..',
  ],
};

/// The icon's colour.
Color _fightEffectColor(FightEffect effect) => switch (effect) {
      FightEffect.poison => const Color(0xFF4CAF50),
      FightEffect.stun => Palette.goldDark,
      FightEffect.weaken => const Color(0xFFA070E0),
      FightEffect.block => Palette.blue54,
      FightEffect.parry => const Color(0xFF5FD0D0),
      FightEffect.shelter => Palette.orange61,
      FightEffect.fury => Palette.orange52,
      FightEffect.watchfire => const Color(0xFFF2D14E),
      FightEffect.target => const Color(0xFFE0453B),
      FightEffect.guard => Palette.stone57a,
      FightEffect.windUp => Palette.orange52,
      FightEffect.staggered => const Color(0xFF3FB5A8),
      FightEffect.rally => const Color(0xFFD64A4A),
      FightEffect.flee => Palette.orange55,
      FightEffect.info => const Color(0xFF9A94A8),
    };

class _PixelPainter extends CustomPainter {
  const _PixelPainter(this.rows, this.color);

  final List<String> rows;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '#') {
          canvas.drawRect(
              Rect.fromLTWH(x * cell, y * cell, cell + 0.4, cell + 0.4), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) =>
      old.rows != rows || old.color != color;
}

/// One effect icon: a tinted tile with the 9 x 9 pixel picture, [badge] (the
/// turns left or the value) at its corner, and [onTap] (usually the pop-in).
class FightEffectChip extends StatelessWidget {
  const FightEffectChip({
    super.key,
    required this.effect,
    required this.label,
    this.badge,
    this.size = 22,
    this.onTap,
  });

  final FightEffect effect;

  /// What a screen reader says (the effect's name).
  final String label;
  final String? badge;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _fightEffectColor(effect);
    return Semantics(
      button: onTap != null,
      label: badge == null ? label : '$label $badge',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 3),
          child: _EffectTile(
            size: size,
            color: color,
            radius: 6,
            badge: badge,
            child: Padding(
              padding: EdgeInsets.all(size * 0.2),
              child:
                  CustomPaint(painter: _PixelPainter(_bitmaps[effect]!, color)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A fight-wide status as an icon tile (the top strip: the goal, the
/// weather, an anomaly, the momentum, a nudge count...): a tinted tile with
/// a Material [icon], [badge] at its corner (a count or turns left), and a
/// tap that opens the pop-in with [label] and [body].
class FightStatusTile extends StatelessWidget {
  const FightStatusTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.body,
    required this.closeHint,
    this.badge,
    this.subtitle = '',
    this.size = 32,
    this.reachTop = 0,
    this.reachBottom = 0,
  });

  /// Room above and below the tile that belongs to its tap area but not to
  /// its look: the strip it sits in hands over its own spacing, so the tap
  /// area is taller while nothing moves (a tap outside a widget's own box
  /// never reaches it, so the room has to be inside it).
  final double reachTop;
  final double reachBottom;

  final IconData icon;
  final Color color;
  final String label;
  final String body;
  final String closeHint;
  final String? badge;
  final String subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: badge == null ? label : '$label $badge',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final box = context.findRenderObject();
          if (box is! RenderBox || !box.hasSize) return;
          showFightEffectPopin(
            context,
            // The tile itself, not the room around it that only taps use.
            anchor: box.localToGlobal(Offset(0, reachTop)) &
                Size(box.size.width, box.size.height - reachTop - reachBottom),
            leading: _statusTile(icon, color, null, 34),
            color: color,
            title: label,
            subtitle: subtitle,
            body: body,
            closeHint: closeHint,
          );
        },
        child: Padding(
          padding:
              EdgeInsets.only(top: reachTop, right: 6, bottom: 5 + reachBottom),
          child: _statusTile(icon, color, badge, size),
        ),
      ),
    );
  }

  static Widget _statusTile(
          IconData icon, Color color, String? badge, double size) =>
      _EffectTile(
        size: size,
        color: color,
        radius: 8,
        badge: badge,
        child: Icon(icon, size: size * 0.56, color: color),
      );
}

/// The tinted square both kinds of tile share (a fighter's effect and a
/// fight-wide status): [child] inside, [badge] at its corner.
class _EffectTile extends StatelessWidget {
  const _EffectTile({
    required this.size,
    required this.color,
    required this.radius,
    required this.child,
    this.badge,
  });

  final double size;
  final Color color;
  final double radius;
  final Widget child;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: color.withValues(alpha: 0.65)),
              ),
              child: child,
            ),
          ),
          if (badge != null)
            Positioned(
              right: -4,
              bottom: -5,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF15131A),
                  borderRadius: BorderRadius.circular(radius - 1),
                  border: Border.all(color: color.withValues(alpha: 0.9)),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 9,
                        height: 1.1,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The pop-in under (or over) the icon at [anchor] (its rectangle on the
/// screen): the icon, [title], [subtitle] (who, turns left), [body] (what it
/// does) and a line to close it; a tap anywhere closes it.
Future<void> showFightEffectPopin(
  BuildContext context, {
  required Rect anchor,
  FightEffect? effect,
  Widget? leading,
  Color? color,
  required String title,
  required String subtitle,
  required String body,
  required String closeHint,
}) {
  assert(effect != null || (leading != null && color != null));
  final color0 = color ?? _fightEffectColor(effect!);
  final lead =
      leading ?? FightEffectChip(effect: effect!, label: title, size: 34);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: closeHint,
    barrierColor: Colors.transparent,
    transitionDuration: MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 120),
    pageBuilder: (context, _, __) {
      final screen = MediaQuery.of(context).size;
      const width = 300.0;
      final left = (anchor.left - 8).clamp(10.0, screen.width - width - 10);
      final below = anchor.bottom + 160 < screen.height;
      final theme = Theme.of(context);
      final card = Material(
        key: const Key('fight_effect_popin'),
        color: const Color(0xFF241F2B),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  lead,
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: color0, fontWeight: FontWeight.w700)),
                        Text(subtitle,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: const Color(0xFF9A94A8))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(body,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFFE8E2D2), height: 1.35)),
              const SizedBox(height: 8),
              Text(closeHint,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: const Color(0xFF9A94A8))),
            ],
          ),
        ),
      );
      return Stack(
        children: [
          Positioned(
            left: left,
            width: width,
            top: below ? anchor.bottom + 6 : null,
            bottom: below ? null : screen.height - anchor.top + 6,
            child: card,
          ),
        ],
      );
    },
  );
}

/// One line of the effects pop-in: an effect of a fighter, with what it does.
class FightEffectEntry {
  const FightEffectEntry({
    required this.effect,
    required this.title,
    required this.body,
    this.badge,
  });

  final FightEffect effect;
  final String title;
  final String body;
  final String? badge;
}

/// The pop-in of a fighter's effects, all at once: [title] (who, how many),
/// then each of [entries] with its icon, name and rule, and a line to close
/// it. Same card as [showFightEffectPopin], under (or over) the icon at
/// [anchor]; it scrolls when the list is long. A tap anywhere closes it.
Future<void> showFightEffectsPopin(
  BuildContext context, {
  required Rect anchor,
  required String title,
  required List<FightEffectEntry> entries,
  required String closeHint,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: closeHint,
    barrierColor: Colors.transparent,
    transitionDuration: MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 120),
    pageBuilder: (context, _, __) {
      final screen = MediaQuery.of(context).size;
      const width = 300.0;
      final left = (anchor.left - 8).clamp(10.0, screen.width - width - 10);
      final below = anchor.bottom + 200 < screen.height;
      final room = below
          ? screen.height - anchor.bottom - 16
          : anchor.top - MediaQuery.of(context).padding.top - 16;
      final theme = Theme.of(context);
      const ink = Color(0xFFE8E2D2);
      const muted = Color(0xFF9A94A8);
      final card = Material(
        key: const Key('fight_effect_popin'),
        color: const Color(0xFF241F2B),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.white38),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: room.clamp(160.0, 1000.0)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in entries) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FightEffectChip(
                                  effect: e.effect,
                                  label: e.title,
                                  badge: e.badge,
                                  size: 30),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: ink,
                                                fontWeight: FontWeight.w700)),
                                    Text(e.body,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: ink, height: 1.3)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(closeHint,
                    style: theme.textTheme.labelSmall?.copyWith(color: muted)),
              ],
            ),
          ),
        ),
      );
      return Stack(
        children: [
          Positioned(
            left: left,
            width: width,
            top: below ? anchor.bottom + 6 : null,
            bottom: below ? null : screen.height - anchor.top + 6,
            child: card,
          ),
        ],
      );
    },
  );
}

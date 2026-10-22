// The fight's entrance card (wave 16, item 3): a boss or a named foe is
// announced before the fight opens. Its pixel portrait slides in from the
// right with its name and one line of its story, holds, and fades away,
// 1.2 s in all; a tap on the card ends it at once. With reduced motion the
// card is not shown. It takes no touch outside the card, so the setup under
// it is never kept waiting.
import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';
import 'combat_vfx.dart';
import 'pixel_portrait.dart';

/// How long the entrance card lasts.
const Duration fightEntranceTime = Duration(milliseconds: 1200);

/// The first sentence of [description], cut at [max] characters with an
/// ellipsis: the one line of story the card carries.
String entranceLine(String description, {int max = 90}) {
  final text = description.trim();
  if (text.isEmpty) return '';
  final end = RegExp(r'[.!?](\s|$)').firstMatch(text);
  final first = end == null ? text : text.substring(0, end.start + 1);
  if (first.length <= max) return first;
  return '${first.substring(0, max - 1).trimRight()}…';
}

/// [child] with the entrance card of [enemyId] laid over it for
/// [fightEntranceTime] when [show] is set.
class FightEntrance extends StatefulWidget {
  const FightEntrance({
    super.key,
    required this.enemyId,
    required this.name,
    required this.child,
    this.line = '',
    this.boss = false,
    this.show = true,
  });

  final String enemyId;
  final String name;

  /// One line of the foe's story; none when empty.
  final String line;
  final bool boss;
  final bool show;
  final Widget child;

  @override
  State<FightEntrance> createState() => _FightEntranceState();
}

class _FightEntranceState extends State<FightEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: fightEntranceTime)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) _end();
        });
  final CombatVfxController _vfx = CombatVfxController();
  final GlobalKey _anchor = GlobalKey();
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced motion: no card at all.
    if (!widget.show || MediaQuery.of(context).disableAnimations) {
      _done = true;
      return;
    }
    _anim.forward();
  }

  void _end() {
    if (_done) return;
    setState(() => _done = true);
  }

  @override
  void dispose() {
    _anim.dispose();
    _vfx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => _card(context, _anim.value),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, double t) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    // In over the first fifth, out over the last fifth.
    final fade = (t / 0.15).clamp(0.0, 1.0) * ((1 - t) / 0.2).clamp(0.0, 1.0);
    final slide = Curves.easeOutCubic.transform((t / 0.3).clamp(0.0, 1.0));
    final accent = widget.boss ? ink.ember : ink.gold;
    final line = widget.line;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child:
                ColoredBox(color: Colors.black.withValues(alpha: 0.5 * fade)),
          ),
        ),
        Align(
          child: Opacity(
            opacity: fade,
            child: GestureDetector(
              key: const Key('fight_entrance_card'),
              behavior: HitTestBehavior.opaque,
              onTap: _end,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: widget.boss ? 22 : 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(90 * (1 - slide), 0),
                      child: PixelEnemyPortrait(
                        enemyId: widget.enemyId,
                        alive: true,
                        controller: _vfx,
                        anchor: _anchor,
                        boss: widget.boss,
                        animate: false,
                        size: 96,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.name,
                        key: const Key('fight_entrance_name'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: accent)),
                    if (line.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(line,
                          key: const Key('fight_entrance_line'),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

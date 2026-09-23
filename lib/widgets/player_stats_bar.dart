import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';

class PlayerStatsBar extends ConsumerWidget {
  const PlayerStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);

    Widget chip(IconData icon, String label) => Chip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          chip(Icons.shield, '${tr(ref, 'level_abbrev')} ${session.level}'),
          const SizedBox(width: 6),
          _PulseOnChange(
            value: session.currentHealth,
            child: chip(
              Icons.favorite,
              '${session.currentHealth}/${session.maxHealth} ${tr(ref, 'hp_label')}',
            ),
          ),
          const SizedBox(width: 6),
          _PulseOnChange(
            value: session.mana,
            child: chip(
              manaIcon,
              '${session.mana}/${session.maxMana} ${tr(ref, 'mana_label')}',
            ),
          ),
          const SizedBox(width: 6),
          _PulseOnChange(
              value: session.gold, child: chip(Icons.paid, '${session.gold}g')),
          const SizedBox(width: 6),
          chip(Icons.balance, trAlignmentLabel(ref, session.alignmentLabel)),
          if (session.flags.isNotEmpty) ...[
            const SizedBox(width: 6),
            chip(Icons.flag,
                '${session.flags.length} ${tr(ref, 'flags_count_label')}'),
          ],
        ],
      ),
    );
  }
}

/// Briefly scales [child] up and back down whenever [value] changes —
/// gives a quick "pop" to the HP/gold chips when they take damage, heal, or
/// gain/spend gold, instead of the number silently changing.
class _PulseOnChange extends StatefulWidget {
  const _PulseOnChange({required this.value, required this.child});

  final Object value;
  final Widget child;

  @override
  State<_PulseOnChange> createState() => _PulseOnChangeState();
}

class _PulseOnChangeState extends State<_PulseOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _PulseOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}

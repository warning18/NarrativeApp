import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/player_session_provider.dart';
import '../utils/game_icons.dart';

/// The party's vital numbers on one line: level, health, mana, gold and
/// the open quests, sized down rather than scrolled when the screen is
/// narrow. [trailing] widgets (the story's journal and read-aloud buttons)
/// sit at the end of the line. Tapping the numbers opens the rest in a
/// sheet: experience, alignment, flags, and the way to the quests and
/// shops (see [showPlayerStatusSheet]).
class PlayerStatsBar extends ConsumerWidget {
  const PlayerStatsBar({super.key, this.trailing = const []});

  final List<Widget> trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final scheme = Theme.of(context).colorScheme;
    final lowHealth = session.maxHealth > 0 &&
        session.currentHealth * 10 <= session.maxHealth * 3;

    final stats = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Stat(
          icon: Icons.shield,
          text: '${tr(ref, 'level_abbrev')} ${session.level}',
          tooltip: tr(ref, 'level_abbrev'),
        ),
        _PulseOnChange(
          value: session.currentHealth,
          child: _Stat(
            icon: Icons.favorite,
            text: '${session.currentHealth}/${session.maxHealth}',
            tooltip: tr(ref, 'hp_label'),
            color: lowHealth ? scheme.error : null,
          ),
        ),
        _PulseOnChange(
          value: session.mana,
          child: _Stat(
            icon: manaIcon,
            text: '${session.mana}/${session.maxMana}',
            tooltip: tr(ref, 'mana_label'),
          ),
        ),
        _PulseOnChange(
          value: session.gold,
          child: _Stat(
            icon: Icons.paid,
            text: '${session.gold}',
            tooltip: tr(ref, 'gold_label'),
          ),
        ),
        if (session.activeQuestIds.isNotEmpty)
          _Stat(
            icon: Icons.assignment_outlined,
            text: '${session.activeQuestIds.length}',
            tooltip: tr(ref, 'quests'),
          ),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => showPlayerStatusSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: stats,
              ),
            ),
          ),
        ),
        ...trailing,
      ],
    );
  }
}

/// One number on [PlayerStatsBar]: an icon and its value.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.text,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final String text;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(width: 4),
            Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything [PlayerStatsBar] leaves out: level and experience, health,
/// mana, gold, alignment and flags, with the way to the quests and shops
/// on the Play tab.
Future<void> showPlayerStatusSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _PlayerStatusSheet(),
  );
}

class _PlayerStatusSheet extends ConsumerWidget {
  const _PlayerStatusSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    Widget row(IconData icon, String label, String value) => ListTile(
          dense: true,
          leading: Icon(icon, size: 20),
          title: Text(label),
          trailing: Text(value, style: Theme.of(context).textTheme.titleSmall),
        );
    void openPlay() {
      Navigator.of(context).pop();
      ref.read(homeTabIndexProvider.notifier).state =
          questsTabIndex(ref.read(appModeProvider));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(Icons.shield, tr(ref, 'level_field_label'),
                '${session.level} · ${session.currentXP}/${session.xpToNextLevel} ${tr(ref, 'xp_label')}'),
            row(Icons.favorite, tr(ref, 'hp_label'),
                '${session.currentHealth}/${session.maxHealth}'),
            row(manaIcon, tr(ref, 'mana_label'),
                '${session.mana}/${session.maxMana}'),
            row(Icons.paid, tr(ref, 'gold_field_label'), '${session.gold}'),
            row(Icons.balance, tr(ref, 'alignment_label'),
                trAlignmentLabel(ref, session.alignmentLabel)),
            if (session.flags.isNotEmpty)
              row(Icons.flag, tr(ref, 'flags_count_label'),
                  '${session.flags.length}'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.assignment, size: 16),
                    label: Text(
                        '${tr(ref, 'quests')} (${session.activeQuestIds.length})'),
                    onPressed: openPlay,
                  ),
                  if (session.unlockedShopIds.isNotEmpty)
                    ActionChip(
                      avatar: const Icon(Icons.storefront, size: 16),
                      label: Text(
                          '${tr(ref, 'shops')} (${session.unlockedShopIds.length})'),
                      onPressed: openPlay,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The purse, for the top of any screen where gold is spent or earned
/// (shops, the forge, the camp, the boat): a coin and the amount, which
/// pops when it changes.
class GoldBadge extends ConsumerWidget {
  const GoldBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gold = ref.watch(playerSessionProvider.select((s) => s.gold));
    final theme = Theme.of(context);
    return Tooltip(
      message: tr(ref, 'gold_label'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _PulseOnChange(
          value: gold,
          child: Container(
            key: const ValueKey('gold_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.paid,
                    size: 18, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 4),
                Text(
                  '$gold',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
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

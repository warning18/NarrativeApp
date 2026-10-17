import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/fight_goal.dart' show yieldHealthShare;
import '../../combat/fight_tips.dart';
import '../../l10n/app_strings.dart';
import '../../providers/player_session_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../theme/stitched_ink.dart';

/// The fight's one-time tips on its setup screen (see fight_tips.dart):
/// what this fight's goal, doctrine and situation mean, the first time a
/// save meets each. Every tip due is shown in one card, one after another
/// ("1/3", Next), and each is marked seen on this save as the player moves
/// past it. Nothing shows when tutorials are off.
///
/// The look is the ship battle's one-time tip (ship_battle_panel.dart):
/// a lightbulb on the secondary container, a gold edge, a tick.
class FightTipsCard extends ConsumerStatefulWidget {
  const FightTipsCard({super.key, required this.shown, this.holdRounds = 0});

  /// The tips this fight shows (see [fightTipIdsFor]).
  final List<String> shown;

  /// A hold's turns, for the hold's `{n}`.
  final int holdRounds;

  @override
  ConsumerState<FightTipsCard> createState() => _FightTipsCardState();
}

class _FightTipsCardState extends ConsumerState<FightTipsCard> {
  /// The tips due, fixed the first time the tutorial settings are known so
  /// the count does not shrink as each is marked seen.
  List<String>? _due;
  int _index = 0;

  void _next() {
    final due = _due!;
    final id = due[_index];
    setState(() => _index++);
    ref.read(playerSessionProvider.notifier).markFightTipsSeen([id]);
  }

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialProvider);
    if (_due == null) {
      if (!tutorial.loaded) return const SizedBox.shrink();
      _due = dueFightTips(
        shown: widget.shown,
        seen: ref.read(playerSessionProvider).seenFightTipIds,
        enabled: tutorial.enabled && ref.read(tutorialAutoShowProvider),
      );
    }
    final due = _due!;
    if (!tutorial.enabled || _index >= due.length) {
      return const SizedBox.shrink();
    }
    final id = due[_index];
    final last = _index == due.length - 1;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final onTip = theme.colorScheme.onSecondaryContainer;
    final text = tr(ref, fightTipTextKey(id))
        .replaceAll('{n}', '${widget.holdRounds}')
        .replaceAll('{pct}', '${(yieldHealthShare * 100).round()}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        key: Key('fight_tip_$id'),
        color: theme.colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: ink.gold),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: onTip),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due.length > 1
                          ? '${tr(ref, fightTipNameKey(id))} · '
                              '${_index + 1}/${due.length}'
                          : tr(ref, fightTipNameKey(id)),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold, color: onTip),
                    ),
                    Text(text,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(height: 1.25, color: onTip)),
                  ],
                ),
              ),
              IconButton(
                key: Key(last ? 'fight_tip_ok' : 'fight_tip_next'),
                tooltip: tr(ref, last ? 'tip_got_it' : 'tip_fight_next'),
                visualDensity: VisualDensity.compact,
                icon: Icon(last ? Icons.check : Icons.arrow_forward,
                    size: 20, color: ink.gold),
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

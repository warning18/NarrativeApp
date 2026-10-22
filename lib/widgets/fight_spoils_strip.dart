// The fight's finish (wave 16, item 3): once a fight is won, a strip over the
// log tallies what it brought as it lands: the gold and the XP count up,
// then each item drops into the strip, one after another. The numbers are
// the ones the fight already settled (fight_rewards.dart); this only shows
// them. With reduced motion the strip is complete at once.
import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';

/// One item of the spoils: its id and kind (for the icon) and its name.
class SpoilItem {
  const SpoilItem(this.id, this.type, this.name);

  final String id;
  final String type;
  final String name;
}

/// What a won fight brought.
class FightSpoils {
  const FightSpoils({
    required this.gold,
    required this.xp,
    this.items = const [],
  });

  final int gold;
  final int xp;
  final List<SpoilItem> items;

  /// Nothing to show: no gold, no XP, no items.
  bool get isEmpty => gold <= 0 && xp <= 0 && items.isEmpty;
}

/// How long the gold and the XP count up, and the pause before and between
/// the items.
const Duration spoilsCountTime = Duration(milliseconds: 700);
const Duration spoilsItemGap = Duration(milliseconds: 220);
const Duration spoilsItemTime = Duration(milliseconds: 320);

/// The strip: "+gold G  +xp XP" and the items, dropping in.
class FightSpoilsStrip extends StatefulWidget {
  const FightSpoilsStrip({
    super.key,
    required this.spoils,
    required this.goldLabel,
  });

  final FightSpoils spoils;

  /// The word for gold ("Gold").
  final String goldLabel;

  @override
  State<FightSpoilsStrip> createState() => _FightSpoilsStripState();
}

class _FightSpoilsStripState extends State<FightSpoilsStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: spoilsCountTime +
        spoilsItemGap * widget.spoils.items.length +
        spoilsItemTime,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _anim.value = 1;
    } else {
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spoils = widget.spoils;
    if (spoils.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final total = _anim.duration!.inMilliseconds;
    return Container(
      key: const Key('fight_spoils_strip'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.gold.withValues(alpha: 0.7)),
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final ms = _anim.value * total;
          final count = Curves.easeOut
              .transform((ms / spoilsCountTime.inMilliseconds).clamp(0.0, 1.0));
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              if (spoils.gold > 0)
                Text('+${(spoils.gold * count).round()} ${widget.goldLabel}',
                    key: const Key('fight_spoils_gold'),
                    style:
                        theme.textTheme.labelLarge?.copyWith(color: ink.gold)),
              if (spoils.xp > 0)
                Text('+${(spoils.xp * count).round()} XP',
                    key: const Key('fight_spoils_xp'),
                    style:
                        theme.textTheme.labelLarge?.copyWith(color: ink.heal)),
              for (var i = 0; i < spoils.items.length; i++)
                _drop(spoils.items[i], i, ms),
            ],
          );
        },
      ),
    );
  }

  /// Item [i] falls in from above once its turn comes.
  Widget _drop(SpoilItem item, int i, double ms) {
    final start =
        spoilsCountTime.inMilliseconds * 0.6 + spoilsItemGap.inMilliseconds * i;
    final p = ((ms - start) / spoilsItemTime.inMilliseconds).clamp(0.0, 1.0);
    final fall = Curves.bounceOut.transform(p);
    return Tooltip(
      message: item.name,
      child: Opacity(
        opacity: (p * 3).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -18 * (1 - fall)),
          child: ItemPixelIcon(item.id, item.type, size: 28),
        ),
      ),
    );
  }
}

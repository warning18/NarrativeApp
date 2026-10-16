// The unlock moment (docs/proposals/unlock-moment-ux.md): how the feature
// ladder (data/feature_unlocks.dart) shows itself.
//
// - [FeatureGate]: a tab or button of a bar is hidden until it opens; a part
//   of a screen the player is already in is greyed with a lock, and a tap
//   says in one line when it opens ([FeatureLockedTile], [showFeatureLocked]).
// - [FeatureUnlockHost]: over the home shell, the "New: X" card that slides
//   in when a feature opens, one at a time, never over a fight. "Show me"
//   plays the feature's tour; "Later" keeps the gold dot ([UnlockDot]) on the
//   thing until it is first opened.
// - Under reduced motion the card fades in place and the dot is still.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feature_unlocks.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/feature_unlocks_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/tutorial_launcher.dart';
import '../tutorial/tutorial_topics.dart';

export '../data/feature_unlocks.dart' show GameFeature, GameFeatureInfo;
export '../providers/feature_unlocks_provider.dart' show isFeatureUnlocked;

/// What the player is told of a feature: its icon, its tour (when it has
/// one), and its words in `feature_<id>_name` / `feature_<id>_line`.
class FeatureUnlockInfo {
  const FeatureUnlockInfo(this.icon, {this.topic});

  final IconData icon;
  final TutorialTopic? topic;
}

FeatureUnlockInfo featureUnlockInfo(GameFeature feature) => switch (feature) {
      GameFeature.chest => const FeatureUnlockInfo(Icons.inventory_2_outlined),
      GameFeature.placeRules => const FeatureUnlockInfo(Icons.rule),
      GameFeature.conditions =>
        const FeatureUnlockInfo(Icons.thunderstorm_outlined),
      GameFeature.levelUp => const FeatureUnlockInfo(Icons.trending_up,
          topic: TutorialTopic.levelUp),
      GameFeature.quests => const FeatureUnlockInfo(Icons.assignment_outlined,
          topic: TutorialTopic.other),
      GameFeature.inventory => const FeatureUnlockInfo(Icons.backpack_outlined,
          topic: TutorialTopic.inventory),
      GameFeature.skills => const FeatureUnlockInfo(Icons.auto_awesome,
          topic: TutorialTopic.skills),
      GameFeature.politics => const FeatureUnlockInfo(Icons.balance),
      GameFeature.clans => const FeatureUnlockInfo(Icons.draw_outlined,
          topic: TutorialTopic.signs),
    };

/// Tells the session the player has found [feature] (its dot goes). Safe to
/// call for a feature that is not new.
void acknowledgeOnOpen(WidgetRef ref, GameFeature feature) {
  if (ref.read(newlyUnlockedProvider).contains(feature.id)) {
    ref.read(playerSessionProvider.notifier).acknowledgeFeature(feature.id);
  }
}

/// Shows [child] once [feature] is open. Locked, a bar's item is gone
/// ([SizedBox.shrink]) and a part of a screen shows [locked] (a
/// [FeatureLockedTile] for instance) when given.
class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.locked,
  });

  final GameFeature feature;
  final Widget child;
  final Widget? locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      isFeatureUnlocked(ref, feature.id)
          ? child
          : (locked ?? const SizedBox.shrink());
}

/// Whether [feature] is open (a watch).
bool featureOpen(WidgetRef ref, GameFeature feature) =>
    isFeatureUnlocked(ref, feature.id);

/// A small sheet: what is shut and when it opens, in one line.
Future<void> showFeatureLocked(
    BuildContext context, WidgetRef ref, GameFeature feature) {
  final info = featureUnlockInfo(feature);
  final name = tr(ref, 'feature_${feature.id}_name');
  final ink = InkColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Row(
          key: const Key('feature_locked_sheet'),
          children: [
            Icon(Icons.lock_outline, color: ink.ash),
            const SizedBox(width: 12),
            Icon(info.icon, color: ink.ash),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(ref, 'feature_opens_in')
                    .replaceAll('{n}', '${feature.chapter}')
                    .replaceAll('{name}', name),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A part of a screen that is shut: calmly greyed with a lock, and a tap
/// says when it opens.
class FeatureLockedTile extends ConsumerWidget {
  const FeatureLockedTile({super.key, required this.feature, this.title});

  final GameFeature feature;

  /// The shut part's own name; the feature's when null.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    return Opacity(
      opacity: 0.6,
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: ink.seam),
        ),
        child: InkWell(
          key: Key('feature_locked_${feature.id}'),
          borderRadius: BorderRadius.circular(4),
          onTap: () => showFeatureLocked(context, ref, feature),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(featureUnlockInfo(feature).icon, color: ink.ash),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title ?? tr(ref, 'feature_${feature.id}_name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall),
                ),
                Icon(Icons.lock_outline, size: 18, color: ink.ash),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gold dot on a thing that just opened, kept until it is first opened
/// (it breathes three times, then rests; still under reduced motion).
class UnlockDot extends ConsumerStatefulWidget {
  const UnlockDot({super.key, required this.feature});

  final GameFeature feature;

  @override
  ConsumerState<UnlockDot> createState() => _UnlockDotState();
}

class _UnlockDotState extends ConsumerState<UnlockDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
  bool _started = false;

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fresh = ref.watch(newlyUnlockedProvider).contains(widget.feature.id);
    if (!fresh) return const SizedBox.shrink();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!_started && !still) {
      _started = true;
      _ring.repeat(count: 3);
    }
    final gold = InkColors.of(context).gold;
    return SizedBox(
      key: Key('unlock_dot_${widget.feature.id}'),
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!still)
            AnimatedBuilder(
              animation: _ring,
              builder: (context, _) => Container(
                width: 8 + 10 * _ring.value,
                height: 8 + 10 * _ring.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: gold.withValues(alpha: 1 - _ring.value),
                      width: 1.5),
                ),
              ),
            ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// How long a card stays when it is not tapped.
const Duration unlockCardStay = Duration(seconds: 6);

/// Over its [child] (the home shell), the card of the next feature that
/// opened and was not yet told of. It waits while another screen (a fight,
/// a page) covers the child, and is not a dialog: the game underneath keeps
/// working.
class FeatureUnlockHost extends ConsumerStatefulWidget {
  const FeatureUnlockHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FeatureUnlockHost> createState() => _FeatureUnlockHostState();
}

class _FeatureUnlockHostState extends ConsumerState<FeatureUnlockHost> {
  /// Cards let go by their time, kept new (their dot stays) but not shown
  /// again this run.
  final Set<String> _passed = {};
  Timer? _timer;
  String? _timed;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm(String id) {
    if (_timed == id) return;
    _timer?.cancel();
    _timed = id;
    _timer = Timer(unlockCardStay, () {
      if (!mounted) return;
      setState(() => _passed.add(id));
    });
  }

  void _done(GameFeature feature, {bool tour = false}) {
    _timer?.cancel();
    _timed = null;
    ref.read(playerSessionProvider.notifier).acknowledgeFeature(feature.id);
    final topic = featureUnlockInfo(feature).topic;
    if (tour && topic != null) playTutorial(context, ref, topic);
  }

  @override
  Widget build(BuildContext context) {
    final newly = ref.watch(newlyUnlockedProvider);
    final id = newly.where((i) => !_passed.contains(i)).firstOrNull;
    final feature = gameFeatureNamed(id);
    final fighting = ref.watch(combatActiveProvider);
    final showing = feature != null &&
        !fighting &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (showing) {
      _arm(feature.id);
    } else {
      _timer?.cancel();
      _timed = null;
    }
    return Stack(
      children: [
        widget.child,
        if (showing)
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _UnlockCard(
                    key: ValueKey('unlock_card_${feature.id}'),
                    feature: feature,
                    onShow: () => _done(feature, tour: true),
                    onLater: () => _done(feature),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UnlockCard extends ConsumerStatefulWidget {
  const _UnlockCard({
    super.key,
    required this.feature,
    required this.onShow,
    required this.onLater,
  });

  final GameFeature feature;
  final VoidCallback onShow;
  final VoidCallback onLater;

  @override
  ConsumerState<_UnlockCard> createState() => _UnlockCardState();
}

class _UnlockCardState extends ConsumerState<_UnlockCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _in.duration = Duration(milliseconds: still ? 150 : 280);
    if (!_in.isAnimating && _in.value == 0) _in.forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final feature = widget.feature;
    final info = featureUnlockInfo(feature);
    final curve = CurvedAnimation(parent: _in, curve: Curves.easeOutCubic);
    final card = Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: ink.gold, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface,
                    border: Border.all(color: ink.gold, width: 2),
                  ),
                  child: Icon(info.icon, color: ink.gold, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          tr(ref, 'feature_new').replaceAll(
                              '{name}', tr(ref, 'feature_${feature.id}_name')),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: ink.gold)),
                      Text(tr(ref, 'feature_${feature.id}_line'),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  key: const Key('unlock_later'),
                  onPressed: widget.onLater,
                  child: Text(tr(ref, 'feature_later')),
                ),
                if (info.topic != null)
                  FilledButton(
                    key: const Key('unlock_show'),
                    style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    onPressed: widget.onShow,
                    child: Text(tr(ref, 'feature_show_me')),
                  )
                else
                  FilledButton(
                    key: const Key('unlock_show'),
                    style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    onPressed: widget.onLater,
                    child: Text(tr(ref, 'feature_ok')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return Semantics(
      liveRegion: true,
      child: still
          ? FadeTransition(opacity: curve, child: card)
          : FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, -0.6), end: Offset.zero)
                    .animate(curve),
                child: card,
              ),
            ),
    );
  }
}

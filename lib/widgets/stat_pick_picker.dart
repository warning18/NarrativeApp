// The stat pick a level's points bring (docs/proposals/stat-picks.md): each
// point earned is one pick of three offers, taken one at a time. Laid out
// like the clans' gift choice (banner-choice-unified.md): the offers in a row
// on top, the picked one ringed in gold and the others dimmed, its detail
// under them (the path it comes from, each gain from where it stands to where
// it goes) and "Take this pick" at the bottom. The three offers share the
// pick's rarity (Common, Rare, Epic, Heroic: the signs' colours): a frame in
// its colour that gets thicker and brighter with it, a rarity chip on the
// rarer ones, and under each gain what it does for this hero.
//
// Shown on the Level Up screen and in the pop-up after a fight while picks
// wait; the next pick is drawn as soon as one is taken.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/signs.dart' show SignRarity;
import '../data/stat_pick_text.dart';
import '../data/training.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../providers/training_provider.dart';
import '../screens/training_picker.dart'
    show
        trainingPathItem,
        trainingStatColor,
        trainingStatLabelKey,
        trainingStatNow;
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart' show ItemPixelIcon;
import 'sign_widgets.dart' show SignRarityChip, signRarityColor;

class StatPickPicker extends ConsumerStatefulWidget {
  const StatPickPicker({super.key});

  @override
  ConsumerState<StatPickPicker> createState() => _StatPickPickerState();
}

class _StatPickPickerState extends ConsumerState<StatPickPicker> {
  bool _busy = false;

  /// The offer picked, not yet taken.
  int? _selected;

  /// Draws the pick when one waits and none is on the table.
  void _ensure(Map<String, TrainingPath> paths) {
    final session = ref.read(playerSessionProvider);
    if (_busy || session.pendingStatPicks <= 0) return;
    if (session.statPickOffer.isNotEmpty) return;
    _busy = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (mounted) {
          await ref.read(playerSessionProvider.notifier).ensureStatPick(paths);
        }
      } finally {
        _busy = false;
      }
    });
  }

  Future<void> _take(int index) async {
    if (_busy) return;
    _busy = true;
    try {
      await ref.read(playerSessionProvider.notifier).takeStatPick(index);
      if (mounted) setState(() => _selected = null);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final paths = ref.watch(trainingPathsProvider).value;
    if (paths == null || session.pendingStatPicks <= 0) {
      return const SizedBox.shrink();
    }
    _ensure(paths);
    final offer = session.statPickOffer;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final picked =
        _selected != null && _selected! < offer.length ? _selected : null;
    final chosen = picked == null ? null : offer[picked];

    return Column(
      key: const Key('stat_pick_picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(ref, 'stat_pick_title'),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontFamily: InkFonts.display, color: ink.gold),
        ),
        const SizedBox(height: 8),
        // The offers, side by side: the picked one ringed, the rest dimmed.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, o) in offer.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _OfferBanner(
                    key: Key('stat_pick_offer_$i'),
                    offer: o,
                    path: paths[o.pathId],
                    fr: fr,
                    professionId: session.professionId,
                    selected: picked == i,
                    dimmed: picked != null && picked != i,
                    onTap: () => setState(() => _selected = i),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (chosen != null)
          _OfferDetail(
            key: Key('stat_pick_detail_${chosen.pathId}'),
            offer: chosen,
            path: paths[chosen.pathId],
            session: session,
            fr: fr,
          )
        else if (offer.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              tr(ref, 'stat_pick_hint'),
              key: const Key('stat_pick_hint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic),
            ),
          ),
        if (offer.isNotEmpty) ...[
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('stat_pick_take'),
            onPressed: picked == null ? null : () => _take(picked),
            child: Text(tr(ref, 'stat_pick_take')),
          ),
        ],
      ],
    );
  }
}

/// The colour of an offer: that of the stat it raises most.
Color _offerColor(StatPickOffer offer, InkColors ink) {
  var best = offer.gains.keys.isEmpty ? 'strength' : offer.gains.keys.first;
  var bestPoints = -1;
  for (final MapEntry(:key, :value) in offer.gains.entries) {
    final points = value;
    if (points > bestPoints) {
      best = key;
      bestPoints = points;
    }
  }
  return trainingStatColor(best, ink);
}

/// The frame of a pick of [tier]: the signs' rarity colour; Common stays the
/// quiet seam colour.
Color statPickFrameColor(SignRarity tier, InkColors ink) =>
    tier == SignRarity.common ? ink.seam : signRarityColor(tier);

/// How thick the frame of [tier] is, and how much of its colour tints the
/// card.
double _frameWidth(SignRarity tier) => switch (tier) {
      SignRarity.common => 1,
      SignRarity.rare => 1.5,
      SignRarity.epic => 2,
      SignRarity.heroic => 2.5,
    };

double _frameTint(SignRarity tier) => switch (tier) {
      SignRarity.common => 0,
      SignRarity.rare => 0.07,
      SignRarity.epic => 0.11,
      SignRarity.heroic => 0.15,
    };

/// "+1" or "+10", as the offer's headline gain.
String _gainText(int value) => '+$value';

/// One offer as a banner in the row: the path's icon, the gain, the path.
class _OfferBanner extends ConsumerWidget {
  const _OfferBanner({
    super.key,
    required this.offer,
    required this.path,
    required this.fr,
    required this.professionId,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final StatPickOffer offer;
  final TrainingPath? path;
  final bool fr;
  final String professionId;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final tier = offer.tier;
    final tierColor = statPickFrameColor(tier, ink);
    final accent = offer.rare ? tierColor : _offerColor(offer, ink);
    final frame = selected ? ink.gold : tierColor;
    final width = selected ? 2.5 : _frameWidth(tier);
    final language = fr ? AppLanguage.fr : AppLanguage.en;
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            if (tier == SignRarity.heroic)
              BoxShadow(
                  color: tierColor.withValues(alpha: 0.35), blurRadius: 10),
          ],
        ),
        child: Material(
          color: selected
              ? ink.gold.withValues(alpha: 0.12)
              : Color.alphaBlend(tierColor.withValues(alpha: _frameTint(tier)),
                  theme.colorScheme.surfaceContainerLow),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: frame, width: width),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (offer.rare)
                    Padding(
                      key: const Key('stat_pick_tier'),
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SignRarityChip(rarity: tier, language: language),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent, width: 1.5),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.32),
                          accent.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: ItemPixelIcon(
                        trainingPathItem(path?.icon ?? ''), null,
                        size: 28),
                  ),
                  const SizedBox(height: 6),
                  for (final MapEntry(:key, :value) in offer.gains.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_gainText(value),
                              style: TextStyle(
                                  fontFamily: InkFonts.system,
                                  fontSize: 18,
                                  height: 1.1,
                                  color: trainingStatColor(key, ink))),
                          Text(
                            tr(ref, trainingStatLabelKey(key)),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(height: 1.1),
                          ),
                          // What it does for this hero.
                          for (final (n, effect)
                              in statPickEffects(key, professionId, value)
                                  .indexed)
                            Text(
                              statEffectText(effect, language),
                              key: Key('stat_pick_effect_${key}_$n'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10, height: 1.15, color: ink.ash),
                            ),
                        ],
                      ),
                    ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child:
                          Icon(Icons.check_circle, size: 18, color: ink.gold),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The picked offer, in full: the path it comes from, and each gain from
/// where the stat stands to where it goes.
class _OfferDetail extends ConsumerWidget {
  const _OfferDetail({
    super.key,
    required this.offer,
    required this.path,
    required this.session,
    required this.fr,
  });

  final StatPickOffer offer;
  final TrainingPath? path;
  final PlayerSession session;
  final bool fr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final blurb = path?.blurbFor(fr) ?? '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ink.gold.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(path?.nameFor(fr) ?? offer.pathId,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontFamily: InkFonts.display)),
              ),
              if (offer.rare)
                Text(
                  tr(ref, 'stat_pick_worth')
                      .replaceAll('{n}', '${offer.points}'),
                  key: const Key('stat_pick_worth'),
                  style: theme.textTheme.labelMedium?.copyWith(color: ink.gold),
                ),
            ],
          ),
          if (blurb.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(blurb,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic, color: ink.ash)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(:key, :value) in offer.gains.entries)
                _GainTile(
                  key: Key('stat_pick_gain_$key'),
                  label: tr(ref, trainingStatLabelKey(key)),
                  gain: value,
                  before: trainingStatNow(session, key),
                  color: trainingStatColor(key, ink),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final MapEntry(:key, :value) in offer.gains.entries)
            Text(
              statPickEffect(key, session.professionId, value,
                  fr ? AppLanguage.fr : AppLanguage.en),
              key: Key('stat_pick_line_$key'),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// One gain: the stat, the big "+n", and where the stat goes.
class _GainTile extends StatelessWidget {
  const _GainTile({
    super.key,
    required this.label,
    required this.gain,
    required this.before,
    required this.color,
  });

  final String label;
  final int gain;
  final int before;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('+$gain',
                  style: TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 20,
                      height: 1.2,
                      color: color)),
              const SizedBox(width: 6),
              Text('$before',
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              Icon(Icons.arrow_right_alt, size: 14, color: ink.ash),
              Text('${before + gain}',
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ],
          ),
        ],
      ),
    );
  }
}

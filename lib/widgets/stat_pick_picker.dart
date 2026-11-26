// The stat pick a level's points bring (docs/proposals/stat-picks.md): each
// point earned is one pick of three offers, taken one at a time. Laid out
// like the clans' gift choice (banner-choice-unified.md): the offers in a row
// on top, the picked one ringed in gold and the others dimmed, the pick drawn
// on the ability radar under them (the hero's shape, and the shape the pick
// gives over it in a second colour) and "Take this pick" at the bottom. The three offers share the
// pick's rarity (Common, Rare, Epic, Heroic: the signs' colours): a frame in
// its colour that gets thicker and brighter with it, a rarity chip on the
// rarer ones, and under each gain what it does for this hero.
//
// Shown on the Level Up screen and in the pop-up after a fight while picks
// wait; the next pick is drawn as soon as one is taken.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/gear_effects.dart' show parseItemSets;
import '../data/signs.dart' show SignRarity;
import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/signs_provider.dart' show signEffectsProvider;
import '../screens/tower/ink/ink_palette.dart';
import 'level_up_art.dart';
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
import 'ability_radar.dart';
import 'roll_power_row.dart';
import 'sign_widgets.dart' show SignRarityChip, signRarityColor;
import '../theme/icon_sizes.dart';

class StatPickPicker extends ConsumerStatefulWidget {
  const StatPickPicker({
    super.key,
    this.art = false,
    this.tower = false,
    this.takeSlot,
    this.previewSlot,
  });

  /// The Level Up screen's look (v2.10.19): paper cards with Art's symbols
  /// and the before -> after of what a pick changes, then the stats area
  /// (the ability radar, the pick ghosted over it). The pop-up after a
  /// fight keeps the plain look.
  final bool art;

  /// The pick is the Tower hero's: the preview reads the Tower's checks and
  /// says "No effect in the Tower" for a pick nothing there reads.
  final bool tower;

  /// With [art]: where the Take action goes while an offer is picked (null
  /// when none is). The Level Up screen shows its button at the foot of the
  /// screen, out of the scroll; without it the button sits under the stats.
  final ValueNotifier<VoidCallback?>? takeSlot;

  /// With [art]: what the picked offer changes (null when none is), for the
  /// screen's stats under the picker.
  final ValueNotifier<StatPickPreview?>? previewSlot;

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

  /// Picks an offer (or none) and tells the screen's Take button.
  void _select(int? i) {
    setState(() => _selected = i);
    final slot = widget.takeSlot;
    if (slot == null) return;
    slot.value = i == null ? null : () => _take(i);
  }

  Future<void> _take(int index) async {
    if (_busy) return;
    _busy = true;
    try {
      await ref.read(playerSessionProvider.notifier).takeStatPick(index);
      if (mounted) _select(null);
    } finally {
      _busy = false;
    }
  }

  /// A roll power (camp_rolls.dart) used on the pick on the table; the
  /// selection kept only for a raise.
  Future<void> _roll(Future<void> Function() use, {bool keep = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      await use();
      if (mounted && !keep) _select(null);
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
    if (widget.art) {
      return _artBody(context, session, paths, offer, picked, chosen, fr);
    }

    return Column(
      key: const Key('stat_pick_picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(ref, 'stat_pick_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: InkFonts.display,
            color: ink.gold,
          ),
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
        // The one radar on the page while a pick waits (v1.565): the hero's
        // shape, with the pick drawn over it once one is chosen.
        if (chosen != null)
          _PickRadar(
            key: Key('stat_pick_detail_${chosen.pathId}'),
            offer: chosen,
            session: session,
          )
        else ...[
          _PickRadar(offer: null, session: session),
          if (offer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                tr(ref, 'stat_pick_hint'),
                key: const Key('stat_pick_hint'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ink.ash,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
        if (offer.isNotEmpty)
          RollPowerRow(
            keyPrefix: 'stat_pick',
            rolls: ref.watch(campRollsProvider),
            canBanish: picked != null,
            canRaise: picked != null &&
                ref
                    .read(playerSessionProvider.notifier)
                    .canRaiseStatPickOffer(picked),
            warnRaised: offer.any((o) => o.raised),
            onReroll: () => _roll(
              () => ref
                  .read(playerSessionProvider.notifier)
                  .rerollStatPick(paths),
            ),
            onBanish: (draws) => _roll(
              () => ref
                  .read(playerSessionProvider.notifier)
                  .banishStatPickOffer(picked!, draws, paths),
            ),
            onRaise: () => _roll(
              () => ref
                  .read(playerSessionProvider.notifier)
                  .raiseStatPickOffer(picked!, paths),
              keep: true,
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

  /// The Level Up screen's body (see [StatPickPicker.art]).
  Widget _artBody(
    BuildContext context,
    PlayerSession session,
    Map<String, TrainingPath> paths,
    List<StatPickOffer> offer,
    int? picked,
    StatPickOffer? chosen,
    bool fr,
  ) {
    final language = fr ? AppLanguage.fr : AppLanguage.en;
    Map<String, dynamic> table(DbSchema schema) =>
        ref.watch(gameDbProvider(schema)).value ?? const {};
    final items = table(itemsSchema);
    final itemSets = parseItemSets(table(itemSetsSchema));
    final signs = ref.watch(signEffectsProvider);
    final before = {
      for (final k in abilityRadarOrder) k: trainingStatNow(session, k),
    };
    // What the chosen offer changes, told to the screen after the frame.
    final slot = widget.previewSlot;
    if (slot != null) {
      final StatPickPreview? now = chosen == null
          ? null
          : statPickPreviewOf(session, chosen.gains,
              tower: widget.tower,
              items: items,
              itemSets: itemSets,
              signs: signs);
      String sig(StatPickPreview? p) =>
          p == null ? '' : p.rows.map((r) => '${r.labelKey}${r.after}').join();
      if (sig(now) != sig(slot.value)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) slot.value = now;
        });
      }
    }
    final after = chosen == null
        ? null
        : {
            for (final k in abilityRadarOrder)
              k: before[k]! + (chosen.gains[k] ?? 0),
          };
    return Column(
      key: const Key('stat_pick_picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(ref, 'stat_pick_title'),
          style: const TextStyle(
            fontFamily: InkFonts.display,
            fontSize: 17,
            height: 1.1,
            color: inkDeep,
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, o) in offer.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ArtOfferCard(
                    key: Key('stat_pick_offer_$i'),
                    offer: o,
                    preview: statPickPreviewOf(
                      session,
                      o.gains,
                      tower: widget.tower,
                      items: items,
                      itemSets: itemSets,
                      signs: signs,
                    ),
                    language: language,
                    professionId: session.professionId,
                    tower: widget.tower,
                    selected: picked == i,
                    onTap: () => _select(i),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (chosen != null && chosen.rare)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              tr(ref, 'stat_pick_worth').replaceAll('{n}', '${chosen.points}'),
              key: const Key('stat_pick_worth'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: InkFonts.prose,
                fontSize: 12,
                color: inkRedDeep,
              ),
            ),
          )
        else if (chosen == null && offer.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              tr(ref, 'stat_pick_hint'),
              key: const Key('stat_pick_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: InkFonts.prose,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: inkSlate,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Container(height: 1.5, color: inkDeep),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: chosen == null ? null : Key('stat_pick_detail_${chosen.pathId}'),
          child: LevelUpStatsArea(
            before: before,
            after: after,
            label: (k) => tr(ref, abilityAbbrevKey(k)),
          ),
        ),
        if (offer.isNotEmpty)
          RollPowerRow(
            keyPrefix: 'stat_pick',
            rolls: ref.watch(campRollsProvider),
            canBanish: picked != null,
            canRaise: picked != null &&
                ref
                    .read(playerSessionProvider.notifier)
                    .canRaiseStatPickOffer(picked),
            warnRaised: offer.any((o) => o.raised),
            onReroll: () => _roll(
              () => ref
                  .read(playerSessionProvider.notifier)
                  .rerollStatPick(paths),
            ),
            onBanish: (draws) => _roll(
              () => ref
                  .read(playerSessionProvider.notifier)
                  .banishStatPickOffer(picked!, draws, paths),
            ),
            onRaise: () => _roll(
              () => ref
                  .read(playerSessionProvider.notifier)
                  .raiseStatPickOffer(picked!, paths),
              keep: true,
            ),
          ),
      ],
    );
  }
}

/// The Take button of the Level Up screen: the Tower's red block.
class LevelUpTakeButton extends StatelessWidget {
  const LevelUpTakeButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        key: const Key('stat_pick_take'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: inkRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: inkRedDeep.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white70,
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(
            fontFamily: InkFonts.system,
            fontSize: 17,
            height: 1.1,
          ),
        ),
        child: Text(label),
      );
}

/// One offer on the Level Up screen: paper card, Art's symbol, the gain, then
/// the numbers it moves (before -> after, straight from statPickPreviewOf)
/// or, plainly, "No effect in the Tower". An offer not picked keeps its full
/// colour; the picked one has a red frame and a tick.
class _ArtOfferCard extends ConsumerWidget {
  const _ArtOfferCard({
    super.key,
    required this.offer,
    required this.preview,
    required this.language,
    required this.professionId,
    required this.tower,
    required this.selected,
    required this.onTap,
  });

  final StatPickOffer offer;
  final StatPickPreview preview;
  final AppLanguage language;
  final String professionId;
  final bool tower;
  final bool selected;
  final VoidCallback onTap;

  static String _n(num v, String unit) {
    final r = (v * 10).round() / 10;
    final t = r == r.roundToDouble() ? '${r.round()}' : '$r';
    return '${r < 0 ? '\u2212${t.substring(1)}' : t}$unit';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = offer.tier;
    final frame = selected
        ? inkRed
        : tier == SignRarity.common
            ? inkDeep
            : signRarityColor(tier);
    const slate = TextStyle(
      fontFamily: InkFonts.prose,
      fontSize: 11,
      height: 1.15,
      color: inkSlate,
    );
    return Material(
      color: inkPaper,
      shape: Border.all(
        color: frame,
        width: selected ? 3 : (tier == SignRarity.common ? 2 : 2.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (offer.rare)
                Padding(
                  key: const Key('stat_pick_tier'),
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SignRarityChip(rarity: tier, language: language),
                ),
              for (final MapEntry(:key, :value) in offer.gains.entries) ...[
                LevelUpSymbol(key, size: 36),
                const SizedBox(height: 4),
                Text(
                  '+$value ${trFor(language, abilityAbbrevKey(key))}',
                  style: const TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 17,
                    height: 1.1,
                    color: inkDeep,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    trFor(language, trainingStatLabelKey(key)),
                    maxLines: 1,
                    style: slate,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Container(height: 1, color: inkSlate.withValues(alpha: 0.4)),
              const SizedBox(height: 6),
              if (preview.rows.isNotEmpty)
                for (final r in preview.rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trFor(language, r.labelKey),
                          key: Key('stat_pick_row_${r.labelKey}'),
                          textAlign: TextAlign.center,
                          style: slate,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _n(r.before, r.unit),
                                  style: _artDigits(15, inkDeep),
                                ),
                                TextSpan(
                                  text: ' \u2192 ',
                                  style: _artDigits(13, inkSlate),
                                ),
                                TextSpan(
                                  text: _n(r.after, r.unit),
                                  style: _artDigits(
                                    15,
                                    inkRedDeep,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              else if (tower && preview.noTowerEffect)
                Text(
                  trFor(language, 'stat_preview_no_tower_effect'),
                  key: const Key('stat_pick_no_effect'),
                  textAlign: TextAlign.center,
                  style: slate,
                )
              else
                // Counts, but this step moves nothing yet: what it does in
                // words, as before.
                for (final (n, e) in [
                  for (final MapEntry(:key, :value) in offer.gains.entries)
                    ...statPickEffects(key, professionId, value, tower: tower),
                ].indexed)
                  Text(
                    statEffectText(e, language),
                    key: Key('stat_pick_effect_${offer.gains.keys.first}_$n'),
                    textAlign: TextAlign.center,
                    style: slate,
                  ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.check_circle, size: 16, color: inkRed),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _artDigits(double size, Color color, {FontWeight? weight}) =>
    TextStyle(
      fontFamily: InkFonts.prose,
      fontSize: size,
      height: 1.1,
      color: color,
      fontWeight: weight,
      fontFeatures: const [FontFeature.liningFigures()],
    );

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
Color _statPickFrameColor(SignRarity tier, InkColors ink) =>
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
    final tierColor = _statPickFrameColor(tier, ink);
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
                color: tierColor.withValues(alpha: 0.35),
                blurRadius: 10,
              ),
          ],
        ),
        child: Material(
          color: selected
              ? ink.gold.withValues(alpha: 0.12)
              : Color.alphaBlend(
                  tierColor.withValues(alpha: _frameTint(tier)),
                  theme.colorScheme.surfaceContainerLow,
                ),
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
                      trainingPathItem(path?.icon ?? ''),
                      null,
                      size: IconSize.s32,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final MapEntry(:key, :value) in offer.gains.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _gainText(value),
                            style: TextStyle(
                              fontFamily: InkFonts.system,
                              fontSize: 18,
                              height: 1.1,
                              color: trainingStatColor(key, ink),
                            ),
                          ),
                          // Whole words: each word shrinks to the card rather
                          // than break in two (#1139); no LayoutBuilder, the
                          // row is an IntrinsicHeight.
                          for (final word in tr(
                            ref,
                            trainingStatLabelKey(key),
                          ).split(' '))
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                word,
                                maxLines: 1,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  height: 1.1,
                                ),
                              ),
                            ),
                          // What it does for this hero.
                          for (final (n, effect) in statPickEffects(
                            key,
                            professionId,
                            value,
                          ).indexed)
                            Text(
                              statEffectText(effect, language),
                              key: Key('stat_pick_effect_${key}_$n'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                height: 1.15,
                                color: ink.ash,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle,
                        size: IconSize.s16,
                        color: ink.gold,
                      ),
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

/// The picked offer, on the radar (v1.549): the hero's shape as it stands and
/// the shape the pick would give, drawn over it in a second colour, the
/// corners it moves showing the new value and the gain. A pick worth more
/// than one point says so under it. (The path it comes from and what each
/// gain does for the hero are on the offer's own banner.)
class _PickRadar extends ConsumerWidget {
  const _PickRadar({super.key, required this.offer, required this.session});

  /// The pick drawn over the hero's shape; null while none is chosen: the
  /// shape alone.
  final StatPickOffer? offer;
  final PlayerSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final values = {
      for (final k in abilityRadarOrder) k: trainingStatNow(session, k),
    };
    final pick = offer;
    final after = pick == null
        ? null
        : {
            for (final k in abilityRadarOrder)
              k: values[k]! + (pick.gains[k] ?? 0),
          };
    return Column(
      children: [
        AbilityRadar(
          key: const Key('stat_pick_radar'),
          // On a short screen (320 x 568) a smaller radar keeps "Take this
          // pick" above the fold (#893).
          size: MediaQuery.sizeOf(context).height < 640 ? 150 : 220,
          t: (key) => tr(ref, key),
          values: values,
          preview: after,
        ),
        // The corner labels hang below the radar's own box.
        const SizedBox(height: 14),
        if (pick != null && pick.rare)
          Text(
            tr(ref, 'stat_pick_worth').replaceAll('{n}', '${pick.points}'),
            key: const Key('stat_pick_worth'),
            style: theme.textTheme.labelMedium?.copyWith(color: ink.gold),
          ),
      ],
    );
  }
}

// Rules 4's screens: the stat choice after taking the stat-pick card, and the
// gamble card's reveal. (The cards themselves are drawn by
// towerStyledCardFor; the "No turning back" confirm is TowerPickConfirm's.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/stat_pick_text.dart' show statPickPreview;
import '../../data/tower/tower_hero.dart' show TowerData, towerHeroOf;
import '../../data/tower/tower_rules4.dart'
    show towerGambleIsGood, towerStatPickStats;
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_session.dart' show towerSessionOf;
import '../../data/tower/tower_tables.dart' show TowerGambleOutcome;
import '../../l10n/app_strings.dart';
import '../../theme/motion.dart';
import '../../theme/stitched_ink.dart' show InkFonts;
import '../../widgets/ability_radar.dart' show abilityAbbrevKey;
import '../../widgets/level_up_art.dart' show LevelUpStatsArea;
import 'ink/ink_palette.dart';
import 'tower_bookmarks.dart' show towerAbilitiesOf;

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

/// The stat choice after the stat-pick card is taken: a ribbon, the radar with
/// the +1 ghosted on the stat touched, what it moves, the eight stats, then
/// Confirm (only once a stat is chosen) and Change (back to the cards).
class TowerStatChoice extends ConsumerStatefulWidget {
  const TowerStatChoice({
    super.key,
    required this.run,
    required this.data,
    required this.onConfirm,
    required this.onChange,
  });

  final TowerRun run;
  final TowerData data;
  final void Function(String stat) onConfirm;
  final VoidCallback onChange;

  @override
  ConsumerState<TowerStatChoice> createState() => _StatChoiceState();
}

class _StatChoiceState extends ConsumerState<TowerStatChoice> {
  String? _stat;

  @override
  Widget build(BuildContext context) {
    final hero = towerHeroOf(widget.run, widget.data);
    final before = towerAbilitiesOf(hero);
    final stat = _stat;
    final after = stat == null ? null : {...before, stat: before[stat]! + 1};
    final preview = stat == null
        ? null
        : statPickPreview(towerSessionOf(widget.run, widget.data), stat, 1,
            tower: true, items: widget.data.items);
    return ListView(
      key: const Key('tower_stat_choice'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      children: [
        // The bookmarks hang over the top right: the ribbon starts below them.
        const SizedBox(height: 52),
        Container(
          height: 40,
          alignment: Alignment.center,
          color: inkRed,
          child: Text(tr(ref, 'tower_stat_choose').toUpperCase(),
              style: _d(15, inkPaper)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 360,
          child: LevelUpStatsArea(
              before: before,
              after: after,
              label: (k) => tr(ref, abilityAbbrevKey(k)),
              dark: true),
        ),
        if (preview != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
                preview.rows.isEmpty
                    ? tr(ref, 'stat_preview_no_tower_effect')
                    : [
                        for (final r in preview.rows)
                          '${tr(ref, r.labelKey)} ${r.before}${r.unit} → ${r.after}${r.unit}',
                      ].join('\n'),
                key: const Key('tower_stat_preview'),
                textAlign: TextAlign.center,
                style: _p(12, inkGrey)),
          ),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in towerStatPickStats)
            GestureDetector(
              key: Key('tower_stat_$s'),
              onTap: () => setState(() => _stat = s),
              child: Container(
                width: 74,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: s == stat ? inkPaper : Colors.transparent,
                    border: Border.all(
                        color: s == stat ? inkPaper : inkGrey, width: 1.5),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${tr(ref, abilityAbbrevKey(s))} ${before[s]}',
                    style: _p(13, s == stat ? inkBlack : inkPaper,
                        w: FontWeight.w800)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton(
              key: const Key('tower_stat_confirm'),
              style: FilledButton.styleFrom(
                  backgroundColor: inkRed,
                  foregroundColor: inkPaper,
                  minimumSize: const Size.fromHeight(46)),
              onPressed: stat == null ? null : () => widget.onConfirm(stat),
              child: Text(stat == null
                  ? tr(ref, 'tower_confirm')
                  : tr(ref, 'tower_stat_confirm')
                      .replaceAll('{stat}', tr(ref, abilityAbbrevKey(stat)))),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            key: const Key('tower_change'),
            onPressed: widget.onChange,
            child: Text(tr(ref, 'tower_change'),
                style: _p(14, inkGold, w: FontWeight.w700)),
          ),
        ]),
      ],
    );
  }
}

/// The reveal after a gamble card is taken: the card turns over (reduce
/// motion: it is simply face up) and says what it was.
Future<void> towerShowGambleReveal(
    BuildContext context, WidgetRef ref, TowerGambleOutcome outcome) {
  final good = towerGambleIsGood(outcome);
  final reduced = MediaQuery.of(context).disableAnimations;
  Widget face() => Container(
        key: const Key('tower_gamble_reveal'),
        width: 240,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: inkPaper,
            border: Border.all(color: good ? inkGold : inkRed, width: 3),
            borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr(ref, 'tower_kind_gamble').toUpperCase(),
              style: _p(10, inkOnPaper, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(tr(ref, 'tower_gamble_${outcome.name}'),
              textAlign: TextAlign.center, style: _d(26, inkOnPaper)),
          const SizedBox(height: 8),
          Text(tr(ref, 'tower_gamble_${outcome.name}_line'),
              textAlign: TextAlign.center, style: _p(13, inkOnPaper)),
        ]),
      );
  return showDialog<void>(
    context: context,
    barrierColor: inkBlack.withValues(alpha: 0.75),
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: reduced
              ? face()
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Motion.slow,
                  curve: Curves.easeOut,
                  builder: (context, v, _) => Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY((1 - v) * 1.5708),
                    child: Opacity(opacity: v, child: face()),
                  ),
                ),
        ),
      ),
    ),
  );
}

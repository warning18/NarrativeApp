// The Tower's floor events on the floor screen (floor events PR 1, Core's
// towerEventOf): the setback's test with its odds, the rival's condition, how
// the last event ended, and the line of a floor met again. Core's figures are
// shown as they are: the odds are TowerEventView.chance and the roll line the
// roll Core rolled, so the two can never read differently.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_events.dart';
import '../../l10n/app_strings.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/stitched_ink.dart';
import '../../widgets/ink_panel.dart';

/// The card of [view]'s event, or nothing when its floor holds none (a floor
/// met again, or one shown only for its last result).
class TowerEventCard extends ConsumerWidget {
  const TowerEventCard(this.view, {super.key, this.bagFull = false});

  final TowerEventView view;

  /// The potion bag is full: a pass drinks the potion at once.
  final bool bagFull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (view.kind) {
      case TowerEventKind.test:
        return _TestCard(view, bagFull);
      case TowerEventKind.rival:
        return _RivalCard(view);
      case null:
        return const SizedBox.shrink();
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: IconSize.s16, color: color),
      const SizedBox(width: 6),
      Text(text.toUpperCase(),
          style: theme.textTheme.labelMedium
              ?.copyWith(color: color, letterSpacing: 1.2)),
    ]);
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome(this.icon, this.color, this.label, this.text);

  final IconData icon;
  final Color color;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: IconSize.s16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: '$label  ',
                style: theme.textTheme.labelLarge?.copyWith(color: color)),
            TextSpan(text: text, style: theme.textTheme.bodyMedium),
          ])),
        ),
      ]),
    );
  }
}

class _TestCard extends ConsumerWidget {
  const _TestCard(this.view, this.bagFull);

  final TowerEventView view;
  final bool bagFull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final ability = tr(ref, '${view.ability}_label').toLowerCase();
    final chance = view.chance ?? 0;
    final modifier = view.modifier ?? 0;
    final dc = view.dc ?? 0;
    String sub(String key, Map<String, Object> values) {
      var text = tr(ref, key);
      values.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
      return text;
    }

    final signed = modifier >= 0 ? '+$modifier' : '$modifier';
    return InkPanel(
      key: const Key('tower_event_test'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Tag(Icons.trending_down, tr(ref, 'tower_event_setback'), ink.blood),
        const SizedBox(height: 6),
        Text(sub('tower_event_test_title', {'ability': ability}),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontFamily: InkFonts.display)),
        Text(tr(ref, 'tower_event_test_body_${view.ability}'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        Row(children: [
          Text('${(chance * 100).round()}%',
              key: const Key('tower_event_chance'),
              style: theme.textTheme.headlineSmall?.copyWith(color: ink.gold)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                  value: chance, minHeight: 8, color: ink.heal),
            ),
          ),
        ]),
        Text(sub('tower_event_chance', {'mod': signed, 'dc': dc}),
            style: theme.textTheme.bodySmall),
        _Outcome(
            Icons.check_circle_outline,
            ink.heal,
            tr(ref, 'tower_event_pass'),
            tr(ref, 'tower_event_pass_text_${view.ability}') +
                (bagFull ? ' ${tr(ref, 'tower_event_pass_full')}' : '')),
        _Outcome(
            Icons.south,
            ink.blood,
            tr(ref, 'tower_event_fail'),
            sub('tower_event_fail_text_${view.ability}',
                {'n': view.fallTo ?? view.floor})),
        const SizedBox(height: 6),
        Text(
            sub(
                view.setbacksLeft == 1
                    ? 'tower_event_left_one'
                    : 'tower_event_left',
                {'n': view.setbacksLeft}),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _RivalCard extends ConsumerWidget {
  const _RivalCard(this.view);

  final TowerEventView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    String sub(String key, Map<String, Object> values) {
      var text = tr(ref, key);
      values.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
      return text;
    }

    return InkPanel(
      key: const Key('tower_event_rival'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Tag(Icons.bolt, tr(ref, 'tower_event_rival'), ink.gold),
        const SizedBox(height: 6),
        Text(tr(ref, 'tower_event_rival_title'),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontFamily: InkFonts.display)),
        Text(sub('tower_event_rival_body', {'n': view.floor + 1}),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        _Outcome(
            Icons.timer_outlined,
            ink.gold,
            sub('tower_event_rival_win', {'n': view.rounds ?? 3}),
            sub('tower_event_rival_win_text',
                {'n': view.landsOn ?? view.floor + 2})),
        _Outcome(
            Icons.arrow_forward,
            theme.colorScheme.onSurfaceVariant,
            tr(ref, 'tower_event_rival_slow'),
            tr(ref, 'tower_event_rival_slow_text')),
      ]),
    );
  }
}

/// How the last event ended, and where the run now stands.
class TowerEventResultLine extends ConsumerWidget {
  const TowerEventResultLine(this.result, {super.key});

  final TowerEventResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final fell = result.to < result.from;
    final skipped = result.to > result.from + 1;
    final color = fell ? ink.blood : ink.gold;
    String sub(String key) => tr(ref, key)
        .replaceAll('{from}', '${result.from}')
        .replaceAll('{to}', '${result.to}')
        .replaceAll('{skipped}', '${result.from + 1}');
    final headline = switch ((result.kind, result.passed)) {
      (TowerEventKind.test, false) => sub(result.to == result.from
          ? 'tower_event_fell_same'
          : 'tower_event_fell'),
      (TowerEventKind.test, true) =>
        sub('tower_event_held_${towerSetbackAbilityOf(result.from)}'),
      (TowerEventKind.rival, true) => sub('tower_event_outran'),
      (TowerEventKind.rival, false) => sub('tower_event_rival_lost'),
    };
    final rolled = result.roll == null
        ? null
        : tr(ref, 'tower_event_rolled')
            .replaceAll('{roll}', '${result.roll}')
            .replaceAll('{total}', '${result.total}');
    return InkPanel(
      key: const Key('tower_event_result'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(fell ? Icons.south : (skipped ? Icons.north : Icons.check),
            color: color, size: IconSize.s16),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(headline,
                style: theme.textTheme.titleSmall?.copyWith(color: color)),
            if (rolled != null)
              Text(rolled,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (fell)
              Text(tr(ref, 'tower_event_nothing_again'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }
}

/// The line of a floor met again: it pays nothing.
class TowerRevisitLine extends ConsumerWidget {
  const TowerRevisitLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkPanel(
      key: const Key('tower_event_revisit'),
      dim: true,
      child: Row(children: [
        Icon(Icons.history,
            size: IconSize.s16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
            child: Text(tr(ref, 'tower_event_nothing'),
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant))),
      ]),
    );
  }
}

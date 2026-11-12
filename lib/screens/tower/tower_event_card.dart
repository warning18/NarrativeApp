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
import '../../data/tower/tower_tables.dart' show towerSalveShare;
import 'tower_peaceful_cards.dart'
    show TowerBargainCard, TowerMerchantRoom, TowerParleyCard, TowerStallItem;

/// The card of [view]'s event, or nothing when its floor holds none (a floor
/// met again, or one shown only for its last result).
class TowerEventCard extends ConsumerWidget {
  const TowerEventCard(this.view,
      {super.key,
      this.bagFull = false,
      this.onShortcut,
      this.onParley,
      this.onBuy,
      this.onLeaveStore,
      this.onBargain});

  final TowerEventView view;

  /// The potion bag is full: a pass drinks the potion at once.
  final bool bagFull;

  /// A shortcut's choice: true takes the stair, false the door. The card
  /// shows its two buttons while the choice is open and this is given.
  final void Function(bool take)? onShortcut;

  /// A parley's choice: true talks, false fights.
  final void Function(bool talk)? onParley;

  /// The merchant's Buy (the stock's id) and Leave, and the bargain's choice
  /// (true takes it).
  final void Function(String id)? onBuy;
  final VoidCallback? onLeaveStore;
  final void Function(bool accept)? onBargain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (view.kind) {
      case TowerEventKind.test:
        return _TestCard(view, bagFull);
      case TowerEventKind.rival:
        return _RivalCard(view);
      case TowerEventKind.shortcut:
        return _ShortcutCard(view, onShortcut);
      // The parley: the guardian's card until the choice is made (a failed
      // talk reads in the result line, a fight chosen needs no card).
      case TowerEventKind.parley:
        if (view.accepted != null) return const SizedBox.shrink();
        return TowerParleyCard(
          ability: view.ability ?? 'charisma',
          dc: view.dc ?? 10,
          modifier: view.modifier ?? 0,
          chance: view.chance ?? 0,
          landsOn: view.landsOn ?? view.floor + 1,
          clanId: view.clanId,
          oathPass: view.oathPass ?? false,
          onTalk: onParley == null ? null : () => onParley!(true),
          onFight: onParley == null ? null : () => onParley!(false),
        );
      // The merchant's stall while its store is open (Leave closes it; the
      // next fight does too), and the bargain until it is chosen (a chosen
      // one reads in the result line).
      case TowerEventKind.merchant:
        if (!view.storeOpen) return const SizedBox.shrink();
        return TowerMerchantRoom(
          wallet: view.wallet ?? 0,
          clanId: view.clanId,
          discount: view.discount ?? false,
          stock: [
            for (final item in view.stock ?? const <TowerStockView>[])
              TowerStallItem(
                id: item.id,
                icon: item.kind == TowerStockKind.salve
                    ? Icons.healing
                    : Icons.local_drink_outlined,
                price: item.price,
                // The salve's text says a share of the health, not points.
                amount: item.kind == TowerStockKind.salve
                    ? (towerSalveShare * 100).round()
                    : item.amount,
                bought: item.bought,
                affordable: item.affordable,
              ),
          ],
          onBuy: onBuy,
          onLeave: onLeaveStore,
        );
      case TowerEventKind.bargain:
        if (view.accepted != null) return const SizedBox.shrink();
        return TowerBargainCard(
          maxHealthCost: view.maxHealthCost ?? 0,
          stat: view.stat ?? 'strength',
          onAccept: onBargain == null ? null : () => onBargain!(true),
          onRefuse: onBargain == null ? null : () => onBargain!(false),
        );
      case null:
        return const SizedBox.shrink();
    }
  }
}

class TowerEventTag extends StatelessWidget {
  const TowerEventTag(this.icon, this.text, this.color, {super.key});

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

class TowerEventOutcome extends StatelessWidget {
  const TowerEventOutcome(this.icon, this.color, this.label, this.text,
      {super.key});

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
        TowerEventTag(
            Icons.trending_down, tr(ref, 'tower_event_setback'), ink.blood),
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
        TowerEventOutcome(
            Icons.check_circle_outline,
            ink.heal,
            tr(ref, 'tower_event_pass'),
            tr(ref, 'tower_event_pass_text_${view.ability}') +
                (bagFull ? ' ${tr(ref, 'tower_event_pass_full')}' : '')),
        TowerEventOutcome(
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

/// The shortcut offered before a floor's fight: the stair (a tougher fight,
/// floors skipped, a loss ends the run) or the door (the floor as it is).
/// Taken, it shows as a line; declined, nothing.
class _ShortcutCard extends ConsumerWidget {
  const _ShortcutCard(this.view, this.onChoose);

  final TowerEventView view;
  final void Function(bool take)? onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final skip = view.skip ?? 1;
    final landsOn = view.landsOn ?? view.floor + skip + 1;
    if (view.accepted == false) return const SizedBox.shrink();
    if (view.accepted ?? false) {
      return InkPanel(
        key: const Key('tower_event_shortcut_taken'),
        lit: true,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.stairs, size: IconSize.s16, color: ink.gold),
          const SizedBox(width: 10),
          Expanded(
              child: Text(tr(ref, 'tower_event_shortcut_taken'),
                  style: theme.textTheme.bodyMedium)),
        ]),
      );
    }
    String sub(String key) => tr(ref, key)
        .replaceAll('{a}', '${view.floor + 1}')
        .replaceAll('{b}', '${landsOn - 1}')
        .replaceAll('{to}', '$landsOn');
    return InkPanel(
      key: const Key('tower_event_shortcut'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TowerEventTag(Icons.stairs, tr(ref, 'tower_event_shortcut'), ink.gold),
        const SizedBox(height: 6),
        Text(tr(ref, 'tower_event_shortcut_title'),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontFamily: InkFonts.display)),
        Text(tr(ref, 'tower_event_shortcut_body'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(
            tr(
                ref,
                (view.elite ?? false)
                    ? 'tower_event_shortcut_elite'
                    : 'tower_event_shortcut_pack'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        TowerEventOutcome(
            Icons.north,
            ink.gold,
            tr(ref, 'tower_event_shortcut_win'),
            sub(skip == 1
                ? 'tower_event_shortcut_win_one'
                : 'tower_event_shortcut_win_many')),
        TowerEventOutcome(
            Icons.south,
            ink.blood,
            tr(ref, 'tower_event_shortcut_lose'),
            tr(ref, 'tower_event_shortcut_lose_text')),
        if (onChoose != null) ...[
          const SizedBox(height: 12),
          // Full width, the stair first and the door under it: neither wraps
          // and both stand as tall.
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('tower_shortcut_take'),
              onPressed: () => onChoose!(true),
              child: Text(tr(ref, 'tower_event_shortcut_take')),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('tower_shortcut_decline'),
              onPressed: () => onChoose!(false),
              child: Text(tr(ref, 'tower_event_shortcut_decline')),
            ),
          ),
        ],
      ]),
    );
  }
}

/// After a won shortcut's fight, above the cards: where the run goes next.
class TowerShortcutWonLine extends ConsumerWidget {
  const TowerShortcutWonLine(this.view, {super.key});

  final TowerEventView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return InkPanel(
      key: const Key('tower_event_shortcut_won'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.north, size: IconSize.s16, color: ink.gold),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                tr(ref, 'tower_event_shortcut_won')
                    .replaceAll('{to}', '${view.landsOn}'),
                style: theme.textTheme.bodyMedium)),
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
        TowerEventTag(Icons.bolt, tr(ref, 'tower_event_rival'), ink.gold),
        const SizedBox(height: 6),
        Text(tr(ref, 'tower_event_rival_title'),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontFamily: InkFonts.display)),
        Text(sub('tower_event_rival_body', {'n': view.floor + 1}),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        TowerEventOutcome(
            Icons.timer_outlined,
            ink.gold,
            sub('tower_event_rival_win', {'n': view.rounds ?? 3}),
            sub('tower_event_rival_win_text',
                {'n': view.landsOn ?? view.floor + 2})),
        TowerEventOutcome(
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
    // A slip on the same floor is a failure too: the mark follows the roll.
    final failed = !result.passed;
    final fell = failed && result.kind == TowerEventKind.test;
    final skipped = result.to > result.from + 1;
    final color = failed ? ink.blood : ink.gold;
    String sub(String key) => tr(ref, key)
        .replaceAll('{from}', '${result.from}')
        .replaceAll('{to}', '${result.to}')
        .replaceAll('{skipped}', '${result.from + 1}')
        .replaceAll('{paid}', '${result.paid}');
    final headline = switch ((result.kind, result.passed)) {
      (TowerEventKind.test, false) => sub(result.to == result.from
          ? 'tower_event_fell_same'
          : 'tower_event_fell'),
      (TowerEventKind.test, true) =>
        sub('tower_event_held_${towerSetbackAbilityOf(result.from)}'),
      (TowerEventKind.rival, true) => sub('tower_event_outran'),
      (TowerEventKind.rival, false) => sub('tower_event_rival_lost'),
      // A lost shortcut ends the run, so only a won one shows here.
      (TowerEventKind.shortcut, _) => sub('tower_event_shortcut_landed'),
      (TowerEventKind.parley, false) => sub('tower_event_parley_failed'),
      // No roll: the guardian knew the oath.
      (TowerEventKind.parley, true) => sub(result.roll == null
          ? 'tower_event_parley_sworn'
          : 'tower_event_parley_passed'),
      (TowerEventKind.merchant, _) => sub('tower_event_merchant_paid'),
      (TowerEventKind.bargain, true) => sub('tower_event_bargain_taken'),
      (TowerEventKind.bargain, false) => sub('tower_event_bargain_refused'),
    };
    final rolled = result.roll == null
        ? null
        : tr(
                ref,
                result.kind == TowerEventKind.test
                    ? 'tower_event_rolled_against'
                    : 'tower_event_rolled')
            .replaceAll('{roll}', '${result.roll}')
            .replaceAll('{total}', '${result.total}')
            .replaceAll('{dc}', '${towerSetbackDcOf(result.from)}');
    return InkPanel(
      key: const Key('tower_event_result'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            result.kind == TowerEventKind.shortcut
                ? Icons.north
                : failed
                    ? (fell ? Icons.south : Icons.close)
                    : (skipped ? Icons.north : Icons.check),
            color: color,
            size: IconSize.s16),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // The stair's notes (taken, won, landed) share one face.
            Text(headline,
                style: result.kind == TowerEventKind.shortcut
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.titleSmall?.copyWith(color: color)),
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

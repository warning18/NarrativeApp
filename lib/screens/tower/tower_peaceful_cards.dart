// The Tower's floors without a fight (docs/proposals/tower-peaceful-floors-and-
// stores.md): the parley with a guardian, the merchant's stall (the
// Stair-Chandler) and the bargain (the Tally-Clerk). Each card is given the
// figures it shows, so Core's view fields (towerEventOf) can feed it as they
// are: the parley's odds are the setback's d20 check, the stock and its
// prices are the store's.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart' show appLanguageProvider;
import '../../l10n/app_strings.dart';
import '../../providers/clans_provider.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/stitched_ink.dart';
import '../../widgets/ink_chip.dart';
import '../../widgets/ink_panel.dart';
import '../../widgets/race_profession_cards.dart' show ClanDisc;
import 'tower_event_card.dart' show TowerEventOutcome, TowerEventTag;
import 'tower_look.dart' show TowerFoeFigure;

String _sub(WidgetRef ref, String key, Map<String, Object> values) {
  var text = tr(ref, key);
  values.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
  return text;
}

/// The pictures of the Tower's people (the user's PixelLab characters, 64x64,
/// standing, turned a quarter toward the words at their left, in
/// assets/visuals/tower/npc/), drawn at their own size (one picture pixel is
/// one scene pixel, as the hero's): the Stair-Chandler, the
/// Tally-Clerk and the guardian of a Dominion or Vigil parley. A missing file
/// draws nothing.
const Set<String> towerNpcNames = {'chandler', 'clerk', 'guardian'};

/// The clans whose guardian wears the officer's coat of the picture.
const Set<String> towerOfficerClans = {'dominion', 'vigil'};

class TowerNpcFigure extends StatelessWidget {
  const TowerNpcFigure(this.name, {super.key, this.size = 64});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/visuals/tower/npc/$name.png',
        key: Key('tower_npc_$name'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
}

/// A card's head (its tag, title and words) with the figure standing at its
/// right, when there is one.
class _Head extends StatelessWidget {
  const _Head({required this.children, this.figure});

  final List<Widget> children;
  final Widget? figure;

  @override
  Widget build(BuildContext context) {
    final column = Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
    if (figure == null) return column;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: column),
      const SizedBox(width: 8),
      figure!,
    ]);
  }
}

/// The two buttons of a choice, stacked full width: the first is the way
/// the card pushes, the second the way out.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.firstKey,
    required this.first,
    required this.onFirst,
    required this.secondKey,
    required this.second,
    required this.onSecond,
  });

  final Key firstKey;
  final String first;
  final VoidCallback? onFirst;
  final Key secondKey;
  final String second;
  final VoidCallback? onSecond;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child:
            FilledButton(key: firstKey, onPressed: onFirst, child: Text(first)),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
            key: secondKey, onPressed: onSecond, child: Text(second)),
      ),
    ]);
  }
}

/// A guardian that can be talked past: the check's odds (or, sworn to its
/// clan, no check), what a pass gives up, and the two buttons.
class TowerParleyCard extends ConsumerWidget {
  const TowerParleyCard({
    super.key,
    required this.ability,
    required this.dc,
    required this.modifier,
    required this.chance,
    required this.landsOn,
    this.clanId,
    this.oathPass = false,
    this.foeId,
    this.onTalk,
    this.onFight,
  });

  /// The ability checked (charisma, wisdom or dexterity), the check's DC,
  /// the hero's modifier and the chance to pass.
  final String ability;
  final int dc;
  final int modifier;
  final double chance;

  /// The floor a pass lands on.
  final int landsOn;

  /// The guardian's clan, and whether the hero is sworn to it (no roll).
  final String? clanId;
  final bool oathPass;

  /// The floor's own foe, whose figure stands by the card when the guardian's
  /// clan has no picture of its own.
  final String? foeId;
  final VoidCallback? onTalk;
  final VoidCallback? onFight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final faction = clanId == null ? null : ref.watch(factionsProvider)[clanId];
    final signed = modifier >= 0 ? '+$modifier' : '$modifier';
    return InkPanel(
      key: const Key('tower_parley'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Head(
          figure: towerOfficerClans.contains(clanId)
              ? const TowerNpcFigure('guardian')
              : foeId == null
                  ? null
                  : TowerFoeFigure(foeId!, size: 72),
          children: [
            TowerEventTag(
                Icons.forum_outlined, tr(ref, 'tower_parley'), ink.gold),
            const SizedBox(height: 6),
            Text(tr(ref, 'tower_parley_title'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: InkFonts.display)),
            Text(tr(ref, 'tower_parley_body'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        if (faction != null) ...[
          const SizedBox(height: 8),
          ClanDisc(faction, size: 28, name: true),
        ],
        const SizedBox(height: 10),
        if (oathPass)
          Row(children: [
            Icon(Icons.verified_outlined, size: IconSize.s16, color: ink.heal),
            const SizedBox(width: 8),
            Expanded(
                child: Text(tr(ref, 'tower_parley_sworn'),
                    key: const Key('tower_parley_sworn'),
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: ink.heal))),
          ])
        else ...[
          Row(children: [
            Text('${(chance * 100).round()}%',
                key: const Key('tower_parley_chance'),
                style:
                    theme.textTheme.headlineSmall?.copyWith(color: ink.gold)),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                    value: chance, minHeight: 8, color: ink.heal),
              ),
            ),
          ]),
          Text(
              '${tr(ref, '${ability}_label')} · '
              '${_sub(ref, 'tower_event_chance', {'mod': signed, 'dc': dc})}',
              style: theme.textTheme.bodySmall),
          TowerEventOutcome(
              Icons.check_circle_outline,
              ink.heal,
              tr(ref, 'tower_parley_pass'),
              _sub(ref, 'tower_parley_pass_text', {'n': landsOn})),
          TowerEventOutcome(Icons.sports_mma, ink.blood,
              tr(ref, 'tower_parley_fail'), tr(ref, 'tower_parley_fail_text')),
        ],
        const SizedBox(height: 8),
        Text(tr(ref, 'tower_parley_forgo'),
            key: const Key('tower_parley_forgo'),
            style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant)),
        if (onTalk != null || onFight != null) ...[
          const SizedBox(height: 12),
          _Choice(
            firstKey: const Key('tower_parley_talk'),
            first: tr(ref, 'tower_parley_talk'),
            onFirst: onTalk,
            secondKey: const Key('tower_parley_fight'),
            second: tr(ref, 'tower_parley_fight'),
            onSecond: onFight,
          ),
        ],
      ]),
    );
  }
}

/// One thing the merchant sells this run (Core's TowerStockView, as the
/// stall shows it).
class TowerStallItem {
  const TowerStallItem({
    required this.id,
    required this.icon,
    required this.price,
    required this.amount,
    this.bought = false,
    this.affordable = true,
  });

  /// 'salve' or 'potions' (its strings are the tower_merchant_ keys ending in the id).
  final String id;
  final IconData icon;

  /// The marks it costs now (half, when sworn).
  final int price;

  /// The health percent healed, or the potions given.
  final int amount;
  final bool bought;
  final bool affordable;
}

/// The Stair-Chandler's stall: the marks to spend, the half price when
/// sworn to its clan, the stock with its prices, and the way out.
class TowerMerchantRoom extends ConsumerWidget {
  const TowerMerchantRoom({
    super.key,
    required this.wallet,
    required this.stock,
    this.clanId,
    this.discount = false,
    this.onBuy,
    this.onLeave,
  });

  final int wallet;
  final List<TowerStallItem> stock;
  final String? clanId;

  /// Sworn to its clan: everything at half price.
  final bool discount;
  final void Function(String id)? onBuy;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final faction = clanId == null ? null : ref.watch(factionsProvider)[clanId];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkPanel(
        key: const Key('tower_merchant'),
        lit: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Head(
            figure: const TowerNpcFigure('chandler'),
            children: [
              TowerEventTag(Icons.storefront_outlined,
                  tr(ref, 'tower_merchant'), ink.gold),
              const SizedBox(height: 6),
              Text(tr(ref, 'tower_merchant_title'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontFamily: InkFonts.display)),
              Text(tr(ref, 'tower_merchant_body'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          InkChip(_sub(ref, 'tower_merchant_wallet', {'n': wallet}),
              color: ink.gold),
          const SizedBox(height: 6),
          // The half price: a muted line for a climber who is not sworn to
          // the clan, the green chip for one who is.
          if (discount)
            InkChip(tr(ref, 'tower_merchant_sworn'), color: ink.heal)
          else if (faction != null)
            Text(
                _sub(ref, 'tower_merchant_half_price',
                    {'clan': faction.shortFor(ref.watch(appLanguageProvider))}),
                key: const Key('tower_merchant_half_price'),
                style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ),
      for (final item in stock)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkPanel(
            key: Key('tower_stall_${item.id}'),
            dim: item.bought,
            child: Row(children: [
              Icon(item.icon, size: IconSize.s32, color: ink.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(ref, 'tower_merchant_${item.id}'),
                          style: theme.textTheme.titleSmall),
                      Text(
                          _sub(ref, 'tower_merchant_${item.id}_text',
                              {'n': item.amount}),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                    _sub(
                        ref,
                        item.price == 1
                            ? 'tower_merchant_price_one'
                            : 'tower_merchant_price',
                        {'n': item.price}),
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: item.affordable || item.bought
                            ? ink.gold
                            : ink.blood)),
                const SizedBox(height: 4),
                // A Buy you cannot pay for is switched off and dimmed, like a
                // bought one.
                Opacity(
                  opacity: item.affordable || item.bought ? 1 : .4,
                  child: FilledButton(
                    key: Key('tower_stall_buy_${item.id}'),
                    onPressed: item.bought || !item.affordable || onBuy == null
                        ? null
                        : () => onBuy!(item.id),
                    child: Text(tr(
                        ref,
                        item.bought
                            ? 'tower_merchant_bought'
                            : 'tower_merchant_buy')),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: const Key('tower_merchant_leave'),
          // A solid ground: on the plate's arch the bare frame read weakly.
          style: OutlinedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface),
          onPressed: onLeave,
          child: Text(tr(ref, 'tower_merchant_leave')),
        ),
      ),
    ]);
  }
}

/// The Tally-Clerk's bargain: a tenth of the maximum health for a point
/// on the damage stat, for the rest of the climb. Taken or refused, once.
class TowerBargainCard extends ConsumerWidget {
  const TowerBargainCard({
    super.key,
    required this.maxHealthCost,
    required this.stat,
    this.onAccept,
    this.onRefuse,
  });

  /// The maximum health given up, and the stat that gains a point.
  final int maxHealthCost;
  final String stat;
  final VoidCallback? onAccept;
  final VoidCallback? onRefuse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return InkPanel(
      key: const Key('tower_bargain'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Head(
          figure: const TowerNpcFigure('clerk'),
          children: [
            TowerEventTag(Icons.balance, tr(ref, 'tower_bargain'), ink.gold),
            const SizedBox(height: 6),
            Text(tr(ref, 'tower_bargain_title'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: InkFonts.display)),
            Text(tr(ref, 'tower_bargain_body'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        TowerEventOutcome(
            Icons.north,
            ink.gold,
            tr(ref, 'tower_bargain_gain'),
            _sub(ref, 'tower_bargain_gain_text',
                {'stat': tr(ref, '${stat}_label').toLowerCase()})),
        TowerEventOutcome(
            Icons.favorite_border,
            ink.blood,
            tr(ref, 'tower_bargain_cost'),
            _sub(ref, 'tower_bargain_cost_text', {'n': maxHealthCost})),
        if (onAccept != null || onRefuse != null) ...[
          const SizedBox(height: 12),
          _Choice(
            firstKey: const Key('tower_bargain_accept'),
            first: tr(ref, 'tower_bargain_accept'),
            onFirst: onAccept,
            secondKey: const Key('tower_bargain_refuse'),
            second: tr(ref, 'tower_bargain_refuse'),
            onSecond: onRefuse,
          ),
        ],
      ]),
    );
  }
}

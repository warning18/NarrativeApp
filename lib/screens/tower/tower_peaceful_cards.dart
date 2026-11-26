// The Tower's floors without a fight (docs/proposals/tower-peaceful-floors-and-
// stores.md): the parley with a guardian, the merchant's stall (the
// Stair-Chandler) and the bargain (the Tally-Clerk). Each card is given the
// figures it shows, so Core's view fields (towerEventOf) can feed it as they
// are: the parley's odds are the setback's d20 check, the stock and its
// prices are the store's.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart' show appLanguageProvider;
import '../../l10n/app_strings.dart';
import '../../providers/clans_provider.dart';
import '../../theme/icon_sizes.dart';
import '../../utils/pixel_icons/item_icons.dart' show ItemIcons;
import '../../utils/pixel_icons/pixel_icon.dart' show PixelIcon;
import '../../theme/stitched_ink.dart' show InkFonts;
import 'ink/ink_kit.dart' show InkBar;
import 'ink/ink_palette.dart';
import '../../widgets/ink_chip.dart';
import '../../widgets/ink_panel.dart';
import '../../widgets/race_profession_cards.dart' show ClanDisc;
import 'tower_event_card.dart'
    show TowerChoiceBlock, TowerEventOutcome, TowerEventTag;
import 'ink/ink_sprites.dart';
import 'tower_look.dart' show TowerFoeFigure;

String _sub(WidgetRef ref, String key, Map<String, Object> values) {
  var text = tr(ref, key);
  values.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
  return text;
}

/// The pictures of the Tower's people (the user's PixelLab characters, 64x64,
/// standing, turned a quarter toward the words at their left, in
/// assets/visuals/tower/npc/): the Stair-Chandler, the
/// Tally-Clerk and the guardian of a Dominion or Vigil parley. A missing file
/// draws nothing.
const Set<String> towerNpcNames = {'chandler', 'clerk', 'guardian'};

/// The clans whose guardian wears the officer's coat of the picture.
const Set<String> towerOfficerClans = {'dominion', 'vigil'};

/// How many screen pixels one picture pixel of a figure takes, and the size of
/// the parley's foe figure beside them (the same height: 2 and 108).
int towerNpcScale = 2;
double towerParleyFoeSize = 108;

/// A figure trimmed to the part of its 64x64 canvas that holds it (the same
/// box for all three: 29 by 51, the feet on the bottom row).
class TowerNpcFigure extends StatelessWidget {
  const TowerNpcFigure(this.name, {super.key});

  final String name;

  static const _x0 = 18, _y0 = 6, _w = 29, _h = 51;

  @override
  Widget build(BuildContext context) {
    final k = towerNpcScale;
    return SizedBox(
      key: Key('tower_npc_$name'),
      width: _w * k.toDouble(),
      height: _h * k.toDouble(),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: 66.0 * k,
          maxHeight: 66.0 * k,
          // In ink (v1.1010) the sprite is recoloured once and cached (one
          // pixel of ink round it, so the crop shifts by one pixel); until it
          // is ready, or if it fails, nothing stands there.
          child: Transform.translate(
            offset:
                Offset(-(_x0 - 1) * k.toDouble(), -(_y0 - 1) * k.toDouble()),
            child: FutureBuilder<ui.Image>(
              future: InkSprites.of('assets/visuals/tower/npc/$name.png'),
              builder: (context, snap) => snap.data == null
                  ? const SizedBox.shrink()
                  : RawImage(
                      image: snap.data,
                      width: 66.0 * k,
                      height: 66.0 * k,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false),
            ),
          ),
        ),
      ),
    );
  }
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

/// The two choices of a card, stacked full width, each a button with what it
/// costs and gives written under it (the first is the way the card pushes,
/// the second the way out).
class _Choice extends StatelessWidget {
  const _Choice({
    required this.firstKey,
    required this.first,
    required this.onFirst,
    required this.secondKey,
    required this.second,
    required this.onSecond,
    this.firstPre = const [],
    this.firstLines = const [],
    this.secondLines = const [],
  });

  final Key firstKey;
  final String first;
  final VoidCallback? onFirst;
  final Key secondKey;
  final String second;
  final VoidCallback? onSecond;
  final List<Widget> firstPre, firstLines, secondLines;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TowerChoiceBlock(
        button:
            FilledButton(key: firstKey, onPressed: onFirst, child: Text(first)),
        pre: firstPre,
        lines: firstLines,
      ),
      TowerChoiceBlock(
        button: OutlinedButton(
            key: secondKey, onPressed: onSecond, child: Text(second)),
        lines: secondLines,
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

  Widget _odds(WidgetRef ref, ThemeData theme, String signed) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${(chance * 100).round()}%',
              key: const Key('tower_parley_chance'),
              style: theme.textTheme.headlineSmall?.copyWith(color: inkPaper)),
          const SizedBox(width: 10),
          Expanded(child: InkBar(value: chance, height: 8)),
        ]),
        Text(
            '${tr(ref, '${ability}_label')} · '
            '${_sub(ref, 'tower_event_chance', {'mod': signed, 'dc': dc})}',
            style: theme.textTheme.bodySmall),
      ]);

  List<Widget> _passFail(WidgetRef ref) => [
        TowerEventOutcome(
            Icons.check_circle_outline,
            inkPaper,
            tr(ref, 'tower_parley_pass'),
            _sub(ref, 'tower_parley_pass_text', {'n': landsOn})),
        TowerEventOutcome(Icons.sports_mma, inkRed,
            tr(ref, 'tower_parley_fail'), tr(ref, 'tower_parley_fail_text')),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                  : TowerFoeFigure(foeId!, size: towerParleyFoeSize),
          children: [
            TowerEventTag(
                Icons.forum_outlined, tr(ref, 'tower_parley'), inkPaper),
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
        const SizedBox(height: 4),
        if (oathPass)
          Row(children: [
            const Icon(Icons.verified_outlined,
                size: IconSize.s16, color: inkPaper),
            const SizedBox(width: 8),
            Expanded(
                child: Text(tr(ref, 'tower_parley_sworn'),
                    key: const Key('tower_parley_sworn'),
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: inkPaper))),
          ]),
        // Each way shows what it costs and what it gives under its own
        // button: the talk its stat, odds and both branches, the fight what
        // it keeps.
        if (onTalk != null || onFight != null)
          _Choice(
            firstKey: const Key('tower_parley_talk'),
            first: oathPass
                ? tr(ref, 'tower_parley_talk')
                : '${tr(ref, 'tower_parley_talk')}  ·  '
                    '${tr(ref, '${ability}_label')} $signed',
            onFirst: onTalk,
            firstPre: oathPass ? const [] : [_odds(ref, theme, signed)],
            firstLines: [
              if (!oathPass) ..._passFail(ref),
              Text(tr(ref, 'tower_parley_forgo'),
                  key: const Key('tower_parley_forgo'),
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
            secondKey: const Key('tower_parley_fight'),
            second: tr(ref, 'tower_parley_fight'),
            onSecond: onFight,
            secondLines: [
              TowerEventOutcome(Icons.check, inkPaper,
                  tr(ref, 'tower_parley_fight_keep'), ''),
            ],
          )
        else ...[
          if (!oathPass) ...[_odds(ref, theme, signed), ..._passFail(ref)],
          const SizedBox(height: 8),
          Text(tr(ref, 'tower_parley_forgo'),
              key: const Key('tower_parley_forgo'),
              style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant)),
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
    this.iconId,
    required this.price,
    required this.amount,
    this.bought = false,
    this.affordable = true,
  });

  /// 'salve' or 'potions' (its strings are the tower_merchant_ keys ending in the id).
  final String id;
  final IconData icon;

  /// The item icon that stands for it (Art's wave 2), when it has one.
  final String? iconId;

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
                  tr(ref, 'tower_merchant'), inkPaper),
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
              color: inkPaper),
          const SizedBox(height: 6),
          // The half price: a muted line for a climber who is not sworn to
          // the clan, the green chip for one who is.
          if (discount)
            InkChip(tr(ref, 'tower_merchant_sworn'), color: inkPaper)
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
              item.iconId == null
                  ? Icon(item.icon, size: IconSize.s32, color: inkPaper)
                  : PixelIcon(ItemIcons.pathFor(item.iconId!),
                      size: IconSize.s32),
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
                            ? inkPaper
                            : inkRed)),
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

  List<Widget> _lines(WidgetRef ref) => [
        TowerEventOutcome(
            Icons.north,
            inkPaper,
            tr(ref, 'tower_bargain_gain'),
            _sub(ref, 'tower_bargain_gain_text',
                {'stat': tr(ref, '${stat}_label').toLowerCase()})),
        TowerEventOutcome(
            Icons.favorite_border,
            inkRed,
            tr(ref, 'tower_bargain_cost'),
            _sub(ref, 'tower_bargain_cost_text', {'n': maxHealthCost})),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkPanel(
      key: const Key('tower_bargain'),
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Head(
          figure: const TowerNpcFigure('clerk'),
          children: [
            TowerEventTag(Icons.balance, tr(ref, 'tower_bargain'), inkPaper),
            const SizedBox(height: 6),
            Text(tr(ref, 'tower_bargain_title'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontFamily: InkFonts.display)),
            Text(tr(ref, 'tower_bargain_body'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        if (onAccept != null || onRefuse != null)
          _Choice(
            firstKey: const Key('tower_bargain_accept'),
            first: tr(ref, 'tower_bargain_accept'),
            onFirst: onAccept,
            firstLines: _lines(ref),
            secondKey: const Key('tower_bargain_refuse'),
            second: tr(ref, 'tower_bargain_refuse'),
            onSecond: onRefuse,
            secondLines: [
              TowerEventOutcome(Icons.check, inkPaper,
                  tr(ref, 'tower_bargain_refuse_text'), ''),
            ],
          )
        else
          ..._lines(ref),
      ]),
    );
  }
}

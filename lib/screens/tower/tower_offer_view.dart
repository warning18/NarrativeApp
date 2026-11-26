// The cards of a won floor (v1.848, the-tower-designs.md screen 4, the loot
// dialog's design A in "choose one" mode): three cards of different kinds,
// the one in hand ringed and the others dimmed, Take for the card in hand,
// or leave them all for a mark.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/dice_faces.dart' show skillDisplayName;
import '../../data/tower/tower_coins.dart';
import '../../data/tower/tower_hero.dart';
import '../../data/tower/tower_rewards.dart';
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_tables.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/clans_provider.dart';
import '../../widgets/clan_offer_gifts.dart';
import '../../widgets/item_lore.dart' show itemRarityLabelFor;
import '../../widgets/pixel_banner.dart' show clanBannerId;
import '../../widgets/race_profession_cards.dart' show ClanDisc;
import '../../providers/game_db_providers.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/stitched_ink.dart';
import '../../data/tower/tower_clans.dart' show towerClanRipple;
import '../../data/tower/tower_events.dart';
import 'ink/ink_palette.dart' show inkGrey;
import 'tower_card_art.dart';
import 'tower_clan_cards.dart';
import 'tower_coin_view.dart';
import 'tower_providers.dart';
import 'tower_event_card.dart';
import 'tower_tarot_card.dart';

/// What a card reads: its kind, its name and what it does.
class TowerCardText {
  const TowerCardText(this.kind, this.name, this.text);

  final String kind;
  final String name;
  final String text;
}

/// A die's name in the reader's language: its English name is its id
/// ("lantern_die"), worded as a title.
String towerDieName(WidgetRef ref, String id) {
  final row = ((ref.watch(localizedDbProvider(diceSchema)).value ??
          const {})[id] as Map?)
      ?.cast<String, dynamic>();
  final name = '${row?['diceName'] ?? id}';
  if (!name.contains('_')) return name;
  return name
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// The words of [reward] in the reader's language. [tier]: a rank-up's
/// skill's tier now (0 for the base skill, shown as rank 1); the card shows
/// the step, "rank 1 to 2".
TowerCardText towerCardText(WidgetRef ref, TowerReward reward, {int tier = 0}) {
  final lang = ref.watch(appLanguageProvider);
  Map<String, dynamic> row(DbSchema schema, String id) =>
      ((ref.watch(localizedDbProvider(schema)).value ?? const {})[id] as Map?)
          ?.cast<String, dynamic>() ??
      const {};
  String dieName(String id) => towerDieName(ref, id);
  switch (reward.kind) {
    case TowerRewardKind.die:
      return TowerCardText(tr(ref, 'tower_kind_die'), dieName(reward.id),
          '${row(diceSchema, reward.id)['numberOfFaces'] ?? ''}');
    case TowerRewardKind.skill:
      return TowerCardText(
          reward.clan.isEmpty
              ? tr(ref, 'tower_kind_skill')
              : towerGiftKind(ref, reward.clan),
          skillDisplayName(reward.id, language: lang),
          '${row(skillsSchema, reward.id)['description'] ?? ''}');
    case TowerRewardKind.spell:
      final r = row(spellsSchema, reward.id);
      return TowerCardText(tr(ref, 'tower_kind_spell'),
          '${r['spellName'] ?? reward.id}', '${r['description'] ?? ''}');
    case TowerRewardKind.rankUp:
      return TowerCardText(
          reward.clan.isEmpty
              ? tr(ref, 'tower_kind_rank_up')
              : '${tr(ref, 'tower_kind_rank_up')} · '
                  '${towerGiftKind(ref, reward.clan)}',
          // The name is the skill; the step ("rank 1 to 2") leads the text, so
          // a long French name does not wrap tight in the plate (Core's note
          // on #1134).
          skillDisplayName(reward.id, language: lang),
          '${tr(ref, 'tower_rank_up_step').replaceAll('{from}', '${tier + 1}').replaceAll('{to}', '${tier + 2}')}\n'
          '${tr(ref, 'tower_rank_up_text')}');
    case TowerRewardKind.clanOath:
      // A clan offers its oath (Core's v1.855; UX-2 dresses the card).
      return TowerCardText(
          tr(ref, 'tower_kind_oath'),
          ref.watch(factionsProvider)[reward.id]?.shortFor(lang) ?? reward.id,
          tr(ref, 'tower_oath_text'));
  }
}

/// A clan's short name in the reader's language (factions.json).
String towerClanName(WidgetRef ref, String clanId) =>
    ref
        .watch(factionsProvider)[clanId]
        ?.shortFor(ref.watch(appLanguageProvider)) ??
    clanId;

/// A clan's gift's kind: "Gift · Crows".
String towerGiftKind(WidgetRef ref, String clanId) =>
    tr(ref, 'tower_kind_gift').replaceAll('{clan}', towerClanName(ref, clanId));

/// What a gift of [clanId] moves, clan by clan: "Crows +2 · Dominion +1 ·
/// Vigil -1" (towerClanRipple).
String towerRippleLine(WidgetRef ref, String clanId, TowerData data,
        {int heat = 0}) =>
    [
      for (final MapEntry(:key, :value)
          in towerClanRipple(clanId, data.clans, heat: heat).entries)
        '${towerClanName(ref, key)} ${value > 0 ? '+' : ''}$value',
    ].join(' · ');

/// The toast's lines when a clan's gift is taken: each clan whose standing
/// moved, the one that rose with its Narrative line, "from to to".
List<String> towerStandingToast(
        WidgetRef ref, Map<String, int> before, Map<String, int> after) =>
    [
      for (final MapEntry(:key, :value) in after.entries)
        if (value != (before[key] ?? 0))
          '${value > (before[key] ?? 0) ? tr(ref, 'tower_standing_toast_$key') : towerClanName(ref, key)} '
              '${tr(ref, 'tower_standing_step').replaceAll('{from}', '${before[key] ?? 0}').replaceAll('{to}', '$value')}',
    ];

/// The standing line of a clan's card: "Standing 4/6".
String towerStandingLabel(WidgetRef ref, int n) =>
    tr(ref, 'tower_standing_line')
        .replaceAll('{n}', '$n')
        .replaceAll('{max}', '$towerOathStep');

class TowerOfferView extends ConsumerStatefulWidget {
  const TowerOfferView({
    super.key,
    required this.run,
    required this.data,
    required this.onPick,
    this.event,
    this.cardTag,
    this.cardFooter,
    this.controls,
  });

  /// Clean slots for what Core has not defined yet: a mark on a card (a "new
  /// synergy" tag), a line under its words (a price), and a control under the
  /// pick (reroll, banish). Nothing is given today.
  final Widget? Function(int index)? cardTag;
  final Widget? Function(int index)? cardFooter;
  final Widget? controls;

  /// The floor's event (towerEventOf): a setback's test shows above the cards,
  /// rolled when the run moves on.
  final TowerEventView? event;

  final TowerRun run;
  final TowerData data;

  /// The card taken (its index), or null when all were left.
  final ValueChanged<int?> onPick;

  @override
  ConsumerState<TowerOfferView> createState() => _TowerOfferViewState();
}

class _TowerOfferViewState extends ConsumerState<TowerOfferView> {
  int _held = 0;
  bool _done = false;

  /// Card [i] of the offer, as a tarot card or, narrow, a row.
  Widget _card(BuildContext context, int i, bool tarot, double room) {
    final reward = widget.run.offer[i];
    final held = i == _held;
    final key = Key('tower_card_$i');
    final tag = widget.cardTag?.call(i);
    final footer = widget.cardFooter?.call(i);
    late final String kind, name, text, art;
    late final Widget icon;
    int? rarity;
    Key? nameKey;
    final iconSize = tarot ? 22.0 : 44.0;
    if (reward.kind == TowerRewardKind.clanOath) {
      final faction = ref.watch(factionsProvider)[reward.id];
      final lang = ref.watch(appLanguageProvider);
      final clan = faction?.shortFor(lang) ?? reward.id;
      final die = towerClanDieOf(reward.id, widget.data.dice);
      kind = tr(ref, 'tower_kind_oath');
      name = tr(ref, 'tower_oath_title').replaceAll('{clan}', clan);
      nameKey = Key('tower_oath_title_${reward.id}');
      text = [
        ..._oathLines(reward.id),
        if (die != null)
          tr(ref, 'tower_oath_die').replaceAll('{die}', towerDieName(ref, die)),
      ].join(' ');
      // The oath's vignette is the clan's own backdrop (the banner on its
      // plate); a clan without one keeps the stand-in.
      art = 'assets/visuals/cards/clans/backdrop_${reward.id}.png';
      icon = faction == null
          ? SizedBox(width: iconSize, height: iconSize)
          : ClanDisc(faction, size: iconSize);
    } else {
      final t = towerCardText(ref, reward, tier: _tierOf(reward));
      kind = t.kind;
      name = t.name;
      final isDie = reward.kind == TowerRewardKind.die;
      text =
          _withClan(reward, isDie && t.text.isNotEmpty ? 'd${t.text}' : t.text);
      final skillLike = reward.kind == TowerRewardKind.skill ||
          reward.kind == TowerRewardKind.rankUp;
      final k = switch (reward.kind) {
        TowerRewardKind.skill || TowerRewardKind.rankUp => 'skill',
        TowerRewardKind.spell => 'spell',
        _ => 'die',
      };
      final row = _row(reward);
      rarity = skillLike ? towerRarityIndex('${row['rarity'] ?? ''}') : null;
      // Art's keys: a skill by its element, a spell by its family (effect).
      art = towerCardVignette(k,
          variant: skillLike
              ? '${row['element'] ?? ''}'
              : reward.kind == TowerRewardKind.spell
                  ? towerSpellFamily('${row['effect'] ?? ''}')
                  : null);
      icon = towerCardPicture(
          towerCardIcon(k, reward.id,
              faces: isDie ? int.tryParse(t.text) : null),
          iconSize,
          fallback: Icon(Icons.casino,
              size: iconSize, color: InkColors.of(context).gold));
    }
    if (tarot) {
      // A lone card (the oath alone) is one of three, centred: not a
      // screen-high black tarot (#1145).
      final slots = widget.run.offer.length < 2 ? 3 : widget.run.offer.length;
      final w = (room - 8 * (slots - 1)) / slots;
      return TowerTarotCard(
        key: key,
        width: w,
        kind: kind,
        name: name,
        nameKey: nameKey,
        text: text,
        vignette: art,
        icon: icon,
        rarity: rarity,
        lightBadge: reward.kind == TowerRewardKind.skill ||
            reward.kind == TowerRewardKind.rankUp,
        held: held,
        dim: !held,
        tag: tag,
        footer: footer,
        onTap: () => setState(() => _held = i),
      );
    }
    return TowerRowCard(
      key: key,
      kind: kind,
      name: name,
      nameKey: nameKey,
      text: text,
      icon: icon,
      rarity: rarity,
      held: held,
      dim: !held,
      tag: tag,
      footer: footer,
      onTap: () => setState(() => _held = i),
    );
  }

  /// The clans' offer in the story's look (offer_dialog.dart): the gifts as a
  /// fanned hand of tier cards, each with its clan's banner and colour on the
  /// name band, and the oath as a wide row under them. What a card says and
  /// what a tap does are the Tower's own (the ripple and the standing stay
  /// in the card in hand's words under the table).
  Widget _clanTable(BuildContext context) {
    final offer = widget.run.offer;
    final lang = ref.watch(appLanguageProvider);
    final factions = ref.watch(factionsProvider);
    final gifts = <int>[
      for (var i = 0; i < offer.length; i++)
        if (offer[i].kind != TowerRewardKind.clanOath) i,
    ];
    final oaths = <int>[
      for (var i = 0; i < offer.length; i++)
        if (offer[i].kind == TowerRewardKind.clanOath) i,
    ];
    Color colourOf(String clanId) {
      final f = factions[clanId];
      return f == null ? inkGrey : Color(f.color | 0xFF000000);
    }

    Widget flagOf(String clanId, Color colour) => clanCardFlag(
          clanBannerId(clanId),
          plain:
              SizedBox(width: 40, height: 80, child: ColoredBox(color: colour)),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final i in oaths) ...[
        Builder(builder: (context) {
          final reward = offer[i];
          final colour = colourOf(reward.id);
          final faction = factions[reward.id];
          final clan = faction?.shortFor(lang) ?? reward.id;
          final die = towerClanDieOf(reward.id, widget.data.dice);
          return TowerClanOathRow(
            key: Key('tower_card_$i'),
            color: colour,
            flag: flagOf(reward.id, colour),
            icon: faction == null
                ? const SizedBox(width: 32, height: 32)
                : ClanDisc(faction, size: 32),
            name: tr(ref, 'tower_oath_title').replaceAll('{clan}', clan),
            tags: [towerClanTag(tr(ref, 'tower_kind_oath'))],
            text: [
              tr(ref, 'tower_oath_line_${reward.id}'),
              if (die != null)
                tr(ref, 'tower_oath_die')
                    .replaceAll('{die}', towerDieName(ref, die)),
            ].join(' '),
            // A late oath (the clan below 6/6, v2.8.0) says why in the envoy's
            // voice; an earned one carries the clan's motto.
            greeting: _late(reward.id)
                ? tr(ref, 'tower_oath_late_${reward.id}')
                : faction?.mottoFor(lang) ?? '',
            clanName: clan,
            standing:
                towerStandingLabel(ref, _standing[reward.id] ?? towerOathStep),
            selected: _held == i,
            onTap: () => setState(() => _held = i),
          );
        }),
        const SizedBox(height: 8),
      ],
      if (gifts.isNotEmpty)
        ClanHandFan(
          cards: [
            for (final i in gifts)
              Builder(builder: (context) {
                final reward = offer[i];
                final colour = colourOf(reward.clan);
                final faction = factions[reward.clan];
                final t = towerCardText(ref, reward, tier: _tierOf(reward));
                final row = _row(reward);
                final rarity = '${row['rarity'] ?? ''}';
                final idx = towerRarityIndex(rarity) ?? 0;
                final isSkill = reward.kind == TowerRewardKind.skill ||
                    reward.kind == TowerRewardKind.rankUp;
                return TowerClanCard(
                  rarity: idx.clamp(0, 4),
                  color: colour,
                  flag: flagOf(reward.clan, colour),
                  icon: towerCardPicture(
                      towerCardIcon(isSkill ? 'skill' : 'die', reward.id),
                      IconSize.s32,
                      fallback: Icon(Icons.auto_awesome,
                          size: IconSize.s32, color: colour)),
                  // Art's cut-paper vignette fills the card's top: a skill's
                  // by its element, a spell's by its family, a die's own.
                  vignette: towerCardVignette(
                      isSkill
                          ? 'skill'
                          : reward.kind == TowerRewardKind.spell
                              ? 'spell'
                              : 'die',
                      variant: isSkill
                          ? '${row['element'] ?? ''}'
                          : reward.kind == TowerRewardKind.spell
                              ? towerSpellFamily('${row['effect'] ?? ''}')
                              : null),
                  lightBadge: reward.kind == TowerRewardKind.skill ||
                      reward.kind == TowerRewardKind.rankUp,
                  name: t.name,
                  tags: [
                    towerClanTag(t.kind.split(' · ').first),
                    if (rarity.isNotEmpty)
                      towerClanTag(itemRarityLabelFor(lang, rarity)),
                  ],
                  greeting: faction?.mottoFor(lang) ?? '',
                  clanName: faction?.shortFor(lang) ?? reward.clan,
                  ripple: towerRippleLine(ref, reward.clan, widget.data,
                      heat: widget.run.heat),
                  standing:
                      towerStandingLabel(ref, _standing[reward.clan] ?? 0),
                  backdropId: reward.clan,
                  lit: _held == i,
                );
              }),
          ],
          keys: [for (final i in gifts) Key('tower_card_$i')],
          lit: gifts.indexOf(_held),
          onTap: (k) => setState(() => _held = gifts[k]),
        ),
    ]);
  }

  /// The card in hand, in full under the tarot row: its name and all its words
  /// at a readable size.
  Widget _detail(BuildContext context, int i) {
    final reward = widget.run.offer[i];
    final theme = Theme.of(context);
    late final String name, text;
    if (reward.kind == TowerRewardKind.clanOath) {
      final faction = ref.watch(factionsProvider)[reward.id];
      final clan =
          faction?.shortFor(ref.watch(appLanguageProvider)) ?? reward.id;
      final die = towerClanDieOf(reward.id, widget.data.dice);
      name = tr(ref, 'tower_oath_title').replaceAll('{clan}', clan);
      text = [
        ..._oathLines(reward.id),
        if (die != null)
          tr(ref, 'tower_oath_die').replaceAll('{die}', towerDieName(ref, die)),
      ].join(' ');
    } else {
      final t = towerCardText(ref, reward, tier: _tierOf(reward));
      name = t.name;
      text = _withClan(
          reward,
          reward.kind == TowerRewardKind.die && t.text.isNotEmpty
              ? 'd${t.text}'
              : t.text);
    }
    return Padding(
      key: const Key('tower_card_detail'),
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: theme.textTheme.titleSmall),
        if (text.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: theme.textTheme.bodySmall)),
      ]),
    );
  }

  /// A rank-up's skill's tier now (0 for any other card): the card names
  /// the step it gives (v2.4.0).
  int _tierOf(TowerReward reward) => reward.kind == TowerRewardKind.rankUp
      ? towerHeroOf(widget.run, widget.data).skillTiers[reward.id] ?? 0
      : 0;

  /// The table row of a skill, a spell or a die (its rarity, its profession).
  Map<String, dynamic> _row(TowerReward r) {
    final schema = switch (r.kind) {
      TowerRewardKind.skill || TowerRewardKind.rankUp => skillsSchema,
      TowerRewardKind.spell => spellsSchema,
      _ => diceSchema,
    };
    return ((ref.watch(localizedDbProvider(schema)).value ?? const {})[r.id]
                as Map?)
            ?.cast<String, dynamic>() ??
        const {};
  }

  /// The clans' standing in the run (docs/simulation/tower-clan-offers.md).
  Map<String, int> get _standing => towerStandingOf(widget.run, widget.data);

  /// A clan's oath card's words: at the oath's step its banner and standing,
  /// its own oath line and "One oath a climb" (the clans' offers), else the
  /// plain oath text.
  List<String> _oathLines(String clanId) {
    if (!towerClans.contains(clanId)) return [tr(ref, 'tower_oath_text')];
    final n = _standing[clanId] ?? 0;
    return [
      if (_late(clanId)) tr(ref, 'tower_oath_late_$clanId'),
      if (n >= towerOathStep)
        '${tr(ref, 'tower_unlock_banner_$clanId')} ${towerStandingLabel(ref, n)}.',
      tr(ref, 'tower_oath_line_$clanId'),
      tr(ref, 'tower_one_oath'),
    ];
  }

  /// Whether [clanId]'s oath is offered early (v2.8.0): the clan is below the
  /// oath's step.
  bool _late(String clanId) =>
      towerClans.contains(clanId) && (_standing[clanId] ?? 0) < towerOathStep;

  /// A clan's gift's words: what it moves and the clan's standing now.
  String _withClan(TowerReward reward, String text) => reward.clan.isEmpty
      ? text
      : [
          if (text.isNotEmpty) text,
          towerRippleLine(ref, reward.clan, widget.data, heat: widget.run.heat),
          towerStandingLabel(ref, _standing[reward.clan] ?? 0),
        ].join('\n');

  void _pick(int? index) {
    if (_done) return;
    setState(() => _done = true);
    final offer = widget.run.offer;
    // A clan's gift taken: the standing it moved, as a toast.
    if (index != null &&
        index >= 0 &&
        index < offer.length &&
        offer[index].clan.isNotEmpty) {
      final run = widget.run;
      final before = towerStandingOf(run, widget.data);
      final after = towerStandingOf(
          run.copyWith(taken: {...run.taken, run.floor: offer[index]}),
          widget.data);
      final lines = towerStandingToast(ref, before, after);
      if (lines.isNotEmpty) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
            key: const Key('tower_standing_toast'),
            content: Text(lines.join('\n'))));
      }
    }
    widget.onPick(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = widget.run.offer;
    final clans = offer
        .any((r) => r.clan.isNotEmpty || r.kind == TowerRewardKind.clanOath);
    return ListView(
      // The clans' table is tall: its Not now stays built below the fold.
      scrollCacheExtent: const ScrollCacheExtent.pixels(1600),
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
      children: [
        Text(tr(ref, 'tower_cleared').replaceAll('{n}', '${widget.run.floor}'),
            key: const Key('tower_cleared'),
            style: theme.textTheme.headlineSmall),
        Text(tr(ref, 'tower_choose_one'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Align(
            alignment: Alignment.centerLeft,
            child: TowerCoinChip(coins: widget.run.coins)),
        // The clans' offer: its frame over the cards.
        if (clans) ...[
          const SizedBox(height: 8),
          Text(tr(ref, 'tower_offer_frame_title'),
              key: const Key('tower_offer_frame'),
              style: theme.textTheme.titleSmall),
          Text(tr(ref, 'tower_offer_frame_body'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 12),
        if (widget.event?.kind == TowerEventKind.test) ...[
          TowerEventCard(widget.event!,
              bagFull: widget.run.potions >= towerBagCapOf(widget.run)),
          const SizedBox(height: 12),
        ],
        if (widget.event?.kind == TowerEventKind.shortcut &&
            (widget.event?.accepted ?? false)) ...[
          TowerShortcutWonLine(widget.event!),
          const SizedBox(height: 12),
        ],
        if (offer.isNotEmpty && clans)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _clanTable(context),
            if (_held < offer.length) _detail(context, _held),
            if (_held < offer.length)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton(
                    key: const Key('tower_take'),
                    onPressed: _done ? null : () => _pick(_held),
                    child: Text(tr(
                        ref,
                        offer[_held].kind == TowerRewardKind.clanOath
                            ? 'tower_swear'
                            : 'tower_take')),
                  ),
                ),
              ),
            if (widget.controls != null) widget.controls!,
          ])
        else if (offer.isNotEmpty)
          LayoutBuilder(builder: (context, box) {
            final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
            final tarot = towerTarotFits(box.maxWidth, scale,
                count: offer.length < 2 ? 3 : offer.length);
            final cards = [
              for (var i = 0; i < offer.length; i++)
                _card(context, i, tarot, box.maxWidth),
            ];
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tarot)
                    Row(
                        mainAxisAlignment: offer.length < 2
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            cards[i],
                          ],
                        ])
                  else
                    for (final c in cards)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8), child: c),
                  if (tarot && _held < offer.length) _detail(context, _held),
                  if (offer.isNotEmpty && _held < offer.length)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: FilledButton(
                          key: const Key('tower_take'),
                          onPressed: _done ? null : () => _pick(_held),
                          child: Text(tr(
                              ref,
                              offer[_held].kind == TowerRewardKind.clanOath
                                  ? 'tower_swear'
                                  : 'tower_take')),
                        ),
                      ),
                    ),
                  TowerTableCoinRow(
                    run: widget.run,
                    held: _held.clamp(0, offer.length - 1),
                    onReroll: () {
                      setState(() => _held = 0);
                      ref
                          .read(towerProvider.notifier)
                          .reroll(data: widget.data);
                    },
                    onBanish: (i) {
                      setState(() => _held = 0);
                      ref.read(towerProvider.notifier).banish(i);
                    },
                  ),
                  if (widget.controls != null) widget.controls!,
                ]);
          }),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            key: const Key('tower_refuse'),
            onPressed: _done ? null : () => _pick(null),
            child: Text(tr(
                ref,
                offer.isEmpty
                    ? 'tower_continue'
                    : clans
                        ? 'tower_not_now'
                        : 'tower_refuse')),
          ),
        ),
      ],
    );
  }
}

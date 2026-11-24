// The cards of a won floor (v1.848, the-tower-designs.md screen 4, the loot
// dialog's design A in "choose one" mode): three cards of different kinds,
// the one in hand ringed and the others dimmed, Take for the card in hand,
// or leave them all for a mark.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/dice_faces.dart' show skillDisplayName;
import '../../data/tower/tower_hero.dart';
import '../../data/tower/tower_rewards.dart';
import '../../data/tower/tower_run.dart';
import '../../data/tower/tower_tables.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/clans_provider.dart';
import '../../widgets/race_profession_cards.dart' show ClanDisc;
import '../../providers/game_db_providers.dart';
import '../../theme/stitched_ink.dart';
import '../../data/tower/tower_events.dart';
import 'tower_card_art.dart';
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

/// The words of [reward] in the reader's language.
TowerCardText towerCardText(WidgetRef ref, TowerReward reward) {
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
          tr(ref, 'tower_kind_skill'),
          skillDisplayName(reward.id, language: lang),
          '${row(skillsSchema, reward.id)['description'] ?? ''}');
    case TowerRewardKind.spell:
      final r = row(spellsSchema, reward.id);
      return TowerCardText(tr(ref, 'tower_kind_spell'),
          '${r['spellName'] ?? reward.id}', '${r['description'] ?? ''}');
    case TowerRewardKind.clanOath:
      // A clan offers its oath (Core's v1.855; UX-2 dresses the card).
      return TowerCardText(
          tr(ref, 'tower_kind_oath'),
          ref.watch(factionsProvider)[reward.id]?.shortFor(lang) ?? reward.id,
          tr(ref, 'tower_oath_text'));
  }
}

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
        tr(ref, 'tower_oath_text'),
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
      final t = towerCardText(ref, reward);
      kind = t.kind;
      name = t.name;
      final isDie = reward.kind == TowerRewardKind.die;
      text = isDie && t.text.isNotEmpty ? 'd${t.text}' : t.text;
      final k = switch (reward.kind) {
        TowerRewardKind.skill => 'skill',
        TowerRewardKind.spell => 'spell',
        _ => 'die',
      };
      final row = _row(reward);
      rarity = reward.kind == TowerRewardKind.skill
          ? towerRarityIndex('${row['rarity'] ?? ''}')
          : null;
      // Art's keys: a skill by its element, a spell by its family (effect).
      art = towerCardVignette(k,
          variant: reward.kind == TowerRewardKind.skill
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
      // A lone card (the oath alone) is one of three, centred: not a screen-high
      // black tarot (#1145).
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
        tr(ref, 'tower_oath_text'),
        if (die != null)
          tr(ref, 'tower_oath_die').replaceAll('{die}', towerDieName(ref, die)),
      ].join(' ');
    } else {
      final t = towerCardText(ref, reward);
      name = t.name;
      text = reward.kind == TowerRewardKind.die && t.text.isNotEmpty
          ? 'd${t.text}'
          : t.text;
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

  /// The table row of a skill, a spell or a die (its rarity, its profession).
  Map<String, dynamic> _row(TowerReward r) {
    final schema = switch (r.kind) {
      TowerRewardKind.skill => skillsSchema,
      TowerRewardKind.spell => spellsSchema,
      _ => diceSchema,
    };
    return ((ref.watch(localizedDbProvider(schema)).value ?? const {})[r.id]
                as Map?)
            ?.cast<String, dynamic>() ??
        const {};
  }

  void _pick(int? index) {
    if (_done) return;
    setState(() => _done = true);
    widget.onPick(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = widget.run.offer;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
      children: [
        Text(tr(ref, 'tower_cleared').replaceAll('{n}', '${widget.run.floor}'),
            key: const Key('tower_cleared'),
            style: theme.textTheme.headlineSmall),
        Text(tr(ref, 'tower_choose_one'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (widget.event?.kind == TowerEventKind.test) ...[
          TowerEventCard(widget.event!,
              bagFull: widget.run.potions >= towerBagCap),
          const SizedBox(height: 12),
        ],
        if (widget.event?.kind == TowerEventKind.shortcut &&
            (widget.event?.accepted ?? false)) ...[
          TowerShortcutWonLine(widget.event!),
          const SizedBox(height: 12),
        ],
        if (offer.isNotEmpty)
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
                  if (widget.controls != null) widget.controls!,
                ]);
          }),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            key: const Key('tower_refuse'),
            onPressed: _done ? null : () => _pick(null),
            child: Text(
                tr(ref, offer.isEmpty ? 'tower_continue' : 'tower_refuse')),
          ),
        ),
      ],
    );
  }
}

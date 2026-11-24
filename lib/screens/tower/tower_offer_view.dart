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
import '../../data/tower/tower_clans.dart' show towerClanRipple;
import '../../data/tower/tower_events.dart';
import '../../widgets/ink_panel.dart';
import 'tower_event_card.dart';

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
          tr(ref, 'tower_rank_up_name')
              .replaceAll(
                  '{skill}', skillDisplayName(reward.id, language: lang))
              .replaceAll('{from}', '${tier + 1}')
              .replaceAll('{to}', '${tier + 2}'),
          tr(ref, 'tower_rank_up_text'));
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
String towerRippleLine(WidgetRef ref, String clanId, TowerData data) => [
      for (final MapEntry(:key, :value)
          in towerClanRipple(clanId, data.clans).entries)
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

class TowerOfferView extends ConsumerStatefulWidget {
  const TowerOfferView({
    super.key,
    required this.run,
    required this.data,
    required this.onPick,
    this.event,
  });

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
    final ink = InkColors.of(context);
    final offer = widget.run.offer;
    final tiers = offer.any((r) => r.kind == TowerRewardKind.rankUp)
        ? towerHeroOf(widget.run, widget.data).skillTiers
        : const <String, int>{};
    // The clans' offer (docs/simulation/tower-clan-offers.md): its frame,
    // each gift's clan and what it moves, Not now for a mark.
    final clans = offer
        .any((r) => r.clan.isNotEmpty || r.kind == TowerRewardKind.clanOath);
    final standing = clans
        ? towerStandingOf(widget.run, widget.data)
        : const <String, int>{};
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
      children: [
        Text(tr(ref, 'tower_cleared').replaceAll('{n}', '${widget.run.floor}'),
            key: const Key('tower_cleared'),
            style: theme.textTheme.headlineSmall),
        Text(tr(ref, 'tower_choose_one'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
              bagFull: widget.run.potions >= towerBagCap),
          const SizedBox(height: 12),
        ],
        if (widget.event?.kind == TowerEventKind.shortcut &&
            (widget.event?.accepted ?? false)) ...[
          TowerShortcutWonLine(widget.event!),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < offer.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(builder: (context) {
              final text =
                  towerCardText(ref, offer[i], tier: tiers[offer[i].id] ?? 0);
              final held = i == _held;
              if (offer[i].kind == TowerRewardKind.clanOath) {
                return _OathCard(
                  key: Key('tower_card_$i'),
                  clanId: offer[i].id,
                  held: held,
                  done: _done,
                  data: widget.data,
                  standing: standing[offer[i].id] ?? 0,
                  onHold: () => setState(() => _held = i),
                  onSwear: () => _pick(i),
                );
              }
              return InkPanel(
                key: Key('tower_card_$i'),
                lit: held,
                dim: !held,
                onTap: () => setState(() => _held = i),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(text.name,
                              style: theme.textTheme.titleSmall),
                        ),
                        Text(text.kind,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: ink.gold)),
                      ],
                    ),
                    if (text.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child:
                            Text(text.text, style: theme.textTheme.bodySmall),
                      ),
                    if (offer[i].clan.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            '${towerRippleLine(ref, offer[i].clan, widget.data)}'
                            '\n${tr(ref, 'tower_standing_line').replaceAll('{n}', '${standing[offer[i].clan] ?? 0}').replaceAll('{max}', '$towerOathStep')}',
                            key: Key('tower_card_clan_$i'),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                    if (held)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FilledButton(
                            key: const Key('tower_take'),
                            onPressed: _done ? null : () => _pick(i),
                            child: Text(tr(ref, 'tower_take')),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
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

/// A clan's oath among the cards: its banner on its colour, "The Salt Crows
/// offer you their oath", what swearing gives (their standing, and their
/// die by name) and Swear for the card in hand.
class _OathCard extends ConsumerWidget {
  const _OathCard({
    super.key,
    required this.clanId,
    required this.held,
    required this.done,
    required this.data,
    this.standing = 0,
    required this.onHold,
    required this.onSwear,
  });

  /// The run's standing with the clan (its oath comes at towerOathStep).
  final int standing;
  final String clanId;
  final bool held;
  final bool done;
  final TowerData data;
  final VoidCallback onHold;
  final VoidCallback onSwear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final faction = ref.watch(factionsProvider)[clanId];
    final colour =
        faction == null ? InkColors.of(context).gold : Color(faction.color);
    final name = faction?.shortFor(lang) ?? clanId;
    final die = towerClanDieOf(clanId, data.dice);
    return InkPanel(
      lit: held,
      dim: !held,
      onTap: onHold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The banner of a clan at the oath's step (the clans' offers).
          if (standing >= towerOathStep)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  '${tr(ref, 'tower_unlock_banner_$clanId')} '
                  '${tr(ref, 'tower_standing_line').replaceAll('{n}', '$standing').replaceAll('{max}', '$towerOathStep')}',
                  key: Key('tower_oath_banner_$clanId'),
                  style: theme.textTheme.bodySmall?.copyWith(color: colour)),
            ),
          Row(
            children: [
              if (faction != null) ...[
                ClanDisc(faction, size: 34),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                    tr(ref, 'tower_oath_title').replaceAll('{clan}', name),
                    key: Key('tower_oath_title_$clanId'),
                    style: theme.textTheme.titleSmall),
              ),
              Text(tr(ref, 'tower_kind_oath'),
                  style: theme.textTheme.labelSmall?.copyWith(color: colour)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
                towerClans.contains(clanId)
                    ? '${tr(ref, 'tower_oath_line_$clanId')} '
                        '${tr(ref, 'tower_one_oath')}'
                    : tr(ref, 'tower_oath_text'),
                style: theme.textTheme.bodySmall),
          ),
          if (die != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                  tr(ref, 'tower_oath_die')
                      .replaceAll('{die}', towerDieName(ref, die)),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          if (held)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton(
                  key: const Key('tower_take'),
                  onPressed: done ? null : onSwear,
                  child: Text(tr(ref, 'tower_swear')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

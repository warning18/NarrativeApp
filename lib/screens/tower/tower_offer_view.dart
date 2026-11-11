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
    widget.onPick(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
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
          TowerEventCard(widget.event!),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < offer.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(builder: (context) {
              final text = towerCardText(ref, offer[i]);
              final held = i == _held;
              if (offer[i].kind == TowerRewardKind.clanOath) {
                return _OathCard(
                  key: Key('tower_card_$i'),
                  clanId: offer[i].id,
                  held: held,
                  done: _done,
                  data: widget.data,
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
            child: Text(
                tr(ref, offer.isEmpty ? 'tower_continue' : 'tower_refuse')),
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
    required this.onHold,
    required this.onSwear,
  });

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
            child: Text(tr(ref, 'tower_oath_text'),
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

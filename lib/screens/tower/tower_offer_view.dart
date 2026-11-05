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
import '../../providers/game_db_providers.dart';
import '../../theme/stitched_ink.dart';
import 'tower_widgets.dart';

/// What a card reads: its kind, its name and what it does.
class TowerCardText {
  const TowerCardText(this.kind, this.name, this.text);

  final String kind;
  final String name;
  final String text;
}

/// The words of [reward] in the reader's language.
TowerCardText towerCardText(WidgetRef ref, TowerReward reward) {
  final lang = ref.watch(appLanguageProvider);
  Map<String, dynamic> row(DbSchema schema, String id) =>
      ((ref.watch(localizedDbProvider(schema)).value ?? const {})[id] as Map?)
          ?.cast<String, dynamic>() ??
      const {};
  String dieName(String id) => '${row(diceSchema, id)['diceName'] ?? id}';
  switch (reward.kind) {
    case TowerRewardKind.item:
      final r = row(itemsSchema, reward.id);
      return TowerCardText(
          tr(ref, 'tower_kind_item'),
          '${r['itemName'] ?? reward.id}',
          [
            trItemType(ref, '${r['itemType'] ?? ''}'),
            '${r['rarity'] ?? ''}',
          ].where((s) => s.isNotEmpty).join(' · '));
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
    case TowerRewardKind.heal:
      return TowerCardText(
          tr(ref, 'tower_kind_heal'),
          tr(ref, 'tower_heal_name').replaceAll('{n}', '${reward.amount}'),
          tr(ref, 'tower_heal_text').replaceAll('{n}', '${reward.amount}'));
    case TowerRewardKind.clanGift:
      return reward.id.isEmpty
          ? TowerCardText(
              tr(ref, 'tower_kind_gift'),
              tr(ref, 'tower_gift_name'),
              tr(ref, 'tower_gift_stat').replaceAll('{n}', '${reward.amount}'))
          : TowerCardText(tr(ref, 'tower_kind_gift'), dieName(reward.id), '');
  }
}

class TowerOfferView extends ConsumerStatefulWidget {
  const TowerOfferView({
    super.key,
    required this.run,
    required this.data,
    required this.onPick,
  });

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
        for (var i = 0; i < offer.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(builder: (context) {
              final text = towerCardText(ref, offer[i]);
              final held = i == _held;
              return TowerPanel(
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
            child: Text(tr(ref, 'tower_refuse')),
          ),
        ),
      ],
    );
  }
}

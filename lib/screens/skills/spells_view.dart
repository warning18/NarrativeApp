// The Spells tab: the mana pool and what refills it, then the spells the
// class can cast -- known ones first with the numbers they would land now,
// then the ones still to find and where their spellbooks are sold. A row
// opens the spell's full card.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/spells.dart';
import '../../combat/status_effect.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/game_db_providers.dart';
import '../../providers/player_session_provider.dart';
import '../../theme/stitched_ink.dart';
import '../../utils/game_icons.dart';
import '../../utils/spell_preview.dart';
import '../../widgets/detail_dialog.dart';
import '../../widgets/mana_meter.dart';

class SpellsView extends ConsumerWidget {
  const SpellsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final session = ref.watch(playerSessionProvider);
    final spells = parseSpells(
        ref.watch(localizedDbProvider(spellsSchema)).value ?? const {});
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    final shops = ref.watch(localizedDbProvider(shopsSchema)).value ?? const {};
    final list = spellsForProfession(
        spells, session.professionId, session.knownSpellIds);
    final known = [
      for (final s in list)
        if (session.knownSpellIds.contains(s.id)) s
    ];
    final toFind = [
      for (final s in list)
        if (!session.knownSpellIds.contains(s.id)) s
    ];
    final wisdomBonus = wisdomManaBonusFor(session.wisdom);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 2),
          child: Text(text.toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, letterSpacing: 1)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          key: const Key('spells_mana'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: manaColor),
            color: manaColor.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(manaIcon, size: 18, color: manaColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${tr(ref, 'mana_label')} ${session.mana} / ${session.maxMana}',
                    style:
                        theme.textTheme.titleMedium?.copyWith(color: manaColor),
                  ),
                ),
                ManaMeter(mana: session.mana, maxMana: session.maxMana),
              ]),
              const SizedBox(height: 6),
              Text(
                '${tr(ref, 'mana_faces_note')} ${tr(ref, 'cast_in_battle_hint')}',
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
              ),
              if (wisdomBonus > 0)
                Text(
                  tr(ref, 'wisdom_mana_bonus_line')
                      .replaceAll('{n}', '$wisdomBonus')
                      .replaceAll('{wis}', '${session.wisdom}'),
                  style: theme.textTheme.bodySmall?.copyWith(color: manaColor),
                ),
            ],
          ),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(tr(ref, 'no_spells_hint'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
          ),
        if (known.isNotEmpty) heading(tr(ref, 'spells_known')),
        for (final spell in known)
          _SpellRow(spell: spell, known: true, items: items, shops: shops),
        if (toFind.isNotEmpty) heading(tr(ref, 'spells_to_find')),
        for (final spell in toFind)
          _SpellRow(spell: spell, known: false, items: items, shops: shops),
      ],
    );
  }
}

class _SpellRow extends ConsumerWidget {
  const _SpellRow({
    required this.spell,
    required this.known,
    required this.items,
    required this.shops,
  });

  final SpellSpec spell;
  final bool known;
  final Map<String, dynamic> items;
  final Map<String, dynamic> shops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final preview = previewSpellFor(spell, session, items);
    final colour = spellEffectColor(spell.effect);
    final shopNames = spellbookShopsFor(spell.id, items, shops)
        .map((id) =>
            (shops[id] as Map<String, dynamic>?)?['shopName']?.toString() ?? id)
        .join(', ');
    final whereLine = known
        ? null
        : shopNames.isEmpty
            ? tr(ref, 'spellbook_not_sold')
            : '${tr(ref, 'spellbook_sold_at_prefix')} $shopNames';
    final status = preview.status;
    final statusLine = status == null
        ? null
        : switch (status.type) {
            StatusEffectType.poison =>
              '${tr(ref, 'status_poison_label')} ${status.magnitude} x ${status.remainingTurns}',
            StatusEffectType.stun =>
              '${tr(ref, 'status_stun_label')} ${status.remainingTurns}',
            StatusEffectType.weaken =>
              '${tr(ref, 'status_weaken_label')} ${status.magnitude}% x ${status.remainingTurns}',
          };
    final numbers = [
      '${spell.manaCost} ${tr(ref, 'mana_label')}',
      '${tr(ref, spellEffectLabelKey(spell.effect))}'
          '${preview.amount > 0 ? ' ${preview.amount}' : ''}',
      tr(ref, spellTargetLabelKey(spell.target)),
      if (spell.element != 'None') spell.element,
      if (statusLine != null) statusLine,
    ].join(' · ');
    final name = spell.nameFor(lang);
    final description = spell.descriptionFor(lang);

    return InkWell(
      key: Key('spell_row_${spell.id}'),
      onTap: () => showDetailDialog(
        context,
        title: name,
        description: description,
        leading: Icon(spellEffectIcon(spell.effect), color: colour, size: 24),
        closeLabel: tr(ref, 'close_button'),
        rows: [
          MapEntry(tr(ref, 'cost_label'),
              '${spell.manaCost} ${tr(ref, 'mana_label')}'),
          MapEntry(tr(ref, 'effect_label'),
              tr(ref, spellEffectLabelKey(spell.effect))),
          if (preview.amount > 0)
            MapEntry(tr(ref, 'right_now_label'), '${preview.amount}'),
          MapEntry(tr(ref, 'target_label'),
              tr(ref, spellTargetLabelKey(spell.target))),
          if (spell.element != 'None')
            MapEntry(tr(ref, 'element_label'), spell.element),
          if (statusLine != null) MapEntry(tr(ref, 'status_label'), statusLine),
          if (whereLine != null)
            MapEntry(tr(ref, 'where_to_learn_label'),
                shopNames.isEmpty ? tr(ref, 'spellbook_not_sold') : shopNames),
        ],
      ),
      child: Opacity(
        opacity: known ? 1 : 0.65,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ink.seam))),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: colour.withValues(alpha: 0.15),
                child: Icon(spellEffectIcon(spell.effect),
                    color: colour, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.bodyLarge),
                    Text(numbers,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                    if (whereLine != null)
                      Text(whereLine,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.gold)),
                  ],
                ),
              ),
              Icon(known ? Icons.chevron_right : Icons.lock_outline,
                  size: 18, color: ink.ash),
            ],
          ),
        ),
      ),
    );
  }
}

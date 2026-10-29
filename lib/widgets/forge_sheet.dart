// The Forge sheet, with tabs (v1.593, docs/proposals/redraw-2.md E and
// forge-mock.md): the pieces forged at a shop, one tab for each slot a
// recipe is for (Head, Body, Legs, Feet), a gold dot on the tab where
// something can be forged now. One short line says the roll (d20 and its
// modifiers), the odds behind a tap; each piece is a compact card: its name,
// its number, what it needs with a tick or a cross, one button that says what
// it lacks when it cannot be pressed. Forging plays the forging moment
// (forge_moment.dart). The rule is Core's (forge_roll.dart, v1.562).
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fate_coin.dart';
import '../data/forge_roll.dart';
import '../data/item_origin_here.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/forge_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../screens/fate_coin_offer.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'forge_moment.dart';
import 'player_stats_bar.dart';

/// A test seam: the random the forge rolls its d20 with (null: a fresh one).
Random Function()? forgeRandomForTest;

/// Opens the forge's recipes at [shopId].
Future<void> showForgeSheet(BuildContext context, {required String shopId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.8,
      child: ForgeSheetView(shopId: shopId),
    ),
  );
}

/// The order the slot tabs come in; any other slot follows by name.
const List<String> forgeSlotOrder = ['Head', 'Top', 'Bottom', 'Foot', 'Weapon'];

String _nameOf(Map<String, dynamic>? item, String id, AppLanguage lang) {
  final fr = item?['itemName_fr']?.toString() ?? '';
  if (lang == AppLanguage.fr && fr.isNotEmpty) return fr;
  return item?['itemName']?.toString() ?? id;
}

String _capital(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class ForgeSheetView extends ConsumerStatefulWidget {
  const ForgeSheetView({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<ForgeSheetView> createState() => _ForgeSheetViewState();
}

class _ForgeSheetViewState extends ConsumerState<ForgeSheetView> {
  String? _slot;
  bool _odds = false;
  bool _hint = false;
  bool _busy = false;

  bool _canForge(String id, Map<String, dynamic> items, PlayerSession session) {
    final item = items[id] as Map<String, dynamic>?;
    if (item == null) return false;
    final gold = (item['craftGold'] as num?)?.toInt() ?? 0;
    if (session.gold < gold) return false;
    return craftMaterialsFor(item).entries.every((m) =>
        session.inventoryItemIds.where((i) => i == m.key).length >= m.value);
  }

  /// Asks whether the Bone-Caster's Hut rolls the flawed piece again; true
  /// when the player spends the charge.
  Future<bool> _offerHutReroll(AppLanguage lang) async {
    String t(String key) => trFor(lang, key);
    final left = ref.read(playerSessionProvider).rerollCharges;
    final reroll = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('forge_hut_offer'),
        content: Text(t('forge_hut_offer').replaceAll('{n}', '$left')),
        actions: [
          TextButton(
            key: const Key('forge_hut_keep'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('fate_coin_keep_button')),
          ),
          FilledButton(
            key: const Key('forge_hut_reroll'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('reroll_button')),
          ),
        ],
      ),
    );
    return reroll ?? false;
  }

  Future<void> _forge(String id, Map<String, dynamic> items) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      var again = true;
      while (again) {
        again = false;
        final notifier = ref.read(playerSessionProvider.notifier);
        final item = items[id] as Map<String, dynamic>?;
        if (item == null || !notifier.canCraft(item)) break;
        final lang = ref.read(appLanguageProvider);
        final random = forgeRandomForTest?.call() ?? Random();
        // What this forging spends, said before it is gone.
        final spent = [
          for (final m in craftMaterialsFor(item).entries)
            '${m.value} ${_nameOf(items[m.key] as Map<String, dynamic>?, m.key, lang).toLowerCase()}',
          '${(item['craftGold'] as num?)?.toInt() ?? 0} ${trFor(lang, 'gold_label')}',
        ].join(' · ');
        var roll = await notifier.craftItem(id, item,
            origin: itemOriginHere(ref),
            random: random,
            modifiers: ref.read(forgeModifiersProvider));
        if (roll == null || !mounted) break;
        // A Flawed piece, and the Bone-Caster's Hut standing with a Reroll
        // charge: the hut may roll the forge's d20 again (camp_rolls.dart).
        var coinLine = '';
        if (roll.tier == ForgeTier.flawed &&
            notifier.canRerollForge &&
            await _offerHutReroll(lang)) {
          final redo = await notifier.rerollForge(
              forgedVariantId(baseItemIdOf(id), roll.tier), roll,
              random: random);
          if (redo != null) {
            coinLine = '${trFor(lang, 'forge_hut_rolled')} ';
            roll = redo;
          }
        }
        if (!mounted) break;
        // A Flawed piece, and a fate coin in the pack: the coin may forge it
        // once more (fate_coin.dart).
        if (fateCoinWorthFlippingForge(roll) &&
            carriesFateCoin(ref.read(playerSessionProvider).inventoryItemIds) &&
            await offerFateCoin(context, lang,
                messageKey: 'forge_coin_offer')) {
          final redo = await notifier.reforgeWithFateCoin(
              forgedVariantId(baseItemIdOf(id), roll.tier), roll,
              random: random);
          if (redo != null) {
            coinLine += '${fateCoinLandedLine(flipFateCoin(random), lang)} ';
            roll = redo;
          }
        }
        if (!mounted) break;
        final name = _nameOf(item, id, lang);
        again = await showForgeMoment(
          context,
          roll: roll,
          itemId: forgedVariantId(baseItemIdOf(id), roll.tier),
          base: item,
          pieceName: forgedNameFor(name, roll.tier, lang),
          spent: spent,
          coinLine: coinLine,
          canForgeAnother:
              ref.read(playerSessionProvider.notifier).canCraft(item),
        );
        if (!mounted) break;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ??
        const <String, dynamic>{};
    final shops = ref.watch(localizedDbProvider(shopsSchema)).value ??
        const <String, dynamic>{};
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final recipes = recipesAt(widget.shopId, items);

    String slotOf(String id) =>
        (items[id] as Map<String, dynamic>?)?['equipSlot']?.toString() ?? '';
    final slots = {for (final id in recipes) slotOf(id)}.toList()
      ..sort((a, b) {
        int rank(String s) {
          final i = forgeSlotOrder.indexOf(s);
          return i < 0 ? forgeSlotOrder.length : i;
        }

        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.compareTo(b);
      });
    final ready = {
      for (final s in slots)
        s: recipes
            .any((id) => slotOf(id) == s && _canForge(id, items, session)),
    };
    // The tab shown: the one left on, else the first with something to
    // forge, else the first.
    final slot = slots.contains(_slot)
        ? _slot!
        : slots.firstWhere((s) => ready[s] == true,
            orElse: () => slots.isEmpty ? '' : slots.first);
    final shown = [
      for (final id in recipes)
        if (slotOf(id) == slot) id
    ];

    final modifiers = ref.watch(forgeModifiersProvider);
    final total = modifiers.fold<int>(0, (n, m) => n + m.value);
    final clans = ref.watch(clanDataProvider);
    final keeper = shops[widget.shopId] as Map<String, dynamic>?;
    final line = keeper?['keeperLine']?.toString() ?? '';
    final firstSentence =
        line.contains('. ') ? line.substring(0, line.indexOf('. ') + 1) : line;
    final keeperName = keeper?['keeperName']?.toString() ?? '';

    String carriedOf(String id) =>
        '${session.inventoryItemIds.where((i) => i == id).length}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          child: Row(children: [
            Text(tr(ref, 'forge_title'), style: theme.textTheme.titleMedium),
            IconButton(
              key: const Key('forge_hint_button'),
              icon: Icon(Icons.info_outline, size: 18, color: ink.ash),
              tooltip: tr(ref, 'forge_hint_tip'),
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _hint = !_hint),
            ),
            const Spacer(),
            const GoldBadge(),
          ]),
        ),
        if (firstSentence.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              keeperName.isEmpty
                  ? '“$firstSentence”'
                  : '“$firstSentence”  $keeperName',
              key: const Key('forge_keeper_line'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: ink.ash,
                  fontStyle: FontStyle.italic,
                  fontFamily: InkFonts.prose),
            ),
          ),
        if (_hint)
          Container(
            key: const Key('forge_hint'),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8)),
            child:
                Text(tr(ref, 'forge_hint'), style: theme.textTheme.bodySmall),
          ),
        // The tabs.
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final s in slots)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: ValueKey('forge_tab_$s'),
                    selected: s == slot,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    labelStyle: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurface),
                    label: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          trFor(lang, 'forge_slot_$s').startsWith('forge_slot_')
                              ? s
                              : trFor(lang, 'forge_slot_$s')),
                      if (ready[s] == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          key: ValueKey('forge_tab_dot_$s'),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              shape: BoxShape.circle),
                        ),
                      ],
                    ]),
                    onSelected: (_) => setState(() => _slot = s),
                  ),
                ),
            ],
          ),
        ),
        // The roll, in one line; its odds behind a tap.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Container(
            key: const Key('forge_roll_box'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(children: [
              InkWell(
                key: const Key('forge_odds_toggle'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _odds = !_odds),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(children: [
                    const Icon(Icons.casino_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                        trFor(lang, 'forge_roll_line').replaceAll(
                            '{mod}',
                            total == 0
                                ? ''
                                : (total > 0
                                    ? '+ $total'
                                    : '− ${total.abs()}')),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                        trFor(lang,
                            _odds ? 'forge_odds_close' : 'forge_odds_open'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                    Icon(_odds ? Icons.expand_less : Icons.expand_more,
                        size: 18, color: ink.ash),
                  ]),
                ),
              ),
              if (_odds)
                Padding(
                  key: const Key('forge_odds'),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (modifiers.isNotEmpty)
                          Wrap(spacing: 6, runSpacing: 4, children: [
                            for (final m in modifiers)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: m.value >= 0
                                          ? Colors.green.shade600
                                          : theme.colorScheme.error),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                    '${m.labelFor(lang, clans: clans)} ${m.value >= 0 ? '+' : '−'}${m.value.abs()}',
                                    style: theme.textTheme.labelMedium),
                              ),
                          ]),
                        const SizedBox(height: 8),
                        ForgeTierBar(odds: forgeOdds(total)),
                        const SizedBox(height: 6),
                        Row(children: [
                          for (final t in ForgeTier.values)
                            Expanded(
                              child: Text(trFor(lang, forgeTierLabelKey(t)),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: forgeTierColor(t))),
                            ),
                        ]),
                        const SizedBox(height: 6),
                        Text(trFor(lang, 'forge_odds_note'),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: ink.ash, fontStyle: FontStyle.italic)),
                      ]),
                ),
            ]),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              for (final id in shown)
                Builder(builder: (context) {
                  final item = items[id] as Map<String, dynamic>;
                  final name = _nameOf(item, id, lang);
                  final stat = forgeMainStatOf(item);
                  final number = (item[stat] as num?)?.toInt() ?? 0;
                  final gold = (item['craftGold'] as num?)?.toInt() ?? 0;
                  final materials = craftMaterialsFor(item);
                  final can = _canForge(id, items, session);
                  // What is missing, the first thing first.
                  String? lacking;
                  for (final m in materials.entries) {
                    final have = session.inventoryItemIds
                        .where((i) => i == m.key)
                        .length;
                    if (have < m.value) {
                      lacking = trFor(lang, 'forge_short_of')
                          .replaceAll('{n}', '${m.value - have}')
                          .replaceAll(
                              '{item}',
                              _nameOf(items[m.key] as Map<String, dynamic>?,
                                      m.key, lang)
                                  .toLowerCase());
                      break;
                    }
                  }
                  if (lacking == null && session.gold < gold) {
                    lacking = trFor(lang, 'forge_short_gold')
                        .replaceAll('{n}', '${gold - session.gold}');
                  }
                  Widget need(String text, bool ok) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: ok
                                  ? Colors.green.shade600
                                  : theme.colorScheme.error),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(ok ? Icons.check : Icons.close,
                              size: 14,
                              color: ok
                                  ? Colors.green.shade600
                                  : theme.colorScheme.error),
                          const SizedBox(width: 4),
                          Flexible(
                              child: Text(text,
                                  style: theme.textTheme.labelMedium)),
                        ]),
                      );
                  return Card(
                    key: ValueKey('forge_card_$id'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            ItemPixelIcon(id, item['itemType']?.toString(),
                                size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child:
                                  Text(name, style: theme.textTheme.titleSmall),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.green.shade600),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                  '${trFor(lang, stat == 'attackDamage' ? 'atk_abbrev' : 'arm_abbrev')} +$number',
                                  style: theme.textTheme.labelMedium),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            for (final m in materials.entries)
                              need(
                                  trFor(lang, 'forge_have_need')
                                      .replaceAll(
                                          '{item}',
                                          _nameOf(
                                              items[m.key]
                                                  as Map<String, dynamic>?,
                                              m.key,
                                              lang))
                                      .replaceAll('{have}', carriedOf(m.key))
                                      .replaceAll('{need}', '${m.value}'),
                                  session.inventoryItemIds
                                          .where((i) => i == m.key)
                                          .length >=
                                      m.value),
                            need(
                                trFor(lang, 'forge_have_need')
                                    .replaceAll('{item}',
                                        _capital(trFor(lang, 'gold_label')))
                                    .replaceAll('{have}', '${session.gold}')
                                    .replaceAll('{need}', '$gold'),
                                session.gold >= gold),
                          ]),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: can
                                ? FilledButton.icon(
                                    key: ValueKey('forge_go_$id'),
                                    onPressed:
                                        _busy ? null : () => _forge(id, items),
                                    icon: const Icon(Icons.hardware, size: 18),
                                    label: Text(trFor(lang, 'forge_button')),
                                  )
                                : FilledButton.tonalIcon(
                                    key: ValueKey('forge_go_$id'),
                                    onPressed: null,
                                    icon: const Icon(Icons.lock_outline,
                                        size: 18),
                                    label: Text(
                                        lacking ?? trFor(lang, 'forge_button')),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

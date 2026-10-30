// The pieces of the inventory screen (v1.594, docs/proposals/inventory-review.md):
// tabs only for the kinds the bag holds, six slots as small tiles, a row with
// one quiet line, the numbers as chips against what is worn and one labelled
// button, and the dice as rows in their own skins. The screen
// (lib/screens/inventory_screen.dart) keeps the equip logic; this file only
// draws.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'die_skins.dart';
import 'item_lore.dart';
import 'item_stats.dart';

/// The inventory's tabs, in the order they are drawn.
enum InventoryTab { all, gear, charms, potions, materials, books, quest, dice }

/// The tab an item of [item]'s type belongs to (never [InventoryTab.all] or
/// [InventoryTab.dice]); null for a type the bag has no tab for, which then
/// shows under All only. Gear is what is worn: Weapon, Armor and Artifact;
/// Books are what is read: Spellbook, Tome and Scroll.
InventoryTab? inventoryKindOf(Map<String, dynamic>? item) =>
    switch (item?['itemType']?.toString()) {
      'Weapon' || 'Armor' || 'Artifact' => InventoryTab.gear,
      'Charm' => InventoryTab.charms,
      'Potion' => InventoryTab.potions,
      'Material' => InventoryTab.materials,
      'Spellbook' || 'Tome' || 'Scroll' => InventoryTab.books,
      'Quest' => InventoryTab.quest,
      _ => null,
    };

String inventoryTabLabelKey(InventoryTab tab) => 'inv_tab_${tab.name}';

/// How the rows are ordered.
enum InventorySort { newest, rarity, name }

int _rarityRank(String? rarity) => switch (rarity?.trim()) {
      'Relic' => 0,
      'Rare' => 1,
      'Uncommon' => 2,
      _ => 3,
    };

/// [ids] (each once) ordered by [sort]; [pack] is the bag in the order the
/// pieces came in, so the newest is the one last in it. Names are the
/// localized ones of [items].
List<String> sortInventoryIds(List<String> ids, Map<String, dynamic> items,
    InventorySort sort, List<String> pack) {
  String nameOf(String id) =>
      ((items[id] as Map<String, dynamic>?)?['itemName'] ?? id)
          .toString()
          .toLowerCase();
  final out = [...ids];
  switch (sort) {
    case InventorySort.newest:
      out.sort((a, b) {
        final c = pack.lastIndexOf(b).compareTo(pack.lastIndexOf(a));
        return c != 0 ? c : nameOf(a).compareTo(nameOf(b));
      });
    case InventorySort.rarity:
      out.sort((a, b) {
        final c = _rarityRank(
                (items[a] as Map<String, dynamic>?)?['rarity']?.toString())
            .compareTo(_rarityRank(
                (items[b] as Map<String, dynamic>?)?['rarity']?.toString()));
        return c != 0 ? c : nameOf(a).compareTo(nameOf(b));
      });
    case InventorySort.name:
      out.sort((a, b) => nameOf(a).compareTo(nameOf(b)));
  }
  return out;
}

/// The icon of an equipment slot, for its tile and for a row's line.
IconData inventorySlotIcon(String slot) => switch (slot) {
      'Head' => Icons.sports_motorsports_outlined,
      'Top' => Icons.checkroom_outlined,
      'Weapon' => Icons.gavel,
      'Bottom' => Icons.airline_seat_legroom_normal,
      'Foot' => Icons.hiking,
      _ => Icons.inventory_2_outlined,
    };

/// The slot's name for the player ("Body" for Top).
String inventorySlotName(AppLanguage lang, String slot) {
  final key = 'forge_slot_$slot';
  final name = trFor(lang, key);
  return name == key ? slot : name;
}

/// The item type's word for a quiet line.
String inventoryTypeName(AppLanguage lang, String? itemType) {
  final raw = itemType ?? '';
  if (raw.isEmpty) return '';
  final key = 'inv_type_${raw.toLowerCase()}';
  final name = trFor(lang, key);
  return name == key ? raw : name;
}

/// What the bag remembers between visits: the tab, the sort and the pieces
/// already seen (a piece not in the last list is new, with a gold dot).
class InventoryMemory {
  const InventoryMemory({this.tab, this.sort, this.seen});
  final InventoryTab? tab;
  final InventorySort? sort;

  /// The ids the bag held at the last visit; null on the first visit (then
  /// nothing is new).
  final Set<String>? seen;

  static Future<InventoryMemory> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tab = prefs.getString('inventory_tab');
      final sort = prefs.getString('inventory_sort');
      final seen = prefs.getStringList('inventory_seen');
      return InventoryMemory(
        tab: InventoryTab.values.where((t) => t.name == tab).firstOrNull,
        sort: InventorySort.values.where((s) => s.name == sort).firstOrNull,
        seen: seen?.toSet(),
      );
    } catch (_) {
      return const InventoryMemory();
    }
  }

  static Future<void> saveView(InventoryTab tab, InventorySort sort) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inventory_tab', tab.name);
      await prefs.setString('inventory_sort', sort.name);
    } catch (_) {}
  }

  static Future<void> saveSeen(Iterable<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('inventory_seen', ids.toSet().toList()..sort());
    } catch (_) {}
  }
}

/// The tabs: a chip for each kind the bag holds, with its count. On a narrow
/// phone the chips sit closer and the names are smaller, so more of them (the
/// Dice tab is the last) are on screen before the row scrolls.
class InventoryTabBar extends StatelessWidget {
  const InventoryTabBar({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelect,
    required this.language,
  });

  /// The tabs to show, each with its count, in order.
  final List<(InventoryTab, int)> counts;
  final InventoryTab selected;
  final ValueChanged<InventoryTab> onSelect;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final (tab, n) in counts)
            Padding(
              padding: EdgeInsets.only(right: narrow ? 4 : 6),
              child: Semantics(
                button: true,
                selected: tab == selected,
                child: InkWell(
                  key: Key('inv_tab_${tab.name}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelect(tab),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 8 : 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tab == selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: tab == selected
                              ? theme.colorScheme.primary
                              : ink.seam),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(trFor(language, inventoryTabLabelKey(tab)),
                          style: (narrow
                                  ? theme.textTheme.bodySmall
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(
                                  color: tab == selected
                                      ? theme.colorScheme.onSurface
                                      : ink.ash)),
                      const SizedBox(width: 5),
                      Text('$n',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: tab == selected
                                  ? theme.colorScheme.onSurface
                                  : ink.ash)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// The sort, quiet, at the end of the tabs' line: a tap goes to the next.
class InventorySortButton extends StatelessWidget {
  const InventorySortButton(
      {super.key,
      required this.sort,
      required this.onChanged,
      required this.language});

  final InventorySort sort;
  final ValueChanged<InventorySort> onChanged;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final next =
        InventorySort.values[(sort.index + 1) % InventorySort.values.length];
    return InkWell(
      key: const Key('inv_sort'),
      borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(next),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sort, size: 16, color: ink.ash),
          const SizedBox(width: 3),
          Text(trFor(language, 'inv_sort_${sort.name}'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: ink.ash)),
        ]),
      ),
    );
  }
}

/// A slot as a small tile: its own icon (faded when empty), under it the
/// name of what is worn there or the slot's name. [lit] marks the slot the
/// piece in view would go to.
class InventorySlotTile extends StatelessWidget {
  const InventorySlotTile({
    super.key,
    required this.slotLabel,
    required this.icon,
    this.worn,
    this.lit = false,
    this.onTap,
    this.onClear,
    this.clearTip = '',
    this.tip = '',
  });

  final String slotLabel;
  final Widget icon;
  final String? worn;
  final bool lit;
  final VoidCallback? onTap;

  /// Takes the piece off (a small cross on a filled tile).
  final VoidCallback? onClear;
  final String clearTip;
  final String tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final filled = worn != null;
    return Material(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: lit
                ? ink.gold
                : filled
                    ? ink.gold.withValues(alpha: 0.6)
                    : ink.seam,
            width: lit ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Tooltip(
          message: tip,
          child: Stack(children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(opacity: filled ? 1 : 0.5, child: icon),
                    const SizedBox(height: 4),
                    Text(worn ?? slotLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: filled ? null : ink.ash,
                            fontStyle: filled ? null : FontStyle.italic)),
                  ],
                ),
              ),
            ),
            if (onClear != null)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  tooltip: clearTip,
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                  onPressed: onClear,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// One row of the bag: the picture, the name, one quiet line, the numbers
/// against what is worn, and one labelled button.
class InventoryRow extends StatelessWidget {
  const InventoryRow({
    super.key,
    required this.itemId,
    required this.item,
    required this.language,
    required this.line,
    this.slot,
    this.worn,
    this.fresh = false,
    this.isWorn = false,
    this.count,
    this.actionLabel,
    this.onAction,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.locked = false,
  });

  final String itemId;
  final Map<String, dynamic>? item;
  final AppLanguage language;

  /// "Rare · goes on the Head": the one quiet line.
  final String line;

  /// The slot whose icon leads the line (gear only).
  final String? slot;

  /// The piece worn in this one's slot, for the change in the chips.
  final Map<String, dynamic>? worn;
  final bool fresh;
  final bool isWorn;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Picked as the first piece of a manual compare.
  final bool selected;

  /// The character can't wear it (a requirement, or someone else has it):
  /// the row is dimmed, with a padlock for a button.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final name = item?['itemName']?.toString() ?? itemId;
    final type = item?['itemType']?.toString();
    final gear = isGear(item);
    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        color: selected
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: selected
                  ? theme.colorScheme.tertiary
                  : isWorn
                      ? ink.gold
                      : ink.seam),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(children: [
              ItemPixelIcon(itemId, type, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontFamily: InkFonts.display)),
                      ),
                      if (count != null && count! > 1) ...[
                        const SizedBox(width: 6),
                        Text('×$count',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: ink.ash)),
                      ],
                      if (fresh) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: trFor(language, 'inv_new'),
                          child: Container(
                            key: Key('inv_new_$itemId'),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: ink.gold),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      if (slot != null && slot!.isNotEmpty) ...[
                        Icon(inventorySlotIcon(slot!),
                            size: 13, color: ink.ash),
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: ink.ash)),
                      ),
                    ]),
                    if (gear)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ItemStatChips(
                            item: item,
                            equipped: isWorn ? null : worn,
                            language: language,
                            compact: true,
                            maxChips: 3,
                            deltaVsEmpty: false),
                      ),
                  ],
                ),
              ),
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.lock_outline, color: ink.ash),
                )
              else if (actionLabel != null && onAction != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: isWorn
                      ? OutlinedButton(
                          key: Key('inv_action_$itemId'),
                          style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10)),
                          onPressed: onAction,
                          child: Text(actionLabel!))
                      : FilledButton(
                          key: Key('inv_action_$itemId'),
                          style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12)),
                          onPressed: onAction,
                          child: Text(actionLabel!)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The rarity word for a quiet line; '' for a Common (not worth a word).
String inventoryRarityWord(AppLanguage lang, Map<String, dynamic>? item) {
  final rarity = item?['rarity']?.toString() ?? '';
  if (rarity.isEmpty || rarity == 'Common') return '';
  return itemRarityLabelFor(lang, rarity);
}

/// A die as a tile in its own skin: the stone, the mark cut in it, its edge
/// and its glow; the shape's name on it.
class InventoryDieTile extends StatelessWidget {
  const InventoryDieTile(
      {super.key,
      required this.dieId,
      required this.faces,
      this.size = 44,
      this.lit = false});

  final String dieId;
  final int faces;
  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final skin = dieSkinOf(dieId);
    final dark = skin.base.computeLuminance() > 0.45;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: skin.base,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: skin.edge, width: lit ? 2.2 : 1.4),
        boxShadow: [
          if (skin.glow != null || lit)
            BoxShadow(
                color: (skin.glow ?? InkColors.of(context).gold)
                    .withValues(alpha: lit ? 0.55 : 0.35),
                blurRadius: lit ? 12 : 8),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
            child: CustomPaint(
                painter: DiePatternPainter(skin.pattern, skin.edge))),
        Text('d$faces',
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: size * 0.34,
                color: dark ? const Color(0xFF1B1710) : skin.edge,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// A die of the bag: in hand it is lit gold with a chevron; in the bag it
/// has one labelled button; one made for another class is dimmed with a
/// padlock and who it is for.
class InventoryDieRow extends StatelessWidget {
  const InventoryDieRow({
    super.key,
    required this.dieId,
    required this.name,
    required this.faces,
    required this.language,
    this.inHand = false,
    this.madeFor = '',
    this.locked = false,
    this.onOpen,
    this.onEquip,
    this.gift,
  });

  /// A clan die's gift line (ClanDieGift), under the die's details.
  final Widget? gift;

  final String dieId;
  final String name;
  final int faces;
  final AppLanguage language;
  final bool inHand;
  final String madeFor;
  final bool locked;

  /// Opens the dice screen on this die.
  final VoidCallback? onOpen;
  final VoidCallback? onEquip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final skin = dieSkinOf(dieId);
    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        color: inHand
            ? ink.gold.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: inHand ? ink.gold : ink.seam, width: inHand ? 1.6 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Row(children: [
              SizedBox(
                  width: 52,
                  child: Center(
                      child: InventoryDieTile(
                          dieId: dieId, faces: faces, lit: inHand))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontFamily: InkFonts.display)),
                    Text(
                        trFor(language, 'inv_die_line')
                            .replaceAll('{n}', '$faces')
                            .replaceAll('{material}', skin.material),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                    if (gift != null) gift!,
                    if (inHand)
                      Text(trFor(language, 'inv_in_hand'),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: ink.gold, fontStyle: FontStyle.italic))
                    else if (locked && madeFor.isNotEmpty)
                      Text(
                          trFor(language, 'inv_die_made_for')
                              .replaceAll('{who}', madeFor),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: ink.ash, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              if (inHand)
                Icon(Icons.chevron_right, color: ink.ash)
              else if (locked)
                Icon(Icons.lock_outline, color: ink.ash)
              else if (onEquip != null)
                FilledButton(
                  key: Key('inv_equip_die_$dieId'),
                  style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                  onPressed: onEquip,
                  child: Text(trFor(language, 'equip_button')),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

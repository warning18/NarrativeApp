// The gear card's one step (v2.10.46): after a loot card's gear is chosen, the
// piece worn in its slot beside the new one with what changes, and one
// question: replace it (or equip it, with nothing worn) or keep what you wear.
// Change, while the card is still on the table, goes back to the cards.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tower/tower_gear_choice.dart' show towerGearCompareOf;
import '../../data/tower/tower_hero.dart' show TowerData;
import '../../data/tower/tower_run.dart';
import '../../gamedata/db_schema.dart';
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/game_db_providers.dart';
import '../../theme/icon_sizes.dart';
import '../../theme/stitched_ink.dart' show InkFonts;
import '../../utils/pixel_icons/game_pixel_icons.dart';
import '../../widgets/item_stats.dart';
import 'ink/ink_kit.dart' show InkButton;
import 'ink/ink_palette.dart';

TextStyle _prose(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _display(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

class TowerGearReplace extends ConsumerWidget {
  const TowerGearReplace({
    super.key,
    required this.run,
    required this.data,
    required this.itemId,
    required this.onReplace,
    required this.onKeep,
    this.onChange,
  });

  final TowerRun run;
  final TowerData data;

  /// The new piece.
  final String itemId;

  /// Replace (or Equip, with nothing worn), and Keep mine (or Leave them).
  final VoidCallback onReplace;
  final VoidCallback onKeep;

  /// Back to the cards; null once the card has been taken (the piece waits
  /// on the run, TowerRun.pendingGear).
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    Map<String, dynamic>? row(String? id) =>
        id == null ? null : (items[id] as Map?)?.cast<String, dynamic>();
    final compare = towerGearCompareOf(run, data, itemId);
    final worn = row(compare.wornId);
    final fresh = row(itemId);
    final newName = '${fresh?['itemName'] ?? itemId}';
    final wornName = '${worn?['itemName'] ?? ''}';
    String sub(String key) => tr(ref, key)
        .replaceAll('{new}', newName)
        .replaceAll('{worn}', wornName);
    final empty = compare.wornId == null;

    Widget tile(String caption, String? id, Map<String, dynamic>? item,
        {Map<String, dynamic>? against}) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: inkBlack,
            border: Border.all(color: inkPaper, width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(caption.toUpperCase(),
              style: _prose(9.5, inkGrey, w: FontWeight.w800)),
          const SizedBox(height: 6),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: id == null ? inkSlate : inkGrey),
                borderRadius: BorderRadius.circular(6)),
            child: id == null
                ? Text('—', style: _display(20, inkGrey))
                : ItemPixelIcon(id, item?['itemType']?.toString(),
                    size: IconSize.s48),
          ),
          const SizedBox(height: 6),
          Text(
              id == null
                  ? tr(ref, 'tower_gear_empty_slot')
                  : newOrWorn(item, id),
              textAlign: TextAlign.center,
              style: _display(13, inkPaper)),
          if (item != null) ...[
            const SizedBox(height: 4),
            ItemStatChips(
                item: item,
                equipped: against,
                language: lang,
                compact: true,
                deltaVsEmpty: against != null || empty),
          ],
        ]),
      );
    }

    return SingleChildScrollView(
      key: const Key('tower_gear_replace'),
      // The bookmark tabs sit over the top right: the title starts under them.
      padding: const EdgeInsets.fromLTRB(8, 64, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(sub(empty ? 'tower_gear_equip_title' : 'tower_gear_replace_title'),
            style: _display(22, inkPaper)),
        const SizedBox(height: 6),
        Text(tr(ref, empty ? 'tower_gear_empty_line' : 'tower_gear_lost_line'),
            style: _prose(12.5, inkGrey)),
        const SizedBox(height: 14),
        IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: tile(tr(ref, 'tower_gear_worn'), compare.wornId, worn)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward,
                  color: inkPaper, size: IconSize.s16)),
          Expanded(
              child: tile(tr(ref, 'tower_gear_new'), itemId, fresh,
                  against: worn)),
        ])),
        const SizedBox(height: 18),
        InkButton(
            buttonKey: const Key('tower_gear_replace_yes'),
            label: tr(ref, empty ? 'tower_gear_equip' : 'tower_gear_replace'),
            onPressed: onReplace,
            primary: true,
            height: 48),
        const SizedBox(height: 8),
        InkButton(
            buttonKey: const Key('tower_gear_replace_keep'),
            label: tr(ref, empty ? 'tower_gear_leave' : 'tower_gear_keep'),
            onPressed: onKeep,
            height: 44),
        if (onChange != null)
          TextButton(
              key: const Key('tower_gear_replace_change'),
              onPressed: onChange,
              child: Text(tr(ref, 'tower_change'),
                  style: _prose(13, inkGrey, w: FontWeight.w700))),
      ]),
    );
  }

  String newOrWorn(Map<String, dynamic>? item, String id) =>
      '${item?['itemName'] ?? id}';
}

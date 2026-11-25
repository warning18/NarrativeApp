// The chapter's chest (v2.5.0, UX): given once, as the story enters the next
// chapter, right after its chapter card. A screen of its own, apart from the
// boss's chest: the goals met, the chest they earned (Wooden for none, Iron,
// Silver, Gold for all three), a line, and "Open the chest", which hands over
// to the usual spoils sheet. Core's rules: the claim adds the gold and the
// items and marks the chest given, so it never comes twice.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_goals.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../gamedata/db_schema.dart' show itemsSchema, professionsSchema;
import '../providers/combat_settings_provider.dart' show chestAutoOpenProvider;
import '../providers/game_db_providers.dart' show localizedDbProvider;
import '../providers/player_session_provider.dart';
import 'chapter_goals_card.dart';
import 'ink_panel.dart';
import 'spoils_chest_dialog.dart';

/// The chest [chapter]'s goals earned, if it is owed ([PlayerSession]'s
/// chapterChestDue): shows the screen, then the spoils sheet. Returns whether
/// a chest was given.
Future<bool> showChapterChest(
    BuildContext context, WidgetRef ref, int chapter) async {
  final lang = ref.read(appLanguageProvider);
  final met = (ref.read(playerSessionProvider).chapterGoalsMet['$chapter'] ??
          const <String>[])
      .length;
  final open = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ChapterChestDialog(chapter: chapter, met: met, lang: lang),
  );
  if (open != true || !context.mounted) return false;
  final items = ref.read(localizedDbProvider(itemsSchema)).value ?? const {};
  final notifier = ref.read(playerSessionProvider.notifier);
  final session = ref.read(playerSessionProvider);
  final professions =
      ref.read(localizedDbProvider(professionsSchema)).value ?? const {};
  final chest = await notifier.claimChapterChest(chapter,
      items: items,
      random: Random(),
      preferredScalingStat: (professions[session.professionId]
                  as Map<String, dynamic>?)?['preferredScalingStat']
              ?.toString() ??
          '');
  if (chest == null || !context.mounted) return false;
  final spoils = await showSpoilsChestDialog(
    context,
    result: chest,
    items: items,
    autoOpen: ref.read(chestAutoOpenProvider),
    language: lang,
    equippedItemIds: session.equippedItemIds,
  );
  for (final id in spoils.equipItemIds) {
    final item = items[id] as Map<String, dynamic>?;
    await notifier.equipItem(id,
        slot: item?['equipSlot']?.toString(), items: items);
  }
  return true;
}

class _ChapterChestDialog extends StatelessWidget {
  const _ChapterChestDialog(
      {required this.chapter, required this.met, required this.lang});

  final int chapter, met;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = chapterChestTier(met);
    return Dialog(
      key: const Key('chapter_chest_dialog'),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(trFor(lang, 'chapter_chest_title').replaceAll('{n}', '$chapter'),
              textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(chapterChestLine(lang, chapter),
              textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          _GoalsRecap(chapter: chapter, lang: lang),
          const SizedBox(height: 12),
          InkPanel(
            lit: true,
            child: Column(children: [
              Image.asset(chapterChestAsset(tier),
                  key: Key('chapter_chest_${tier.name}'),
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none),
              const SizedBox(height: 6),
              Text(chapterChestName(lang, met),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium),
              Text(trFor(lang, 'chapter_chest_met').replaceAll('{m}', '$met'),
                  style: theme.textTheme.bodySmall),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('chapter_chest_open'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(trFor(lang, 'chapter_chest_open')),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The goals of the chapter as ticks (the card, without its chests).
class _GoalsRecap extends ConsumerWidget {
  const _GoalsRecap({required this.chapter, required this.lang});

  final int chapter;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ChapterGoalsCard(chapter: chapter, showChests: false);
}

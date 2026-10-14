import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geography.dart';
import '../data/throne.dart' show midSentenceName;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/item_origin.dart';

/// An item's gold, for a Relic's tag: the same on every screen.
const Color relicColor = Color(0xFFC9A227);

/// [rarity] (items.json: Common, Uncommon, Rare, Relic) in [language];
/// the raw word for one the game does not name, '' for none.
String itemRarityLabelFor(AppLanguage language, String? rarity) {
  final raw = rarity?.trim() ?? '';
  if (raw.isEmpty) return '';
  final key = 'item_rarity_${raw.toLowerCase()}';
  final label = trFor(language, key);
  return label == key ? raw : label;
}

/// See [itemRarityLabelFor], in the app's language.
String itemRarityLabel(WidgetRef ref, String? rarity) =>
    itemRarityLabelFor(ref.watch(appLanguageProvider), rarity);

/// The colour of [rarity]'s tag on [scheme]: muted for a Common, the
/// scheme's primary for an Uncommon, its tertiary for a Rare, gold for a
/// Relic (v1.204).
Color itemRarityColor(ColorScheme scheme, String? rarity) =>
    switch (rarity?.trim()) {
      'Uncommon' => scheme.primary,
      'Rare' => scheme.tertiary,
      'Relic' => relicColor,
      _ => scheme.onSurfaceVariant,
    };

/// The line on where an item came from (v1.204, see item_origin.dart):
/// "Yours since the Lower Town, chapter 1", or "Yours since chapter 1"
/// when the place is unknown to [geography]; null for no [origin].
String? itemOriginLineFor(
    ItemOrigin? origin, Geography geography, AppLanguage language) {
  if (origin == null) return null;
  final place = geography.place(origin.placeId);
  final chapter = '${origin.chapter}';
  if (place == null) {
    return trFor(language, 'item_origin_chapter_line')
        .replaceAll('{n}', chapter);
  }
  // "the Lower Town" mid-sentence, not "The Lower Town".
  return trFor(language, 'item_origin_line')
      .replaceAll(
          '{place}', midSentenceName(place.nameFor(language == AppLanguage.fr)))
      .replaceAll('{n}', chapter);
}

/// An item's lore (`description`, with the French overlay already laid
/// over it by localizedDbProvider), '' for none.
String itemLoreOf(Map<String, dynamic>? item) =>
    item?['description']?.toString().trim() ?? '';

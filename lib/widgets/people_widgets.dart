import 'package:flutter/material.dart';

import '../data/factions.dart';
import '../data/geography.dart';
import '../l10n/app_locale.dart';
import '../theme/stitched_ink.dart' show InkTag;

/// The name of [factionId] (a factions.json or subclans.json id) in
/// [language], with its colour; null for '' or an id the data does not
/// know. A faction reads by its short name ("Compact"), a sub-clan by its
/// own.
({String name, Color color})? npcFactionTag(
    ClanData data, String factionId, AppLanguage language) {
  final id = factionId.trim();
  if (id.isEmpty) return null;
  final faction = data.faction(id);
  if (faction != null) {
    return (name: faction.shortFor(language), color: Color(faction.color));
  }
  final subclan = data.subclan(id);
  if (subclan != null) {
    return (name: subclan.nameFor(language), color: Color(subclan.color));
  }
  return null;
}

/// The name of [placeId] in [language] ('' for none or an unknown place).
String npcPlaceName(
        Geography geography, String placeId, AppLanguage language) =>
    geography.place(placeId)?.nameFor(language == AppLanguage.fr) ?? '';

/// A person's faction as a small coloured tag (see [npcFactionTag]);
/// nothing when they have none.
class NpcFactionTag extends StatelessWidget {
  const NpcFactionTag({
    super.key,
    required this.data,
    required this.factionId,
    required this.language,
  });

  final ClanData data;
  final String factionId;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final tag = npcFactionTag(data, factionId, language);
    if (tag == null) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkTag(
      label: tag.name,
      color: dark ? tag.color : Color.lerp(tag.color, Colors.black, 0.38)!,
    );
  }
}

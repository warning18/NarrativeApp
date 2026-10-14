import 'package:flutter/material.dart';

import '../data/factions.dart' show Faction, TitleDef;
import '../data/signs.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import 'pixel_banner.dart';

/// One title, read: the clan's banner beside the title's own badge in the
/// clan's colour and the clan that grants it, then what it does in a card
/// of its own, then the words it was given with, quiet.
class TitleDetailView extends StatelessWidget {
  const TitleDetailView({
    super.key,
    required this.title,
    required this.faction,
    required this.language,
    this.worn = false,
  });

  final TitleDef title;

  /// The clan that grants it, if any.
  final Faction? faction;
  final AppLanguage language;
  final bool worn;

  @override
  Widget build(BuildContext context) {
    String t(String key) => trFor(language, key);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final clanColor =
        faction == null ? ink.gold : Color(faction!.color | 0xFF000000);
    final accent = title.negative ? ink.blood : clanColor;
    final bannerId = faction == null ? null : clanBannerId(title.factionId);
    final effects = [
      for (final e in title.effects) signEffectText(e, language),
    ];
    final line = title.lineFor(language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (bannerId != null) ...[
              Container(
                key: const Key('title_banner'),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: accent, width: 3)),
                ),
                child: PixelBanner(id: bannerId, scale: 1),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    key: const Key('title_badge'),
                    padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent, width: 1.5),
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.30),
                          accent.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            title.negative
                                ? Icons.report_outlined
                                : Icons.workspace_premium,
                            size: 28,
                            color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(title.nameFor(language),
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontFamily: InkFonts.display)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                      faction == null
                          ? t('title_no_clan')
                          : t('title_granted_by'),
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                  if (faction != null)
                    Text(faction!.nameFor(language),
                        key: const Key('title_clan'),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: clanColor)),
                  if (worn) ...[
                    const SizedBox(height: 6),
                    InkTag(label: t('title_worn'), color: ink.gold),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (effects.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            key: const Key('title_effect'),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('title_effect_heading'),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                const SizedBox(height: 4),
                for (final text in effects)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.bolt, size: 18, color: accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(text,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (title.negative) ...[
          const SizedBox(height: 10),
          Text(t('title_bad_note'),
              style: theme.textTheme.bodyMedium?.copyWith(color: ink.blood)),
        ],
        if (line.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accent, width: 3)),
            ),
            child: Text(line,
                key: const Key('title_line'),
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: InkFonts.prose,
                    fontStyle: FontStyle.italic,
                    color: ink.ash,
                    height: 1.45)),
          ),
        ],
      ],
    );
  }
}

/// The sheet that reads [title]: see [TitleDetailView], then Close and,
/// for a title that can be chosen, Wear or Take off ([onToggle]).
Future<void> showTitleSheet(
  BuildContext context, {
  required TitleDef title,
  required Faction? faction,
  required AppLanguage language,
  required bool worn,
  VoidCallback? onToggle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: TitleDetailView(
                    title: title,
                    faction: faction,
                    language: language,
                    worn: worn),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(trFor(language, 'close_button')),
                  ),
                ),
                if (!title.negative && onToggle != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('title_toggle'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        onToggle();
                      },
                      child: Text(trFor(
                          language, worn ? 'title_take_off' : 'title_wear')),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

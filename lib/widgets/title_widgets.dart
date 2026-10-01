import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/signs.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';

/// The title worn, as it shows under the character's name ('' for none;
/// see offers.dart's titles).
String activeTitleName(WidgetRef ref) {
  final id = ref.watch(playerSessionProvider.select((s) => s.activeTitleId));
  if (id.isEmpty) return '';
  final title = ref.watch(clanDataProvider).titles[id];
  return title?.nameFor(ref.watch(appLanguageProvider)) ?? '';
}

/// The Character tab's titles: every one held, what it does, and which is
/// worn -- a tap wears one (or takes it off). A bad title ("the Marked")
/// can't be chosen or taken off: it counts while it is held.
class TitlesSection extends ConsumerWidget {
  const TitlesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final data = ref.watch(clanDataProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final held = [
      for (final id in session.heldTitleIds)
        if (data.titles[id] != null) data.titles[id]!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr(ref, 'titles_section'), style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        if (held.isEmpty)
          Text(tr(ref, 'titles_none'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        for (final title in held)
          Builder(builder: (context) {
            final worn = session.activeTitleId == title.id;
            final faction = data.faction(title.factionId);
            final effects = [
              for (final e in title.effects) signEffectText(e, lang),
            ];
            return InkWell(
              key: Key('title_${title.id}'),
              borderRadius: BorderRadius.circular(8),
              onTap: title.negative
                  ? null
                  : () => ref
                      .read(playerSessionProvider.notifier)
                      .setActiveTitle(worn ? '' : title.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      title.negative
                          ? Icons.report_outlined
                          : worn
                              ? Icons.workspace_premium
                              : Icons.workspace_premium_outlined,
                      color: title.negative
                          ? theme.colorScheme.error
                          : worn
                              ? Color(faction?.color ?? 0xFFB08D3C)
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(
                                text: title.nameFor(lang),
                                style: theme.textTheme.titleSmall),
                            if (faction != null)
                              TextSpan(
                                text: ' · ${faction.shortFor(lang)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                          ])),
                          for (final line in effects)
                            Text(line, style: theme.textTheme.bodySmall),
                          if (title.lineFor(lang).isNotEmpty)
                            Text(
                              title.lineFor(lang),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          if (title.negative)
                            Text(
                              tr(ref, 'title_bad_note'),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.colorScheme.error),
                            ),
                        ],
                      ),
                    ),
                    if (!title.negative)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          tr(ref, worn ? 'title_worn' : 'title_wear'),
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: worn
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

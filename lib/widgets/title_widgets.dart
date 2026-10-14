import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart' show TitleDef;
import '../data/signs.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import 'title_detail_view.dart';

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
  const TitlesSection({super.key, this.header = true});

  /// Whether the section writes its own "Titles" line (a fold's header
  /// takes its place on the Character tab, v1.201).
  final bool header;

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
        if (header) ...[
          Text(tr(ref, 'titles_section'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
        ],
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

/// The Character tab's titles as chips (v1.266): one per title held, the one
/// worn lit in gold. A tap wears one (or takes it off); a press and hold
/// reads it: what it does, its words, and why a bad one stays. A bad title
/// ("the Marked") counts while it is held and has no tap.
class TitleChips extends ConsumerWidget {
  const TitleChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final data = ref.watch(clanDataProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final held = [
      for (final id in session.heldTitleIds)
        if (data.titles[id] != null) data.titles[id]!,
    ];

    void read(TitleDef title) => showTitleSheet(
          context,
          title: title,
          faction: data.faction(title.factionId),
          language: lang,
          worn: session.activeTitleId == title.id,
          onToggle: () => ref
              .read(playerSessionProvider.notifier)
              .setActiveTitle(
                  session.activeTitleId == title.id ? '' : title.id),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(tr(ref, 'titles_section'), style: theme.textTheme.titleSmall),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                held.isEmpty
                    ? tr(ref, 'gifts_none_short')
                    : tr(ref, 'titles_chip_hint'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
              ),
            ),
          ],
        ),
        if (held.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final title in held)
                Builder(builder: (context) {
                  final worn = session.activeTitleId == title.id;
                  final color = title.negative
                      ? ink.blood
                      : worn
                          ? ink.gold
                          : theme.colorScheme.onSurface;
                  return Semantics(
                    button: true,
                    selected: worn,
                    child: InkWell(
                      key: Key('title_${title.id}'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: title.negative
                          ? null
                          : () => ref
                              .read(playerSessionProvider.notifier)
                              .setActiveTitle(worn ? '' : title.id),
                      onLongPress: () => read(title),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 32),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: worn
                              ? ink.gold.withValues(alpha: 0.14)
                              : Colors.transparent,
                          border: Border.all(
                              color: worn || title.negative
                                  ? color.withValues(alpha: 0.8)
                                  : ink.seam),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title.negative || worn) ...[
                              Icon(
                                  title.negative
                                      ? Icons.report_outlined
                                      : Icons.workspace_premium,
                                  size: 15,
                                  color: color),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(title.nameFor(lang),
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(color: color)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ],
    );
  }
}

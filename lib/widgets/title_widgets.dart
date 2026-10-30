import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart' show TitleDef;
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

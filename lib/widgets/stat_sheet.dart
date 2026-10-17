// A stat's popin (docs/proposals/stat-scale.md §7), opened by a tap on its
// name on the Character page's radar: the exact number, what a point of it
// does for this hero's calling, and where it comes from (Core's
// statBreakdown: the race, the calling, the picks, the patron clan, the
// gear, the signs, the titles...), then what a fight lends on top. A sheet
// like the skill sheet's.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stat_pick_text.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/signs_provider.dart';
import '../providers/stat_breakdown_provider.dart';
import '../providers/training_provider.dart';
import '../theme/stitched_ink.dart';
import 'ability_radar.dart' show abilityAbbrevKey;

/// Opens the sheet of [stat] (an ability: one of the radar's keys).
Future<void> showStatSheet(BuildContext context, String stat) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => StatSheet(stat: stat),
  );
}

/// The l10n key of a source's kind ("Race", "Picks", "Gear"...).
String statSourceKey(String kind) => 'stat_src_$kind';

/// A source row as the sheet shows it: the kind, what names it (the race,
/// the paths picked...), and its points.
typedef StatSourceLine = ({String kind, String detail, int amount});

/// The kept rows of [rows] (or the lent ones) grouped by kind, in the order
/// Core lists them: one line for each kind, its points added up, and, when it
/// has names to give, them (with their points when there are several).
List<StatSourceLine> groupStatSources(
  List<StatSource> rows, {
  required bool lent,
  required String? Function(String kind, String id) nameOf,
}) {
  final kinds = <String>[];
  for (final r in rows) {
    if (r.lent == lent && !kinds.contains(r.kind)) kinds.add(r.kind);
  }
  return [
    for (final kind in kinds)
      () {
        final mine = [
          for (final r in rows)
            if (r.lent == lent && r.kind == kind) r
        ];
        final names = [
          for (final r in mine)
            if (nameOf(kind, r.id) case final n? when n.isNotEmpty)
              (n, r.amount)
        ];
        final detail = names.isEmpty
            ? ''
            : names.length == 1
                ? names.single.$1
                : names
                    .map((e) => '${e.$1} ${e.$2 > 0 ? '+' : ''}${e.$2}')
                    .join(' · ');
        return (
          kind: kind,
          detail: detail,
          amount: mine.fold<int>(0, (a, r) => a + r.amount),
        );
      }(),
  ];
}

class StatSheet extends ConsumerWidget {
  const StatSheet({super.key, required this.stat});

  final String stat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final session = ref.watch(playerSessionProvider);
    final rows = ref.watch(statBreakdownProvider(stat));
    final paths = ref.watch(trainingPathsProvider).value ?? const {};
    final factions = ref.watch(factionsProvider);
    final patrons = ref.watch(patronsProvider);
    final signs = ref.watch(signDefsProvider);
    final clans = ref.watch(clanDataProvider);
    Map<String, dynamic> table(DbSchema schema) =>
        ref.watch(localizedDbProvider(schema)).value ?? const {};
    final races = table(racesSchema);
    final professions = table(professionsSchema);
    final items = table(itemsSchema);

    String? recordName(Map<String, dynamic> records, String id) =>
        (records[id] as Map?)?['name']?.toString();

    String? nameOf(String kind, String id) => switch (kind) {
          'race' => recordName(races, id),
          'profession' => recordName(professions, id),
          'pick' => paths[id]?.nameFor(lang == AppLanguage.fr),
          'tome' || 'gear' => recordName(items, id),
          'sign' => signs[id]?.nameFor(lang),
          'title' => clans.titles[id]?.nameFor(lang),
          'sworn' => factions[id]?.nameFor(lang),
          'patron' => id == 'open_hand'
              ? tr(ref, 'stat_src_open_hand')
              : (patrons[id]?.nameFor(lang) ?? factions[id]?.nameFor(lang)),
          _ => null,
        };

    final stored = rows.storedTotal;
    final fight = rows.fightTotal;
    final kept = groupStatSources(rows, lent: false, nameOf: nameOf);
    final lent = groupStatSources(rows, lent: true, nameOf: nameOf);
    final effects = [
      for (final e in statPickEffects(stat, session.professionId, 1))
        statEffectText(e, lang),
    ];

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(text.toUpperCase(),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: ink.gold, letterSpacing: 1.2)),
        );

    Widget line(StatSourceLine l, {Key? key}) {
      final plus = l.amount > 0;
      return Padding(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(ref, statSourceKey(l.kind)),
                      style: theme.textTheme.bodyMedium),
                  if (l.detail.isNotEmpty)
                    Text(l.detail,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${plus ? '+' : ''}${l.amount}',
                style: TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 16,
                    color: plus ? ink.heal : ink.blood)),
          ],
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          key: Key('stat_sheet_$stat'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('$stored',
                    key: const Key('stat_sheet_value'),
                    style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 34,
                        height: 1.1,
                        color: ink.gold)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(ref, '${stat}_label'),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontFamily: InkFonts.display)),
                      Text(tr(ref, abilityAbbrevKey(stat)),
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
            if (fight != stored)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  tr(ref, 'stat_sheet_in_fight').replaceAll('{n}', '$fight'),
                  key: const Key('stat_sheet_fight'),
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
                ),
              ),
            heading(tr(ref, 'stat_sheet_does')),
            Text(
              tr(ref, 'stat_sheet_per_point')
                  .replaceAll('{effects}', effects.join(', ')),
              key: const Key('stat_sheet_effects'),
              style: theme.textTheme.bodyMedium,
            ),
            heading(tr(ref, 'stat_sheet_from')),
            for (final l in kept) line(l, key: Key('stat_src_${l.kind}')),
            if (kept.length > 1) ...[
              const Divider(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(tr(ref, 'stat_sheet_total'),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Text('$stored',
                      style: TextStyle(
                          fontFamily: InkFonts.system,
                          fontSize: 16,
                          color: ink.gold)),
                ],
              ),
            ],
            if (lent.isNotEmpty) ...[
              heading(tr(ref, 'stat_sheet_lent')),
              for (final l in lent) line(l, key: Key('stat_lent_${l.kind}')),
            ],
          ],
        ),
      ),
    );
  }
}

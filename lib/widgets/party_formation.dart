// The Party tab as a formation (v1.606, the Companion review's version B): the
// seats as large portraits with health and the approval tier, an open seat
// (and the seat a house would add, locked), the bench as a small grid, and one
// plain line that other companions are still out there (no names, no count).
// A tap on any companion opens their page (companion_page.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../screens/companion_page.dart';
import '../theme/stitched_ink.dart';
import 'companion_parts.dart';

class PartyFormation extends ConsumerWidget {
  const PartyFormation({super.key, required this.houses});

  /// houses.json (localized): their party capacity bonuses.
  final Map<String, dynamic> houses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final views = ref.watch(companionViewsProvider);
    final built =
        ref.watch(playerSessionProvider.select((s) => s.builtHouseIds));
    final unmet = ref.watch(unmetCompanionCountProvider);
    if (views == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (views.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(tr(ref, 'no_companions_recruited')),
      );
    }
    final capacity = partyCapacityFor(built, houses);
    final seated = [
      for (final v in views)
        if (v.active) v
    ];
    final bench = [
      for (final v in views)
        if (!v.active) v
    ];
    // The houses that would add a seat, and have not yet: one locked seat
    // each, named by the house.
    final lockedHouses = [
      for (final h in houses.values.whereType<Map<String, dynamic>>())
        if (((h['partyCapacityBonus'] as num?)?.toInt() ?? 0) > 0 &&
            !built.contains(h['houseID']?.toString() ?? ''))
          (h['houseName'] ?? '').toString(),
    ];
    final open = (capacity - seated.length).clamp(0, capacity);

    void openPage(CompanionView v) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CompanionPage(companionId: v.id)));

    Widget seatCard(CompanionView v) => Expanded(
          child: GestureDetector(
            key: Key('party_seat_${v.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => openPage(v),
            child: Container(
              constraints: const BoxConstraints(minHeight: 156),
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
              decoration: BoxDecoration(
                color: ink.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ink.gold, width: 1.6),
              ),
              child: Column(children: [
                CompanionPortrait(v, size: 52),
                const SizedBox(height: 4),
                Text(v.name.split(' ').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                HealthBar(hp: v.hp, max: v.maxHp),
                const SizedBox(height: 4),
                TierChip(v.tier),
              ]),
            ),
          ),
        );

    Widget slot(IconData icon, String title, String line, Color colour,
            {Key? key}) =>
        Expanded(
          child: Container(
            key: key,
            constraints: const BoxConstraints(minHeight: 156),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colour.withValues(alpha: 0.5)),
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: colour),
              const SizedBox(height: 4),
              Text(title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(color: colour)),
              Text(line,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ]),
          ),
        );

    final cells = <Widget>[
      for (final v in seated) seatCard(v),
      for (var i = 0; i < open; i++)
        slot(
            Icons.add,
            tr(ref, 'party_open_seat'),
            tr(
                ref,
                bench.isEmpty
                    ? 'party_open_seat_empty'
                    : 'party_open_seat_bench'),
            ink.gold,
            key: Key('party_open_seat_$i')),
      for (final house in lockedHouses)
        slot(Icons.lock_outline, tr(ref, 'party_locked_seat'), house, ink.ash),
    ];

    Widget benchCard(CompanionView v) => GestureDetector(
          key: Key('party_bench_${v.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => openPage(v),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ink.seam),
            ),
            child: Row(children: [
              CompanionPortrait(v, size: 38),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.name.split(' ').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall),
                    TierChip(v.tier),
                  ],
                ),
              ),
            ]),
          ),
        );

    Widget title(String text, {String? trailing}) => Padding(
          padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
          child: Row(children: [
            Expanded(
              child: Text(text.toUpperCase(),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
            ),
            if (trailing != null)
              Text(trailing,
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            cells[i],
          ],
        ]),
      ),
      if (bench.isNotEmpty) ...[
        title(tr(ref, 'party_bench_title'),
            trailing: tr(ref, 'party_bench_hint')),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 8) / 2;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final v in bench) SizedBox(width: w, child: benchCard(v)),
          ]);
        }),
      ],
      if (unmet > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 16, 2, 4),
          child: Row(children: [
            Icon(Icons.explore_outlined, size: 16, color: ink.ash),
            const SizedBox(width: 6),
            Expanded(
              child: Text(tr(ref, 'party_still_out_there'),
                  key: const Key('party_still_out_there'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
            ),
          ]),
        ),
    ]);
  }
}

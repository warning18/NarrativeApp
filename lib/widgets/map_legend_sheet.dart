import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart' show ChartPalette;
import '../data/world_map.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/map_look_provider.dart';
import '../theme/stitched_ink.dart';
import 'chart_map_painter.dart' show ChartCalque;

/// What the marks on the Journey's chart mean, as the chart draws them:
/// one sheet so a new player does not guess. The calque showing adds its
/// own lines (shops and camps).
Future<void> showMapLegendSheet(
  BuildContext context,
  WidgetRef ref, {
  required ChartPalette palette,
  required Color Function(int chapter) chapterColor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => Consumer(builder: (context, ref, _) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final calque = ref.watch(chartCalqueProvider);
      Widget row(Widget mark, String key) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(width: 44, child: Center(child: mark)),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        Text(tr(ref, key), style: theme.textTheme.bodySmall)),
              ],
            ),
          );
      Widget dot(double size, Color colour, {bool ring = false}) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ring ? null : colour,
              border: ring ? Border.all(color: colour, width: 2) : null,
            ),
          );
      Widget line(Color colour, {bool dashed = false}) => SizedBox(
            width: 36,
            height: 4,
            child: dashed
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(width: 6, height: 3, color: colour),
                    ],
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                        color: colour, borderRadius: BorderRadius.circular(2))),
          );
      return SafeArea(
        child: SingleChildScrollView(
          key: const Key('map_legend_sheet'),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(ref, 'map_legend_title').toUpperCase(),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(letterSpacing: 1.4, color: ink.gold)),
              const SizedBox(height: 6),
              row(Icon(Icons.person_pin_circle, size: 22, color: palette.mark),
                  'map_leg_here'),
              row(dot(10, chapterColor(1)), 'map_leg_place'),
              row(dot(12, chapterColor(1), ring: true), 'map_leg_sea_place'),
              row(line(chapterColor(1)), 'map_leg_road'),
              row(line(chapterColor(1), dashed: true), 'map_leg_sea_road'),
              row(line(palette.ahead, dashed: true), 'map_leg_ahead'),
              row(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final n in const [1, 3, 5])
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: dot(8, chapterColor(n)),
                        ),
                    ],
                  ),
                  'map_leg_chapters'),
              row(
                  Container(
                    width: 22,
                    height: 16,
                    decoration: BoxDecoration(
                        color: palette.fog,
                        border: Border.all(color: palette.coast)),
                  ),
                  'map_leg_fog'),
              if (calque == ChartCalque.shops) ...[
                row(dot(10, const Color(0xFFF2C14E)), 'map_leg_shop'),
                row(
                    Icon(Icons.change_history,
                        size: 18, color: const Color(0xFF7DBE6A)),
                    'map_leg_camp'),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(sheet).pop(),
                  child: Text(tr(ref, 'close_button')),
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

/// What the journeys sheet asks for: the chart turned to [to], or the
/// whole road walked again ([replay]).
class MapJourneysPick {
  const MapJourneysPick.to(Landmark this.to) : replay = false;
  const MapJourneysPick.replay()
      : to = null,
        replay = true;

  final Landmark? to;
  final bool replay;
}

/// The roads walked, by chapter, latest first: [journey] is the places in
/// the order they were reached (see journeyOf). A tap on a stretch closes the
/// sheet and returns the place it ends at; "Replay all" walks the road again.
Future<MapJourneysPick?> showMapJourneysSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<Landmark> journey,
  required Color Function(int chapter) chapterColor,
}) {
  final language = ref.read(appLanguageProvider);
  return showModalBottomSheet<MapJourneysPick>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final legs = [
        for (var i = 0; i + 1 < journey.length; i++)
          (journey[i], journey[i + 1]),
      ];
      final chapters = {for (final l in legs) l.$2.chapter}.toList()
        ..sort((a, b) => b.compareTo(a));
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: ListView(
            key: const Key('map_journeys_sheet'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            shrinkWrap: true,
            children: [
              Text(tr(ref, 'map_journeys_title').toUpperCase(),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(letterSpacing: 1.4, color: ink.gold)),
              if (legs.isNotEmpty && !MediaQuery.of(context).disableAnimations)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('map_replay'),
                    onPressed: () =>
                        Navigator.of(sheet).pop(const MapJourneysPick.replay()),
                    icon: const Icon(Icons.directions_walk, size: 18),
                    label: Text(tr(ref, 'map_replay_all')),
                  ),
                ),
              if (legs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(tr(ref, 'map_journeys_empty'),
                      key: const Key('map_journeys_empty'),
                      style: theme.textTheme.bodySmall),
                ),
              for (final n in chapters) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Text(
                      '${tr(ref, 'world_map_chapter_short')} $n · '
                              '${mapChapter(n).title(language)}'
                          .toUpperCase(),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(letterSpacing: 1, color: chapterColor(n))),
                ),
                for (final leg in legs.reversed.where((l) => l.$2.chapter == n))
                  ListTile(
                    key: Key('map_journey_${leg.$1.id}_${leg.$2.id}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                        leg.$1.atSea || leg.$2.atSea
                            ? Icons.sailing_outlined
                            : Icons.directions_walk,
                        size: 20,
                        color: chapterColor(n)),
                    title: Text(
                        '${leg.$1.name(language)} → ${leg.$2.name(language)}',
                        style: theme.textTheme.bodySmall),
                    trailing: Text(
                        tr(
                            ref,
                            leg.$1.atSea || leg.$2.atSea
                                ? 'map_journey_sea'
                                : 'map_journey_foot'),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                    onTap: () =>
                        Navigator.of(sheet).pop(MapJourneysPick.to(leg.$2)),
                  ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(sheet).pop(),
                  child: Text(tr(ref, 'close_button')),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

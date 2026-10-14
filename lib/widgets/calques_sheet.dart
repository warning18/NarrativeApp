import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart' show MapShape, mapLookShapes;
import '../data/world_map.dart' show MapLook;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/map_look_provider.dart';
import '../theme/stitched_ink.dart';
import 'chart_map_painter.dart' show ChartCalque;

/// The calques sheet: the sphere and the weather, then one calque over the
/// chart at a time, or none. Shared by the Journey and the full map.
Future<void> showCalquesSheet(BuildContext context, WidgetRef ref) {
  final lang = ref.read(appLanguageProvider);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(builder: (context, ref, _) {
      final current = ref.watch(chartCalqueProvider);
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(trFor(lang, 'journey_calques').toUpperCase(),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(letterSpacing: 1.4, color: ink.gold)),
              ),
              // The map's look and the shape of its world (moved here from
              // the old map page).
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: SegmentedButton<MapLook>(
                  key: const Key('world_map_look'),
                  showSelectedIcon: false,
                  segments: [
                    for (final option in MapLook.values)
                      ButtonSegment(
                        value: option,
                        label: Text(
                            trFor(lang, 'world_map_look_${option.name}'),
                            key: Key('world_map_look_${option.name}')),
                      ),
                  ],
                  selected: {ref.watch(mapLookProvider)},
                  onSelectionChanged: (picked) =>
                      ref.read(mapLookProvider.notifier).choose(picked.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: SegmentedButton<MapShape>(
                  key: const Key('world_map_shape'),
                  showSelectedIcon: false,
                  segments: [
                    for (final option in mapLookShapes)
                      ButtonSegment(
                        value: option,
                        label: Text(
                            trFor(lang, 'world_map_shape_${option.name}'),
                            key: Key('world_map_shape_${option.name}')),
                      ),
                  ],
                  selected: {ref.watch(mapShapeProvider)},
                  onSelectionChanged: (picked) =>
                      ref.read(mapShapeProvider.notifier).choose(picked.first),
                ),
              ),
              SwitchListTile(
                key: const Key('journey_globe'),
                dense: true,
                value: ref.watch(chartGlobeProvider),
                secondary: const Icon(Icons.public),
                title: Text(trFor(lang, 'journey_globe')),
                subtitle: Text(trFor(lang, 'journey_globe_sub'),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                onChanged: (on) =>
                    ref.read(chartGlobeProvider.notifier).choose(on),
              ),
              SwitchListTile(
                key: const Key('journey_weather'),
                dense: true,
                value: ref.watch(chartWeatherProvider),
                secondary: const Icon(Icons.cloud_outlined),
                title: Text(trFor(lang, 'journey_weather')),
                subtitle: Text(trFor(lang, 'journey_weather_sub'),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                onChanged: (on) =>
                    ref.read(chartWeatherProvider.notifier).choose(on),
              ),
              if (ref.watch(chartWeatherProvider))
                SwitchListTile(
                  key: const Key('journey_weather_world_only'),
                  dense: true,
                  value: ref.watch(chartWeatherWorldOnlyProvider),
                  secondary: const Icon(Icons.public_outlined),
                  title: Text(trFor(lang, 'journey_weather_world_only')),
                  subtitle: Text(trFor(lang, 'journey_weather_world_only_sub'),
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                  onChanged: (on) => ref
                      .read(chartWeatherWorldOnlyProvider.notifier)
                      .choose(on),
                ),
              const Divider(height: 8),
              for (final calque in ChartCalque.values)
                SwitchListTile(
                  key: Key('calque_${calque.name}'),
                  dense: true,
                  value: current == calque,
                  secondary: Icon(switch (calque) {
                    ChartCalque.none => Icons.layers_clear_outlined,
                    ChartCalque.clans => Icons.balance,
                    ChartCalque.standing => Icons.person_outline,
                    ChartCalque.lands => Icons.map_outlined,
                    ChartCalque.chapters => Icons.route_outlined,
                    ChartCalque.shops => Icons.storefront_outlined,
                    ChartCalque.height => Icons.terrain,
                    ChartCalque.humidity => Icons.water_drop_outlined,
                    ChartCalque.warmth => Icons.thermostat,
                  }),
                  title: Text(trFor(lang, 'calque_${calque.name}')),
                  subtitle: Text(trFor(lang, 'calque_${calque.name}_sub'),
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                  onChanged: (on) => ref
                      .read(chartCalqueProvider.notifier)
                      .choose(on ? calque : ChartCalque.none),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(trFor(lang, 'journey_calques_hint'),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

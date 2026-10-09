// The sky over the party (v1.204): what falls, how warm it is, where the
// wind comes from and how high the ground stands, in a chip on the
// Journey map, read again every few seconds as the clouds move.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/climate.dart';
import '../combat/enemy_intent.dart' show elementLabel;
import '../data/map_charts.dart';
import '../data/weather_effects.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/climate_provider.dart';
import '../theme/stitched_ink.dart';

class WeatherChip extends ConsumerStatefulWidget {
  const WeatherChip({super.key, required this.palette});

  final ChartPalette palette;

  @override
  ConsumerState<WeatherChip> createState() => _WeatherChipState();
}

class _WeatherChipState extends ConsumerState<WeatherChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static IconData iconOf(WeatherKind kind) => switch (kind) {
        WeatherKind.clear => Icons.wb_sunny_outlined,
        WeatherKind.cloud => Icons.cloud_outlined,
        WeatherKind.fog => Icons.blur_on,
        WeatherKind.rain => Icons.water_drop_outlined,
        WeatherKind.snow => Icons.ac_unit,
        WeatherKind.dust => Icons.air,
        WeatherKind.ash => Icons.grain,
      };

  /// What the day's sky does to the play, as short tags: 'Fire −30%'.
  static String effects(WidgetRef ref, WeatherEffects effects) {
    final language = ref.watch(appLanguageProvider);
    return [
      for (final (element, pct) in effects.elementTags)
        '${elementLabel(element, language)} ${pct > 0 ? '+' : '−'}${pct.abs()}%',
    ].join(' · ');
  }

  /// One line: what falls, the warmth, the wind and the height.
  static String describe(WidgetRef ref, WeatherSample sky) {
    final wind = sky.windSpeed < 12
        ? tr(ref, 'weather_calm')
        : tr(ref, 'weather_wind_from')
            .replaceAll('{d}', tr(ref, 'compass_${sky.windFrom}'));
    return [
      tr(ref, 'weather_${sky.kind.name}'),
      '${sky.climate.temperature.round()}°',
      wind,
      if (!sky.climate.sea)
        tr(ref, 'weather_height').replaceAll('{m}', '${sky.climate.metres}'),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final here = ref.watch(skyHereProvider);
    if (here == null) return const SizedBox.shrink();
    final sky = here.now();
    final today = WeatherEffects.of(here.today().kind);
    final tags = effects(ref, today);
    final ink = InkColors.of(context);
    final palette = widget.palette;
    return Semantics(
      container: true,
      label: describe(ref, sky),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.fog.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: ink.gold.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconOf(sky.kind), size: 13, color: palette.place),
              const SizedBox(width: 5),
              Text(
                tags.isEmpty
                    ? describe(ref, sky)
                    : '${describe(ref, sky)} · $tags',
                key: const ValueKey('journey_weather_chip'),
                style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 11,
                  color: palette.place,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

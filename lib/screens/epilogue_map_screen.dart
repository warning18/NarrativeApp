// The realm, at the end (wave 18 step 2, item 4; docs/proposals/
// epilogue-map.md): who holds each town when the story is over, on the
// world chart the Journey's World view draws. Each town wears its holder's
// colour (the chart's own wash under a town), the clans' roads are drawn
// over it (a land route whose two ends one clan holds, in its colour; the
// other routes grey and dashed), and the seven big towns carry numbers. The
// words are in the list below the chart, not on it, where 16 holders' lines
// would collide at phone width: a chip for each clan with how many towns it
// holds, then a line for each big town (who holds it, how it was taken) and,
// when some of its districts are held by others, a tag that opens their
// list.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/town_rulers.dart';
import '../data/epilogue.dart';
import '../data/factions.dart';
import '../data/geography.dart';
import '../data/land_crossing.dart';
import '../data/map_charts.dart';
import '../data/world_map.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/landmark_towns_provider.dart';
import '../providers/map_look_provider.dart';
import '../providers/town_rulers_provider.dart';
import '../theme/stitched_ink.dart';
import '../widgets/chart_map_painter.dart';
import '../widgets/pixel_banner.dart';

class EpilogueMapScreen extends ConsumerWidget {
  const EpilogueMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(tr(ref, 'epilogue_map_button'))),
        body: const EpilogueMapBody(),
      );
}

/// A town of the chart: where it is, who holds it.
class _Spot {
  const _Spot(this.townId, this.at, this.fill, this.accent, this.clanId);

  final String townId;
  final Offset at;
  final Color fill;
  final Color accent;
  final String clanId;
}

/// A route of the land routes drawn over the chart.
class _Road {
  const _Road(this.from, this.to, this.clanId, this.color);

  final Offset from;
  final Offset to;

  /// The clan that holds both ends, '' for a route of several holders.
  final String clanId;
  final Color color;
}

class EpilogueMapBody extends ConsumerStatefulWidget {
  const EpilogueMapBody({super.key});

  @override
  ConsumerState<EpilogueMapBody> createState() => _EpilogueMapBodyState();
}

class _EpilogueMapBodyState extends ConsumerState<EpilogueMapBody> {
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  @override
  void dispose() {
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final language = ref.watch(appLanguageProvider);
    final geography = ref.watch(geographyProvider);
    final politics = ref.watch(politicsProvider);
    final data = ref.watch(clanDataProvider);
    final rulers = ref.watch(townRulersProvider);
    final chart = chartOf(ref.watch(mapShapeProvider));
    final palette = ChartPalette.of(ref.watch(mapLookProvider));
    final routes =
        ref.watch(localizedDbProvider(landRoutesSchema)).value ?? const {};

    final big = epilogueHoldings(politics, geography, towns: epilogueBigTowns);
    // Every town the chart can show: its landmark's place on the chart.
    final spots = <_Spot>[];
    for (final ruler in rulers.values) {
      if (ruler.isDistrict) continue;
      final at = _chartPoint(geography, chart, ruler.placeId);
      if (at == null) continue;
      spots.add(_Spot(ruler.placeId, at, Color(ruler.color),
          Color(ruler.accent), ruler.clanId));
    }
    final tints = {
      for (final e in ref.watch(landmarkRulersProvider).entries)
        e.key: (fill: Color(e.value.color), accent: Color(e.value.accent)),
    };
    final colours = {
      for (final e in data.factions.entries) e.key: Color(e.value.color),
    };
    final roads = <_Road>[];
    for (final e in routes.entries) {
      if (e.value is! Map) continue;
      final route = LandRoute.fromJson(e.key, e.value as Map);
      final from = chart.places[route.from];
      final to = chart.places[route.to];
      if (from == null || to == null) continue;
      final clan = clanRoadOf(route, geography, politics);
      roads.add(_Road(from, to, clan, colours[clan] ?? palette.coast));
    }
    // The clans and how many towns each holds.
    final held = <String, int>{};
    for (final s in spots) {
      if (s.clanId.isNotEmpty) held[s.clanId] = (held[s.clanId] ?? 0) + 1;
    }
    final holders = held.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      children: [
        Text(tr(ref, 'epilogue_map_subtitle'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        const SizedBox(height: 10),
        Semantics(
          label: tr(ref, 'epilogue_map_semantics'),
          child: _MapBox(
            key: const Key('epilogue_map'),
            frame: _frame,
            chart: chart,
            palette: palette,
            language: language,
            tints: tints,
            colours: colours,
            roads: roads,
            spots: spots,
            big: [
              for (final t in big)
                if (spots.any((s) => s.townId == t.townId))
                  (t.townId, spots.firstWhere((s) => s.townId == t.townId)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('epilogue_holders'),
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final h in holders)
              _HolderChip(
                clanId: h.key,
                name: data.faction(h.key)?.shortFor(language) ?? h.key,
                color: colours[h.key] ?? ink.ash,
                count: h.value,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(tr(ref, 'epilogue_map_big_towns').toUpperCase(),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        for (var i = 0; i < big.length; i++)
          _TownRow(
            number: i + 1,
            town: big[i],
            spot: spots.where((s) => s.townId == big[i].townId).firstOrNull,
            onDistricts: () => _showDistricts(
                context, big[i], geography, data, rulers, language, colours),
          ),
        const SizedBox(height: 6),
        Text(tr(ref, 'epilogue_map_legend'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
      ],
    );
  }

  /// [placeId]'s spot on the chart, by its first landmark.
  Offset? _chartPoint(Geography geography, ChartGeography chart, String id) {
    final place = geography.place(id);
    if (place == null) return null;
    for (final landmark in place.landmarks) {
      final at = chart.places[landmark];
      if (at != null) return at;
    }
    return null;
  }

  void _showDistricts(
    BuildContext context,
    EpilogueTown town,
    Geography geography,
    ClanData data,
    Map<String, TownRuler> rulers,
    AppLanguage language,
    Map<String, Color> colours,
  ) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final fr = language == AppLanguage.fr;
    final name = fr ? town.nameFr : town.name;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: ListView(
            key: const Key('epilogue_districts'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                  trFor(language, 'epilogue_districts_title')
                      .replaceAll('{town}', name),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontFamily: InkFonts.display)),
              const SizedBox(height: 8),
              for (final e in town.districts.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    if (e.value.isEmpty)
                      const SizedBox(width: 18)
                    else
                      ClanFlag(factionId: e.value, height: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(geography.place(e.key)?.nameFor(fr) ?? e.key,
                          style: theme.textTheme.bodyMedium),
                    ),
                    Text(
                      e.value.isEmpty
                          ? trFor(language, 'epilogue_map_none')
                          : e.value == town.clanId
                              ? trFor(language, 'epilogue_districts_with_town')
                              : data.faction(e.value)?.shortFor(language) ??
                                  e.value,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: e.value == town.clanId ? ink.ash : null,
                          fontWeight: e.value == town.clanId
                              ? FontWeight.w400
                              : FontWeight.w700),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The world chart (the real painter), cropped to where the towns are, with
/// the roads and the numbered big towns over it.
class _MapBox extends StatelessWidget {
  const _MapBox({
    super.key,
    required this.frame,
    required this.chart,
    required this.palette,
    required this.language,
    required this.tints,
    required this.colours,
    required this.roads,
    required this.spots,
    required this.big,
  });

  final ValueNotifier<int> frame;
  final ChartGeography chart;
  final ChartPalette palette;
  final AppLanguage language;
  final Map<String, ({Color fill, Color accent})> tints;
  final Map<String, Color> colours;
  final List<_Road> roads;
  final List<_Spot> spots;
  final List<(String, _Spot)> big;

  /// The part of the chart the towns and roads fill, padded.
  Rect get _view {
    var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
    void add(Offset o) {
      minX = math.min(minX, o.dx);
      minY = math.min(minY, o.dy);
      maxX = math.max(maxX, o.dx);
      maxY = math.max(maxY, o.dy);
    }

    for (final s in spots) {
      add(s.at);
    }
    for (final r in roads) {
      add(r.from);
      add(r.to);
    }
    if (minX > maxX) return const Rect.fromLTWH(0, 0, 256, 176);
    const pad = 14.0;
    return Rect.fromLTRB(
      math.max(0, minX - pad),
      math.max(0, minY - pad),
      math.min(worldMapWidth.toDouble(), maxX + pad),
      math.min(worldMapHeight.toDouble(), maxY + pad),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final k = w / view.width;
      final full = Size(worldMapWidth * k, worldMapHeight * k);
      final h = view.height * k;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: w,
          height: h,
          color: palette.sea,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: full.width,
            maxWidth: full.width,
            minHeight: full.height,
            maxHeight: full.height,
            child: Transform.translate(
              offset: Offset(-view.left * k, -view.top * k),
              child: SizedBox(
                width: full.width,
                height: full.height,
                child: Stack(fit: StackFit.expand, children: [
                  CustomPaint(
                    painter: ChartMapPainter(
                      frame: frame,
                      walk: const AlwaysStoppedAnimation<double>(0),
                      geography: chart,
                      palette: palette,
                      language: language,
                      discovered: const {},
                      legs: const [],
                      ahead: null,
                      selectedId: '',
                      here: null,
                      walking: false,
                      walkPath: const [],
                      chapterFilter: 0,
                      reduceMotion: true,
                      chapterColor: (_) => palette.road,
                      fog: ChartFog.none,
                      clanColours: colours,
                      townTints: tints,
                      zoomOf: () => k * 2,
                    ),
                  ),
                  CustomPaint(
                    painter: _OverPainter(
                        roads: roads,
                        big: [for (final b in big) b.$2],
                        all: spots,
                        k: k,
                        palette: palette),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// The clans' roads and the big towns' numbered discs, over the chart.
class _OverPainter extends CustomPainter {
  const _OverPainter({
    required this.roads,
    required this.big,
    required this.all,
    required this.k,
    required this.palette,
  });

  final List<_Road> roads;
  final List<_Spot> big;

  /// Every town: a small dot in its holder's colour (the big ones are
  /// numbered over it).
  final List<_Spot> all;
  final double k;
  final ChartPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in roads) {
      final from = r.from * k, to = r.to * k;
      if (r.clanId.isNotEmpty) {
        canvas.drawLine(
            from,
            to,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.6)
              ..strokeWidth = 5.5
              ..strokeCap = StrokeCap.round);
        canvas.drawLine(
            from,
            to,
            Paint()
              ..color = r.color
              ..strokeWidth = 3.2
              ..strokeCap = StrokeCap.round);
      } else {
        final length = (to - from).distance;
        final dir = (to - from) / math.max(length, 0.001);
        for (var d = 0.0; d < length; d += 7) {
          canvas.drawLine(
              from + dir * d,
              from + dir * math.min(d + 3.5, length),
              Paint()
                ..color = palette.coast.withValues(alpha: 0.85)
                ..strokeWidth = 1.5);
        }
      }
    }
    for (final s in all) {
      final c = s.at * k;
      canvas.drawCircle(
          c, 5.6, Paint()..color = Colors.black.withValues(alpha: 0.6));
      canvas.drawCircle(c, 4.2, Paint()..color = s.fill);
      canvas.drawCircle(
          c,
          4.2,
          Paint()
            ..color = s.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
    for (var i = 0; i < big.length; i++) {
      final c = big[i].at * k;
      canvas.drawCircle(
          c, 11.5, Paint()..color = Colors.black.withValues(alpha: 0.6));
      canvas.drawCircle(c, 9.5, Paint()..color = big[i].fill);
      canvas.drawCircle(
          c,
          9.5,
          Paint()
            ..color = big[i].accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      final tp = TextPainter(
        text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(
                fontFamily: InkFonts.system,
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 2, color: Colors.black87)])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_OverPainter old) =>
      old.roads != roads || old.big != big || old.all != all || old.k != k;
}

class _HolderChip extends StatelessWidget {
  const _HolderChip({
    required this.clanId,
    required this.name,
    required this.color,
    required this.count,
  });

  final String clanId;
  final String name;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        key: Key('epilogue_holder_$clanId'),
        padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ClanFlag(factionId: clanId, height: 14),
          const SizedBox(width: 4),
          Text('$name $count',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      );
}

/// One big town: its number, its name, who holds it and how, and a tag for
/// the districts held by others.
class _TownRow extends ConsumerWidget {
  const _TownRow({
    required this.number,
    required this.town,
    required this.spot,
    required this.onDistricts,
  });

  final int number;
  final EpilogueTown town;
  final _Spot? spot;
  final VoidCallback onDistricts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final language = ref.watch(appLanguageProvider);
    final data = ref.watch(clanDataProvider);
    final fr = language == AppLanguage.fr;
    final differing = [
      for (final e in town.districts.entries)
        if (e.value != town.clanId) e.key,
    ].length;
    final none = town.how == EpilogueHow.none;
    var line = epilogueLine(town, data, language);
    if (line.isEmpty && !none) {
      final clan = data.faction(town.clanId)?.shortFor(language) ?? '';
      line = '$clan · ${tr(ref, 'epilogue_how_${town.how.name}')}';
    }
    if (none) line = tr(ref, 'epilogue_map_none');
    final fill = spot?.fill ?? ink.ash;
    final accent = spot?.accent ?? ink.ash;
    return Container(
      key: Key('epilogue_town_${town.townId}'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink.seam),
      ),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: accent, width: 2),
          ),
          child: Text('$number',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black87)])),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(fr ? town.nameFr : town.name,
                      style: theme.textTheme.titleSmall),
                  if (differing > 0)
                    InkWell(
                      key: Key('epilogue_differ_${town.townId}'),
                      borderRadius: BorderRadius.circular(6),
                      onTap: onDistricts,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: ink.seam),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                              differing == 1
                                  ? tr(ref, 'epilogue_districts_differ_one')
                                  : tr(ref, 'epilogue_districts_differ_n')
                                      .replaceAll('{n}', '$differing'),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: ink.ash)),
                          Icon(Icons.chevron_right, size: 14, color: ink.ash),
                        ]),
                      ),
                    ),
                ]),
            const SizedBox(height: 2),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!none)
                Padding(
                  padding: const EdgeInsets.only(top: 1, right: 5),
                  child: ClanFlag(factionId: town.clanId, height: 14),
                ),
              Expanded(
                child: Text(line,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: none ? ink.ash : null)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

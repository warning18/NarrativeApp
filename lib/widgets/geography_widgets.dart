// The world's places on screen (v1.197, see geography.dart): the
// breadcrumb over the Journey map and the world map's panel, the "This
// land" sheet it opens, the codex's Lands, and the node editor's place.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geography.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/geography_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';

/// [text] with its first letter up, for a name that opens a line or heads
/// a section (« l’Ancien Continent » → « L’Ancien Continent »).
String capitalised(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// The icon of a location of [kind] (see geoKinds), or of a place at
/// [level] that has none.
IconData geoPlaceIcon(GeoPlace place) => switch (place.level) {
      GeoLevel.continent => Icons.public,
      GeoLevel.country => Icons.flag_outlined,
      GeoLevel.zone => Icons.landscape_outlined,
      GeoLevel.district => Icons.signpost_outlined,
      GeoLevel.building => Icons.door_front_door_outlined,
      GeoLevel.location => switch (place.kind) {
          'city' => Icons.location_city,
          'town' => Icons.holiday_village_outlined,
          'village' => Icons.cottage_outlined,
          'camp' => Icons.local_fire_department_outlined,
          'site' => Icons.account_balance_outlined,
          'wild' => Icons.forest_outlined,
          'sea' => Icons.sailing_outlined,
          _ => Icons.place_outlined,
        },
    };

/// A biome's icon, by its pattern.
IconData biomeIcon(Biome biome) => switch (biome.pattern) {
      BiomePattern.fields => Icons.agriculture,
      BiomePattern.dunes => Icons.wb_sunny_outlined,
      BiomePattern.saltFlats => Icons.grain,
      BiomePattern.waves => Icons.waves,
      BiomePattern.ash => Icons.cloud_outlined,
      BiomePattern.terraces => Icons.filter_hdr,
      BiomePattern.cliffs => Icons.landscape,
      BiomePattern.reeds => Icons.grass,
      BiomePattern.snow => Icons.ac_unit,
      BiomePattern.glass => Icons.blur_on,
    };

/// A hazard's icon, read from the words of its id and name (each word
/// by how it starts): a sandstorm blows, a ford floods, ash smokes, ice
/// freezes; anything else is a warning.
IconData hazardIcon(BiomeHazard hazard) {
  final words = '${hazard.id} ${hazard.name}'
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.isNotEmpty)
      .toList();
  bool has(List<String> starts) =>
      words.any((word) => starts.any(word.startsWith));
  for (final (starts, icon) in _hazardIcons) {
    if (has(starts)) return icon;
  }
  return Icons.warning_amber_rounded;
}

/// The words a hazard's icon is read from, first match first.
const List<(List<String>, IconData)> _hazardIcons = [
  (['glass', 'shard', 'tear', 'void', 'mirror'], Icons.blur_on),
  (
    ['ash', 'smoke', 'ember', 'fire', 'lava', 'erupt', 'steam', 'vent'],
    Icons.volcano
  ),
  (['scald', 'cinder', 'sulph'], Icons.volcano),
  (
    ['snow', 'blizzard', 'frost', 'ice', 'cold', 'rime', 'hail', 'whiteout'],
    Icons.ac_unit
  ),
  (['fog', 'mist', 'haze', 'murk'], Icons.foggy),
  (['light', 'wisp', 'lantern'], Icons.flare),
  (
    ['flood', 'ford', 'tide', 'river', 'bog', 'mire', 'sink', 'mud', 'quag'],
    Icons.flood
  ),
  (['swamp', 'marsh'], Icons.flood),
  (['sand', 'dust', 'wind'], Icons.air),
  (['storm', 'squall', 'thunder', 'lightning', 'gale'], Icons.thunderstorm),
  (['heat', 'sun', 'thirst', 'drought', 'glare'], Icons.wb_sunny_outlined),
  (
    ['rock', 'slide', 'fall', 'cliff', 'quake', 'scree', 'crumbl', 'crust'],
    Icons.landslide
  ),
  (['wave', 'sea', 'swell', 'current'], Icons.waves),
];

/// Where a place lies, widest first: one crumb per level of [path], each
/// tappable ([onTap], the "This land" sheet). One line that scrolls
/// sideways, opened on its most specific end, so a long French path fits
/// a narrow phone.
class GeoBreadcrumb extends StatelessWidget {
  const GeoBreadcrumb({
    super.key,
    required this.path,
    required this.french,
    required this.onTap,
    this.colour,
    this.strong,
    this.fontFamily,
    this.fontSize = 12.5,
    this.tooltip,
  });

  final List<GeoPlace> path;
  final bool french;
  final ValueChanged<GeoPlace> onTap;

  /// The crumbs' colour, and the last one's (the place itself).
  final Color? colour;
  final Color? strong;
  final String? fontFamily;
  final double fontSize;
  final String? tooltip;

  static const double height = 30;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final colour = this.colour ?? ink.ash;
    final strong = this.strong ?? Theme.of(context).colorScheme.onSurface;
    final style = TextStyle(
      fontFamily: fontFamily ?? InkFonts.prose,
      fontSize: fontSize,
      height: 1.1,
      color: colour,
    );
    final crumbs = <Widget>[
      if (path.isNotEmpty)
        InkWell(
          key: const ValueKey('geo_crumbs_icon'),
          onTap: () => onTap(path.last),
          child: Padding(
            // Clear of the faded edge.
            padding: const EdgeInsets.only(left: 10, right: 4),
            child: Icon(Icons.public, size: 15, color: colour),
          ),
        ),
      for (var i = 0; i < path.length; i++) ...[
        if (i > 0) Text('›', style: style),
        InkWell(
          key: ValueKey('geo_crumb_${path[i].id}'),
          borderRadius: BorderRadius.circular(4),
          onTap: () => onTap(path[i]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: Text(
              i == 0
                  ? capitalised(path[i].nameFor(french))
                  : path[i].nameFor(french),
              maxLines: 1,
              style: i == path.length - 1
                  ? style.copyWith(color: strong, fontWeight: FontWeight.w500)
                  : style,
            ),
          ),
        ),
      ],
    ];
    final row = SizedBox(
      height: height,
      // The left edge fades: the wider lands go on past it.
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [Color(0x00000000), Color(0xFF000000)],
          stops: [0, bounds.width <= 0 ? 0 : (14 / bounds.width).clamp(0, 1)],
        ).createShader(bounds),
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Opened on the place itself; the wider lands are a swipe
            // away. A short path still starts at the left.
            reverse: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: crumbs,
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: tooltip,
      child: row,
    );
  }
}

/// Opens the "This land" sheet (see [ThisLandSheet]) for [placeId].
Future<void> showThisLand(BuildContext context, String placeId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: ThisLandSheet(placeId: placeId),
    ),
  );
}

/// This land (« Cette contrée »): the zone [placeId] lies in and its biome
/// -- what lives and grows there, its weather and its hazards -- then the
/// country with its ruler and the continent. A location or district
/// tapped says its own piece first.
class ThisLandSheet extends ConsumerWidget {
  const ThisLandSheet({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geo = ref.watch(geographyProvider);
    final language = ref.watch(appLanguageProvider);
    final french = language == AppLanguage.fr;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final place = geo.place(placeId);
    if (place == null) return const SizedBox.shrink();
    final zone = geo.zoneOf(placeId);
    final biome = geo.biomeOf(placeId);
    final country = geo.countryOf(placeId);
    final continent = geo.continentOf(placeId);
    final clans = ref.watch(clanDataProvider);

    final caption = TextStyle(
      fontFamily: InkFonts.system,
      fontSize: 11,
      letterSpacing: 1.2,
      color: ink.gold,
    );
    final prose = theme.textTheme.bodyMedium
        ?.copyWith(fontFamily: InkFonts.prose, fontSize: 15, height: 1.4);
    final aside = prose?.copyWith(fontStyle: FontStyle.italic, color: ink.ash);
    final heading =
        theme.textTheme.titleLarge?.copyWith(fontFamily: InkFonts.display);
    final small = theme.textTheme.bodySmall?.copyWith(color: ink.ash);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(title.toUpperCase(), style: caption),
        );

    Widget lineRow(GeoLine line) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.nameFor(french),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (line.noteFor(french).isNotEmpty)
                Text(line.noteFor(french), style: small),
            ],
          ),
        );

    String rulerLine(GeoPlace country) {
      if (country.ruler.isEmpty) return tr(ref, 'geo_no_ruler');
      final name =
          clans.faction(country.ruler)?.nameFor(language) ?? country.ruler;
      return tr(ref, 'geo_ruler').replaceAll('{ruler}', name);
    }

    final focus = place.isSpot
        ? [
            for (final p in geo.pathOf(placeId))
              if (p.isSpot) p
          ]
        : const <GeoPlace>[];
    return SingleChildScrollView(
      key: const ValueKey('this_land_sheet'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The place tapped first, under the place it is a quarter of.
          for (final spot in focus) ...[
            Row(
              children: [
                Icon(geoPlaceIcon(spot), size: 16, color: ink.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(capitalised(spot.nameFor(french)),
                      style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            if (spot.blurbFor(french).isNotEmpty)
              Text(spot.blurbFor(french), style: prose),
            const SizedBox(height: 12),
          ],
          if (focus.isNotEmpty) const Divider(height: 12),
          Text(tr(ref, 'geo_this_land').toUpperCase(), style: caption),
          const SizedBox(height: 4),
          Text(
            capitalised((zone ?? place).nameFor(french)),
            style: heading,
          ),
          if (biome != null) ...[
            const SizedBox(height: 6),
            _BiomeChip(biome: biome, french: french),
          ],
          if (zone != null && zone.blurbFor(french).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(zone.blurbFor(french), style: prose),
          ],
          if (biome != null) ...[
            if (biome.blurbFor(french).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(biome.blurbFor(french), style: aside),
            ],
            if (biome.fauna.isNotEmpty) ...[
              section(tr(ref, 'geo_fauna')),
              for (final line in biome.fauna) lineRow(line),
            ],
            if (biome.flora.isNotEmpty) ...[
              section(tr(ref, 'geo_flora')),
              for (final line in biome.flora) lineRow(line),
            ],
            if (biome.weather.isNotEmpty) ...[
              section(tr(ref, 'geo_weather')),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final line in biome.weather)
                    InkTag(label: line.nameFor(french), color: ink.tide),
                ],
              ),
            ],
            if (biome.hazards.isNotEmpty) ...[
              section(tr(ref, 'geo_hazards')),
              for (final hazard in biome.hazards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(hazardIcon(hazard), size: 16, color: ink.ember),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(hazard.nameFor(french),
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ],
          if (country != null) ...[
            section(tr(ref, 'geo_level_country')),
            Text(capitalised(country.nameFor(french)),
                style: theme.textTheme.titleSmall),
            Text(rulerLine(country),
                key: const ValueKey('this_land_ruler'), style: small),
            if (country.blurbFor(french).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(country.blurbFor(french), style: prose),
            ],
          ],
          if (continent != null) ...[
            section(tr(ref, 'geo_level_continent')),
            Text(capitalised(continent.nameFor(french)),
                style: theme.textTheme.titleSmall),
            if (continent.blurbFor(french).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(continent.blurbFor(french), style: prose),
            ],
          ],
        ],
      ),
    );
  }
}

/// A biome's name on a small tag, with its pattern's icon.
class _BiomeChip extends StatelessWidget {
  const _BiomeChip({required this.biome, required this.french});

  final Biome biome;
  final bool french;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    return Container(
      key: ValueKey('biome_chip_${biome.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ink.heal.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(biomeIcon(biome), size: 14, color: ink.heal),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              biome.nameFor(french),
              style: TextStyle(
                  fontFamily: InkFonts.system, fontSize: 12, color: ink.heal),
            ),
          ),
        ],
      ),
    );
  }
}

/// The codex's Lands (« Contrées »): the continents reached, their
/// countries and zones, each zone with its biome (what lives and grows
/// there) and the places found in it. Nothing is named before it is
/// reached: a place not found yet is "…".
class LandsCodex extends ConsumerWidget {
  const LandsCodex({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geo = ref.watch(geographyProvider);
    final story = ref.watch(storyDataProvider).value;
    final play = ref.watch(storyPlayProvider);
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final found = story == null
        ? const <String>{}
        : geo.discoveredPlaces(
            {...play.visitedNodeIds, play.currentNodeId}, story);
    if (found.isEmpty) {
      return Text(tr(ref, 'geo_codex_empty'),
          key: const ValueKey('lands_codex_empty'),
          style: theme.textTheme.bodyMedium?.copyWith(color: ink.ash));
    }
    final continents = geo.continents;
    return Column(
      key: const ValueKey('lands_codex'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final continent in continents)
          if (found.contains(continent.id))
            _ContinentEntry(
                geo: geo, continent: continent, found: found, french: french),
        if (continents.any((c) => !found.contains(c.id))) const _Unknown(),
      ],
    );
  }
}

/// "…": a place not found yet.
class _Unknown extends ConsumerWidget {
  const _Unknown({this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
      child: Semantics(
        label: tr(ref, 'geo_unknown_place'),
        child: ExcludeSemantics(
          child: Text('…',
              key: const ValueKey('geo_unknown'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: InkColors.of(context).ash)),
        ),
      ),
    );
  }
}

class _ContinentEntry extends ConsumerWidget {
  const _ContinentEntry({
    required this.geo,
    required this.continent,
    required this.found,
    required this.french,
  });

  final Geography geo;
  final GeoPlace continent;
  final Set<String> found;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final language = ref.watch(appLanguageProvider);
    final clans = ref.watch(clanDataProvider);
    String rulerLine(GeoPlace country) {
      if (country.ruler.isEmpty) return tr(ref, 'geo_no_ruler');
      final name =
          clans.faction(country.ruler)?.nameFor(language) ?? country.ruler;
      return tr(ref, 'geo_ruler').replaceAll('{ruler}', name);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.public, size: 18, color: ink.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(capitalised(continent.nameFor(french)),
                    key: ValueKey('geo_codex_${continent.id}'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontFamily: InkFonts.display)),
              ),
            ],
          ),
          if (continent.blurbFor(french).isNotEmpty)
            Text(continent.blurbFor(french),
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          for (final country in geo.childrenOf(continent.id))
            if (found.contains(country.id))
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey('geo_codex_${country.id}'),
                  tilePadding: const EdgeInsets.only(left: 8),
                  childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  leading: Icon(Icons.flag_outlined, size: 18, color: ink.ash),
                  title: Text(capitalised(country.nameFor(french))),
                  subtitle: Text(rulerLine(country),
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
                  children: [
                    if (country.blurbFor(french).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(country.blurbFor(french),
                            style: theme.textTheme.bodySmall),
                      ),
                    for (final zone in geo.childrenOf(country.id))
                      if (found.contains(zone.id))
                        _ZoneCard(
                            geo: geo, zone: zone, found: found, french: french)
                      else
                        const _Unknown(indent: 8),
                  ],
                ),
              )
            else
              const _Unknown(indent: 8),
        ],
      ),
    );
  }
}

/// A zone in the codex: its biome, what lives and grows there (a tap on a
/// name says more), and the places found in it.
class _ZoneCard extends ConsumerWidget {
  const _ZoneCard({
    required this.geo,
    required this.zone,
    required this.found,
    required this.french,
  });

  final Geography geo;
  final GeoPlace zone;
  final Set<String> found;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final biome = geo.biomes[zone.biome];
    final small = theme.textTheme.bodySmall?.copyWith(color: ink.ash);
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(text.toUpperCase(),
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 10.5,
                  letterSpacing: 1.1,
                  color: ink.gold)),
        );
    Widget chips(List<GeoLine> lines) => Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final line in lines)
              Tooltip(
                message: line.noteFor(french),
                triggerMode: TooltipTriggerMode.tap,
                child: InkTag(label: line.nameFor(french), color: ink.heal),
              ),
          ],
        );

    return Card(
      key: ValueKey('geo_codex_${zone.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => showThisLand(context, zone.id),
              child: Row(
                children: [
                  Expanded(
                    child: Text(capitalised(zone.nameFor(french)),
                        style: theme.textTheme.titleSmall),
                  ),
                  if (biome != null) _BiomeChip(biome: biome, french: french),
                ],
              ),
            ),
            if (zone.blurbFor(french).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(zone.blurbFor(french), style: small),
            ],
            if (biome != null && biome.fauna.isNotEmpty) ...[
              label(tr(ref, 'geo_fauna')),
              chips(biome.fauna),
            ],
            if (biome != null && biome.flora.isNotEmpty) ...[
              label(tr(ref, 'geo_flora')),
              chips(biome.flora),
            ],
            label(tr(ref, 'geo_places_found')),
            for (final location in geo.childrenOf(zone.id))
              if (found.contains(location.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(geoPlaceIcon(location), size: 16, color: ink.ash),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: capitalised(location.nameFor(french)),
                                style: theme.textTheme.bodyMedium),
                            // Its quarters, found or not.
                            if (geo.childrenOf(location.id).isNotEmpty)
                              TextSpan(
                                text: ' · ${[
                                  for (final district
                                      in geo.childrenOf(location.id))
                                    found.contains(district.id)
                                        ? district.nameFor(french)
                                        : '…',
                                ].join(', ')}',
                                style: small,
                              ),
                          ]),
                          key: ValueKey('geo_codex_${location.id}'),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const _Unknown(),
          ],
        ),
      ),
    );
  }
}

/// The node editor's place (v1.197): a location or district id typed in,
/// or picked from the list; what it names said under it.
class GeoLocationField extends ConsumerStatefulWidget {
  const GeoLocationField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.unknown,
    required this.pick,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String unknown;
  final String pick;

  @override
  ConsumerState<GeoLocationField> createState() => _GeoLocationFieldState();
}

class _GeoLocationFieldState extends ConsumerState<GeoLocationField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final geo = ref.watch(geographyProvider);
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final id = widget.controller.text.trim();
    final place = geo.place(id);
    final path =
        geo.pathOf(id).map((p) => capitalised(p.nameFor(french))).join(' › ');
    final spots = geo.spots;
    return TextField(
      key: const ValueKey('node_location_field'),
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: id.isEmpty
            ? widget.hint
            : place != null && place.isSpot
                ? path
                : widget.unknown,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.place_outlined),
        border: const OutlineInputBorder(),
        suffixIcon: spots.isEmpty
            ? null
            : PopupMenuButton<String>(
                key: const ValueKey('node_location_pick'),
                tooltip: widget.pick,
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (value) => widget.controller.text = value,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: '', child: Text('—')),
                  for (final spot in spots)
                    PopupMenuItem(
                      value: spot.id,
                      child: Text(
                        '${spot.level == GeoLevel.district ? '   · ' : spot.level == GeoLevel.building ? '      · ' : ''}'
                        '${capitalised(spot.nameFor(french))}  (${spot.id})',
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// A city's district as board 15 draws it, and the town's plan as it was
// when left. Cut out of journey_screen.dart with no change.
part of '../journey_screen.dart';

/// The district of a city, as board 15 draws it (v1.355): the chart framed
/// on the district with a pin on the building of each way (numbered), and
/// under it the ways as rows; zoomed out, the whole town with its districts as rows. A pin
/// or a row opens the way's sheet.
class _CityDistrictView extends ConsumerWidget {
  const _CityDistrictView({
    required this.chart,
    required this.look,
    required this.partyWalk,
    required this.places,
    required this.placeMark,
    required this.onGoPlace,
    required this.onLeavePlace,
    required this.explored,
    required this.hereDistrict,
    required this.focus,
    required this.focusToken,
    required this.steps,
    required this.districtOf,
    required this.palette,
    required this.text,
    required this.onFocus,
    required this.onOpen,
    required this.onOpenPin,
    required this.onWalk,
    required this.overlays,
    required this.tabs,
    this.street,
  });

  final CityChart chart;

  /// Where the party's mark is while it walks to a way (null: at its own
  /// mark), see _walkCity.
  final ValueNotifier<Offset?> partyWalk;

  /// The district as places (v1.586): the map's camera and pin card, where
  /// the party's mark stands at the place it went to, and the way there and
  /// back.
  final DistrictPlacesController places;
  final Offset? placeMark;
  final void Function(PlaceInfo place) onGoPlace;
  final VoidCallback onLeavePlace;

  /// The building a scene is played outside of (v1.544): the district view
  /// is its street (see street_view.dart), not the town's plan.
  final GeoPlace? street;
  final MapLook look;
  final Set<String>? explored;
  final String? hereDistrict;

  /// The district in view; null the whole town.
  final String? focus;
  final int focusToken;
  final List<_Step> steps;

  /// The district each step's pin stands in (a step that leaves the city
  /// stands where the party does).
  final Map<int, String> districtOf;
  final ChartPalette palette;
  final CityChartText text;
  final void Function(String? districtId) onFocus;
  final void Function(int step) onOpen;

  /// A pin with several ways (v1.607): its sheet names them.
  final void Function(List<int> ways, String name) onOpenPin;
  final void Function(String districtId) onWalk;
  final List<Widget> overlays;
  final Widget tabs;

  /// The district's places for the steps [shown] (see placeInfosOf); null
  /// when the plan or the scene is not one to list places of, or a way
  /// would be left out of them.
  List<PlaceInfo>? _placeInfos(WidgetRef ref, List<int> shown) {
    final city = ref.watch(currentCityProvider);
    final record =
        city == null ? null : ref.watch(cityPlanRecordsProvider).value?[city];
    final nodeId = ref.watch(storyPlayProvider.select((p) => p.currentNodeId));
    final node = ref.watch(storyDataProvider).value?.nodeFor(nodeId);
    if (record == null || node == null) return null;
    final geography = ref.watch(geographyProvider);
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final infos = placeInfosOf(
      entries: ref.watch(districtPlacesProvider),
      nodeChoices: node.choices,
      stepChoices: [for (final s in steps) s.choice],
      stepLocked: [for (final s in steps) s.locked],
      stepLabels: [for (final s in steps) s.label],
      shown: shown,
      nameOf: (place) => place.isHere
          ? tr(ref, 'place_here')
          : wayPlaceName(
              place,
              record: record,
              geography: geography,
              french: french,
              fallback: '',
            ),
    );
    // A scene with one place at most has no places to list: its ways are the
    // list, as before.
    return infos == null || infos.length < 2 ? null : infos;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // The rows sit on the page, not on the chart: the page's own colours.
    final ink = InkColors.of(context);
    final pagePalette = ChartPalette.of(
      theme.brightness == Brightness.dark ? MapLook.night : MapLook.parchment,
    );
    // Each way's number: its place among its district's ways.
    // A way hangs as a banner in its category's colour (see
    // journey_banner_pin.dart); only the fights and rolls keep a numbered
    // round pin, and their row its number.
    final chartInk =
        look == MapLook.parchment ? InkColors.light : InkColors.dark;
    final chartDark = journeyInkIsDark(chartInk);
    final chartPalette = ChartPalette.of(look);
    final banners = <String, PinBanner>{};
    final numbers = <String, int>{};
    final byDistrict = <String, List<int>>{};
    for (var i = 0; i < steps.length; i++) {
      final d = districtOf[i];
      if (d == null) continue;
      final list = byDistrict.putIfAbsent(d, () => []);
      list.add(i);
      final cat = journeyPinCatOf(steps[i].kind, steps[i].questTie);
      if (cat == null) {
        numbers['$i'] = list.length;
      } else {
        banners['$i'] = PinBanner(
          cat,
          steps[i].locked
              ? chartPalette.label
              : look == MapLook.shroud && cat != JourneyPinCat.main
                  ? chartPalette.place
                  : cat.colorOn(chartInk, dark: chartDark),
        );
      }
    }
    final shown = focus == null ? const <int>[] : byDistrict[focus] ?? const [];
    // In the party's own district the ways are taken at places (v1.586,
    // way_places.dart): a list of places, pins without words and a card.
    // (Not in a building's street: its own view, see street_view.dart.)
    final inStreet = street != null &&
        focus != null &&
        focus == hereDistrict &&
        street!.parent == hereDistrict;
    final infos = focus != null && focus == hereDistrict && !inStreet
        ? _placeInfos(ref, shown)
        : null;
    final standingId = infos == null ? null : ref.watch(partyPlaceProvider);
    final standing = standingId == null
        ? null
        : infos?.where((p) => p.id == standingId).firstOrNull;
    // Go to a place of the list: a way out with one way to take is taken at
    // once, any other place is walked to.
    void goPlace(PlaceInfo p) {
      final open = [
        for (final i in p.steps)
          if (!steps[i].locked) i,
      ];
      if (p.wayOut && open.length == 1) {
        onOpen(open.first);
      } else {
        onGoPlace(p);
      }
    }

    // The town's own signs (wave 14): a notice board, the market, a tavern...
    final townServices = ref.watch(currentTownServicesProvider);
    final boardContracts = ref.watch(
      playerSessionProvider.select((s) => s.contracts),
    );

    Widget kindDisc(_Step s, {double size = 30}) {
      final colour = s.locked
          ? ink.ash
          : _colorFor(s.kind, ink, pagePalette, greyed: false);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colour.withValues(alpha: 0.16),
          border: Border.all(color: colour, width: 1.5),
        ),
        child: Icon(_iconFor(s.kind), size: size * 0.55, color: colour),
      );
    }

    Widget numberDot(int n) => Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: ink.gold),
          child: Text(
            '$n',
            style: const TextStyle(
              fontFamily: InkFonts.system,
              fontSize: 11,
              height: 1,
              color: Palette.night9,
            ),
          ),
        );

    // A way's pin in the street (v1.544): its banner, else its kind's disc.
    Widget streetPinOf(int i) {
      final banner = banners['$i'];
      return banner == null
          ? kindDisc(steps[i], size: 28)
          : BannerPin(
              cat: banner.cat,
              color: banner.color,
              dark: chartDark,
              icon: steps[i].locked ? Icons.lock_outline : null,
              scale: 0.8,
            );
    }

    // Who rules the town and its districts (wave 15, townRulersProvider): the
    // blocks take the clan's colour, and a line under the plan names it, so two
    // clans of near colours are told apart by the words as well.
    final townRulers = ref.watch(townRulersProvider);
    final factions = ref.watch(factionsProvider);
    final language = ref.watch(appLanguageProvider);
    final rulers = cityChartRulersOf(chart, townRulers);
    // Wave 18: the districts a side quest keeps shut, and who holds the rest
    // and how firmly (district_standing.dart).
    final session18 = ref.watch(playerSessionProvider);
    final standings = districtStandingsOf(
      districtIds: [for (final d in chart.districts) d.id],
      cityId: ref.watch(currentCityProvider),
      geography: ref.watch(geographyProvider),
      politics: session18.politics,
      flags: session18.flags,
      completedQuestIds: session18.completedQuestIds,
      data: ref.watch(clanDataProvider),
      rulers: townRulers,
      language: language,
    );
    final shutDistricts = {
      for (final e in standings.entries)
        if (e.value.locked) e.key,
    };
    final holds = {
      for (final e in standings.entries)
        if (e.value.crest case final crest?) e.key: crest,
    };
    // A shut district is explained, not entered.
    void focusOrExplain(String? id) {
      if (id != null && shutDistricts.contains(id)) {
        showLockedDistrictSheet(
          context,
          standings[id]!,
          name: chart.districts.firstWhere((d) => d.id == id).name,
        );
        return;
      }
      onFocus(id);
    }

    final lookedAt = focus == null
        ? townRulers[chart.districts
                .map((d) => townRulers[d.id]?.cityId)
                .whereType<String>()
                .firstOrNull ??
            '']
        : townRulers[focus];
    final rows = <Widget>[];
    // The name of the place a way hangs at: its building, else the place
    // it leads to (a way out), else the district. A way at a spot in the
    // street before the scene's door (way.at, a doorstep scene) is named by
    // its own words, as its pin is: every such way stands at the same
    // building, so the building's name would read the same on each row.
    String pinName(int lead) {
      final way = chart.ways.where((w) => w.id == '$lead').firstOrNull;
      if (way?.at != null && steps[lead].label.isNotEmpty) {
        return steps[lead].label;
      }
      final building = way == null ? '' : chart.buildingOf(way)?.name ?? '';
      if (building.isNotEmpty) return building;
      final leads = steps[lead].leadsTo ?? '';
      if (leads.isNotEmpty) return leads;
      final district = way == null || way.district >= chart.districts.length
          ? null
          : chart.districts[way.district].name;
      return district == null || district.isEmpty ? chart.name : district;
    }

    // The ways grouped by the pin they hang at (the list's destinations).
    var groups = const <WayPinGroup>[];
    if (lookedAt != null) {
      final clan = lookedAt.isNeutral
          ? null
          : factions[lookedAt.clanId]?.shortFor(language);
      rows.add(
        Padding(
          key: const ValueKey('journey_city_ruler'),
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(lookedAt.color),
                  border: Border.all(color: Color(lookedAt.accent), width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    clan == null
                        ? tr(ref, 'town_ruled_none')
                        : tr(ref, 'town_ruled_by').replaceAll('{clan}', clan),
                    if (lookedAt.mixed && focus == null)
                      tr(ref, 'town_ruled_mixed'),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (focus != null) {
      // The ways hang at pins on the map (a building, or a spot): a pin with
      // several ways is one closed row with a count (way_pin_groups.dart).
      groups = groupWaysByPin([
        for (final i in shown)
          WayPinEntry(
              i,
              switch (chart.ways.where((w) => w.id == '$i').firstOrNull) {
                final way? when way.at != null =>
                  'at:${way.at!.dx.round()},${way.at!.dy.round()}',
                final way? => 'b:${way.building}',
                null => 'step:$i',
              },
              leads: banners['$i'] != null),
      ]);
      if (infos == null && groups.isNotEmpty) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              tr(ref, 'journey_city_places_here').toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: ink.ash,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
      }

      // One way's row (inside a place's list), indented when [indent].
      Widget wayRow(int i, {double indent = 0}) {
        final s = steps[i];
        final way = chart.ways.where((w) => w.id == '$i').firstOrNull;
        final building = way == null ? '' : chart.buildingOf(way)?.name ?? '';
        final target = building == s.label ? '' : building;
        return InkWell(
          key: ValueKey('journey_city_row_$i'),
          onTap: () => onOpen(i),
          child: Container(
            padding: EdgeInsets.fromLTRB(indent, 7, 0, 7),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: ink.seam)),
            ),
            child: Row(
              children: [
                if (banners['$i'] case final banner?)
                  BannerPin(
                    key: ValueKey('journey_row_banner_$i'),
                    cat: banner.cat,
                    color: s.locked
                        ? banner.color
                        : banner.cat.colorOn(
                            ink,
                            dark: theme.brightness == Brightness.dark,
                          ),
                    dark: theme.brightness == Brightness.dark,
                    icon: s.locked ? Icons.lock_outline : null,
                    scale: 0.8,
                  )
                else ...[
                  numberDot(numbers['$i']!),
                  const SizedBox(width: 8),
                  kindDisc(s),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: s.locked ? ink.ash : null,
                      height: 1.2,
                    ),
                  ),
                ),
                if (s.tag case final tag?) ...[
                  const SizedBox(width: 8),
                  ChoiceTagChip(
                    key: ValueKey('journey_row_tag_$i'),
                    tag: tag,
                    locked: s.locked,
                  ),
                ],
                if (target.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: Text(
                        target,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ink.ash,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      // A pin's mark: its way's banner, else its kind's disc.
      Widget pinLead(int i) {
        final banner = banners['$i'];
        if (banner == null) return kindDisc(steps[i]);
        return BannerPin(
          key: ValueKey('journey_row_banner_$i'),
          cat: banner.cat,
          color: steps[i].locked
              ? banner.color
              : banner.cat.colorOn(
                  ink,
                  dark: theme.brightness == Brightness.dark,
                ),
          dark: theme.brightness == Brightness.dark,
          icon: steps[i].locked ? Icons.lock_outline : null,
          scale: 0.8,
        );
      }

      if (infos != null) {
        rows.addAll(
          placesRows(
            context,
            ref,
            infos: infos,
            standing: standing,
            wayRow: wayRow,
            onGo: goPlace,
            onLeave: onLeavePlace,
          ),
        );
      } else {
        // The list names the places, one row each (no count, nothing to
        // open in place); the ways show after a tap, as after a tap on the
        // pin (v1.607).
        for (final g in groups) {
          final name = pinName(g.lead);
          final allShut = g.members.every((i) => steps[i].locked);
          rows.add(
            InkWell(
              key: ValueKey(
                g.isPin
                    ? 'journey_city_pin_${g.lead}'
                    : 'journey_city_row_${g.lead}',
              ),
              onTap: () =>
                  g.isPin ? onOpenPin(g.members, name) : onOpen(g.lead),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ink.seam)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 30, child: Center(child: pinLead(g.lead))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: allShut ? ink.ash : null,
                          height: 1.2,
                        ),
                      ),
                    ),
                    // A place with one way wears that way's tag (v1.854).
                    if (g.members.length == 1 && steps[g.lead].tag != null) ...[
                      const SizedBox(width: 8),
                      ChoiceTagChip(
                        key: ValueKey('journey_row_tag_${g.lead}'),
                        tag: steps[g.lead].tag!,
                        locked: allShut,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
      }
      // No way in the party's own district: a free walk (no time, no
      // story) to each district it borders.
      if (shown.isEmpty && focus == hereDistrict) {
        for (final id in ref.watch(partyDistrictNeighboursProvider)) {
          final d = chart.districts.where((d) => d.id == id).firstOrNull;
          if (d == null) continue;
          rows.add(
            InkWell(
              key: ValueKey('journey_city_walk_$id'),
              onTap: () => onWalk(id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ink.seam)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: IconSize.s16,
                      color: d.colour,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr(
                          ref,
                          'journey_city_walk_to',
                        ).replaceAll('{district}', townNameInSentence(d.name)),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    } else {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            tr(ref, 'journey_city_districts').toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: ink.ash,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
      for (final d in chart.districts) {
        final standing = standings[d.id]!;
        // A shut district is named (a rumour), never "?".
        final known =
            standing.locked || explored == null || explored!.contains(d.id);
        final n = byDistrict[d.id]?.length ?? 0;
        rows.add(
          InkWell(
            key: ValueKey('journey_city_district_${d.id}'),
            // A district not yet found is walked into (and so found), not
            // looked at under its fog; a shut one is explained.
            onTap: () => standing.locked
                ? focusOrExplain(d.id)
                : known
                    ? onFocus(d.id)
                    : onWalk(d.id),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ink.seam)),
              ),
              child: Row(
                children: [
                  DistrictLead(
                    standing,
                    plain: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: known ? d.colour : Colors.transparent,
                        border: Border.all(color: d.colour),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          known ? d.name : '?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: known ? null : ink.ash,
                          ),
                        ),
                        DistrictStandingLine(standing),
                      ],
                    ),
                  ),
                  Text(
                    d.id == hereDistrict
                        ? text.here
                        : standing.locked
                            ? ''
                            : !known
                                ? text.unexplored
                                : (n == 0 ? '' : text.ways(n)),
                    style: theme.textTheme.labelSmall?.copyWith(color: ink.ash),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // With places, the map has the room alone until it is fully zoomed (the
    // handle, or a pinch): then the list rises under it (v1.586).
    Widget layout(bool full) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Walked off to another district, the street is left.
                    if (inStreet)
                      StreetViewScene(
                        kind: street!.kind,
                        name: street!.name,
                        phase: ref.watch(dayPhaseProvider),
                        sky: ref.watch(skyHereProvider)?.today().kind,
                        pins: [
                          for (final i in shown)
                            StreetPin(
                              index: i,
                              label: steps[i].label,
                              locked: steps[i].locked,
                              tag: steps[i].tag == null
                                  ? null
                                  : ChoiceTagChip(
                                      key: ValueKey('journey_pin_tag_$i'),
                                      tag: steps[i].tag!,
                                      locked: steps[i].locked,
                                    ),
                              child: streetPinOf(i),
                            ),
                        ],
                        onPick: onOpen,
                      )
                    else
                      // Its own layer (Maps' perf review): a drag of the
                      // plan repaints the plan, not the Journey around it.
                      RepaintBoundary(
                        child: ValueListenableBuilder<Offset?>(
                          valueListenable: partyWalk,
                          builder: (context, walkAt, _) => CityChartView(
                            key: const ValueKey('journey_city_chart'),
                            camera: places.camera,
                            buildingNames: infos == null,
                            partyAt:
                                walkAt ?? (standing == null ? null : placeMark),
                            chart: chart,
                            look: look,
                            text: text,
                            explored: explored,
                            hereDistrict: hereDistrict,
                            focus: focus,
                            focusToken: focusToken,
                            controls: false,
                            cards: false,
                            numbers: numbers,
                            banners: banners,
                            bannersDark: chartDark,
                            onFocus: focusOrExplain,
                            locked: shutDistricts,
                            holds: holds,
                            onPick: (w) {
                              final i = int.tryParse(w.id);
                              if (i == null || i >= steps.length) return;
                              // With places, a pin shows its place's card (a
                              // second tap folds it); Go takes the party there.
                              final place = infos?.where(
                                (p) => p.steps.contains(i),
                              );
                              if (place == null || place.isEmpty) {
                                final group = groups
                                    .where((g) => g.members.contains(i))
                                    .firstOrNull;
                                if (group != null && group.isPin) {
                                  onOpenPin(group.members, pinName(group.lead));
                                } else {
                                  onOpen(i);
                                }
                              } else {
                                final id = place.first.id;
                                places.card.value =
                                    places.card.value == id ? null : id;
                              }
                            },
                            onPickFog: (_) {},
                            rulers: rulers,
                            phase: ref.watch(dayPhaseProvider),
                            services: [
                              for (final s in townServices)
                                CityChartService(
                                  id: s.id,
                                  kind: s.kind,
                                  at: s.pin.at,
                                  district: s.pin.district,
                                  opens: s.opensSomething,
                                  // The notice board says what waits on it.
                                  badge: s.kind == 'notice_board'
                                      ? boardContracts.length
                                      : 0,
                                  urgent: boardContracts.any((c) => c.done),
                                ),
                            ],
                            onService: (picked) => showTownServiceSheet(
                              context,
                              townServices.firstWhere((s) => s.id == picked.id),
                            ),
                          ),
                        ),
                      ),
                    ...overlays,
                    if (infos != null && hereDistrict != null)
                      PlacesMapLayer(
                        controller: places,
                        infos: infos,
                        districtId: hereDistrict!,
                        partyAt: standing == null ? chart.here : placeMark,
                        showHandle: standing == null,
                        onGo: goPlace,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(alignment: Alignment.centerLeft, child: tabs),
            ),
            if (infos == null || standing != null || full)
              Expanded(
                flex: 9,
                // The Journey's tour shows the rows as the ways to pick (v1.565).
                child: TutorialTarget(
                  id: 'journey.pick',
                  child: ListView(
                    key: const ValueKey('journey_city_list'),
                    padding: EdgeInsets.zero,
                    children: rows,
                  ),
                ),
              ),
          ],
        );
    if (infos == null) return layout(true);
    return ValueListenableBuilder<bool>(
      valueListenable: places.camera.fullZoom,
      builder: (context, full, _) => layout(full),
    );
  }
}

/// The town's plan as it was when left, cut out of the picture of the map
/// box: [at] in the box's measure, [ratio] the picture's pixels per point.
class _TownShotPainter extends CustomPainter {
  final ui.Image shot;
  final Rect at;
  final double ratio;
  const _TownShotPainter(this.shot, this.at, this.ratio);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      shot,
      Rect.fromLTWH(
        at.left * ratio,
        at.top * ratio,
        at.width * ratio,
        at.height * ratio,
      ),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_TownShotPainter old) =>
      !identical(old.shot, shot) || old.at != at || old.ratio != ratio;
}

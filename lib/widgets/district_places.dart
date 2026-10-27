// The district view as places (v1.582; the mocks district-places.md and
// map-first.md): the list under the district's map holds the places, one row
// each, the map's pins carry no words and a tap on one shows a small card
// with its place, and a handle at the foot of the map says there is a list.
// The rows, the card and the handle are drawn here; Core's way_places.dart
// says which ways are taken where.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/city_camera.dart';
import '../data/way_places.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../theme/stitched_ink.dart';
import 'journey_banner_pin.dart';

/// One place of the district's list, ready to draw: its [name] (empty when
/// the plan has none yet), the [steps] taken there (indices of the Journey's
/// steps, in the scene's order), how many are open ([count]), and what kind
/// of place it is.
class PlaceInfo {
  const PlaceInfo({
    required this.id,
    required this.name,
    required this.steps,
    required this.count,
    this.here = false,
    this.wayOut = false,
    this.main = false,
    this.locked = false,
    this.note = '',
  });

  /// WayPlace.id.
  final String id;
  final String name;
  final List<int> steps;
  final int count;
  final bool here;
  final bool wayOut;

  /// A way here goes on with the main story.
  final bool main;

  /// Every way here is shut; [note] says why.
  final bool locked;

  /// The reason a shut place is shut, or what there is to do at `here`.
  final String note;
}

/// The district's places for the Journey's steps: Core's [entries] (their
/// ways index the scene's choices, [nodeChoices]) matched to the steps
/// ([stepChoices], the choices left after the hidden ones; same objects) and
/// restricted to [shown], the steps of the district in view. Null when a
/// shown step is in no place, so the Journey keeps its plain list.
List<PlaceInfo>? placeInfosOf({
  required List<WayPlaceEntry> entries,
  required List<StoryChoice> nodeChoices,
  required List<StoryChoice> stepChoices,
  required List<bool> stepLocked,
  required List<String> stepLabels,
  required Iterable<int> shown,
  required String Function(WayPlace place) nameOf,
}) {
  final inView = shown.toSet();
  final stepOfChoice = <StoryChoice, int>{
    for (var i = 0; i < stepChoices.length; i++) stepChoices[i]: i,
  };
  final covered = <int>{};
  final infos = <PlaceInfo>[];
  for (final entry in entries) {
    final steps = <int>[
      for (final w in entry.ways)
        if (w >= 0 && w < nodeChoices.length)
          if (stepOfChoice[nodeChoices[w]] case final s?)
            if (inView.contains(s)) s,
    ];
    if (steps.isEmpty) continue;
    covered.addAll(steps);
    final open = steps.where((s) => !stepLocked[s]).toList();
    final locked = open.isEmpty;
    infos.add(PlaceInfo(
      id: entry.place.id,
      name: nameOf(entry.place),
      steps: steps,
      count: open.length,
      here: entry.place.isHere,
      wayOut: entry.place.kind == WayPlaceKind.wayOut,
      main: entry.main && !locked,
      locked: locked,
      note: locked
          ? stepLabels[steps.first]
          : entry.place.isHere
              ? stepLabels[open.first]
              : '',
    ));
  }
  if (!inView.every(covered.contains)) return null;
  return infos;
}

/// What the district view keeps between builds: the camera of its map, and
/// the place whose card is open on the map.
class DistrictPlacesController {
  final CityChartCamera camera = CityChartCamera();

  /// The place (PlaceInfo.id) whose card shows over the map, if any.
  final ValueNotifier<String?> card = ValueNotifier(null);

  void dispose() {
    camera.dispose();
    card.dispose();
  }
}

Widget _count(BuildContext context, int n) {
  final ink = InkColors.of(context);
  return Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        shape: BoxShape.circle, border: Border.all(color: ink.ash, width: 1.3)),
    child: Text('$n',
        style: TextStyle(
            fontFamily: InkFonts.system, fontSize: 11, color: ink.ash)),
  );
}

/// A place's row in the list: its mark, its name, a flag where the story
/// goes on, how many things there are, and a chevron (a padlock when shut).
class PlaceRow extends StatelessWidget {
  const PlaceRow({
    super.key,
    required this.info,
    required this.noName,
    required this.goesOn,
    required this.onTap,
  });

  final PlaceInfo info;

  /// What an unnamed place reads, and the line under the one with the main
  /// story.
  final String noName;
  final String goesOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final dark = theme.brightness == Brightness.dark;
    final named = info.name.isNotEmpty;
    final cat = info.main ? JourneyPinCat.main : JourneyPinCat.side;
    final Widget lead = info.here
        ? Icon(Icons.my_location, size: 20, color: ink.gold)
        : info.wayOut
            ? Icon(info.locked ? Icons.lock_outline : Icons.logout,
                size: 19, color: ink.ash)
            : BannerPin(
                cat: cat,
                color: info.locked ? ink.ash : cat.colorOn(ink, dark: dark),
                dark: dark,
                icon: info.locked ? Icons.lock_outline : null,
                scale: 0.62,
              );
    final sub = info.locked
        ? info.note
        : info.main
            ? goesOn
            : info.here
                ? info.note
                : '';
    return InkWell(
      key: ValueKey('place_row_${info.id}'),
      onTap: onTap,
      child: Opacity(
        opacity: info.locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: ink.seam))),
          child: Row(children: [
            SizedBox(width: 30, child: Center(child: lead)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(named ? info.name : noName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: named && !info.locked ? null : ink.ash,
                            fontStyle:
                                named ? FontStyle.normal : FontStyle.italic,
                            height: 1.2)),
                    if (sub.isNotEmpty)
                      Text(sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: info.main && !info.locked
                                  ? ink.gold
                                  : ink.ash,
                              fontStyle: FontStyle.italic)),
                  ]),
            ),
            if (info.main)
              Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.flag, size: 17, color: ink.gold)),
            if (!info.locked) _count(context, info.count),
            const SizedBox(width: 4),
            Icon(info.locked ? Icons.lock_outline : Icons.chevron_right,
                size: 18, color: ink.ash),
          ]),
        ),
      ),
    );
  }
}

/// The card a tap on a pin shows over the map: the place's name, how many
/// things there are, and Go.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.info,
    required this.noName,
    required this.things,
    required this.go,
    required this.onGo,
  });

  final PlaceInfo info;
  final String noName;

  /// "1 thing to do" / "3 things to do".
  final String things;
  final String go;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final named = info.name.isNotEmpty;
    return Container(
      key: const Key('place_card'),
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xF217151B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB8A9C9)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(named ? info.name : noName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFEDE3C8),
                    fontWeight: FontWeight.w600,
                    fontStyle: named ? FontStyle.normal : FontStyle.italic)),
            Text(things,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9A93A6),
                    fontStyle: FontStyle.italic)),
          ]),
        ),
        const SizedBox(width: 8),
        Material(
          color: ink.gold,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            key: const Key('place_card_go'),
            borderRadius: BorderRadius.circular(4),
            onTap: onGo,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(go,
                  style: const TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 12.5,
                      color: Color(0xFF17151B))),
            ),
          ),
        ),
      ]),
    );
  }
}

/// The handle at the foot of the map: "Places · N" (tapped, the map goes to
/// its full zoom and the list rises), "Map" once it has (tapped, it folds).
class PlacesHandle extends StatelessWidget {
  const PlacesHandle({
    super.key,
    required this.open,
    required this.label,
    required this.onTap,
  });

  final bool open;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    return Material(
      color: const Color(0xEE17151B),
      shape: StadiumBorder(side: BorderSide(color: ink.gold, width: 1.2)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                size: 18, color: ink.gold),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontFamily: InkFonts.system,
                    fontSize: 12.5,
                    color: Color(0xFFEDE3C8))),
          ]),
        ),
      ),
    );
  }
}

/// The list under the map: with the party at the list, one row per place
/// (`here` first, the ways out under their own title); with the party at a
/// place ([standing]), a line back to the list and that place's ways, drawn
/// by [wayRow] (the Journey's own row for a step).
List<Widget> placesRows(
  BuildContext context,
  WidgetRef ref, {
  required List<PlaceInfo> infos,
  required PlaceInfo? standing,
  required Widget Function(int step) wayRow,
  required void Function(PlaceInfo place) onGo,
  required VoidCallback onLeave,
}) {
  final theme = Theme.of(context);
  final ink = InkColors.of(context);
  Widget title(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(text.toUpperCase(),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: ink.ash, letterSpacing: 0.8)),
      );
  if (standing != null) {
    return [
      InkWell(
        key: const Key('place_back'),
        onTap: onLeave,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(Icons.arrow_back, size: 18, color: ink.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  standing.name.isEmpty ? tr(ref, 'place_back') : standing.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall),
            ),
            Text(tr(ref, 'place_back'),
                style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          ]),
        ),
      ),
      for (final i in standing.steps) wayRow(i),
    ];
  }
  PlaceRow row(PlaceInfo p) => PlaceRow(
        info: p,
        noName: tr(ref, 'place_no_name'),
        goesOn: tr(ref, 'place_story_goes_on'),
        onTap: p.locked ? () {} : () => onGo(p),
      );
  final places = infos.where((p) => !p.wayOut).toList();
  final out = infos.where((p) => p.wayOut).toList();
  return [
    title(tr(ref, 'district_places_title')),
    for (final p in places) row(p),
    if (out.isNotEmpty) ...[
      title(tr(ref, 'places_ways_out')),
      for (final p in out) row(p),
    ],
  ];
}

/// Over the map: the handle at its foot and, when a pin was tapped, the
/// card of its place above it. The handle zooms the map fully (the list
/// rises) or back to the district's frame; with the party at a place, only
/// the card shows.
class PlacesMapLayer extends ConsumerWidget {
  const PlacesMapLayer({
    super.key,
    required this.controller,
    required this.infos,
    required this.districtId,
    required this.partyAt,
    required this.showHandle,
    required this.onGo,
  });

  final DistrictPlacesController controller;
  final List<PlaceInfo> infos;
  final String districtId;

  /// Where the party's mark is on the plan, the centre of the camera's shots.
  final Offset? partyAt;
  final bool showHandle;
  final void Function(PlaceInfo place) onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camera = controller.camera;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 8,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ValueListenableBuilder<String?>(
          valueListenable: controller.card,
          builder: (context, id, _) {
            final info = infos.where((p) => p.id == id).firstOrNull;
            if (info == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlaceCard(
                info: info,
                noName: tr(ref, 'place_no_name'),
                things: info.count == 1
                    ? tr(ref, 'place_things_one')
                    : tr(ref, 'place_things_many')
                        .replaceAll('{n}', '${info.count}'),
                go: tr(ref, 'place_go'),
                onGo: info.locked ? () {} : () => onGo(info),
              ),
            );
          },
        ),
        if (showHandle)
          ValueListenableBuilder<bool>(
            valueListenable: camera.fullZoom,
            builder: (context, full, _) => PlacesHandle(
              key: const Key('places_handle'),
              open: full,
              label: full
                  ? tr(ref, 'places_handle_map')
                  : tr(ref, 'places_handle')
                      .replaceAll('{n}', '${infos.length}'),
              onTap: () {
                controller.card.value = null;
                camera.show(full
                    ? CityCameraShot(districtId: districtId)
                    : CityCameraShot.full(districtId, centre: partyAt));
              },
            ),
          ),
      ]),
    );
  }
}

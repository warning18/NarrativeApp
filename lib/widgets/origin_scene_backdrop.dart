// The picture behind each of "A Life Before This One"'s memories (v1.560): a
// side-view backdrop of the memory's place, from the kits the Journey and the
// crossings already use. Most memories happen in a street, in front of a
// building (the street kit of v1.544, with its hour and weather); three are
// out of town (the frozen well, the docks, the marsh). The table below is the
// only place that says which memory sits where: it is read off each memory's
// own words (origin_stories.dart), one row for each of the fourteen.
import 'package:flutter/material.dart';

import '../data/climate.dart' show WeatherKind;
import '../data/journey_rules.dart' show DayPhase;
import 'sea_battlefield.dart' show SeaWaters;
import 'side_view/fen_kit.dart';
import 'side_view/frost_kit.dart';
import 'side_view/sea_kit.dart';
import 'side_view/side_view.dart';
import 'street_view/street_view.dart';

/// What a memory's backdrop is: a building in a street, or a wild kit.
enum OriginPlace { street, frost, fen, sea }

class OriginBackdrop {
  const OriginBackdrop.street(this.kind, this.name,
      {this.phase = DayPhase.day, this.sky})
      : place = OriginPlace.street;

  const OriginBackdrop.wild(this.place, {this.phase = DayPhase.day, this.sky})
      : kind = '',
        name = '';

  final OriginPlace place;

  /// For a street: the building's kind and name (see facadeStyleOf).
  final String kind;
  final String name;
  final DayPhase phase;
  final WeatherKind? sky;
}

/// Each memory's place, by its id (OriginMemory.id), with the hour and the
/// weather its words give.
const Map<String, OriginBackdrop> originBackdrops = {
  // Age 6: the gutter behind the rope-walk, the rain on the stones.
  'sparrow': OriginBackdrop.street('warehouse', 'The rope-walk',
      sky: WeatherKind.rain),
  // Age 8, by race.
  'mark_human': OriginBackdrop.street('temple', 'The Inquisition chapel',
      phase: DayPhase.dusk),
  'mark_elf':
      OriginBackdrop.street('shop', 'The market awning', sky: WeatherKind.rain),
  'mark_dwarf':
      OriginBackdrop.street('forge', 'The smithy', phase: DayPhase.dusk),
  'mark_orc': OriginBackdrop.street('house', 'The street'),
  'mark_voidkin': OriginBackdrop.wild(OriginPlace.frost),
  // Age 10: the tavern on Tallow Street, a winter evening.
  'beggar': OriginBackdrop.street('tavern', 'The Blind Beggar',
      phase: DayPhase.dusk, sky: WeatherKind.snow),
  // Age 12, by profession.
  'calling_warrior': OriginBackdrop.wild(OriginPlace.sea),
  'calling_mage':
      OriginBackdrop.street('shop', 'The chandler’s', phase: DayPhase.dusk),
  'calling_rogue':
      OriginBackdrop.street('den', 'The back alley', phase: DayPhase.night),
  'calling_cleric': OriginBackdrop.street(
      'temple', 'The shrine of the Drowned Saint',
      phase: DayPhase.night),
  'calling_ranger': OriginBackdrop.wild(OriginPlace.fen),
  // Age 14: Old Hesk's house next door, of an evening.
  'lamp':
      OriginBackdrop.street('house', 'Old Hesk’s house', phase: DayPhase.dusk),
  // Age 16: the house the parents left, in the winter.
  'board': OriginBackdrop.street('house', 'Your parents’ house',
      phase: DayPhase.night, sky: WeatherKind.snow),
};

/// A memory without a row (a new one) gets a plain house by day.
const OriginBackdrop _originBackdropFallback =
    OriginBackdrop.street('house', 'The house');

OriginBackdrop originBackdropOf(String memoryId) =>
    originBackdrops[memoryId] ?? _originBackdropFallback;

/// The backdrop of [memoryId], filling the height it is given.
class OriginSceneBackdrop extends StatelessWidget {
  const OriginSceneBackdrop(
      {super.key, required this.memoryId, this.height = 210});

  final String memoryId;
  final double height;

  @override
  Widget build(BuildContext context) {
    final b = originBackdropOf(memoryId);
    return SizedBox(
      height: height,
      child: switch (b.place) {
        OriginPlace.street => StreetViewScene(
            kind: b.kind,
            name: b.name,
            phase: b.phase,
            sky: b.sky,
            party: false,
          ),
        OriginPlace.frost => SideViewScene(
            layers: frostLayers(progress: 0.3),
            particles: SideParticles.snow,
            moving: false,
            height: height,
          ),
        OriginPlace.fen => SideViewScene(
            layers: fenLayers(progress: 0.3),
            moving: false,
            height: height,
          ),
        OriginPlace.sea => SideViewScene(
            layers: seaLayers(waters: SeaWaters.shallows),
            moving: false,
            height: height,
          ),
      },
    );
  }
}

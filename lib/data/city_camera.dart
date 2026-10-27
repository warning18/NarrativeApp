// The district view's camera (v1.580, docs/proposals/map-first.md): the
// Journey sets the city chart's zoom and centre through a [CityChartCamera]
// (on arriving in a district it eases in and centres on the party), and
// the chart says when it reaches its full zoom or leaves it, so the list
// of places can rise under the map and fold away again.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset;

/// How much closer than the district's own frame the camera stands after
/// an arrival: 25% in (map-first.md, "the arrival").
const double arrivalZoomIn = 1.25;

/// How long the arrival's ease takes.
const Duration arrivalEase = Duration(milliseconds: 600);

/// The share of the chart's closest zoom from which it counts as fully
/// zoomed (the list of places shows).
const double fullZoomShare = 0.95;

/// Where the camera goes: [zoom] times the frame of district [districtId]
/// (the whole city when null), centred on [centre] (a point of the plan;
/// the district's, or the city's, middle when null), over [duration]; a
/// [jump] goes at once (reduced motion, a skip).
class CityCameraShot {
  const CityCameraShot({
    this.districtId,
    this.zoom = 1,
    this.centre,
    this.duration = arrivalEase,
    this.jump = false,
    this.full = false,
  });

  /// The arrival's shot (map-first.md): the district's frame 25% closer,
  /// centred on the party's mark ([partyAt]).
  const CityCameraShot.arrival(String districtId,
      {Offset? partyAt, bool jump = false})
      : this(
            districtId: districtId,
            zoom: arrivalZoomIn,
            centre: partyAt,
            jump: jump);

  /// The chart's closest zoom on [centre] (or the district's middle): the
  /// list of places shows.
  const CityCameraShot.full(String districtId, {Offset? centre})
      : this(districtId: districtId, centre: centre, full: true);

  final String? districtId;
  final double zoom;
  final Offset? centre;
  final Duration duration;
  final bool jump;

  /// The chart's closest zoom, whatever [zoom] says.
  final bool full;
}

/// The camera of a city chart: the Journey asks for a shot with [show];
/// the chart (CityChartView's `camera`) goes there and reports, in
/// [fullZoom], whether it stands at its full zoom (pinched there, or sent
/// by a [CityCameraShot.full]).
class CityChartCamera extends ChangeNotifier {
  CityCameraShot? _shot;
  int _shots = 0;

  /// The last shot asked for, and how many came before (a chart that
  /// missed one, being built, goes to the last).
  CityCameraShot? get shot => _shot;
  int get shots => _shots;

  /// Whether the chart stands at its full zoom.
  final ValueNotifier<bool> fullZoom = ValueNotifier(false);

  /// The chart's zoom, as a multiple of the whole city's frame.
  double get zoom => _zoom;
  double _zoom = 1;

  void show(CityCameraShot shot) {
    _shot = shot;
    _shots++;
    notifyListeners();
  }

  /// Called by the chart as its zoom changes: [zoom] over the city's frame,
  /// and whether that is its full zoom.
  void report({required double zoom, required bool full}) {
    _zoom = zoom;
    fullZoom.value = full;
  }

  @override
  void dispose() {
    fullZoom.dispose();
    super.dispose();
  }
}

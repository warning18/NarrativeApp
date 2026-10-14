import 'dart:ui' show Offset, Rect;

/// A drawn plan the Journey lays its ways on (v1.207): a city's streets
/// (see city_plan.dart) or the inside of a building (see room_plan.dart).
/// Both are laid out in their own units and know where each named spot
/// is and how to walk between two points.
abstract interface class PlacePlan {
  /// What the map should keep in view.
  Rect get frame;

  /// Where [id] is on the plan ('' for the middle of it).
  Offset anchorOf(String id);

  /// The way from [from] to [to] along what can be walked.
  List<Offset> route(Offset from, Offset to);
}

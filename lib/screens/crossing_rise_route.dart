// The road trip as one camera travel (v1.846): a long road the story crosses
// (land_routes.json) used to be shown twice, the chart flight to the far
// place and then a new screen that set out again from the first day. Now the
// chart flight only sets out, and the crossing rises over the chart from the
// top, its scene first, so the party that left the place is the party on the
// road.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

/// True from the moment the Journey map's flight has set out for a crossing
/// until that crossing opens (or the step ends): `runLandCrossing` then
/// rises over the map instead of pushing a plain page. Set by the Journey
/// screen; read and cleared by the crossing.
final crossingRiseProvider = StateProvider<bool>((ref) => false);

/// How far along its flight the chart goes before the crossing takes over
/// (the flight's own scale, 0 to 1: the map has zoomed out and the party is
/// on the road, well short of the far place).
const double crossingSetOutAt = 0.4;

/// The longest the set-out flight lasts (a long world road's flight is 6 to
/// 13 s; the set-out is its first stretch, sped up to this).
const Duration crossingSetOutMax = Duration(milliseconds: 2200);

/// How long the crossing takes to rise over the chart.
const Duration crossingRiseDuration = Duration(milliseconds: 420);

/// The crossing's route when it follows the map's flight: the page is
/// uncovered from the top down, its scene strip first, with the chart still
/// showing below; going back (turning back) pulls it up the same way.
/// With reduced motion it is there at once.
class CrossingRiseRoute<T> extends PageRouteBuilder<T> {
  CrossingRiseRoute({required WidgetBuilder builder, bool still = false})
      : super(
          transitionDuration: still ? Duration.zero : crossingRiseDuration,
          reverseTransitionDuration:
              still ? Duration.zero : crossingRiseDuration,
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            // The outer Align loosens the page's tight size, so the inner one
            // can be as tall as the part uncovered.
            return Align(
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) => Align(
                    key: const ValueKey('crossing_rise'),
                    alignment: Alignment.topCenter,
                    heightFactor: Curves.easeInOut.transform(animation.value),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}

// A scene played outside a building (v1.544): the street-view kit, the
// room kits' counterpart for the outside. The building's front stands over
// the street, the street runs before it in cobbles, the day's weather falls
// on it (rain wets the stones, snow whitens the roof, fog thickens the air)
// and the hour lights it (the windows and a lantern at dusk and night), the
// party at the door and the choices as pins along the street. It stands in
// the district view where Core's doorstep scenes (v1.542) used to show the
// town's plan; the town view still does.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/climate.dart' show WeatherKind;
import '../../data/journey_rules.dart' show DayPhase;
import '../side_view/kit_common.dart';
import '../side_view/kit_hour.dart';
import '../side_view/side_view.dart';
import 'street_facade.dart';

/// One choice standing in the street: its [index] among the scene's ways,
/// the [child] (the pin the Journey draws everywhere else), its [label].
class StreetPin {
  const StreetPin({
    required this.index,
    required this.child,
    required this.label,
    this.locked = false,
  });

  final int index;
  final Widget child;
  final String label;
  final bool locked;
}

/// The row the buildings stand on, in scene pixels from the top.
const double streetKerb = 50;

/// The particles the sky puts over a street: the weather's own; clear and
/// cloud leave the air alone.
SideParticles streetParticles(WeatherKind? sky) => switch (sky) {
      WeatherKind.rain => SideParticles.rain,
      WeatherKind.snow => SideParticles.snow,
      WeatherKind.fog => SideParticles.fog,
      WeatherKind.ash => SideParticles.ash,
      WeatherKind.dust => SideParticles.dust,
      _ => SideParticles.none,
    };

/// The sky's bands for [phase], greyed when the weather is overcast.
List<Color> streetSkyBands(DayPhase phase, WeatherKind? sky) {
  final bands = switch (phase) {
    DayPhase.day => const [
        Color(0xFF8FB6D6),
        Color(0xFFB6D0E2),
        Color(0xFFE6E3D2)
      ],
    DayPhase.dawn => const [
        Color(0xFF8D9CC4),
        Color(0xFFE2A48E),
        Color(0xFFF5D3A0)
      ],
    DayPhase.dusk => const [
        Color(0xFF47507F),
        Color(0xFF9A5E7E),
        Color(0xFFE59A62)
      ],
    DayPhase.night => const [
        Color(0xFF0B1230),
        Color(0xFF16204A),
        Color(0xFF2A3562)
      ],
  };
  final grey = switch (sky) {
    WeatherKind.rain || WeatherKind.snow || WeatherKind.ash => 0.55,
    WeatherKind.fog || WeatherKind.cloud => 0.4,
    WeatherKind.dust => 0.3,
    _ => 0.0,
  };
  if (grey == 0) return bands;
  return [
    for (final c in bands)
      Color.lerp(
          c,
          phase == DayPhase.night
              ? const Color(0xFF1B1E2C)
              : const Color(0xFF8A8F99),
          grey)!
  ];
}

/// The layers of a street before a [style] building, back to front.
List<SideLayer> streetLayers({
  required FacadeStyle style,
  required DayPhase phase,
  WeatherKind? sky,
}) {
  final wet = sky == WeatherKind.rain;
  final snowy = sky == WeatherKind.snow;
  return withHourStars([
    // The sky.
    SideLayer(0, (canvas, size, scroll, t, u) {
      kitSky(canvas, size, u,
          bands: streetSkyBands(phase, sky),
          ground: const Color(0xFF4B463F),
          horizon: streetKerb.toInt());
    }),
    // The rooftops behind: a ragged row of houses in the haze.
    SideLayer(0, (canvas, size, scroll, t, u) {
      final cols = size.width / u;
      final haze = Color.lerp(
          const Color(0xFF6B6F7C),
          phase == DayPhase.night ? const Color(0xFF10142A) : Colors.white,
          0.25)!;
      final paint = Paint()..color = haze;
      var x = -2.0;
      var i = 0;
      while (x < cols) {
        final w = 9.0 + _hash(i, 1) * 9;
        final h = 12.0 + _hash(i, 2) * 12;
        sidePixels(canvas, u, paint, x, streetKerb - h, w, h);
        // A roof on it.
        sidePixels(canvas, u, paint, x - 1, streetKerb - h - 2, w + 2, 2);
        x += w + 1;
        i++;
      }
    }),
    // The street itself, behind the building's feet: the kerb and the far
    // pavement.
    SideLayer(0, (canvas, size, scroll, t, u) {
      final cols = size.width / u;
      final paint = Paint();
      paint.color = const Color(0xFF5B554C);
      sidePixels(canvas, u, paint, 0, streetKerb, cols, 22);
      // Cobbles in offset rows, bigger towards the viewer.
      for (var row = 0; row < 11; row++) {
        final y = streetKerb + 1 + row * (1 + row * 0.18);
        final s = 3 + row * 0.9;
        final shift = row.isOdd ? s / 2 : 0.0;
        paint.color =
            row.isEven ? const Color(0xFF6A6358) : const Color(0xFF625B51);
        for (var x = -shift; x < cols; x += s) {
          sidePixels(canvas, u, paint, x, y, s - 1, 1 + row * 0.18);
        }
        if (y > 71) break;
      }
      // The kerb line and its shadow.
      paint.color = const Color(0xFF8C857A);
      sidePixels(canvas, u, paint, 0, streetKerb, cols, 1);
      paint.color = Colors.black.withValues(alpha: 0.18);
      sidePixels(canvas, u, paint, 0, streetKerb + 1, cols, 2);
      if (snowy) {
        paint.color = Colors.white.withValues(alpha: 0.6);
        sidePixels(canvas, u, paint, 0, streetKerb, cols, 1);
        for (var i = 0; i < cols / 4; i++) {
          sidePixels(canvas, u, paint, _hash(i, 3) * cols,
              streetKerb + 2 + _hash(i, 4) * 18, 2, 1);
        }
      }
      if (wet) {
        // Puddles with a streak of the sky in them.
        for (var i = 0; i < 6; i++) {
          final px = _hash(i, 5) * cols;
          final py = streetKerb + 6 + _hash(i, 6) * 14;
          paint.color = const Color(0xFF8FB6D6).withValues(alpha: 0.28);
          sidePixels(canvas, u, paint, px, py, 7 + _hash(i, 7) * 6, 1);
        }
      }
    }),
    // The building.
    SideLayer(0, (canvas, size, scroll, t, u) {
      final box = facadeBoxFor(style, size.width / u, streetKerb);
      paintFacade(canvas, u, style, box, snow: snowy);
      // Its shadow on the street.
      canvas.drawRect(
          Rect.fromLTWH(
              box.left * u, (streetKerb + 1) * u, box.width * u, 3 * u),
          Paint()..color = Colors.black.withValues(alpha: 0.2));
    }),
  ], phase);
}

/// The overlay: the hour's wash, then the lights over it, so they are not
/// dimmed with the evening. A pool of window light lies on the street.
SideLayer streetOverlay({required FacadeStyle style, required DayPhase phase}) {
  final wash = hourWash(phase);
  final lit = phase == DayPhase.dusk || phase == DayPhase.night;
  return SideLayer(0, (canvas, size, scroll, t, u) {
    wash?.paint(canvas, size, scroll, t, u);
    if (!lit) return;
    final box = facadeBoxFor(style, size.width / u, streetKerb);
    // The pool of light before the door.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(box.doorX * u, (streetKerb + 6) * u),
            width: box.width * 0.9 * u,
            height: 9 * u),
        Paint()
          ..color = const Color(0xFFFFD27A)
              .withValues(alpha: phase == DayPhase.night ? 0.2 : 0.12));
    paintFacadeLights(canvas, u, style, box, t,
        strength: phase == DayPhase.night ? 1 : 0.7);
  });
}

/// The party at the door: the hero, small, with the cloak and the hat of
/// the deck and the walk.
SideLayer streetParty({required FacadeStyle style}) {
  return SideLayer(0, (canvas, size, scroll, t, u) {
    final box = facadeBoxFor(style, size.width / u, streetKerb);
    // On the pavement beside the door, clear of the pin that stands before it.
    final x = (box.doorX - 14).floorToDouble();
    final feet = streetKerb + 5;
    final paint = Paint();
    paint.color = const Color(0xFF2B2420);
    sidePixels(canvas, u, paint, x, feet - 2, 3, 2);
    paint.color = const Color(0xFFC0392B);
    sidePixels(canvas, u, paint, x - 1, feet - 6, 5, 4);
    paint.color = const Color(0xFF8E2B20);
    sidePixels(canvas, u, paint, x - 1, feet - 3, 5, 1);
    paint.color = const Color(0xFFE2B890);
    sidePixels(canvas, u, paint, x, feet - 8, 3, 2);
    paint.color = const Color(0xFFEFE6CF);
    sidePixels(canvas, u, paint, x - 1, feet - 9, 4, 1);
    // A shadow under their feet.
    paint.color = Colors.black.withValues(alpha: 0.25);
    sidePixels(canvas, u, paint, x - 1, feet, 5, 1);
  });
}

double _hash(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// The street scene with its pins. It fills the room it is given; the pins
/// stand along the street, in two rows when there are many.
class StreetViewScene extends StatelessWidget {
  const StreetViewScene({
    super.key,
    required this.kind,
    required this.name,
    this.phase = DayPhase.day,
    this.sky,
    this.pins = const [],
    this.onPick,
  });

  /// The building's kind and name (see facadeStyleOf).
  final String kind;
  final String name;
  final DayPhase phase;
  final WeatherKind? sky;
  final List<StreetPin> pins;
  final void Function(int index)? onPick;

  /// Where pin [k] of [n] stands across the street, as shares of the width
  /// and of the height.
  static Offset pinAt(int k, int n) {
    if (n <= 4) return Offset((k + 0.5) / n, 0.8);
    final first = (n / 2).ceil();
    final row = k < first ? 0 : 1;
    final count = row == 0 ? first : n - first;
    final col = row == 0 ? k : k - first;
    return Offset((col + 0.5) / count, row == 0 ? 0.74 : 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final style = facadeStyleOf(kind, name);
    return LayoutBuilder(builder: (context, box) {
      final height = box.maxHeight.isFinite ? box.maxHeight : 260.0;
      final width = box.maxWidth.isFinite ? box.maxWidth : 360.0;
      final stack = Stack(
        fit: StackFit.expand,
        children: [
          SideViewScene(
            key: const ValueKey('journey_street_scene'),
            layers: streetLayers(style: style, phase: phase, sky: sky),
            actors: streetParty(style: style),
            overlay: streetOverlay(style: style, phase: phase),
            particles: streetParticles(sky),
            intensity: sky == WeatherKind.fog ? 0.7 : 0.8,
            moving: false,
            height: height,
          ),
          for (final (k, pin) in pins.indexed)
            Builder(builder: (context) {
              final at = pinAt(k, pins.length);
              final inRow = pins.length <= 4
                  ? pins.length
                  : (k < (pins.length / 2).ceil()
                      ? (pins.length / 2).ceil()
                      : pins.length - (pins.length / 2).ceil());
              final cell = math.min(84.0, width / inRow - 2);
              return Positioned(
                left: (at.dx * width - cell / 2).clamp(0.0, width - cell),
                top: (at.dy * height - 34).clamp(0.0, height - 56),
                width: cell,
                child: GestureDetector(
                  key: ValueKey('street_pin_${pin.index}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onPick == null ? null : () => onPick!(pin.index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      pin.child,
                      const SizedBox(height: 2),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          child: Text(
                            pin.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: pin.locked
                                      ? Colors.white60
                                      : Colors.white,
                                  height: 1.1,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      );
      return SizedBox(width: width, height: height, child: stack);
    });
  }
}

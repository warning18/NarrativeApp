// The Tower's look (v1.900, UX-2's option B): the whole climb in the night
// theme (the dark scheme of the app's palette, on the Tower's own screens
// only), its panels in the double-ink-line and bevel style, the foe standing
// in its panel when it has art.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/climate.dart' show WeatherKind;
import '../../providers/palette_provider.dart';
import '../../theme/frame_style.dart';
import '../../theme/stitched_ink.dart';
import 'ink/ink_images.dart';
import 'ink/ink_palette.dart';
import 'ink/ink_weather.dart';
import 'tower_providers.dart';
import '../../widgets/fight_sprites.dart';

/// Whether the panels under it wear the Tower's double ink line and bevel.
class TowerPanelStyle extends InheritedWidget {
  const TowerPanelStyle({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TowerPanelStyle>() != null;

  @override
  bool updateShouldNotify(TowerPanelStyle old) => false;
}

/// The frame material of the Tower's panels and buttons: the interface gets
/// less cheap as the climb goes on (floors 1 to 10 wood, 11 to 20 iron, 21 to
/// 30 silver), and gilt for good once a run has been won.
FrameMaterial towerMaterialOf({required int floor, required bool climbed}) {
  if (climbed) return FrameMaterial.gilt;
  if (floor <= 10) return FrameMaterial.wood;
  if (floor <= 20) return FrameMaterial.iron;
  return FrameMaterial.silver;
}

/// The Tower's screens wear this: the dark scheme of the current palette, the
/// frames of the floor's material and the bevel panels. Each Tower screen is a
/// thin wrapper that puts its body under it, so the body's own theme reads,
/// and the dialogs it opens, are dark. [floor] overrides the run's floor (the
/// end screen, where the run is already cleared).
class TowerNight extends ConsumerWidget {
  const TowerNight({
    super.key,
    required this.child,
    this.floor,
    this.frames = true,
  });

  final Widget child;
  final int? floor;

  /// Whether the theme carries the wood, iron and silver frame pieces (the
  /// fight, in ink, has none).
  final bool frames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(appPaletteProvider);
    final state = ref.watch(towerProvider).value;
    final material = towerMaterialOf(
      floor: floor ?? state?.run?.floor ?? 1,
      climbed: (state?.progress.wins ?? 0) > 0,
    );
    // The band's own decorations on the frame: the night rooms, the stone
    // stairs, the void.
    final floorNow = floor ?? state?.run?.floor ?? 1;
    final env = floorNow <= 10
        ? EnvDecor.towerNight
        : floorNow <= 20
            ? EnvDecor.towerStone
            : EnvDecor.towerVoid;
    // The pieces are small and loaded ahead (main.dart); until they are
    // there the Tower wears its plain bevel, so no panel is drawn bare.
    final ready = FrameImages.ready(material, env);
    if (!ready) FrameImages.preload(material, env);
    // The ink frames (v1.1004), the same way: loaded once, ahead.
    if (!InkImages.ready) unawaited(InkImages.preload());
    return ValueListenableBuilder<int>(
      valueListenable: FrameImages.loaded,
      builder: (context, _, __) => Theme(
        data: _inkButtons(
          buildAppTheme(
            palette.schemeFor(Brightness.dark),
            frames: frames && FrameImages.ready(material, env)
                ? FrameStyle(
                    material: material,
                    env: env,
                    compactScale: 2,
                    seed: floorNow,
                  )
                : null,
          ),
        ),
        // Snow on the ink pieces, harder with the band: 0.4, 0.7, 1.0.
        child: WeatherScope(
          id: 'tower',
          kind: WeatherKind.snow,
          fall: floorNow <= 10
              ? 0.4
              : floorNow <= 20
                  ? 0.7
                  : 1.0,
          child: TowerPanelStyle(child: child),
        ),
      ),
    );
  }
}

/// The Tower's buttons in ink (v1.1005): a flat red block with paper text for
/// the one that matters, a black block with a paper line for the rest; square.
/// The Tower's colours for everything that reads [InkColors] (the level up, the
/// spoils sheet, the offers): paper for the main action and healing, red only
/// for blood and danger, cold greys for the rest (v1.1010).
const InkColors towerInkColors = InkColors(
  gold: inkPaper,
  blood: inkRed,
  ember: inkRed,
  tide: inkGrey,
  voidColor: inkGrey,
  heal: inkPaper,
  seam: inkSlate,
  ash: inkGrey,
);

ThemeData _inkButtons(ThemeData t) {
  const square = RoundedRectangleBorder();
  return t.copyWith(
    extensions: [
      for (final e in t.extensions.values)
        if (e is! InkColors) e,
      towerInkColors,
    ],
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: inkRed,
        foregroundColor: inkPaper,
        disabledBackgroundColor: inkSlate,
        disabledForegroundColor: inkGrey,
        shape: square,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: inkRed,
        foregroundColor: inkPaper,
        disabledBackgroundColor: inkSlate,
        disabledForegroundColor: inkGrey,
        elevation: 0,
        shape: square,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: inkBlack,
        foregroundColor: inkPaper,
        side: const BorderSide(color: inkPaper),
        shape: square,
      ),
    ),
  );
}

/// A foe standing: its sprite, as drawn (facing west, toward the hero).
class TowerFoeFigure extends StatelessWidget {
  const TowerFoeFigure(this.enemyId, {super.key, this.size = 56});

  final String enemyId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final set = enemyFightSprite(enemyId);
    if (set == null) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: FightSpriteImages.loaded,
      builder: (context, _, __) {
        final image = FightSpriteImages.idleOf(set);
        return SizedBox(
          key: Key('tower_foe_$enemyId'),
          width: size,
          height: size,
          child: image == null
              ? null
              : CustomPaint(
                  painter: _FoePainter(image, set.frameWidth, set.frameHeight),
                ),
        );
      },
    );
  }
}

class _FoePainter extends CustomPainter {
  _FoePainter(this.image, this.w, this.h);

  final ui.Image image;
  final int w, h;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Offset.zero & size,
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );

  @override
  bool shouldRepaint(_FoePainter old) => old.image != image;
}

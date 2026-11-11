// The Tower floor's backdrop (v1.895): a PixelLab picture of the tower's room
// for the band the party climbs in (floors 1 to 10, 11 to 20, 21 to 30),
// cover-fitted behind the floor screen with the page's own colour laid over it,
// so the text and panels on top read as they always did (the layout is not
// touched; only what is drawn behind it).
import 'package:flutter/material.dart';

/// The band of a floor: 1 for floors 1 to 10, 2 for 11 to 20, 3 above.
int towerBandOf(int floor) => floor <= 10
    ? 1
    : floor <= 20
        ? 2
        : 3;

/// The picture of [band] (1 to 3).
String towerBackdropAsset(int band) =>
    'assets/visuals/tower/tower_band${band.clamp(1, 3)}.png';

/// The picture of a special floor: the wardens (5, 15, 25) and the bosses (10,
/// 20, 30) each have their own; null for an ordinary floor.
String? towerFloorPlate(int floor) => switch (floor) {
      5 || 15 || 25 => 'assets/visuals/tower/tower_ward$floor.png',
      10 || 20 || 30 => 'assets/visuals/tower/tower_boss$floor.png',
      _ => null,
    };

/// The end of a run: the picture of a won run, of a lost one.
String towerEndPlate({required bool won}) =>
    'assets/visuals/tower/tower_${won ? 'win' : 'lose'}.png';

/// How much of the page's colour lies over the picture.
const double towerBackdropVeil = 0.58;

class TowerBackdrop extends StatelessWidget {
  const TowerBackdrop(
      {super.key, required this.floor, required this.child, this.asset});

  final int floor;

  /// A picture to wear in place of the floor's (the end of a run).
  final String? asset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ground = Theme.of(context).colorScheme.surface;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset ??
              towerFloorPlate(floor) ??
              towerBackdropAsset(towerBandOf(floor)),
          key: const Key('tower_backdrop'),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
        ColoredBox(color: ground.withValues(alpha: towerBackdropVeil)),
        child,
      ],
    );
  }
}

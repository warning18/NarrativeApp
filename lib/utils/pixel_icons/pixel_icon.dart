import 'package:flutter/widgets.dart';

/// Renders a pixel-art icon asset with crisp pixels -- no smoothing on
/// upscale, which is essential for 16x16-native art blown up to display
/// size (`FilterQuality.none` is what keeps the pixel look; the default
/// `Image.asset` behavior blurs it away).
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.assetPath, {super.key, this.size = 32});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      fit: BoxFit.contain,
    );
  }
}

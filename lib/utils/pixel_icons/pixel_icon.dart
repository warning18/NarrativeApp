import 'package:flutter/widgets.dart';

/// Renders a pixel-art icon asset with crisp pixels -- no smoothing on
/// upscale, which is essential for 16x16-native art blown up to display
/// size (`FilterQuality.none` is what keeps the pixel look; the default
/// `Image.asset` behavior blurs it away).
///
/// An asset that is missing (a record in the Data tab naming a picture
/// the build does not carry) draws [fallback], or the icon's blank space,
/// instead of throwing (v1.201.2).
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.assetPath, {super.key, this.size = 32, this.fallback});

  final String assetPath;
  final double size;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          fallback ?? SizedBox(width: size, height: size),
    );
  }
}

// A one-colour pixel glyph (v1.907): the game's own little marks (lock, star,
// the empty-slot silhouettes, block) as 16 x 16 masks that the theme tints,
// so light, dark and faded states cost nothing. Each is a PNG under
// assets/icons/glyphs/; until Art's file for a glyph is in the bundle the
// glyph shows its Material stand-in, same size and colour, so a screen never
// shows a hole. Drawn nearest neighbour, on the size scale (IconSize).
import 'package:flutter/material.dart';

import '../theme/icon_sizes.dart';

enum PixelGlyphs {
  lock('lock', Icons.lock),
  star('star', Icons.star),
  block('block', Icons.block),
  slotHead('slot_head', Icons.sports_motorsports_outlined),
  slotBody('slot_body', Icons.checkroom_outlined),
  slotWeapon('slot_weapon', Icons.gavel),
  slotLegs('slot_legs', Icons.airline_seat_legroom_normal),
  slotFeet('slot_feet', Icons.hiking),
  slotBag('slot_bag', Icons.inventory_2_outlined);

  const PixelGlyphs(this.file, this.fallback);

  /// The file name under assets/icons/glyphs/ (without .png).
  final String file;

  /// What shows until the file is in the bundle.
  final IconData fallback;

  String get asset => 'assets/icons/glyphs/$file.png';
}

class PixelGlyph extends StatelessWidget {
  const PixelGlyph(this.glyph,
      {super.key, this.size = IconSize.s16, this.color, this.opacity = 1});

  final PixelGlyphs glyph;

  /// A size of the scale (see [IconSize]).
  final double size;

  /// The tint; the ambient icon colour when null.
  final Color? color;

  /// 1 normally; less for a faded (locked or empty) state.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? Colors.black;
    final fallback = Icon(glyph.fallback, size: size, color: tint);
    Widget child = Image.asset(
      glyph.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      // The mask is white (its ink pixels stay dark): multiplied by the tint.
      color: tint,
      colorBlendMode: BlendMode.modulate,
      errorBuilder: (context, error, stack) => fallback,
    );
    if (opacity < 1) child = Opacity(opacity: opacity, child: child);
    return Semantics(excludeSemantics: true, child: child);
  }
}

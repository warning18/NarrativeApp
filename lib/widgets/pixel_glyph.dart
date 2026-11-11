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

  /// The 8 x 8 lock with its ink ring, for badges (drawn at 16 dp, 2x).
  lock8('lock8', Icons.lock, tinted: false),
  star('star', Icons.star, tinted: false),
  block('block', Icons.block, tinted: false),
  slotHead('slot_head', Icons.sports_motorsports_outlined),
  slotBody('slot_body', Icons.checkroom_outlined),
  slotWeapon('slot_weapon', Icons.gavel),
  slotLegs('slot_legs', Icons.airline_seat_legroom_normal),
  slotFeet('slot_feet', Icons.hiking),
  slotBag('slot_bag', Icons.inventory_2_outlined);

  const PixelGlyphs(this.file, this.fallback, {this.tinted = true});

  /// Whether the file is a white mask the theme tints (the lock, the slot
  /// silhouettes) or a picture with its own colours (the star, the block).
  final bool tinted;

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
      // A mask is white (its ink pixels stay dark): multiplied by the tint.
      color: glyph.tinted ? tint : null,
      colorBlendMode: glyph.tinted ? BlendMode.modulate : null,
      errorBuilder: (context, error, stack) => fallback,
    );
    if (opacity < 1) child = Opacity(opacity: opacity, child: child);
    return Semantics(excludeSemantics: true, child: child);
  }
}

# 1.905: icon sizes on one scale (UI list item 1)

`lib/theme/icon_sizes.dart`: `IconSize.inline` 12, `s16` 16, `s32` 32, `s48` 48,
`s64` 64 (above that, whole multiples of 16). Every `Icon(...)` and pixel icon
(`PixelIcon`, `SkillPixelIcon`, `ItemPixelIcon`, `EnemyPixelIcon`,
`ShopPixelIcon`) that asked for a number now asks for a token: 9 to 12 become
inline, 13 to 21 become 16, 22 to 39 become 32, 40 to 55 become 48. 134 + 283
sites in the code; the pixel icons are drawn nearest neighbour (they already
were) so a 16-art-pixel icon only lands on 1x, 2x, 3x, 4x. Guard test
`test/ux_icon_sizes_test.dart` fails on any off-scale literal.

Pictures (left before, right after): the Journey place strip, the inventory,
the skills tree and Other, at 412 and 360, light and dark. The visible
differences: empty-slot glyphs and skill icons in the tree grow from 26 and 28
to 32, small chip glyphs from 18/20 to 16.

Not in this PR: icons without a size (Flutter's 24 default: nav bar, app bar,
buttons: items 3 and 9), sizes computed from another size (`size * 0.55` on
the die faces and so on), and the pixel sets Art is still drawing.

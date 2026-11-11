# 1.908: square pixel chips and tabs (UI list item 6)

`lib/theme/pixel_chip.dart`: `PixelChipBorder`, a rectangle whose corners
step like pixels (three steps of 2 dp = 1 art pixel each), drawn without
antialiasing, with the chip's own border colour. It replaces the rounded
rectangle in the theme's chips (every `Chip`, `ChoiceChip`, `FilterChip`,
`ActionChip`: the theme's `chipTheme.shape`) and the pills that were drawn by
hand: the inventory tabs, the district and city-chart "places" pills
(`StadiumBorder`), the ability tags and the origin-stories tags.

Pictures: `chips-{412,360}-{light,dark}.png` (a gallery of the real chip types,
before above, after below), `inventory-tabs-*.png` (the real inventory tab row,
before left, after right). Not changed: tab bars with an underline, segmented
buttons (already square), the fight HUD's condition chips, cards and panels
(item 8, panels A + buttons C).

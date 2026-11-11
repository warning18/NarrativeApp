# Art's harmonised icons wired (#923): the 289 skill and item icons

`art/pixellab-icons/harmonised/{skills,items}` copied over `assets/icons/{skills,items}`
(157 + 132 files, same names and sizes, drawings untouched: one ink outline
`#0A0807`, every pixel on the 63-colour shared palette), stored as PNG8 with
`tool/png8.py` (`qa_png_palette_test` passes). Pictures: inventory and skills
tree at 412 and 360, light and dark (left before, right after); the change is
the uniform outline and palette, so it is subtle by design.

Known side effect from Art's README: a dark-purple fill (the purple ring
skill) can become ink black.

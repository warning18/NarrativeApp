# Can gear be layered on a character later? (Art's answer, 24 November 2026; no generation)

**Recommendation: do not build a true paper doll with PixelLab. Make 4 to 6 gear looks per hero (cloth, leather, mail, plate, and one robe or cloak look where the class needs it) and draw weapons and shields as small overlays in code at a hand anchor.** About 60 generations per hero for 5 looks with idle and a left and right walk; per-item looks would cost about the whole allowance.

**What PixelLab can do**
- It has no layer output. Every tool gives back a fully redrawn character (a state, an edited image, or an edited animation), never a transparent gear layer that lines up over a base body. Cutting a layer out by subtracting the base from the look in code only works where the model left the base pixels unchanged, and it does not (it redraws the whole figure).
- Re-dress one look: `create_character_state` gives a new look of the hero in all 8 directions, 10 generations at 48x48, and keeps the hero's face and body by design.
- Re-dress an existing animation: `transfer_outfit` (from a reference image of the same character in the new outfit) and `edit_animation` (from a text instruction) keep each frame's pose and motion and change the look, **per frame**, one call for a whole walk: 10 generations for up to 16 frames at 64 px (billed by the grid, not the frame count). The result is not written back to the stored character unless saved with `save_to_asset`. Frames can drift a pixel or two between looks, so they do not line up exactly.
- New animation for a look: a template walk is 1 generation per direction (6 frames), so left and right is 2.

**Cost per look and per item** (48x48, east and west only)
- One look with idle and a walk left and right: 10 (state) + 2 (walks) = about 12 generations; or 10 + 10 to carry the base hero's existing walk through `transfer_outfit` (the same motion, only the outfit changes).
- 5 looks for one hero: about 60. For 5 classes: about 300. For the 134 items as separate looks: about 1,600, which is the whole allowance, so no.
- Weapons and shields as code overlays: the 16 px item icons rotated at a hand anchor per frame (UX or Core writes the anchor table: one hand point per walk frame). 0 generations, and the weapon always lines up.

**Middle way in detail**
1. Gear looks by armour class, not by item: each armour item names the look it wears (`cloth`, `leather`, `mail`, `plate`, plus rarity colour as a palette tint in code).
2. One look set per class, made from the hero's own idle and walk so the silhouette is the same.
3. Helmets and capes are the hard part (they change the silhouette): fold them into the look (a plate look has a helm) instead of layering them.
4. A test first: one class (the warrior), 3 looks, 36 generations, then judge.

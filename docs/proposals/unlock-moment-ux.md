# The unlock moment (UX's part of the feature ladder)

For `docs/proposals/feature-ladder.md` (Core leads, Narrative writes the beats). Nothing here is built; this is how UX would show a feature opening, and what UX needs from Core.

## How it shows

**The card.** When a feature opens, a small "New" card slides down from under the status bar (never over the choices, and never during a fight: it waits for the fight to end). It holds the feature's icon in its colour, "New: Camp", one line on what it does ("Rest, buy and build between roads."), a "Show me" button that opens its tutorial topic (the guide's `TutorialTopic`), and a quiet "Later". It stays until it is tapped or for 6 seconds, whichever comes first, and it is not a dialog: the game underneath keeps working. Several unlocks at once queue: one card at a time, the next after the first closes.

**The pulse.** The tab or button that just appeared pulses (a ring that breathes, three times) with a small gold dot on it, and the dot stays until the player first opens it. So a player who dismissed the card still finds the thing; the dot is the memory.

**Under reduced motion.** No slide and no breathing ring: the card fades in place in 150 ms and the dot is static. The information is the same.

## Locked things

One rule, so every screen answers the same way:
- **A tab or button of a bar** (the bottom bar's Camp, the top bar's tools, the Character tab's sub-tabs): hidden until it opens. A player in chapter 1 sees a bar of two items, not four with two greyed; each arrives with its card.
- **A part of a screen the player is already in** (a row, a section, a button inside a card): calmly greyed, with a small lock, because its absence would leave a hole. A tap says in one line when it opens ("Opens in chapter 2: the Camp") in a small sheet; never an error, never nothing.
- A screen reached by a link while it is locked shows the same one-line sheet.

## What UX needs from Core

Yes, a provider would help, and it is enough:
- `unlockedFeatures`: the set of feature ids that are open;
- `newlyUnlocked`: the ids opened and not yet acknowledged (ordered), with `acknowledgeFeature(id)` to clear one (the card's "Later" or "Show me", or the first time the tab is opened);
- a feature id for each thing that can be locked, kept to the ids the UI already has (`camp`, `ship`, `dice`, `titles`, `map`, `clans`, ...). The label, the icon, the one line and the tutorial topic per id live on UX's side (`lib/widgets/feature_unlock.dart`), in both languages.

UX would add one widget, `FeatureGate(feature: 'camp', child: ..., locked: ...)`, that shows the child when the feature is open, nothing (for a bar item) or the greyed form (inside a screen) otherwise, so no screen needs its own `if`.

**Saves.** A save already past chapter 2 should open everything and acknowledge it all, so no one is shown a card for something they have used for hours: that is Core's migration, one line in the loader.

## If the user approves

Mockups next: the card over the Journey tab and over a fight's end, the bar at chapter 1 and at chapter 2, one greyed row, in English and French at 320 px. Say which screens the ladder touches first and UX starts there.

## Built (v1.423.0)

`lib/widgets/feature_unlock.dart`: `FeatureGate`, `FeatureLockedTile` (+ the "Opens in chapter N" sheet), `UnlockDot`, and `FeatureUnlockHost` (the "New: X" card over the home shell, one at a time, held back while a fight or a page covers the shell; "Later" and "Show me" both acknowledge, 6 s without a tap lets the card go and keeps the dot). Words per feature are `feature_<id>_name` / `feature_<id>_line` in both languages.

Where each of Core's ids is gated:
- `quests`: Other → Quests row (greyed with a lock, dot when new).
- `inventory`: Character → Pages: Inventory and Dice tiles (greyed), the Shroud card (hidden).
- `skills`: the Skills screen (a locked page) and the Overview card's skills part (greyed).
- `politics`: the app bar's ⚖ (hidden, dot when new).
- `clans`: Character → Gifts tab (hidden, dot when new).
- `chest`, `placeRules`, `conditions`, `levelUp`: card only (their things live in fights and the level-up).

Pictures: `docs/ux-shots/unlock-card.png`, `unlock-card-fr-320.png`, `unlock-locked.png`.

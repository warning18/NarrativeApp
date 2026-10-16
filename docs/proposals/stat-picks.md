# Stat points become picks (Core, proposal)

The user wrote: "On rewards stat points, offer one choice per stat point. But the choice should replace the stat points themselves."

**Today**, a level brings 5 stat points. They sit in a pool ("Stat Points Available: 7") and are spent two ways:
- by hand, one at a time, on any stat;
- through the build cards (training, v1.320): a 5-point bundle along one of ten paths, or a one-point "small offer" when fewer than 5 are left.

**After this change:**
- The pool and both ways of spending it are gone.
- Each point earned is one **pick**: three offers, and the character takes one.
- A pick never waits for a later choice: it stays on the table until something is taken. That is the rule the build cards already follow.
- Patron favour stays automatic.

## A pick

Each pick shows three offers. Each offer is one gain worth one point, at today's exchange: +1 to a stat, or +10 max health. The three offers are drawn the way today's small offer is, so a character stays coherent:

1. **The calling.** The lead gain of a training path that leans to the character's profession or people. Paths taken before are likelier.
2. **The habit.** The lead gain of the path the character has taken most. With none taken yet, it's the path closest to the stats they already have.
3. **A turn.** Any other path's lead gain, so a build can change course.

"Lead gain" means a path's biggest single gain. For example, the Duelist's is Dexterity and the Juggernaut's is max health. If two offers would show the same gain, the turn is redrawn.

**The rare offer.** About one pick in eight (proposed 12%), the turn is replaced by a rare offer worth two points:
- double the gain (+2 to a stat, or +20 max health);
- or two different stats at +1 each, taken from one path (for example, Hunter: +1 Perception +1 Dexterity).

It is marked rare so UX can draw it apart. The roll is seeded per pick, so reopening never rerolls it.

**Taken paths** still count, as `trainingTaken` does today. A pick taken from a path counts for that path, so the calling and the habit keep following the build.

## The game, in numbers

- **What a level gives** doesn't change: 5 picks, so 5 points of gains.
- **The rare offer** adds about 0.6 points a level on average: 5 picks × 12% × 1 extra point.
- **What is lost** is free choice: a player can no longer pour every point into one stat. A pick offers it about two times in three: the calling, plus the habit once a build has formed.

I'll measure the playthrough simulator before and after and report the win-rate change. If the rare offer moves things beyond about a point, I'll bring its rate down.

## Saves

- **Unspent points.** An old save's unspent `statPoints` become pending picks, one each. The counter is the same, so nothing is lost.
- **Build cards.** A 5-point build card left on the table is dropped and redrawn as a pick.
- **Taken paths** (`trainingTaken`) are kept.

## The simulator and autoplay

Each pick takes the offer that raises the build's stat (`autoplay_build`'s `statToRaise`), else the calling. A rare offer is taken when it raises that stat. This is today's training policy, applied one point at a time.

## For UX: the API (in `player_session_provider.dart`)

- **`int pendingStatPicks`**: how many picks are waiting. It is today's `statPoints`, renamed in the API only; the save field stays.
- **`Future<List<StatPickOffer>> ensureStatPick(Map<String, TrainingPath> paths)`**: the three offers of the next pick. They are drawn once and kept until one is taken; it returns an empty list when nothing is pending.
- **`Future<bool> takeStatPick(int index)`**: applies the chosen offer's gain (max health heals as much), spends one pick, counts the path, and draws the next pick on the following `ensureStatPick`.
- **`StatPickOffer`** has:
  - `pathId`;
  - `gains` (`Map<String, int>`, one or two entries);
  - `rare` (bool);
  - `points` (1, or 2 when rare).

  The path names and icons come from `training_paths.json`, as today.

The banner-choice layout is UX's. Once UX has moved to the picks API, the old entry points can go:
- `spendStatPoint`, the "Stat Points Available" panel, and the 5-point build cards;
- `ensureTraining` and `takeTraining`.

Until then they stay working, so nothing breaks between the two PRs.

## Knobs for the user

- **The rare offer's chance:** 12% proposed.
- **What it is:** double gain, or two stats from one path. Proposed: whichever the path's lead gains allow, half and half.
- **Max health per point:** stays +10.

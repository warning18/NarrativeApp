# The competent player (v1.564)

The playthrough simulator now has two player profiles (`SimPolicy` in
`lib/data/sim_policy.dart`):

- **naive**: the simulator as it always played. Every CI band
  (`boss_balance_test`, `clash_balance_test`, `qa_clan_power_50_test` and the
  rest) still uses it, so no band moves.
- **competent**: plays the choices between fights the way a good real player
  does. The simulator screen's runs now use it.

## What the competent player does differently

| Part | Naive (unchanged) | Competent |
|---|---|---|
| Gear | Wears a clan's gift or a shop's piece when its flat attack + armor beats the slot. Never wears loot, quest rewards or what a scene hands over. | Before every fight it wears the best loadout out of everything it owns: loot, quest rewards, scene grants, gifts, purchases. It weighs attack, armor, elemental damage and resists, uniques and set bonuses, keeps a set when the bonus beats a single upgrade, and respects stat requirements. |
| Shops | Spellbook, 2 potions per entry, the best piece per slot by attack + armor, the sage die for a caster. | Spellbook, potions up to 3 charges, the best die it may roll if it beats its own, gear one piece at a time by loadout gain, then the change on potions (up to 5). |
| Dice | The starting die, or the sage die (which wipes its skill faces). | Owns its signature die from the start, buys better ones and rolls the best die it owns, with its skills placed best. At the Skillwright it crafts a `skill_merges.json` recipe when the die gets better for it. |
| Clan offers | 25% of the time the clan it stands best with, otherwise the best gift, keeping to its main clan and allies. | Takes the gift that raises its power most. A tie (within 1 point) goes to the clan it stands closest to. It never takes a banner whose standing would turn its main clan or an ally Hostile. |
| Stat picks, skill faces, potions in a fight | Already planned (damage stat / Constitution / secondary shares, `simSkillScore` faces, drinks below 40% health) | Same |
| Companions | Not modelled by the simulator | Not modelled (since v1.567, see `companions-v1.567.md`) |

Both profiles record every offer: chapter, source, the banners offered, the
one taken and why. The run transcript prints these under "Clan offers", with
the gear worn, the die and the skills crafted.

## Measurement

These are 10 runs per profile on the same plan and seed (seed 7; the five
professions twice, 5 random walks and 5 favour-good walks; the full gamedata
with `skill_merges`). Encounter win rate means an encounter won within its 3
tries. "1st" is the share won on the first try.

| Chapter | Naive encounters | Naive win | Naive 1st | Competent encounters | Competent win | Competent 1st |
|---|---|---|---|---|---|---|
| 1 | 23 | 0.96 | 0.96 | 23 | 0.96 | 0.96 |
| 2 | 59 | 0.93 | 0.76 | 59 | 1.00 | 0.98 |
| 3 | 110 | 0.69 | 0.55 | 151 | 0.90 | 0.80 |
| 4 | 97 | 0.64 | 0.44 | 102 | 0.89 | 0.69 |
| 5 | 106 | 0.59 | 0.44 | 118 | 0.86 | 0.70 |
| 6 | 76 | 0.61 | 0.24 | 85 | 0.88 | 0.35 |
| 7 | 18 | 0.67 | 0.17 | 15 | 0.87 | 0.47 |
| 8 | 41 | 0.54 | 0.22 | 48 | 0.90 | 0.52 |

Per run, on average:

| | Naive | Competent |
|---|---|---|
| Final level | 20.5 | 22.9 |
| Fights won / lost | 36.0 / 66.2 | 54.2 / 32.9 |
| Gear slots filled (of 5) | 3.6 | 5.0 |
| Potions drunk | 5.7 | 8.2 |
| Offers taken | 44.3 | 56.0 |

- **Gear:** the competent player fills all five slots. Loot and rewards that
  the naive player never wore make up most of it: `void_banner`,
  `boots_tearwalker`, `plate_emberproof` and `tear_glass_blade` turn up in
  almost every run.
- **Dice:** 3 of the 4 competent caster runs bought a better die (tearglass
  twice, ossuary once). The non-casters kept their starting die: no die they
  could afford beat it. Three Skillwright merges were crafted
  (`wrath_of_dawn` twice, `bastion_of_stone`). The naive player's only
  possible die change is the sage die.
- **Offers:** the competent player takes signs much more often (386 of 560
  gifts, against 177 of 443 for naive) and skills less often (47 against 119):
  once the die's open faces are full, a skill adds little. 120 picks were
  ties settled toward the closest clan. One banner was turned down because it
  would have made a needed clan Hostile.

**Reading:** chapters 3 to 8 are where the competent player is much stronger
(about 0.88 against about 0.62). Those chapters are easy for a real player
who wears the loot and plays the offers well. The naive CI bands understate
how easy they are.

## How it was run

A one-off `flutter test` harness that was not committed. It called
`simulatePlaythroughs(..., seed: 7, policy: SimPolicy.naive / competent)` on
the plan above and summed `byChapter` (fights, won, firstTry) and the
summaries' `offerPicks`, `gear`, `die` and `merged`. It takes about 7 seconds
for both profiles.

## Limits

- The Hostile guard reads "Hostile" as standing below Resented. It is checked
  at every pick rather than only before the clan's next gate, which is
  stricter than the rule.
- Gear alignment (`meetsItemAlignment`) is not checked, as in the naive walk.
- The simulator has one die in play (no cup of several dice), and it has no
  companions.

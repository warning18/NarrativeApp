# Chapter goals: wording

For Core's chapter goals (`assets/gamedata/chapter_goals.json`, chapters 4 to 8, three optional goals each). Wording only: nothing is wired. EN and FR, each goal one short line (about 40 characters at most, one line with a tick on a phone), French typography applied.

## Keys (proposed, to agree with Core)

| key | for | falls back to |
|---|---|---|
| `chapter_goal_<kind>` | the generic line of a goal kind: `rounds`, `weakness`, `first_try`, `no_potion` | none (always written) |
| `chapter_goal_<kind>_ch<N>` | the line flavoured to chapter N (4 to 8) | `chapter_goal_<kind>` |
| `chapter_chest_<tier>` | the chest's name: `wooden`, `iron`, `silver`, `gold` | none |
| `chapter_chest_line` | one line when the chapter's chest opens | none |
| `chapter_chest_line_ch<N>` | the same flavoured to chapter N | `chapter_chest_line` |

`{n}` in a `rounds` line is the round count (`value` in the data). The `weakness` goal reads "a win in which a die hit the foe's weakness". `no_potion` means a close fight won without a potion (the hero ends under half health), so it has one line for every chapter. `first_try` is used only in chapter 7 (any claimant duel: Tallis, Morrow or Vane) and chapter 8 (the Sovereign, not the Tear Herald), so only those two chapters have a flavoured line. The `chapter_goal_<kind>_ch<N>` rows below are the ones Core uses.

## The four kinds, generic

| kind | EN | FR |
|---|---|---|
| `rounds` | Win in {n} rounds or fewer | Gagner en {n} tours ou moins |
| `weakness` | Win using a die on the foe’s weakness | Gagner avec un dé sur le point faible de l’ennemi |
| `first_try` | Beat the boss on the first try | Vaincre le chef du premier coup |
| `no_potion` | Win at under half health, no potion | Gagner sous la moitié des PV, sans potion |

## By chapter

### Chapter 4: The Hollow Court

| kind | EN | FR |
|---|---|---|
| `rounds` | Win in {n} rounds, before the flood | Gagner en {n} tours, avant la crue |
| `weakness` | Turn a robed foe’s weakness against it | Viser le point faible d’un ennemi en robe |

### Chapter 5: The Shroud’s Truth

| kind | EN | FR |
|---|---|---|
| `rounds` | Win in {n} rounds, before the frost sets | Gagner en {n} tours, avant que le givre ne prenne |
| `weakness` | Crack a Reliquary guard on its weakness | Briser un garde du Reliquaire sur son point faible |

### Chapter 6: The Hollow Shore

| kind | EN | FR |
|---|---|---|
| `rounds` | Win in {n} rounds, before the glass wakes | Gagner en {n} tours, avant l’éveil du verre |
| `weakness` | Use a reflection’s weakness against it | Retourner contre lui le point faible d’un reflet |

### Chapter 7: The Lantern Throne

| kind | EN | FR |
|---|---|---|
| `rounds` | Win in {n} rounds, before the Hall burns | Gagner en {n} tours, avant que la Salle ne brûle |
| `weakness` | Hit a claimant’s guard where it is weak | Frapper un prétendant sur son point faible |
| `first_try` | Beat the rival claimant on the first try | Vaincre le prétendant rival du premier coup |

### Chapter 8: Beyond the Tear

| kind | EN | FR |
|---|---|---|
| `rounds` | Win in {n} rounds; the tear is widening | Gagner en {n} tours : la déchirure s’élargit |
| `weakness` | Hit a faceless foe where it is weak | Frapper un ennemi sans visage sur son point faible |
| `first_try` | Beat the Sovereign on the first try | Vaincre le Souverain du premier coup |

## The chest

| tier | EN | FR |
|---|---|---|
| `wooden` | Wooden Chapter Chest | Coffre de chapitre en bois |
| `iron` | Iron Chapter Chest | Coffre de chapitre en fer |
| `silver` | Silver Chapter Chest | Coffre de chapitre en argent |
| `gold` | Gold Chapter Chest | Coffre de chapitre en or |

Generic end-of-chapter line: EN “A chest for the chapter’s work, whatever it cost you.” / FR « Un coffre pour le travail du chapitre, quel qu’en ait été le prix. ».

By chapter:

| chapter | EN | FR |
|---|---|---|
| 4 | The Court’s ledger kept a share for whoever came back. | Le registre de la Cour gardait une part pour qui reviendrait. |
| 5 | The Reliquary’s frost gave one thing back. | Le givre du Reliquaire a rendu une chose. |
| 6 | The sea kept the White Fleet’s dead and returned its coin. | La mer a gardé les morts de la Flotte Blanche et rendu sa monnaie. |
| 7 | The Houses pay their debts, in their own time. | Les Maisons paient leurs dettes, à leur heure. |
| 8 | Whatever the tear took, it left a share. | Ce que la déchirure a pris, elle en a laissé une part. |

## Ready to paste into `lib/l10n/app_strings.dart`

Next to the other chapter strings; the `\u00a0` escapes are the no-break spaces. Core adds the keys it reads, in the same PR as the code, so no unused key lands first.

```dart
  // Chapter goals and the chapter chest (Narrative wording; keys per docs/narrative/chapter-goals-wording.md).
  'chapter_goal_rounds': {
    AppLanguage.en: 'Win in {n} rounds or fewer',
    AppLanguage.fr: 'Gagner en {n} tours ou moins',
  },
  'chapter_goal_weakness': {
    AppLanguage.en: 'Win using a die on the foe’s weakness',
    AppLanguage.fr: 'Gagner avec un dé sur le point faible de l’ennemi',
  },
  'chapter_goal_first_try': {
    AppLanguage.en: 'Beat the boss on the first try',
    AppLanguage.fr: 'Vaincre le chef du premier coup',
  },
  'chapter_goal_no_potion': {
    AppLanguage.en: 'Win at under half health, no potion',
    AppLanguage.fr: 'Gagner sous la moitié des PV, sans potion',
  },
  'chapter_goal_rounds_ch4': {
    AppLanguage.en: 'Win in {n} rounds, before the flood',
    AppLanguage.fr: 'Gagner en {n} tours, avant la crue',
  },
  'chapter_goal_weakness_ch4': {
    AppLanguage.en: 'Turn a robed foe’s weakness against it',
    AppLanguage.fr: 'Viser le point faible d’un ennemi en robe',
  },
  'chapter_goal_rounds_ch5': {
    AppLanguage.en: 'Win in {n} rounds, before the frost sets',
    AppLanguage.fr: 'Gagner en {n} tours, avant que le givre ne prenne',
  },
  'chapter_goal_weakness_ch5': {
    AppLanguage.en: 'Crack a Reliquary guard on its weakness',
    AppLanguage.fr: 'Briser un garde du Reliquaire sur son point faible',
  },
  'chapter_goal_rounds_ch6': {
    AppLanguage.en: 'Win in {n} rounds, before the glass wakes',
    AppLanguage.fr: 'Gagner en {n} tours, avant l’éveil du verre',
  },
  'chapter_goal_weakness_ch6': {
    AppLanguage.en: 'Use a reflection’s weakness against it',
    AppLanguage.fr: 'Retourner contre lui le point faible d’un reflet',
  },
  'chapter_goal_rounds_ch7': {
    AppLanguage.en: 'Win in {n} rounds, before the Hall burns',
    AppLanguage.fr: 'Gagner en {n} tours, avant que la Salle ne brûle',
  },
  'chapter_goal_weakness_ch7': {
    AppLanguage.en: 'Hit a claimant’s guard where it is weak',
    AppLanguage.fr: 'Frapper un prétendant sur son point faible',
  },
  'chapter_goal_first_try_ch7': {
    AppLanguage.en: 'Beat the rival claimant on the first try',
    AppLanguage.fr: 'Vaincre le prétendant rival du premier coup',
  },
  'chapter_goal_rounds_ch8': {
    AppLanguage.en: 'Win in {n} rounds; the tear is widening',
    AppLanguage.fr: 'Gagner en {n} tours\u00a0: la déchirure s’élargit',
  },
  'chapter_goal_weakness_ch8': {
    AppLanguage.en: 'Hit a faceless foe where it is weak',
    AppLanguage.fr: 'Frapper un ennemi sans visage sur son point faible',
  },
  'chapter_goal_first_try_ch8': {
    AppLanguage.en: 'Beat the Sovereign on the first try',
    AppLanguage.fr: 'Vaincre le Souverain du premier coup',
  },
  'chapter_chest_wooden': {
    AppLanguage.en: 'Wooden Chapter Chest',
    AppLanguage.fr: 'Coffre de chapitre en bois',
  },
  'chapter_chest_iron': {
    AppLanguage.en: 'Iron Chapter Chest',
    AppLanguage.fr: 'Coffre de chapitre en fer',
  },
  'chapter_chest_silver': {
    AppLanguage.en: 'Silver Chapter Chest',
    AppLanguage.fr: 'Coffre de chapitre en argent',
  },
  'chapter_chest_gold': {
    AppLanguage.en: 'Gold Chapter Chest',
    AppLanguage.fr: 'Coffre de chapitre en or',
  },
  'chapter_chest_line': {
    AppLanguage.en: 'A chest for the chapter’s work, whatever it cost you.',
    AppLanguage.fr: 'Un coffre pour le travail du chapitre, quel qu’en ait été le prix.',
  },
  'chapter_chest_line_ch4': {
    AppLanguage.en: 'The Court’s ledger kept a share for whoever came back.',
    AppLanguage.fr: 'Le registre de la Cour gardait une part pour qui reviendrait.',
  },
  'chapter_chest_line_ch5': {
    AppLanguage.en: 'The Reliquary’s frost gave one thing back.',
    AppLanguage.fr: 'Le givre du Reliquaire a rendu une chose.',
  },
  'chapter_chest_line_ch6': {
    AppLanguage.en: 'The sea kept the White Fleet’s dead and returned its coin.',
    AppLanguage.fr: 'La mer a gardé les morts de la Flotte Blanche et rendu sa monnaie.',
  },
  'chapter_chest_line_ch7': {
    AppLanguage.en: 'The Houses pay their debts, in their own time.',
    AppLanguage.fr: 'Les Maisons paient leurs dettes, à leur heure.',
  },
  'chapter_chest_line_ch8': {
    AppLanguage.en: 'Whatever the tear took, it left a share.',
    AppLanguage.fr: 'Ce que la déchirure a pris, elle en a laissé une part.',
  },
```

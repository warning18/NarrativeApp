# Numbers in descriptions: placeholders

Core, v1.462 (for Narrative). In the code; no text uses them yet.

A description that writes a number ("+2 armor", "times 1.6") goes stale the
day the number changes, as v1.458 showed (every fight number divided by 5,
the texts still saying the old ones). A description can now name the
number instead: `{armor}`, `{dodge}%`, `{multiplier}`. The game fills it from
the entry's own field when the text is shown, in English and in French.

## The rules

- A placeholder is a name in braces, letters and digits only: `{heal}`,
  `{duration2}`. Write the unit around it as usual: `+{dodge}% dodge`,
  `+{dodge} % d’esquive`.
- Whole numbers show without decimals; a fraction with at most two
  (`1.6`, `1.88`), with a comma in French (`1,6`).
- A share written as a fraction in the data (0.5) shows as a percent (50):
  write `{splash}%`, never `{splash}`.
- **A name the entry has no number for stays on screen as written**, braces
  and all (`{heall}`), and `test/text_placeholders_test.dart` fails on it.
  So does a name the entry lacks: a Damage spell has no `{heal}`.
- The data editor keeps the placeholders; only what the player reads is
  filled. The French field may use the same names as the English one.

Where it is resolved (every screen that shows these texts goes through one
of them): `SpellSpec.descriptionFor`, `SetBonusTier.descriptionFor`,
`SpecVariantInfo.textFor` / `voiceFor`, and for raw records
`localizedDbProvider`, `loadedGameDb` and the offer tables
(`withResolvedPlaceholders`, `lib/data/description_text.dart`).

## spells.json (`description`, `description_fr`)

| Placeholder | Field | Note |
|---|---|---|
| `{amount}` | `amount` | any spell |
| `{damage}` | `amount` | Damage spells only |
| `{heal}` | `amount` | Heal spells only |
| `{block}` | `amount` | Block spells only |
| `{multiplier}` | `damageMultiplier` | Damage spells only |
| `{mana}` | `manaCost` | |
| `{duration}` | `statusDuration` | spells with a status |
| `{magnitude}` | `statusMagnitude` | spells with a status (Poison's damage, Weaken's %) |

Example, Arcane Bolt (amount 1, ×1.6, cost 2):
"A bolt of raw force hurled at one enemy: your own damage plus {damage},
times {multiplier}. Grows with Intelligence." → "...your own damage plus 1,
times 1.6..." / « ...vos propres dégâts plus {damage}, fois {multiplier} » →
« ...plus 1, fois 1,6 ».

## item_sets.json (each bonus tier: `description`, `descriptionFr`)

The numbers are the tier's own (the two-piece tier's armor, not the
three-piece one's). A tier without a bonus has it at 0.

| Placeholder | Field |
|---|---|
| `{pieces}` | `pieces` |
| `{armor}` | `armor` |
| `{attack}`, `{damage}` | `attackDamage` |
| `{crit}` | `critChance` (%) |
| `{dodge}` | `dodgeChance` (%) |
| `{thorns}` | `thorns` |
| `{lifesteal}` | `lifestealPercent` (%) |
| `{mana}` | `manaOnHit` |

Example, the Harborwatch Kit's two pieces (armor 1, dodge 5): "Two pieces:
+{armor} armor and +{dodge}% dodge — the watch learned to keep its feet on
wet stone." → "Two pieces: +1 armor and +5% dodge — ..." (the text says +2
today). Three pieces: "+{attack} attack and +{crit}% critical chance" →
"+1 attack and +8% critical chance" (it says +4).

## skills.json (`description`, `description_fr`)

Only the fields the record has are offered.

| Placeholder | Field | Note |
|---|---|---|
| `{damage}` | `damageMod` | the flat damage added |
| `{multiplier}` | `damageMultiplier` | |
| `{heal}` | `healAmount` | |
| `{health}` | `healthMod` | |
| `{block}` | `blockAmount` | |
| `{cost}` | `cost` | |
| `{mana}` | `manaGain` | |
| `{rolls}` | `bonusRolls` | |
| `{strikes}` | `strikes` | |
| `{targets}` | `splashTargets` | |
| `{splash}` | `splashShare` | as a percent: `{splash}%` |
| `{armorShare}` | `damageFromArmor` | as a percent |
| `{rally}` | `rallyPercent` | % |
| `{charge}` | `chargeMultiplier` | |
| `{guard}` | `guardMultiplier` | |
| `{duration}`, `{magnitude}` | `statusDuration`, `statusMagnitude` | the first status |
| `{duration2}`, `{magnitude2}` | `statusDuration2`, `statusMagnitude2` | the second status |
| `{reflect}`, `{reflectDuration}` | `reflectMagnitude`, `reflectDuration` | |

Example, a cleave (damageMod 2, splashShare 0.5): "+{damage} damage, and
{splash}% of it to every other enemy." → "+2 damage, and 50% of it to every
other enemy."

## spec_variants.json (`text`, `text_fr`, `voice`, `voice_fr`)

The variants' numbers are not in the file but in the rules
(`SpecMods`, `lib/combat/spec_variants.dart`), so the placeholders read them
there: they follow any change to the rules. Every line may use `{rank}`
(rank II's "half again": 50).

| Variant | Placeholders |
|---|---|
| `brig_born_berserker` | `{heal}` 10 (% of max health a kill heals) |
| `anvil_deaf_briar_guard` | `{share}` 50 (% of each stopped blow sent back) |
| `order_lantern_vanguard` | `{heal}` 30, `{baseHeal}` 20 (% of the heavy blow healed) |
| `candlebearers_long_vigil` | `{heal}` 7, `{baseHeal}` 5 (% of max health a round) |
| `ember_sisters_ashen_hand` | `{cleanse}` 2, `{baseCleanse}` 1 |
| `cantors_beacon` | `{multiplier}` 1.88, `{baseMultiplier}` 1.5 |
| `tribunal_censer_mage` | `{round}` 4 (the round from which the Well may refill) |
| `scorched_choir_burden_bearer` | `{multiplier}` 2.5, `{baseMultiplier}` 2 |
| `spire_fallen_burden_bearer` | `{heal}` 25 (%) |
| `keyholders_tempest_toll` | `{mana}` 1 (the extra discount) |
| `whisper_ledger_tempest_toll`, `whisper_ledger_ledger_knife` | `{gold}` 3 |
| `moss_choir_fever_blade` | `{heal}` 20 (% of the Rot) |
| `reliquary_thieves_relicbreaker` | `{mana}` 2, `{baseMana}` 1 |
| `ember_sisters_relicbreaker` | `{heal}` 3 (%) |
| `brig_born_corsairs_eye` | `{gun}` 15 (%) |
| `scaffolders_trapwright` | `{targets}` 2 |
| `returned_fen_guide` | `{faces}` 2 |

Examples: "Your spells cost {mana} less again." → "Your spells cost 1 less
again."; "Each critical hit gives {mana} mana." → "Each critical hit gives 2
mana."; "A kill heals you {heal}% of your health." → "...10% of your
health." A variant not in the table has only `{rank}`; ask Core for a
number it needs.

## Not covered

ship_parts.json (its numbers stay as written), and every other file. The
signs, titles and clan boons already show their numbers from the effects
(`sign_fx_*` strings with `{v}`), and so do perks.

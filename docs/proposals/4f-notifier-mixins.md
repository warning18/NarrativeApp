# 4f step 2: the session notifier split by feature

Core, 2026-11-04. Docs only. The manager reads this before anything is built.

Step 1 (v1.804) moved the `PlayerSession` model into the part file
`player_session_model.dart`. What is left in `player_session_provider.dart`
is `PlayerSessionNotifier`: about 4,230 lines, 189 members, 151 of them
public.

## 1. Why mixins, not extensions

- `StateNotifier.state` is `@protected`. An extension body is not a subclass
  member, so every `state = ...` inside one would raise
  `invalid_use_of_protected_member`. Analyze would fail, or need an ignore on
  each line.
- A mixin `on` the notifier's own base class may use `state`, the same as
  the class itself.

## 2. The layout

All new files are `part` files of `player_session_provider.dart`. The
importers don't change, and private names stay reachable.

```dart
// player_session_provider.dart
abstract class _SessionNotifierBase extends StateNotifier<PlayerSession> {
  _SessionNotifierBase(super.state);
  // what the features share: _persist, _removeAlly, startNewGame and the
  // declarations of section 3
}

class PlayerSessionNotifier extends _SessionNotifierBase
    with _OfferActions, _PoliticsActions, _QuestActions, _ShopForgeActions,
        _AlliesCampActions, _RoadTimeActions, _SkillsCombatActions {
  // the core: loading, saving, a new game, New Game+, choice effects, deeds
}
```

| Part file | Mixin | What it holds | Lines (about) |
|---|---|---|---|
| (stays) | the class | constructor, load and save, new game and New Game+, `applyChoiceEffects`, deeds | 620 |
| `session_offers.dart` | `_OfferActions` | offers, risky gifts, stat picks, rerolls and bans, suitors, titles, the first banner, Titan's blood | 860 |
| `session_politics.dart` | `_PoliticsActions` | standing, marks, relations, the coast's events, sieges, the throne, betrayals, the hunter | 470 |
| `session_quests.dart` | `_QuestActions` | story flags, losing an ally, quests, contracts | 250 |
| `session_shop_forge.dart` | `_ShopForgeActions` | dice, buying and selling, retreat, crafting, the forge, smithing, tomes, equipping | 445 |
| `session_allies_camp.dart` | `_AlliesCampActions` | recruiting and the bench, houses, town additions, zones, ships and ports, companions' kit, healing | 515 |
| `session_road_time.dart` | `_RoadTimeActions` | time, rest, achievements, unlocks, NPCs, what has been seen, road steps, provisions, sellswords, the temple | 520 |
| `session_skills_combat.dart` | `_SkillsCombatActions` | dice-face skills, branches, merges, stats for debug, potions, mana, level-ups, a fight's result, permadeath | 560 |

`PermadeathResult`, `campRollsProvider`, `roadWardsProvider` and
`playerSessionProvider` stay where they are.

## 3. What each mixin must declare

A mixin only sees its `on` type. A member it calls from another feature must
therefore be declared abstract: in the base when two or more features share
it, otherwise in the calling mixin. A script found these references; the
build re-checks them against the analyzer.

- **All seven:** `state`, which the base inherits, and `_persist()`, which is in the base.
- **`_OfferActions`:** `_politicsChapter`, `_settleExpiredSieges`,
  `_siegeRandom`, `_syncHeld` (politics), `_withTomePicks` (skills and combat).
- **`_PoliticsActions`:** `_removeAlly` (base), `_withTitles` (offers),
  `checkAchievements` (road and time).
- **`_QuestActions`:** `_removeAlly`, `_levelCharges`, `_withTitles`,
  `_healAndGrowAlliesOnLevelUp`, `_withPatronGains`.
- **`_ShopForgeActions`:** `_has` (offers), `_withTomePicks`.
- **`_AlliesCampActions`:** `completeQuest`, `unlockContent`, `buyItem`,
  `equipItem`, `applyCombatResult`, `assignSkillToDiceFace`,
  `clearDiceFaceSkill`. Several of these may only be mentions in doc
  comments, which need no declaration; the build prunes them.
- **`_RoadTimeActions`:** `healPartyToFull` (allies and camp),
  `changeStanding` (politics).
- **`_SkillsCombatActions`:** `startNewGame`, `_starterAssignmentsByDie`
  (base), `_levelCharges`, `_levelOffers`, `_withFirstBanner`,
  `startingOffersFor` (offers), `_politicsChapter`, `completeQuest`.

That is about 25 one-line declarations in all. Fields the methods share,
such as `_pendingWrite` and `_loaded`, move to the base.

## 4. How the PR proves nothing changed

1. **Every line kept.** A line-count diff over the old file and the new ones
   lists only these additions:
   - the `part` lines and the `part of` lines;
   - the mixin heads and their closing braces;
   - the base class;
   - the abstract declarations.

   No method body changes. A method's doc comment travels with it.
2. **Analyzer clean, with no new `ignore` comments.** `grep -c "// ignore"`
   is the same before and after.
3. **Tests.** All session and save tests, the offers, camp, forge and
   politics tests, and every file that names `PlayerSessionNotifier`. CI
   runs the full suite.
4. **Simulator unchanged.** I run a seeded batch before and after
   (`SIM_GOALS`, `SIM_RUNS`, `SIM_SEED`, `SIM_OUT`) and require the output
   files to be byte-identical (`cmp`). The simulator drives the same session
   rules.
5. **Public API unchanged.** A list of the public member names of
   `PlayerSessionNotifier` is the same before and after. Tests and screens
   call them through `playerSessionProvider.notifier`, and that type doesn't
   change.

## 5. Risk

**Medium.** No logic moves between methods. The risks are mechanical:

- **Name clashes.** Two mixins defining the same private name, or a mixin
  shadowing a base member. The analyzer reports these as conflicts.
- **Override order.** `@override` members (`dispose`, `state`) stay in the
  class, so linearization changes nothing. Mixins add only new members.
- **Merge pain.** This is the most-edited Core file, and every other branch
  touching it conflicts afterwards. It should be built and merged the same
  day, in a window when no other open PR touches the file.

It should be one PR, about 4,200 lines moved. Splitting it into two PRs would
halve the review size but double the window in which other branches conflict
with it.

# Fight hooks: fields for UX

Core's hooks for the Tower fight panels and the skill effects. They carry
information only. No rule reads them back, so listening never changes a fight.

## Rival flag

- `towerFightIsRival(TowerRun run)` (`lib/screens/tower/tower_fight_launcher.dart`)
  is true when the floor's event is `TowerEventKind.rival` (win within
  `towerRivalRounds`). It is false on every other floor and when floor events
  are off.
- The launcher passes it as `FightScreen(rival: ...)`. That parameter comes
  from UX's #1187. Until #1187 is on main, the call is left commented at the
  `HOOKUP(#1187)` mark in the launcher. Once #1187 lands, uncomment that line.
  UX reads `widget.rival` in the fight's part files.
- Story duels have no flag of their own. The turned companions, the legate's
  champion, the masked penitent and the claimants sit in `soloOnlyEnemyIds`
  (`lib/combat/combat_engine.dart`), together with the bosses. They are only
  grouped there under a comment, so no story fight sets `rival`.

## Events

Subscribe through `fightEventsProvider` (`lib/providers/fight_events_provider.dart`,
which re-exports `lib/combat/fight_events.dart`):

```dart
final events = ref.read(fightEventsProvider);
final sub = events.hits.listen((FightHitEvent e) { ... });
final sub2 = events.ticks.listen((FightStatusTickEvent e) { ... });
// cancel both in dispose
```

Inside the fight's part files, use `_events`. Both streams are synchronous
broadcast streams. An event fires right after the fight has applied the hit,
in the same frame, before the screen rebuilds. Switching effects off does not
stop the events. A quick-resolved fight (settled on the setup screen) is not
played round by round, so it publishes nothing. With no listener, the fight works
nothing out.

### `FightTarget` (target, source)

- `side`: `FightSide.foe` or `FightSide.party`.
- `index`: the target's place among the foes (0 is the first), or in the party
  (0 is the hero).
- `id`: `enemy_0`, `enemy_1`... for a foe. `player` or the companion's id for
  the party.
- `isFoe`, `isPlayer` (the hero himself).

### `FightHitEvent`: one hit

| field | meaning |
|---|---|
| `kind` | `strike` (a party Attack or Skill face on its target), `splash` (a Cleave, Volley or chain share on another foe), `spell` (a Damage spell, one event per foe), `foeMove` (a foe's move on a party member) |
| `target`, `source` | `FightTarget` |
| `amount` | health taken off the target (0: blocked, absorbed or dodged) |
| `power` / `tier` | `vfxPowerFor` / `vfxTierFor` (skill_vfx.dart), worked out from the same inputs as the fight's own effect: `light`, `normal`, `strong`, `mighty` |
| `crit` | see below |
| `skillId` | the Skill face's linked skill, the spell id, or the foe's move id. Null for a plain Attack face, `''` for a foe's plain attack |
| `element` | `None` (physical), `Fire`, `Ice`, `Water`, `Wind`, `Earth`, `Electricity`, `Light`, `Void`. A foe's plain attack is `None`. Poison is a status, not an element: you see it through the skill id and the ticks |
| `blows` | a multi-blow skill's blows (Gale Cut: 3, published as one hit with their total); 1 otherwise |
| `dodged` | a `foeMove` the member dodged |
| `round` | the round it landed in (1 is the first) |

**Crit** is the engine's own critical, `PlayerActionResult.isCritical`: the roll
from `criticalChanceFor` at Confirm, or the guaranteed critical of a Momentum
surge. A splash carries its strike's crit. Spells and foes' moves never crit,
because the engine rolls no crit for them.

Not published yet: duo techniques, the Watchfire and Censer burns, element
reaction bonuses, thorns and wards sent back, Pain's self-hit. Ask Core if
you need one of them.

### `FightStatusTickEvent`: one status tick

| field | meaning |
|---|---|
| `target` | `FightTarget` |
| `amount` | health the tick took |
| `status` / `statusId` | `StatusEffectType.poison` / `'poison'` |
| `round` | the round |

Poison is the only status that deals damage each round. The engine has no
burn status (`StatusEffectType` holds poison, stun and weaken). A burn added
later would tick through this same event. When the ticks fire:

- a foe's poison ticks at the start of its own turn, after the party's faces;
- a party member's poison ticks at the start of the round, before the roll.

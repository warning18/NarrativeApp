# `unawaited_futures`: the sites where a Future is started and dropped

Item 5 of `cleanup-improvements.md`. Generated with the `unawaited_futures` lint on (`flutter analyze`, v1.696); 47 sites. For each, the owner says either **deliberate** (wrap the call in `unawaited(...)` from `dart:async`: no behaviour change) or **missing await** (add `await` or handle the error: a fix with a test, not a cleanup). Nothing is changed in code yet.

> **Status (Cleanup, main `bcf73433`):** released by the user. Re-measured: 45 sites (the list below is the v1.696 one, kept for the history). I read every site: all 45 are fire-and-forget on purpose, so each is wrapped in `unawaited(...)` and the lint is on. None looks like a missing `await`:
> - 3 are `Map.remove` in a `finally` whose removed value is the Future itself (`elevenlabs_tts_provider.dart`, `chart_map_painter.dart`): nothing to wait for.
> - 6 start a persist whose state change already happened synchronously (`consumeItem`, `setMana`, `_finishFight`, `_take`, in `fight_*` and `journey_screen.dart`): the same calls are not awaited in the 12 non-async call sites either.
> - 28 are `showImmersiveNotice` / `showDialog` / `showChapterCard` / `showLevelUpDialog` / `showOfferIfWaiting`: a notice or a progress dialog that must not hold the caller (an `await` would change when the next line runs). `road_panel.dart:43` is the one to look at: its camp branch awaits `showCampFateDie`, the other branch does not wait for the notice, and `resting.state = false` runs in `finally` right away; awaiting would keep `resting` true until the notice closed, a behaviour change, so it stays as is.
> - 8 are in tests that pump the clock by hand.
> Owners (UX-2: screens and widgets; Core: providers, `fight_*`): a site you want awaited instead is a fix with its own test, not part of the cleanup; say which and it comes out of the PR.

| Where | The call | Owner | Decision (deliberate / missing await) |
|---|---|---|---|
| `lib/providers/elevenlabs_tts_provider.dart:318` | `_recording.remove(file.path);` | Core | |
| `lib/screens/expedition_screen.dart:364` | `showImmersiveNotice(context,` | Core/UX | |
| `lib/screens/fight/fight_actions.dart:355` | `ref.read(playerSessionProvider.notifier).consumeItem(scrollItemId);` | Core/UX | |
| `lib/screens/fight/fight_actions.dart:358` | `ref.read(playerSessionProvider.notifier).setMana(_mana);` | Core/UX | |
| `lib/screens/fight/fight_actions.dart:368` | `_finishFight(won: true);` | Core/UX | |
| `lib/screens/fight/fight_rewards.dart:55` | `notifier.setMana(0);` | Core/UX | |
| `lib/screens/fight/fight_rewards.dart:441` | `showLevelUpDialog(context, ref, newLevel: newLevel);` | Core/UX | |
| `lib/screens/fight/fight_rewards.dart:443` | `showOfferIfWaiting(context, ref);` | Core/UX | |
| `lib/screens/fight/fight_rounds.dart:646` | `ref.read(playerSessionProvider.notifier).setMana(_mana);` | Core/UX | |
| `lib/screens/fight/fight_rounds.dart:681` | `_finishFight(won: true);` | Core/UX | |
| `lib/screens/harbor_screen.dart:102` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/harbor_screen.dart:177` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/harbor_screen.dart:764` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/journey_screen.dart:1476` | `_take(taken, steps[taken]);` | Core/UX | |
| `lib/screens/playthrough_simulator_screen.dart:3329` | `showDialog<void>(` | Core/UX | |
| `lib/screens/settings_screen.dart:872` | `showDialog<void>(` | Core/UX | |
| `lib/screens/shop_detail_screen.dart:445` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/shop_detail_screen.dart:670` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/skills/skill_sheet.dart:93` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/story_graph_screen.dart:542` | `showDialog<void>(` | Core/UX | |
| `lib/screens/story_player_screen.dart:310` | `showChapterCard(context,` | Core/UX | |
| `lib/screens/story_player_screen.dart:486` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/story_player_screen.dart:1319` | `showImmersiveNotice(context,` | Core/UX | |
| `lib/screens/story_player_screen.dart:3600` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/story_player_screen.dart:4208` | `showImmersiveNotice(` | Core/UX | |
| `lib/screens/story_player_screen.dart:4257` | `showImmersiveNotice(` | Core/UX | |
| `lib/widgets/camp_travel.dart:141` | `showImmersiveNotice(context, icon: Icons.hiking, message: walkNotice);` | UX | |
| `lib/widgets/chart_map_painter.dart:817` | `_skinsPending.remove(key);` | UX | |
| `lib/widgets/dice_smithing_sheet.dart:299` | `showImmersiveNotice(` | UX | |
| `lib/widgets/narration_recording_dialogs.dart:36` | `showDialog<void>(` | UX | |
| `lib/widgets/party_actions.dart:48` | `showImmersiveNotice(` | UX | |
| `lib/widgets/quest_turn_in.dart:39` | `showImmersiveNotice(` | UX | |
| `lib/widgets/quest_turn_in.dart:253` | `showLevelUpDialog(context, ref,` | UX | |
| `lib/widgets/road_panel.dart:43` | `showImmersiveNotice(` | UX | |
| `lib/widgets/save_slots_sheet.dart:109` | `showImmersiveNotice(context,` | UX | |
| `lib/widgets/save_slots_sheet.dart:142` | `showImmersiveNotice(context,` | UX | |
| `lib/widgets/save_slots_sheet.dart:153` | `showImmersiveNotice(context,` | UX | |
| `lib/widgets/ship_widgets.dart:194` | `showImmersiveNotice(` | UX | |
| `lib/widgets/shop_trade_sheets.dart:123` | `showImmersiveNotice(` | UX | |
| `test/clan_story_widgets_test.dart:179` | `showChapterCard(ctx,` | QA | |
| `test/moments_test.dart:18` | `announceAchievements(ctx, ['First Blood'], 'ACHIEVEMENT');` | QA | |
| `test/moments_test.dart:41` | `showChapterCard(ctx,` | QA | |
| `test/moments_test.dart:62` | `showChapterCard(ctx, number: '3', title: 'T', colour: Colors.orange);` | QA | |
| `test/ship_dynamics_panel_test.dart:187` | `container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.fr);` | QA | |
| `test/throne_widgets_test.dart:181` | `notifier.setOpenHandStage(2, data: container.read(clanDataProvider));` | QA | |
| `test/throne_widgets_test.dart:182` | `notifier.setSubclanMark('fishbasket_line', SubclanMark.friend,` | QA | |
| `test/ux_intro_anim_test.dart:74` | `.then((_) => introDone = true);` | QA | |

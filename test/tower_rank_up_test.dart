// The Tower's rank-up card (v2.4.0, brief 2 of docs/simulation/
// tower-roguelike-briefs.md, the user's option A): a skill card whose skill
// would sit on no face of the die in play is offered as a tier for the best
// skill on the die instead, so no pick is dead. The tier is the story's
// (applySkillTier, up to maxSkillTier): the hero keeps it, the fight screen
// and the bot's fights play it. The card on the offer screen, English and
// French, drawn with UX_SHOTS=<folder>.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/combat_engine.dart' show maxSkillTier;
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_session.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();
  final start =
      towerStart(seed: 5, raceId: 'human', professionId: 'warrior', data: data);
  final hero = towerHeroOf(start, data);
  final onDie = hero.diceSkillAssignments.values.first;

  TowerHeroView view({Set<String>? unlocked, Map<String, int>? tiers}) =>
      TowerHeroView(
        raceId: 'human',
        professionId: 'warrior',
        health: 30,
        maxHealth: 30,
        unlockedSkillIds: unlocked ?? hero.unlockedSkillIds,
        diceFaces: hero.diceFaces,
        diceSkillAssignments: hero.diceSkillAssignments,
        skillTiers: tiers ?? const {},
      );

  // A skill the hero has not learned, one the warrior may take.
  final newSkill = (data.skills.entries
          .where((e) =>
              !hero.unlockedSkillIds.contains(e.key) &&
              (e.value as Map)['manaCost'] == null &&
              ((e.value as Map)['restrictedProfessionID'] ?? '') == '' &&
              ((e.value as Map)['requiredSkillID'] ?? '') == '')
          .map((e) => e.key)
          .toList()
        ..sort())
      .first;

  group('which card a skill becomes', () {
    test('a skill with a free face stays a skill', () {
      // An empty die's open faces: nothing on them yet.
      final free = TowerHeroView(
        raceId: 'human',
        professionId: 'warrior',
        health: 30,
        maxHealth: 30,
        diceFaces: hero.diceFaces,
      );
      expect(towerRankUpFor(newSkill, free, data.skills), isNull);
    });

    test('a skill with no face to land on ranks up one on the die', () {
      // Every open face holds a skill the hero knows (the start's die is
      // full); a weaker new skill would sit on none of them.
      final full = view();
      final up = towerRankUpFor(newSkill, full, data.skills);
      if (up != null) {
        expect(full.diceSkillAssignments.values, contains(up));
      }
    });

    test('a skill at the last tier is not ranked up again', () {
      final maxed = view(tiers: {
        for (final id in hero.diceSkillAssignments.values) id: maxSkillTier,
      });
      expect(towerRankUpFor(newSkill, maxed, data.skills), isNull);
    });

    test('the best skill on the die is the one ranked up', () {
      // All the skills of the game known: none new can find a face.
      final all = {
        for (final MapEntry(:key, :value) in data.skills.entries)
          if (value is Map && value['manaCost'] == null) key,
      };
      final crowded = view(unlocked: all);
      final up = towerRankUpFor('heavy_attack', crowded, data.skills);
      if (up != null) {
        expect(crowded.diceSkillAssignments.values, contains(up));
      }
    });
  });

  test('a rank-up taken raises the tier, up to the last, and the fight sees it',
      () {
    // One card a floor: floors 1 to 4 each took a rank-up (one past the
    // last tier).
    final run = start.copyWith(floor: maxSkillTier + 2, taken: {
      ...start.taken,
      for (var f = 1; f <= maxSkillTier + 1; f++)
        f: TowerReward(TowerRewardKind.rankUp, id: onDie),
    });
    expect(run.heightCleared, maxSkillTier + 1);
    final ranked = towerHeroOf(run, data);
    expect(ranked.skillTiers[onDie], maxSkillTier);
    expect(towerSessionOf(run, data).skillTiers[onDie], maxSkillTier);
    // The copy the rebuild keeps has its own tiers.
    final copy = ranked.copy()..skillTiers[onDie] = 0;
    expect(ranked.skillTiers[onDie], maxSkillTier);
    expect(copy.skillTiers[onDie], 0);
  });

  test('a rank-up card is saved and read back', () {
    const card = TowerReward(TowerRewardKind.rankUp, id: 'heavy_attack');
    expect(TowerReward.fromJson(jsonDecode(jsonEncode(card.toJson()))), card);
  });

  test('the bot takes a rank-up as it takes a skill', () {
    final run = start.copyWith(status: TowerStatus.choosing, offer: [
      const TowerReward(TowerRewardKind.spell, id: 'x'),
      TowerReward(TowerRewardKind.rankUp, id: onDie),
    ]);
    expect(towerBotChoice(run), 1);
  });

  // The card as the player reads it, on the cards of a won floor.
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the rank-up card on the offer screen, English and French',
      (tester) async {
    // The app's fonts: the card's words at their real width.
    await tester.runAsync(loadAppFonts);
    for (final (lang, width) in [
      (AppLanguage.en, 412.0),
      (AppLanguage.fr, 360.0)
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      final run = start.copyWith(status: TowerStatus.choosing, offer: [
        TowerReward(TowerRewardKind.rankUp, id: onDie),
        if (data.dice.containsKey('flame_die'))
          const TowerReward(TowerRewardKind.die, id: 'flame_die'),
      ]);
      SharedPreferences.setMockInitialValues({
        'app_language': lang.name,
        'tower_run_v1': jsonEncode(run.toJson()),
        'tutorial_enabled': false,
      });
      usePhone(tester, Size(width, 780));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(appLanguageProvider.notifier).setLanguage(lang);
      final key = GlobalKey();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
              theme: buildAppTheme(container
                  .read(appPaletteProvider)
                  .schemeFor(Brightness.light)),
              home: const TowerFloorScreen()),
        ),
      ));
      Future<void> settle([int n = 30]) async {
        for (var i = 0; i < n; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // The localized tables load in the background: wait for the cards.
      for (var i = 0;
          i < 20 &&
              find.byKey(const Key('tower_card_0')).evaluate().isEmpty &&
              find.byType(LevelUpScreen).evaluate().isEmpty &&
              find.byKey(const Key('loot_sheet_take')).evaluate().isEmpty;
          i++) {
        await settle(5);
      }
      final level = find.byType(LevelUpScreen);
      if (level.evaluate().isNotEmpty) {
        Navigator.of(tester.element(level)).pop();
        await settle();
      }
      final take = find.byKey(const Key('loot_sheet_take'));
      if (take.evaluate().isNotEmpty) {
        await tester.tap(take);
        await settle();
      }
      final error = tester.takeException();
      final fr = lang == AppLanguage.fr;
      expect(find.text(fr ? 'Montée en rang' : 'Rank up'), findsOneWidget);
      expect(find.textContaining(fr ? ', rang 1' : ', rank 1'), findsOneWidget);
      expect(
          find.textContaining(
              fr ? 'Votre dé n’a plus de face libre' : 'Your die has no free'),
          findsOneWidget);
      if (shots != null) {
        Directory(shots).createSync(recursive: true);
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/tower-rank-up-${lang.name}-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      expect(error, isNull);
    }
  });
}

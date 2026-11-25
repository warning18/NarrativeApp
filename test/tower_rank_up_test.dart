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
import 'package:narrative_data_app/combat/dice_faces.dart' show isOpenSkillFace;
import 'package:narrative_data_app/data/sim_growth.dart' show simSkillScore;
import 'package:narrative_data_app/data/tower/tower_progress.dart';
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

  // #1147 (the user's call: only skills on the die): a rank-up names a
  // skill on the die in play, and the tier keeps that skill there when a
  // later skill card, or a die rolled afresh, places the die's skills again.
  group('a rank-up stays on the die (#1147)', () {
    double score(String id) =>
        simSkillScore(data.skills[id] as Map<String, dynamic>);
    // The skills that fight from a face (no mana skill), best first.
    final fighting = [
      for (final MapEntry(:key, :value) in data.skills.entries)
        if (value is Map<String, dynamic> &&
            ((value['damageMultiplier'] as num?) ?? 1) > 0)
          key,
    ]..sort((a, b) {
        final byScore = score(b).compareTo(score(a));
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    // The best of them not learned, the rest learned: the die is full, its
    // faces held by the next best, and the best outranks every one of them
    // (with no tier, it would push the weakest off its face).
    final stronger = fighting.first;
    final full = hero.copy()..unlockedSkillIds.addAll(fighting.skip(1));
    towerApplyReward(
        full, TowerReward(TowerRewardKind.skill, id: fighting.last), data);
    final placedIds = full.diceSkillAssignments.values.toSet();
    final weakest = (placedIds.toList()
          ..sort((a, b) => score(a).compareTo(score(b))))
        .first;
    TowerHeroView view(
            {Set<String>? unlocked, Map<String, int> tiers = const {}}) =>
        TowerHeroView(
          raceId: 'human',
          professionId: 'warrior',
          health: 30,
          maxHealth: 30,
          unlockedSkillIds: unlocked ?? full.unlockedSkillIds,
          diceFaces: full.diceFaces,
          diceSkillAssignments: full.diceSkillAssignments,
          skillTiers: tiers,
        );

    test('the die is full and the stronger skill outranks it', () {
      expect(placedIds.length, full.diceFaces.where(isOpenSkillFace).length);
      expect(placedIds, isNot(contains(stronger)));
      expect(placedIds.every((id) => score(stronger) > score(id)), isTrue);
    });

    test('a stronger skill taken later does not push a ranked one off', () {
      // The control: with no tier the weakest gives its face up.
      final plain = full.copy();
      towerApplyReward(
          plain, TowerReward(TowerRewardKind.skill, id: stronger), data);
      expect(plain.diceSkillAssignments.values, isNot(contains(weakest)));
      // Ranked once, it keeps its face.
      final ranked = full.copy()..skillTiers[weakest] = 1;
      towerApplyReward(
          ranked, TowerReward(TowerRewardKind.skill, id: stronger), data);
      expect(ranked.diceSkillAssignments.values, contains(weakest));
    });

    test('a rank-up never names a skill off the die', () {
      // Every skill the hero has not learned, the die's skills ranked or
      // not, a skill known but on no face (the stronger one) ranked too.
      final known = {...full.unlockedSkillIds, stronger};
      for (final tiers in [
        <String, int>{},
        {for (final id in placedIds) id: 1},
        {stronger: 2, weakest: 1},
      ]) {
        final v = view(unlocked: known, tiers: tiers);
        for (final id in data.skills.keys) {
          if (placedIds.contains(id)) continue;
          final up = towerRankUpFor(id, v, data.skills);
          if (up != null) expect(placedIds, contains(up), reason: id);
        }
      }
    });

    test('a skill that would push a ranked one off is a rank-up instead', () {
      // Every skill on the die ranked: the stronger one finds no face, so
      // its card raises a skill on the die.
      final allRanked = view(tiers: {for (final id in placedIds) id: 1});
      final up = towerRankUpFor(stronger, allRanked, data.skills);
      expect(up, isNotNull);
      expect(placedIds, contains(up));
      // With none ranked, it lands on a face: a skill card.
      expect(towerRankUpFor(stronger, view(), data.skills), isNull);
    });

    test('over a batch, every skill ranked up is still on the die at the end',
        () {
      for (final progress in [const TowerProgress(), towerAllUnlocked]) {
        for (var seed = 1; seed <= 40; seed++) {
          final run = playTowerRun(
              seed: seed,
              data: data,
              progress: progress,
              events: towerEventsLive);
          final end = towerHeroOf(run, data);
          final onEnd = end.diceSkillAssignments.values.toSet();
          final open = end.diceFaces.where(isOpenSkillFace).length;
          final ranked = {
            for (final card in run.taken.values)
              if (card.kind == TowerRewardKind.rankUp) card.id,
          };
          // Each ranked skill is on the die at the end, or the die rolled
          // (the bot's choice) has fewer open faces than the skills ranked,
          // every one of them holding a ranked skill.
          if (ranked.difference(onEnd).isNotEmpty) {
            expect(onEnd.length, open, reason: 'seed $seed: a face left');
            expect(ranked.containsAll(onEnd), isTrue,
                reason: 'seed $seed: an unranked skill took a ranked face');
          }
        }
      }
    });
  });

  group('the fallback: nothing on the die to raise', () {
    test('every skill on the die at the last tier: the skill card stays', () {
      final maxed = view(tiers: {
        for (final id in hero.diceSkillAssignments.values) id: maxSkillTier,
      });
      expect(towerRankUpFor(newSkill, maxed, data.skills), isNull);
    });

    test('a die with no open Skill face: the skill card stays', () {
      final closed = TowerHeroView(
        raceId: 'human',
        professionId: 'warrior',
        health: 30,
        maxHealth: 30,
        diceFaces: [
          for (final face in hero.diceFaces)
            if (!isOpenSkillFace(face)) face,
        ],
      );
      expect(closed.diceFaces, isNotEmpty);
      expect(towerRankUpFor(newSkill, closed, data.skills), isNull);
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
      // The Level Up and the spoils, in whichever order they open (the
      // Tower's tables load a little longer since the clans' offers read
      // the clans' tables too), until the cards show.
      for (var i = 0;
          i < 4 && find.byKey(const Key('tower_card_0')).evaluate().isEmpty;
          i++) {
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
      }
      final error = tester.takeException();
      final fr = lang == AppLanguage.fr;
      // The tarot card shows its kind in capitals; the card in hand is
      // repeated in full under the row.
      final kind = fr ? 'Montée en rang' : 'Rank up';
      expect(
          find.byWidgetPredicate(
              (w) => w is Text && w.data?.toLowerCase() == kind.toLowerCase()),
          findsOneWidget);
      expect(
          find.textContaining(fr ? 'Rang 1 à 2' : 'Rank 1 to 2'), findsWidgets);
      expect(
          find.textContaining(
              fr ? 'Votre dé n’a plus de face libre' : 'Your die has no free'),
          findsWidgets);
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

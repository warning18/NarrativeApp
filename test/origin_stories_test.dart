import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/ability_check.dart';
import 'package:narrative_data_app/data/echoes.dart';
import 'package:narrative_data_app/data/origin_stories.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/origin_stories_screen.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';

String en(String key) => trFor(AppLanguage.en, key);

/// Opens [page] from a button, so the test can see what it pops with.
class _Opener<T> extends StatelessWidget {
  const _Opener(this.page, this.onResult);

  final Widget page;
  final void Function(T?) onResult;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () async => onResult(await Navigator.of(context)
              .push<T>(MaterialPageRoute(builder: (_) => page))),
          child: const Text('open'),
        ),
      );
}

Future<void> _settle(WidgetTester tester, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await _settle(tester, 1);
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Picks the [id] answer ('good', 'neutral', 'evil') of [memory], then
/// moves on from what came of it.
Future<void> _answer(WidgetTester tester, OriginMemory memory, String id,
    {bool moveOn = true}) async {
  final answer = memory.answers.firstWhere((a) => a.id == id);
  await _tap(tester, find.text(answer.en));
  expect(find.text(answer.outcomeEn), findsOneWidget);
  if (!moveOn) return;
  final next = find.text(en('origin_next_memory'));
  await _tap(tester,
      next.evaluate().isNotEmpty ? next : find.text(en('origin_to_summary')));
}

final _dialogContinue = find.descendant(
    of: find.byType(AlertDialog), matching: find.byType(FilledButton));

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
  });

  group('the memories', () {
    test('six ages, with every race and profession given its own', () {
      final races = _json('assets/gamedata/races.json').keys;
      final professions = _json('assets/gamedata/professions.json').keys;
      expect(originMarkRaces.toSet(), races.toSet());
      expect(originCallingProfessions.toSet(), professions.toSet());
      for (final race in races) {
        for (final profession in professions) {
          final memories =
              originMemoriesFor(raceId: race, professionId: profession);
          expect(memories.map((m) => m.age), [6, 8, 10, 12, 14, 16]);
          expect(memories[1].id, 'mark_$race');
          expect(memories[3].id, 'calling_$profession');
        }
      }
      // An unknown race or profession still gets six memories.
      expect(originMemoriesFor().length, 6);
    });

    test('every answer leans, teaches, and says what came of it', () {
      for (final memory in allOriginMemories) {
        expect(memory.answers.map((a) => a.id).toList()..sort(),
            ['evil', 'good', 'neutral'],
            reason: memory.id);
        for (final answer in memory.answers) {
          final why = '${memory.id}/${answer.id}';
          expect(answer.alignmentMod,
              {'good': 4, 'neutral': 0, 'evil': -4}[answer.id],
              reason: why);
          expect(abilityScoreKeys, contains(answer.ability), reason: why);
          expect(answer.en.length, lessThanOrEqualTo(60), reason: why);
          expect(answer.outcomeEn, contains('learn'), reason: why);
          expect(answer.fr, isNotEmpty, reason: why);
          expect(answer.outcomeFr, isNotEmpty, reason: why);
        }
        // No memory teaches one ability twice.
        expect(memory.answers.map((a) => a.ability).toSet().length, 3,
            reason: memory.id);
      }
    });

    test('a recall answers an earlier memory, never a later one', () {
      for (final race in originMarkRaces) {
        for (final profession in originCallingProfessions) {
          final memories =
              originMemoriesFor(raceId: race, professionId: profession);
          for (final (i, memory) in memories.indexed) {
            final earlier = {
              for (final m in memories.take(i))
                for (final a in m.answers) m.flagFor(a),
            };
            for (final recall in memory.recalls) {
              if (recall.flag == null) continue;
              // A flag of another race's memory simply never fires.
              if (recall.flag!.startsWith('origin_mark_')) continue;
              expect(earlier, contains(recall.flag),
                  reason: '${memory.id} recalls ${recall.flag}');
            }
          }
        }
      }
      // The lamp always opens with the name the street gave.
      final lamp = originMemoriesFor()[4];
      expect(lamp.recallFor(const {}, 12)!.en, contains('soft'));
      expect(lamp.recallFor(const {}, -12)!.en, contains('mothers'));
      expect(lamp.recallFor(const {}, 0)!.en, contains('own business'));
    });

    test('the answers add up to an alignment, lessons and flags', () {
      final memories = originMemoriesFor(raceId: 'orc', professionId: 'cleric');
      OriginAnswer pick(int i, String id) =>
          memories[i].answers.firstWhere((a) => a.id == id);
      final answers = [
        pick(0, 'good'),
        pick(1, 'good'),
        pick(2, 'good'),
        pick(3, 'evil'),
        pick(4, 'good'),
        pick(5, 'neutral'),
      ];
      final result = originResultOf(memories, answers);
      expect(result.alignment, 12);
      // Sparrow, ink, loaf, soup, lamp, board.
      expect(result.abilities, {
        'wisdom': 1,
        'constitution': 2,
        'luck': 1,
        'intelligence': 1,
        'strength': 1,
      });
      expect(
          result.flags,
          containsAll([
            'origin_sparrow_good',
            'origin_mark_orc',
            'origin_calling_cleric_evil',
            'origin_board_neutral'
          ]));
      expect(originPortraitOf(answers), 'good');
      expect(originPortraitOf([for (final m in memories) m.answers[0]]),
          isNot('mixed'));
      expect(
          originPortraitOf([
            pick(0, 'good'),
            pick(1, 'evil'),
            pick(2, 'neutral'),
            pick(3, 'good'),
            pick(4, 'evil'),
            pick(5, 'neutral'),
          ]),
          'mixed');
    });

    test('French speaks in "vous", never "tu", and every string is there', () {
      final tu = RegExp(
        r"(?<!\p{L})(?:(?:tu|ton|ta|tes|toi|te)(?!\p{L})|t['’])",
        caseSensitive: false,
        unicode: true,
      );
      final texts = <String, String>{
        for (final key in [
          'lock_character_dialog_title',
          'lock_character_dialog_desc',
          'character_name_field_label',
          'character_name_field_hint',
          'random_name_tooltip',
          'begin_story_button',
          'origin_stories_section_title',
          'origin_stories_intro',
          'origin_memory_progress',
          'origin_age_label',
          'origin_stage_childhood',
          'origin_next_memory',
          'origin_to_summary',
          'origin_choose_again',
          'origin_lean_good',
          'origin_lean_evil',
          'origin_lean_neutral',
          'origin_summary_title',
          'origin_summary_intro',
          'origin_summary_lessons',
          'origin_summary_change_hint',
          'origin_starting_alignment',
          'origin_portrait_good',
          'origin_portrait_evil',
          'origin_portrait_neutral',
          'origin_portrait_mixed',
        ])
          key: trFor(AppLanguage.fr, key),
        for (final m in allOriginMemories) ...{
          '${m.id}.title': m.titleFr,
          '${m.id}.scene': m.sceneFr,
          for (final a in m.answers) ...{
            '${m.id}.${a.id}': a.fr,
            '${m.id}.${a.id}.outcome': a.outcomeFr,
          },
          for (final (i, r) in m.recalls.indexed) '${m.id}.recall$i': r.fr,
        },
      };
      for (final entry in texts.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
        expect(tu.hasMatch(entry.value), isFalse,
            reason: '${entry.key}: ${entry.value}');
      }
      for (final key in ['origin_stage_youth', 'origin_teaches']) {
        expect(trFor(AppLanguage.fr, key), isNotEmpty);
      }
    });

    test('every answer is echoed in the story, and the journal knows why', () {
      final dag = _json(StoryRepository.assetPath);
      final story = StoryData({
        for (final entry in dag.entries)
          entry.key: StoryNode.fromJson(
              entry.key, entry.value as Map<String, dynamic>),
      });
      final echoed = {
        for (final node in story.nodes.values)
          for (final callback in node.flagCallbacks) callback.flag,
      };
      for (final memory in allOriginMemories) {
        for (final answer in memory.answers) {
          final flag = memory.flagFor(answer);
          expect(echoed, contains(flag), reason: flag);
          expect(echoCause(story, flag)?.text, answer.en, reason: flag);
          expect(echoCause(story, flag)?.textFr, answer.fr, reason: flag);
        }
      }
      // Old Hesk's lamp comes back when he dies, and again in chapter 5.
      expect(story.nodeFor('450')!.flagCallbacks.map((c) => c.flag),
          contains('origin_lamp_good'));
      expect(story.nodeFor('5004_altar')!.flagCallbacks.map((c) => c.flag),
          contains('origin_lamp_evil'));
    });
  });

  group('memories page', () {
    Future<List<OriginResult?>> pumpPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final results = <OriginResult?>[];
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: _Opener<OriginResult>(
            OriginStoriesScreen(
                raceId: 'dwarf', professionId: 'mage', random: Random(7)),
            results.add,
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    final memories = originMemoriesFor(raceId: 'dwarf', professionId: 'mage');

    testWidgets('an answer tells what came of it; Back never skips a memory',
        (tester) async {
      final results = await pumpPage(tester);
      expect(find.text(en('origin_stories_intro')), findsOneWidget);
      expect(find.text(memories[0].titleEn), findsOneWidget);
      // Each answer says what it teaches.
      expect(find.text('+1 Wisdom'), findsOneWidget);

      await _answer(tester, memories[0], 'good', moveOn: false);
      expect(find.text('Leans Good (+4)'), findsOneWidget);
      // Back from what came of it: the answers again, the pick kept.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(memories[0].answers[0].outcomeEn), findsNothing);
      expect(
        find.ancestor(
          of: find.text(memories[0].answers.first.en),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
        findsOneWidget,
      );
      await _answer(tester, memories[0], 'good');
      expect(find.text(memories[1].titleEn), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(memories[0].titleEn), findsOneWidget);

      // Back on the first memory leaves the page, with nothing chosen.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(OriginStoriesScreen), findsNothing);
      expect(results, [null]);
    });

    testWidgets('a later memory remembers an earlier answer', (tester) async {
      await pumpPage(tester);
      await _answer(tester, memories[0], 'evil');
      expect(find.text(memories[2].recalls[2].en), findsNothing);
      await _answer(tester, memories[1], 'neutral');
      // The blind man's memory opens on the sparrow sold for a copper.
      expect(
          find.text('Since the sparrow, you had known that even pity had '
              'a price.'),
          findsOneWidget);
    });

    testWidgets('the summary adds everything up and pops it', (tester) async {
      final results = await pumpPage(tester);
      final picks = ['good', 'evil', 'neutral', 'good', 'good', 'good'];
      for (final (i, id) in picks.indexed) {
        await _answer(tester, memories[i], id);
      }
      expect(find.text(en('origin_summary_title')), findsOneWidget);
      expect(find.text(en('origin_portrait_good')), findsOneWidget);
      // Wisdom from the sparrow and the flame, Charisma from the crooked
      // mark, Perception from the blind man, Intelligence from the lamp,
      // Charisma again from the board.
      expect(find.text('Wisdom +2'), findsOneWidget);
      expect(find.text('Charisma +2'), findsOneWidget);
      expect(find.text('${en('alignment_good')} (12)'), findsNothing);
      expect(find.text('${en('alignment_neutral')} (12)'), findsOneWidget);

      // Change one answer from the summary: it comes straight back here.
      await _tap(tester, find.text(memories[1].titleEn));
      await _answer(tester, memories[1], 'good');
      expect(find.text(en('origin_summary_title')), findsOneWidget);
      expect(find.text('${en('alignment_good')} (20)'), findsOneWidget);

      // Back from the summary reopens the last memory.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(memories[5].titleEn), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(memories[4].titleEn), findsOneWidget);
      await _answer(tester, memories[4], 'good');
      await _answer(tester, memories[5], 'good');

      await _tap(tester, find.text(en('begin_story_button')));
      final result = results.single!;
      expect(result.alignment, 20);
      expect(result.flags, [
        'origin_sparrow',
        'origin_sparrow_good',
        'origin_mark_dwarf',
        'origin_mark_dwarf_good',
        'origin_beggar',
        'origin_beggar_neutral',
        'origin_calling_mage',
        'origin_calling_mage_good',
        'origin_lamp',
        'origin_lamp_good',
        'origin_board',
        'origin_board_good',
      ]);
      expect(result.abilities.values.fold(0, (a, b) => a + b), 6);
    });
  });

  testWidgets(
      'creation: the name dialog closes cleanly and the memories apply '
      'their alignment, lessons and flags once', (tester) async {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    bool? started;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: _Opener<bool>(
            const RaceProfessionScreen(), (value) => started = value),
      ),
    ));
    await _settle(tester);
    await tester.tap(find.text('open'));
    await _until(tester, find.text('Human'));
    final container = ProviderScope.containerOf(
        tester.element(find.byType(RaceProfessionScreen)));
    await tester.tap(find.text('Human').first);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Warrior'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Warrior').first);
    await tester.pump();
    await tester.scrollUntilVisible(
        find.text('Start New Game With This Character'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Start New Game With This Character'));
    await _settle(tester);
    await tester.tap(find.text('Start'));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 4));
    await _until(tester, find.text('Continue'));

    Future<void> openMemories(String name) async {
      await tester.scrollUntilVisible(find.text('Continue'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Continue'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), name);
      await tester.pump();
      await tester.tap(_dialogContinue);
      await _settle(tester);
    }

    final memories =
        originMemoriesFor(raceId: 'human', professionId: 'warrior');
    final before = container.read(playerSessionProvider);
    await openMemories('Maren');
    expect(tester.takeException(), isNull);
    expect(find.byType(OriginStoriesScreen), findsOneWidget);
    expect(container.read(playerSessionProvider).characterName, 'Maren');
    // The human's second memory and the warrior's fourth.
    expect(memories[1].id, 'mark_human');
    expect(memories[3].id, 'calling_warrior');

    // Backing out of the first memory returns to the sheet, nothing applied.
    await _answer(tester, memories[0], 'evil', moveOn: false);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(OriginStoriesScreen), findsNothing);
    expect(find.byType(RaceProfessionScreen), findsOneWidget);
    expect(container.read(playerSessionProvider).alignmentScore, 0);

    // Continue again: the dialog keeps the name, and the full walk applies
    // everything once.
    await tester.scrollUntilVisible(find.text('Continue'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Continue'));
    await _settle(tester);
    expect(find.widgetWithText(TextField, 'Maren'), findsOneWidget);
    await tester.tap(_dialogContinue);
    await _settle(tester);
    final picks = ['evil', 'evil', 'neutral', 'evil', 'good', 'neutral'];
    for (final (i, id) in picks.indexed) {
      await _answer(tester, memories[i], id);
    }
    expect(find.text('Maren'), findsOneWidget);
    expect(find.text(en('origin_portrait_mixed')), findsOneWidget);
    expect(container.read(playerSessionProvider).alignmentScore, 0);
    await _tap(tester, find.text(en('begin_story_button')));
    await _settle(tester);

    final session = container.read(playerSessionProvider);
    expect(session.alignmentScore, -8);
    // Sparrow sold (Charisma), ribbon asked for (Charisma), sleeve pulled
    // free (Perception), coin caught (Charisma), lamp owned up to
    // (Intelligence), bundle taken back (Strength).
    expect(session.charisma, before.charisma + 3);
    expect(session.perception, before.perception + 1);
    expect(session.intelligence, before.intelligence + 1);
    expect(session.strength, before.strength + 1);
    expect(session.wisdom, before.wisdom);
    expect(
        session.flags,
        containsAll([
          'origin_sparrow_evil',
          'origin_mark_human_evil',
          'origin_board_neutral'
        ]));
    expect(started, isTrue);
    expect(find.byType(RaceProfessionScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}

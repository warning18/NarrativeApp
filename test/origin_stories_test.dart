import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/origin_stories.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
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

Future<void> _tapAnswer(WidgetTester tester, String key) async {
  final answer = find.text(en(key));
  await tester.ensureVisible(answer);
  await tester.tap(answer);
  await tester.pumpAndSettle();
}

final _dialogContinue = find.descendant(
    of: find.byType(AlertDialog), matching: find.byType(FilledButton));

List<OriginPrompt> _allPrompts() => [
      ...originStoryPrompts,
      ...beggarPromptByProfession.values,
    ];

void main() {
  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
  });

  group('memories page', () {
    Future<List<List<OriginChoice>?>> pumpPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final results = <List<OriginChoice>?>[];
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: _Opener<List<OriginChoice>>(
            OriginStoriesScreen(professionId: 'mage', random: Random(7)),
            results.add,
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('Back steps to the previous memory and never skips one',
        (tester) async {
      final results = await pumpPage(tester);
      expect(find.text(en('origin_stories_intro')), findsOneWidget);
      expect(find.text(en('origin_childhood_bird_title')), findsOneWidget);

      await _tapAnswer(tester, 'origin_childhood_bird_good');
      expect(
          find.text(en('origin_childhood_beggar_mage_title')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(en('origin_childhood_bird_title')), findsOneWidget);
      // The earlier answer is still marked.
      expect(
        find.ancestor(
          of: find.text(en('origin_childhood_bird_good')),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
        findsOneWidget,
      );

      // Back on the first memory leaves the page, with nothing chosen.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(OriginStoriesScreen), findsNothing);
      expect(results, [null]);
    });

    testWidgets('answers keep their shuffled order when going back',
        (tester) async {
      await pumpPage(tester);
      double top(String key) => tester.getTopLeft(find.text(en(key))).dy;
      List<String> order() {
        final keys = [
          'origin_childhood_bird_good',
          'origin_childhood_bird_evil',
          'origin_childhood_bird_neutral',
        ]..sort((a, b) => top(a).compareTo(top(b)));
        return keys;
      }

      final before = order();
      await _tapAnswer(tester, 'origin_childhood_bird_neutral');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(order(), before);
    });

    testWidgets('the summary lists every answer and pops them all',
        (tester) async {
      final results = await pumpPage(tester);
      await _tapAnswer(tester, 'origin_childhood_bird_good');
      await _tapAnswer(tester, 'origin_childhood_beggar_mage_good');
      await _tapAnswer(tester, 'origin_teen_bully_evil');
      await _tapAnswer(tester, 'origin_teen_vase_good');
      await _tapAnswer(tester, 'origin_teen_thief_neutral');

      expect(find.text(en('origin_summary_title')), findsOneWidget);
      expect(find.text(en('origin_teen_bully_evil')), findsOneWidget);
      expect(find.text('${en('alignment_neutral')} (8)'), findsOneWidget);

      // Change one answer from the summary: it comes straight back here.
      await tester.tap(find.text(en('origin_teen_bully_title')));
      await tester.pumpAndSettle();
      await _tapAnswer(tester, 'origin_teen_bully_good');
      expect(find.text(en('origin_summary_title')), findsOneWidget);
      expect(find.text('${en('alignment_neutral')} (16)'), findsOneWidget);

      // Back from the summary reopens the last memory.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(en('origin_teen_thief_title')), findsOneWidget);
      await _tapAnswer(tester, 'origin_teen_thief_good');
      expect(find.text('${en('alignment_good')} (20)'), findsOneWidget);

      await tester.tap(find.text(en('begin_story_button')));
      await tester.pumpAndSettle();
      expect(results.single!.map((c) => c.textKey), [
        'origin_childhood_bird_good',
        'origin_childhood_beggar_mage_good',
        'origin_teen_bully_good',
        'origin_teen_vase_good',
        'origin_teen_thief_good',
      ]);
      expect(originAlignmentTotal(results.single!), 20);
    });
  });

  testWidgets(
      'creation: the name dialog closes cleanly and the memories apply '
      'their alignment once', (tester) async {
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

    await openMemories('Maren');
    expect(tester.takeException(), isNull);
    expect(find.byType(OriginStoriesScreen), findsOneWidget);
    expect(container.read(playerSessionProvider).characterName, 'Maren');

    // Backing out of the first memory returns to the sheet, nothing applied.
    await _tapAnswer(tester, 'origin_childhood_bird_evil');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(OriginStoriesScreen), findsNothing);
    expect(find.byType(RaceProfessionScreen), findsOneWidget);
    expect(container.read(playerSessionProvider).alignmentScore, 0);

    // Continue again: the dialog keeps the name, and the full walk applies
    // the total once.
    await tester.scrollUntilVisible(find.text('Continue'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Continue'));
    await _settle(tester);
    expect(find.widgetWithText(TextField, 'Maren'), findsOneWidget);
    await tester.tap(_dialogContinue);
    await _settle(tester);
    await _tapAnswer(tester, 'origin_childhood_bird_evil');
    await _tapAnswer(tester, 'origin_childhood_beggar_warrior_evil');
    await _tapAnswer(tester, 'origin_teen_bully_neutral');
    await _tapAnswer(tester, 'origin_teen_vase_evil');
    await _tapAnswer(tester, 'origin_teen_thief_good');
    expect(container.read(playerSessionProvider).alignmentScore, 0);
    await tester.ensureVisible(find.text(en('begin_story_button')));
    await tester.tap(find.text(en('begin_story_button')));
    await _settle(tester);

    expect(container.read(playerSessionProvider).alignmentScore, -8);
    expect(started, isTrue);
    expect(find.byType(RaceProfessionScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  test('every memory has good, evil and neutral answers', () {
    for (final prompt in _allPrompts()) {
      expect(prompt.choices.map((c) => c.alignmentMod).toList()..sort(),
          [-4, 0, 4],
          reason: prompt.titleKey);
    }
  });

  test('character creation speaks French in "vous", never "tu"', () {
    final keys = <String>{
      'lock_character_dialog_title',
      'lock_character_dialog_desc',
      'character_name_field_label',
      'character_name_field_hint',
      'random_name_tooltip',
      'begin_story_button',
      'origin_stories_section_title',
      'origin_stories_intro',
      'origin_memory_progress',
      'origin_summary_title',
      'origin_summary_intro',
      'origin_summary_change_hint',
      'origin_starting_alignment',
      for (final prompt in _allPrompts()) ...[
        prompt.titleKey,
        prompt.descriptionKey,
        for (final choice in prompt.choices) choice.textKey,
      ],
    };
    final tu = RegExp(
      r"(?<!\p{L})(?:(?:tu|ton|ta|tes|toi|te)(?!\p{L})|t['’])",
      caseSensitive: false,
      unicode: true,
    );
    for (final key in keys) {
      final fr = trFor(AppLanguage.fr, key);
      expect(fr, isNot(trFor(AppLanguage.en, key)),
          reason: '$key has no French');
      expect(tu.hasMatch(fr), isFalse, reason: '$key: $fr');
    }
  });
}

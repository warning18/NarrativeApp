// Pages inside one scene (v1.750, narration_pages.dart): a `[PAGE]` marker,
// and an ending's `[EPILOGUE]`, cut a node's reading into pages. The first
// pages end on Continue; the choices wait on the last. The node keeps its
// id, its choices and its one narration recording.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/narration_clips.dart';
import 'package:narrative_data_app/data/narration_pages.dart';
import 'package:narrative_data_app/data/story_markup.dart'
    show stripStoryMarkup;
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/story_text.dart';
import 'support/pump.dart';

final _story = () {
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  return StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
}();

void main() {
  group('splitNarrationPages', () {
    test('a scene with no marker is one page, as written', () {
      expect(splitNarrationPages('One.\n\nTwo.'), ['One.\n\nTwo.']);
      expect(splitNarrationPages(''), ['']);
    });

    test('[PAGE] cuts the scene and is not shown', () {
      expect(splitNarrationPages('Calm.\n\n[PAGE]\n\nThe wall came in.'),
          ['Calm.', 'The wall came in.']);
      expect(splitNarrationPages('A [PAGE] B [PAGE] C'), ['A', 'B', 'C']);
    });

    test('[EPILOGUE] opens a page of its own and stays as its heading', () {
      expect(splitNarrationPages('The end. [EPILOGUE] After.'),
          ['The end.', '[EPILOGUE] After.']);
      expect(splitNarrationPages('La fin. [ÉPILOGUE] Après.'),
          ['La fin.', '[ÉPILOGUE] Après.']);
      // A page that already opens on it is not cut again.
      expect(splitNarrationPages('[EPILOGUE] After.'), ['[EPILOGUE] After.']);
    });

    test(
        'the recording script of a paged scene has no marker, in both languages',
        () {
      final node = _story.nodeFor('6010_record')!;
      expect(node.description, contains(pageBreakMarker));
      for (final french in [false, true]) {
        final script = nodeNarrationScript(node,
            french: french, personalize: (text) => text, variations: false);
        expect(script.any((p) => p.contains(pageBreakMarker)), isFalse);
        // The same words read-aloud asks for: the scene, marker removed.
        final text =
            node.descriptionFor(french).replaceAll(pageBreakMarker, '');
        expect(script, narrationParagraphs(storyBodyFor(text)));
      }
    });

    test('empty pages are dropped', () {
      expect(splitNarrationPages('[PAGE] A [PAGE][PAGE] B [PAGE]'), ['A', 'B']);
      expect(splitNarrationPages('[PAGE]'), ['']);
    });

    test('every written ending reads in two pages, in both languages', () {
      for (final id in ['7005', '7005_seeker', '7005_dawn', '7005_crown']) {
        final node = _story.nodeFor(id)!;
        for (final text in [node.description, node.descriptionFr!]) {
          final pages = splitNarrationPages(text);
          expect(pages, hasLength(2), reason: id);
          expect(pages.first,
              anyOf(startsWith('[JOURNEY’S END]'), startsWith('[FIN')),
              reason: id);
          expect(pages.last,
              anyOf(startsWith('[EPILOGUE]'), startsWith('[ÉPILOGUE]')),
              reason: id);
        }
        // Its one way on (begin again) is still the node's.
        expect(node.choices.single.isEnding, isTrue, reason: id);
      }
    });
  });

  test(
      'a scene read in one go (the recording preview, an expedition beat) '
      'shows no [PAGE]', () {
    final node = _story.nodeFor('6010_record')!;
    for (final text in [node.description, node.descriptionFr!]) {
      expect(text, contains(pageBreakMarker));
      final shown = storyBodyFor(joinedNarration(text));
      expect(shown, isNot(contains(pageBreakMarker)));
      expect(stripStoryMarkup(joinedNarration(text)),
          isNot(contains(pageBreakMarker)));
    }
  });

  group('scenePageOf', () {
    const state = (key: '7005|false|40', page: 1);
    test('the page of the visit being read, clamped', () {
      expect(scenePageOf(state, '7005|false|40', 2), 1);
      expect(scenePageOf(state, '7005|false|40', 5), 1);
      expect(scenePageOf((key: 'k', page: 7), 'k', 3), 2);
    });
    test('another visit, or a scene of one page, opens on its first page', () {
      expect(scenePageOf(state, '7005|false|41', 2), 0);
      expect(scenePageOf(state, '4999_camp|false|40', 2), 0);
      expect(scenePageOf(state, '7005|false|40', 1), 0);
    });
  });

  testWidgets(
      'the ending 7005 at 320 px: the first page ends on Continue, the '
      'epilogue page shows the way on; a save reopens on the first page',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    usePhone(tester, const Size(320, 640));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({
      'tutorial_enabled': false,
      'player_session': json.encode({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 80,
        'flags': <String>[],
      }),
      'autosave_story_node': '7005',
      'autosave_story_history': json.encode(['0', '7004']),
      'autosave_story_visited': json.encode(['0', '7004', '7005']),
    });
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    for (var i = 0; i < 6; i++) {
      await settleApp(tester);
    }
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.tap(find.byKey(const Key('menu_continue')));
    for (var i = 0; i < 6; i++) {
      await settleApp(tester);
    }
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(storyPlayProvider).currentNodeId, '7005');
    // The ending has no place on the map: the Journey opens it in the
    // story's reader.
    final openStory = find.byKey(const ValueKey('journey_open_story'));
    if (openStory.evaluate().isNotEmpty) {
      // (Called, not tapped: a notice may lie over the empty map.)
      tester.widget<ButtonStyleButton>(openStory).onPressed!();
      await tester.pump(const Duration(seconds: 1));
      await settleApp(tester);
    }

    Finder shown(String words) =>
        find.byWidgetPredicate((w) => w is StoryText && w.text.contains(words));
    final cont = find.byKey(const ValueKey('story_page_continue'));
    final card = find.textContaining('Begin again');

    // Page 1: the return, no epilogue, no way on; Continue turns the page.
    expect(shown('I came back through the tear'), findsWidgets);
    expect(shown('It was the Shroud that did it'), findsNothing);
    expect(card, findsNothing);
    expect(cont, findsOneWidget);
    expect(find.descendant(of: cont, matching: find.text('Continue')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(cont);
    await settleApp(tester);

    // Page 2: the epilogue, and the ending's one way on.
    expect(shown('It was the Shroud that did it'), findsWidgets);
    expect(shown('I came back through the tear'), findsNothing);
    expect(container.read(storyPlayProvider).currentNodeId, '7005');
    expect(card, findsWidgets);
    expect(tester.takeException(), isNull);

    // The page is not saved: the same visit read afresh opens on page 1.
    container.read(scenePageProvider.notifier).state = (key: '', page: 0);
    await settleApp(tester);
    expect(shown('It was the Shroud that did it'), findsNothing);
    expect(card, findsNothing);
  });
}

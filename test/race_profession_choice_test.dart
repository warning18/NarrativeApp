// The race and profession choice (v1.599) on a 360 px phone in French: five
// cards a step, every name whole (« Enfant du Néant » and « Guerrier » take
// two lines rather than an ellipsis, in the app's own fonts), then the open
// card with the clans that will court you, the compare sheet and the summary.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
  expect(finder, findsWidgets);
}

const _races = ['dwarf', 'elf', 'human', 'orc', 'voidkin'];
const _professions = ['cleric', 'mage', 'ranger', 'rogue', 'warrior'];

Future<void> _open(WidgetTester tester, {bool french = false}) async {
  await _loadFonts();
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(360, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(const ColorScheme.light()),
      home: const RaceProfessionScreen(),
    ),
  ));
  await tester.pump();
  if (french) {
    final container = ProviderScope.containerOf(
        tester.element(find.byType(RaceProfessionScreen)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
  }
  await _until(tester, find.byKey(const Key('choice_card_human')));
}

void _namesWhole(WidgetTester tester, Iterable<String> ids) {
  for (final id in ids) {
    final card = find.byKey(Key('choice_card_$id'));
    expect(card, findsOneWidget, reason: id);
    final rect = tester.getRect(card);
    expect(rect.left, greaterThanOrEqualTo(0), reason: id);
    expect(rect.right, lessThanOrEqualTo(360), reason: id);
    final name = find.byKey(Key('choice_name_$id'));
    final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: name, matching: find.byType(RichText)));
    expect(paragraph.didExceedMaxLines, isFalse,
        reason: '$id: "${paragraph.text.toPlainText()}" is cut short');
  }
}

void main() {
  setUp(rootBundle.clear);

  testWidgets('at 360 px in French, both steps show five whole names',
      (tester) async {
    await _open(tester, french: true);
    await _until(tester, find.text('Enfant du Néant'));
    _namesWhole(tester, _races);
    await tester.tap(find.byKey(const Key('rp_step_calling')));
    await tester.pump();
    await _until(tester, find.text('Guerrier'));
    _namesWhole(tester, _professions);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a picked card opens with the clans that will court you',
      (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const Key('choice_card_human')));
    await tester.pump();
    expect(find.byKey(const Key('open_choice_human')), findsOneWidget);
    expect(find.byKey(const Key('open_choice_lore')), findsOneWidget);
    expect(find.textContaining('clans'), findsWidgets);
    // Both steps picked: the summary and the Start button.
    expect(find.byKey(const Key('rp_summary')), findsNothing);
    await tester.tap(find.byKey(const Key('rp_next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('choice_card_warrior')));
    await tester.pump();
    expect(find.byKey(const Key('rp_summary')), findsOneWidget);
    expect(find.text('Start New Game With This Character'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compare sets two peoples side by side and picks one',
      (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const Key('rp_compare')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('compare_pick_dwarf')), findsWidgets);
    await tester.tap(find.byKey(const Key('compare_with_elf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('compare_pick_elf')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open_choice_elf')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

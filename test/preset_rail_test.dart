// The race and profession rails (v1.198) on a 360 px phone in French
// (v1.209): five tiles across, and every name whole on them. « Enfant du
// Néant » and « Guerrier » take two lines rather than an ellipsis, in the
// app's own fonts (loaded here: the test font would measure nothing real).
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

void main() {
  testWidgets('at 360 px in French, all five tiles show and no name is cut',
      (tester) async {
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
    final container = ProviderScope.containerOf(
        tester.element(find.byType(RaceProfessionScreen)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await _until(tester, find.text('Enfant du Néant'));
    expect(find.text('Guerrier'), findsOneWidget);

    for (final id in [..._races, ..._professions]) {
      final tile = find.byKey(Key('preset_tile_$id'));
      expect(tile, findsOneWidget, reason: id);
      // All five across the phone, none pushed off its edge.
      final rect = tester.getRect(tile);
      expect(rect.left, greaterThanOrEqualTo(0), reason: id);
      expect(rect.right, lessThanOrEqualTo(360), reason: id);
      expect(rect.width, greaterThan(40), reason: id);
      // The name whole: within its two lines, no ellipsis reached.
      final name = find.byKey(Key('preset_name_$id'));
      final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: name, matching: find.byType(RichText)));
      expect(paragraph.didExceedMaxLines, isFalse,
          reason: '$id: "${paragraph.text.toPlainText()}" is cut short');
    }
    // The tiles of a rail stand level with one another.
    final tops = {
      for (final id in _races)
        tester.getRect(find.byKey(Key('preset_tile_$id'))).top
    };
    expect(tops, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}

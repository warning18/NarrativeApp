// The Skillwright's bench (merge_skills_dialog.dart): each recipe as two
// skills becoming a third, drawn with icons and real names, the missing
// inputs told apart, and a Merge that asks first and then flips the card.
// UX_SHOTS=<dir> writes a picture.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/skill_craft.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/merge_skills_dialog.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _data(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

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
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<ProviderContainer> _open(WidgetTester tester,
    {AppLanguage language = AppLanguage.en}) async {
  SharedPreferences.setMockInitialValues({
    'app_language': language.name,
    'tutorial_enabled': false,
  });
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(appLanguageProvider);
  final notifier = container.read(playerSessionProvider.notifier);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.runAsync(() => notifier.loadSession(baseSession().copyWith(
        // Fireball and Shadow Step: ready. Cleric's Smite alone: one short.
        unlockedSkillIds: const ['fireball', 'shadow_step', 'cleric_smite'],
        builtHouseIds: const [skillwrightHouseId],
      )));
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final merges = _data('skill_merges');
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showMergeSkillsDialog(context, ref,
                  skills: const {}, merges: merges, unlockedSkillIds: const []),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('a recipe shows its skills by name and what is missing',
      (tester) async {
    await _open(tester);
    expect(find.text('Craft a Skill'), findsOneWidget);
    // No ids anywhere.
    expect(find.textContaining('fireball'), findsNothing);
    expect(find.textContaining('_'), findsNothing);
    // The ready recipe: two tiles with check marks and a Merge button.
    expect(find.byKey(const Key('craft_tile_fireball')), findsOneWidget);
    expect(find.byKey(const Key('craft_tile_shadow_step')), findsOneWidget);
    expect(find.byKey(const Key('merge_blazing_shadow')), findsOneWidget);
    // A recipe one skill short says which, and has no Merge.
    expect(find.byKey(const Key('merge_wrath_of_dawn')), findsNothing);
    expect(find.text('Missing'), findsWidgets);
    await _shot(tester, 'craft_sheet');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Merge asks first, then the card shows it crafted',
      (tester) async {
    final container = await _open(tester);
    await tester.ensureVisible(find.byKey(const Key('merge_blazing_shadow')));
    await tester.tap(find.byKey(const Key('merge_blazing_shadow')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('merge_confirm')), findsOneWidget);
    // Backing out spends nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(playerSessionProvider).unlockedSkillIds,
        contains('fireball'));

    await tester.tap(find.byKey(const Key('merge_blazing_shadow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('merge_confirm')));
    await tester.pumpAndSettle();
    final known = container.read(playerSessionProvider).unlockedSkillIds;
    expect(known, contains('blazing_shadow'));
    expect(known, isNot(contains('fireball')));
    // The sheet stays open and the card now says it was done.
    expect(find.byKey(const Key('merge_blazing_shadow')), findsNothing);
    // Crafted recipes sort last: scroll down to it.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Already crafted'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in French, the French names and tags', (tester) async {
    await _open(tester, language: AppLanguage.fr);
    expect(find.text('Fusionner une compétence'), findsOneWidget);
    expect(find.text('Manquante'), findsWidgets);
    await _shot(tester, 'craft_sheet_fr');
    expect(tester.takeException(), isNull);
  });
}

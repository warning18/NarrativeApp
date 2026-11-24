// #1139: at 320 dp, French and 1.3x text, the stat pick's gain cards keep
// their stat names whole ("Intelligence" is not broken in two), and an app-bar
// title shrinks to its line instead of ending in an ellipsis.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/fit_title.dart';
import 'package:narrative_data_app/widgets/stat_pick_picker.dart';

void main() {
  final paths = trainingPathsFrom(
      jsonDecode(File('assets/gamedata/training_paths.json').readAsStringSync())
          as Map<String, dynamic>);

  testWidgets('the gain cards keep each stat name whole at 320 FR 1.3x',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [trainingPathsProvider.overrideWith((ref) async => paths)],
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!),
        home: const Scaffold(
          body: SingleChildScrollView(
              padding: EdgeInsets.all(16), child: StatPickPicker()),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    container.read(playerSessionProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await tester.runAsync(
        () => container.read(playerSessionProvider.notifier).loadSession(
              PlayerSession.fromJson({
                'statPoints': 3,
                'professionId': 'ranger',
                'statPickOffer': [
                  {
                    'path': 'duelist',
                    'gains': {'intelligence': 2}
                  },
                  {
                    'path': 'bruiser',
                    'gains': {'perception': 2}
                  },
                  {
                    'path': 'hunter',
                    'gains': {'constitution': 2}
                  },
                ],
              }),
            ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(tester.takeException(), isNull);
    // Each word is on a line of its own, in a FittedBox: it shrinks to the
    // card, it is not broken.
    final words = find.descendant(
        of: find.byKey(const Key('stat_pick_offer_0')),
        matching: find.byType(FittedBox));
    expect(words, findsWidgets);
    for (final e in words.evaluate()) {
      final box = tester.getSize(find.byWidget(e.widget));
      final text = e.widget as FittedBox;
      expect(text.fit, BoxFit.scaleDown);
      final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
          of: find.byWidget(text), matching: find.byType(RichText)));
      expect(
          paragraph
              .getBoxesForSelection(
                  const TextSelection(baseOffset: 0, extentOffset: 1))
              .length,
          1);
      expect(box.width, lessThanOrEqualTo(320));
    }
  });

  testWidgets('a long app-bar title shrinks to its line, never cut',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!),
      home: Scaffold(
        appBar: AppBar(
            title: const FitTitle('Combat : Gardien de la Tour de Cendre')),
      ),
    ));
    final box = tester.getSize(find.byType(FittedBox));
    final text = tester.getSize(find.byType(Text));
    expect(text.width, greaterThan(box.width), reason: 'it had to shrink');
    expect(
        tester.widget<FittedBox>(find.byType(FittedBox)).fit, BoxFit.scaleDown);
    expect(box.width, lessThanOrEqualTo(320));
    final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
        of: find.byType(FitTitle), matching: find.byType(RichText)));
    expect(paragraph.didExceedMaxLines, isFalse);
  });
}

// Choices acted out where the party stands (v1.407, design 1 of
// docs/proposals/inplace-choices.md; in the scene view since v1.465): in a
// place, a fight, a payment, a check or a decision is a card in the scene view
// (a button under the map opens it) -- the action's icon, its words, a
// "→ destination" line and a tag (a price, a kind, an alignment shift) -- and
// has no pin on the map; only the plain ways on keep their marks, and a hub's
// choices are a chip for each kind. At phone width, in English and in French.
// UX_SHOTS (a folder) saves pictures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/city_provider.dart'
    show cityPlanRecordsProvider;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

int _count(String prefix) => find
    .byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        RegExp('^$prefix\\d+\$').hasMatch((w.key as ValueKey<String>).value))
    .evaluate()
    .length;

void main() {
  testWidgets('the scene view holds what is done here, the map the ways on',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        // The generated plan under the marks, not the stored city chart.
        cityPlanRecordsProvider.overrideWith((ref) async => const {}),
      ],
      child: RepaintBoundary(key: _shotKey, child: const MyApp()),
    ));
    await tester.runAsync(_loadFonts);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 127,
        })));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    // A sheet opening or closing, over a map that never stops moving.
    Future<void> sheet() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    await tester.tap(find.text('Journey'));
    await _settle(tester);

    // The Stone Bridge: a toll to pay or a fight, both done on the bridge.
    // They are not on the map (no way on, so no mark either): a button under
    // the map opens the scene view, where they are cards.
    play.jumpTo('260');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 6));
    expect(_count('journey_step_'), 0, reason: 'no way on: no mark');
    expect(_count('journey_choice_card_'), 0,
        reason: 'the choices done here are not on the map');
    expect(find.byKey(const ValueKey('journey_open_choices')), findsOneWidget);
    await _shot(tester, 'choice-cards-bridge-map');
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_count('journey_choice_card_'), 2);
    final toll = find.byKey(const ValueKey('journey_choice_card_0'));
    expect(find.descendant(of: toll, matching: find.textContaining('Pay the')),
        findsOneWidget);
    // The price comes from the next scene, and the card says it.
    expect(find.descendant(of: toll, matching: find.textContaining('30')),
        findsWidgets);
    final fight = find.byKey(const ValueKey('journey_choice_card_1'));
    expect(find.descendant(of: fight, matching: find.text('The family house')),
        findsOneWidget,
        reason: 'the fight walks on to the family house afterwards');
    expect(find.descendant(of: fight, matching: find.text('Fight')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('journey_go')), findsNothing);
    await _shot(tester, 'choice-cards-bridge');

    // A tap picks a card: Go appears on it, and its tag gives way.
    await tester.tap(toll);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.descendant(of: toll, matching: find.byType(FilledButton)),
        findsOneWidget);
    await _shot(tester, 'choice-cards-bridge-picked');

    // French, and the narrowest phone.
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    tester.view.physicalSize = const Size(320, 640);
    await _settle(tester);
    expect(find.byKey(const ValueKey('journey_choice_card_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'choice-cards-bridge-fr-320');
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    tester.view.physicalSize = const Size(400, 860);
    await _settle(tester);
    // Back to the map.
    await tester.tap(find.byKey(const ValueKey('journey_continue')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_count('journey_choice_card_'), 0);

    // The wharf, a hub: marks on the map for the ways on, and nothing else;
    // in the scene view, a chip for each kind of choice done here.
    play.jumpTo('2015');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 6));
    // What arriving opens over the game (the new place's card) is closed.
    for (var i = 0; i < 3; i++) {
      Navigator.of(tester.element(find.byType(JourneyScreen)))
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
    final pins = _count('journey_step_');
    expect(pins, greaterThan(3));
    expect(_count('journey_choice_card_'), 0, reason: 'a hub shows chips');
    for (final id in ['fight', 'talkDecide', 'checksPay']) {
      expect(find.byKey(ValueKey('choice_chip_$id')), findsNothing,
          reason: 'the map offers only the ways that move the party');
      expect(find.byKey(ValueKey('choice_ring_chip_$id')), findsNothing,
          reason: id);
    }
    await _shot(tester, 'choice-hub-map');
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_count('journey_choice_card_'), 0, reason: 'a hub shows chips');
    for (final id in ['fight', 'talkDecide', 'checksPay']) {
      expect(find.byKey(ValueKey('choice_chip_$id')), findsOneWidget,
          reason: id);
    }
    expect(find.byKey(const ValueKey('choice_chip_ways')), findsNothing);
    await _shot(tester, 'choice-hub-scene');

    // A chip opens its list in a sheet.
    await tester.tap(find.byKey(const ValueKey('choice_chip_talkDecide')));
    await sheet();
    expect(find.byKey(const ValueKey('choice_sheet_close')), findsOneWidget);
    expect(_count('journey_choice_card_'), greaterThan(3));
    await _shot(tester, 'choice-hub-scene-open');
    await tester.tap(find.byKey(const ValueKey('choice_sheet_close')));
    await sheet();
    expect(find.byKey(const ValueKey('choice_sheet_close')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('choice_chip_fight')));
    await sheet();
    expect(_count('journey_choice_card_'), greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('choice_sheet_close')));
    await sheet();
    expect(tester.takeException(), isNull);
  });
}

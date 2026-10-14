// The character sheet (v1.223): the race and the profession lead with the
// first sentence of their lore and show what they change; the numbers that
// matter come first as bars and tiles; the eight abilities are a grid whose
// tiles tell what they do when held.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';

Future<void> _settle(WidgetTester tester, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUp(rootBundle.clear);

  test('a lore text splits into its first sentence and the rest', () {
    final (lead, rest) = leadAndRest(
        'Quick and attuned to the around, at the cost of a frailer frame. '
        'The painted folk: an elf is strong.');
    expect(lead,
        'Quick and attuned to the around, at the cost of a frailer frame.');
    expect(rest, 'The painted folk: an elf is strong.');
    final (only, none) = leadAndRest('One sentence only.');
    expect(only, 'One sentence only.');
    expect(none, isEmpty);
    expect(leadAndRest(''), ('', ''));
  });

  testWidgets(
      'the sheet is a dossier: the abilities beside the radar, chips for the elements',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: RaceProfessionScreen()),
    ));
    await _settle(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(RaceProfessionScreen)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'elf',
          'professionId': 'warrior',
          'characterName': 'Maren',
          'strength': 3,
          'luck': 2,
          'equippedItemIds': ['staff_t6', 'cloak_frostward'],
        })));
    await _settle(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('Maren'), findsOneWidget);
    expect(find.byKey(const Key('sheet_race_card')), findsOneWidget);
    expect(find.byKey(const Key('sheet_profession_card')), findsOneWidget);
    expect(find.byKey(const Key('sheet_level')), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    // The tag is a chip of its own, no longer a prefix of the lore.
    expect(find.text('QUICK'), findsOneWidget);
    expect(find.textContaining('Quick · '), findsNothing);

    await tester.scrollUntilVisible(
        find.byKey(const Key('sheet_abilities')), 300,
        scrollable: find.byType(Scrollable).first);
    final grid = find.byKey(const Key('sheet_abilities'));
    expect(grid, findsOneWidget);
    for (final label in [
      'Strength',
      'Dexterity',
      'Constitution',
      'Intelligence',
      'Wisdom',
      'Perception',
      'Luck',
      'Charisma',
    ]) {
      expect(
          find.descendant(of: grid, matching: find.text(label)), findsOneWidget,
          reason: label);
    }
    // Held, a tile tells what the stat does.
    await tester
        .longPress(find.descendant(of: grid, matching: find.text('Strength')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The elements the equipped items give: a staff of fire and a frost
    // cloak, a chip each; the four views of them a tap away.
    await tester.scrollUntilVisible(
        find.byKey(const Key('sheet_elements')), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Fire 12/0'), findsOneWidget); // +12 damage
    expect(find.text('Ice 0/14'), findsOneWidget); // 14 resistance
    expect(find.byKey(const Key('elements_view_0')), findsNothing);
    await tester.tap(find.byKey(const Key('sheet_elements_open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('elements_view_0')), findsOneWidget);
    expect(find.text('12/0'), findsOneWidget);
    expect(find.text('0/14'), findsOneWidget);
    await tester.tap(find.text('Rose'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('elements_view_2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing a race and a profession draws the shape they make',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: RaceProfessionScreen()),
    ));
    for (var i = 0; i < 40 && find.text('Human').evaluate().isEmpty; i++) {
      await _settle(tester, 1);
    }
    // The radar is there from the start, showing the plain start, and
    // answers each pick.
    expect(find.byKey(const Key('start_preview_radar')), findsOneWidget);
    await tester.tap(find.text('Human').first);
    await tester.pump();
    expect(find.byKey(const Key('preset_detail_human')), findsOneWidget);
    await tester.tap(find.text('Warrior').first);
    await tester.pump();
    // One detail card for the two: the profession's now, the race behind its tab.
    expect(find.byKey(const Key('preset_detail_warrior')), findsOneWidget);
    expect(find.byKey(const Key('preset_detail_human')), findsNothing);
    expect(find.byKey(const Key('start_preview_name')), findsOneWidget);
    await tester.tap(find.byKey(const Key('detail_tab_race')));
    await tester.pump();
    expect(find.byKey(const Key('preset_detail_human')), findsOneWidget);
    expect(find.byKey(const Key('start_preview_radar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

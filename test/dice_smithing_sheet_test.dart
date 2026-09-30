// The Hammersmith's dice smithing sheet (v1.182): the Temper names its
// elements as the game does and never sells a face its own, a Recast
// shows the number the face comes out with, and a companion's copy of a
// die the player also owns is worked apart from the player's.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/dice_smithing_sheet.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// [text] exactly, in the smithing sheet.
Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

void main() {
  testWidgets('Temper, Recast, and Sable\'s Shadow Die apart from yours',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    // Tall enough for every piece of work a face offers at once.
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    // The player carries a Shadow Die, Sable's own signature die.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'rogue',
          'ownedDiceIds': ['shadow_die'],
          'equippedDiceId': 'shadow_die',
          'gold': 1000,
          'inventoryItemIds': ['material_iron_ore', 'material_iron_ore'],
          'recruitedAllies': [
            {'companionId': 'sable', 'currentHealth': 1 << 30},
          ],
        })));
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => showDiceSmithingSheet(context),
                    child: const Text('forge'),
                  ),
                ),
              ),
            )));
    await _settle(tester);
    await tester.tap(find.text('forge'));
    await _settle(tester);

    // The Shadow Die's strike is a Void one: Void isn't offered, and
    // Electricity reads as the game names it.
    await tester.tap(_inSheet('Attaque'));
    await _settle(tester);
    expect(_inSheet('Foudre'), findsOneWidget);
    expect(_inSheet('Vide'), findsNothing);
    expect(_inSheet('Electricity'), findsNothing);
    expect(_inSheet('Elec'), findsNothing);

    // Its Heal 7 recast: an Attack 6 at most (the die's best strike), a
    // Guard 5 (its best guard).
    await tester.tap(_inSheet('Soin'));
    await _settle(tester);
    expect(_inSheet('Attaque 6'), findsOneWidget);
    expect(_inSheet('Garde 5'), findsOneWidget);

    // Sable's copy is honed; the player's isn't.
    await tester.tap(_inSheet('Sable'));
    await _settle(tester);
    await tester.tap(_inSheet('Attaque'));
    await _settle(tester);
    await tester.tap(_inSheet('+2'));
    await _settle(tester);
    final session = container.read(playerSessionProvider);
    expect(session.gold, 920);
    expect(session.upgradesOfDie('shadow_die'), isNull);
    expect(
        session.upgradesOfDie('shadow_die', companionId: 'sable')!['0']!.hones,
        1);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}

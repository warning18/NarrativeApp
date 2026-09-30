// The Harbor and the sea beasts (v1.185): the hunter's harpoon on sale
// once a beast has been seen, fitted in place of a gun with the gun kept
// in store, and a beast with enough signs to hunt.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/harbor_screen.dart';

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a harpoon swapped in, and a beast ready to hunt',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 500,
          'currentPortId': 'port_ashen_landing',
          'shipPartIds': ['ballista', 'harpoon_rack'],
          'seaBeasts': {
            'brinejaw': {'seen': true, 'clues': 3, 'encounters': 1},
            'pale_leviathan': {'seen': true, 'clues': 1, 'wounds': 40},
          },
        })));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HarborScreen()),
    ));
    final swap = find.byKey(const Key('swap_hunters_harpoon'));
    final card = find.byKey(const Key('beast_card_brinejaw'));
    await _pumpUntil(tester, () => swap.evaluate().isNotEmpty);
    // The beasts are listed below the shipwright's parts.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.scrollUntilVisible(card, 300);

    // The beasts the crew has seen, and which one can be hunted.
    expect(card, findsOneWidget);
    expect(find.byKey(const Key('beast_card_tide_kraken')), findsNothing);
    ElevatedButton hunt(String id) =>
        tester.widget<ElevatedButton>(find.byKey(Key('beast_hunt_$id')));
    expect(hunt('brinejaw').onPressed, isNotNull);
    expect(hunt('pale_leviathan').onPressed, isNull, reason: 'one sign of 3');
    expect(find.textContaining('40'), findsWidgets, reason: 'its wounds');
    // No trophy on offer before a beast is slain.
    expect(find.byKey(const Key('install_sharkskin_hull')), findsNothing);

    // Both gun slots full: the harpoon goes on in place of the rack.
    await tester.ensureVisible(swap);
    await tester.tap(swap);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap_out_harpoon_rack')));
    await _pumpUntil(
        tester,
        () => container
            .read(playerSessionProvider)
            .shipPartIds
            .contains('hunters_harpoon'));
    final session = container.read(playerSessionProvider);
    expect(session.shipPartIds, ['ballista', 'hunters_harpoon']);
    expect(session.storedShipPartIds, ['harpoon_rack']);
    expect(session.gold, 500 - 180);
  });
}

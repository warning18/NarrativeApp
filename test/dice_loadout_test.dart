// The loadout's die: a flat die of its size in the middle of the ring of face
// slots (v1.635), which rolls to the face the player taps; the odds are told
// in Edit Mode only.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';
import 'package:narrative_data_app/widgets/rolling_die.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'the loadout shows the die in the ring, which rolls to a tapped face, '
      'and the odds only in Edit Mode', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DiceLoadoutScreen()),
    ));
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'dwarf',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die', 'iron_die'],
          'equippedDiceId': 'starter_die',
        })));
    await _settle(tester);

    // The die in the middle of the ring: a d6 here, at its first face.
    expect(find.byType(RollingDie), findsOneWidget);
    expect(tester.widget<RollingDie>(find.byType(RollingDie)).face, 0);
    expect(tester.widget<RollingDie>(find.byType(RollingDie)).faceCount, 6);
    // The owned dice are small shapes to pick from.
    expect(find.byKey(const Key('die_pick_iron_die')), findsOneWidget);

    // Edit Mode (the default) tells the odds.
    expect(container.read(appModeProvider), AppMode.edit);
    expect(find.textContaining('of rolls'), findsWidgets);

    // In-game, the numbers go.
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    expect(find.textContaining('of rolls'), findsNothing);

    // A face tapped in the list is the one the die rolls to: it is mid-roll
    // a moment later, a tap on the die skips to its end.
    final before = tester.widget<Text>(find.byKey(const Key('die_face_name')));
    await tester.tap(find.byKey(const Key('face_slot_1')));
    // (A slot also takes a double tap, so its single tap waits a moment.)
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 150));
    double progress() =>
        tester.widget<PolyDie>(find.byType(PolyDie).first).progress!;
    expect(tester.widget<RollingDie>(find.byType(RollingDie)).face, 1);
    expect(progress(), lessThan(1));
    await tester.tap(find.byKey(const ValueKey('rolling_die')));
    await tester.pump();
    expect(progress(), 1);
    await _settle(tester);
    final after = tester.widget<Text>(find.byKey(const Key('die_face_name')));
    expect(after.data, isNot(before.data));

    // A double tap on a face chooses its skill.
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byKey(const Key('face_slot_3')));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byKey(const Key('face_slot_3')));
    await _settle(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

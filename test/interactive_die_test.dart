// The loadout's die as a cube the player turns (v1.241): a drag turns it and
// lets it go on the side nearest the viewer, a tap on the front side acts on
// it, a face tapped in the list is the one in front; and the faces' odds are
// told in Edit Mode only.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/interactive_die.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

List<DieCubeFace> _faces() => [
      for (var i = 0; i < 6; i++)
        DieCubeFace(glyph: Text('$i'), color: Colors.primaries[i]),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each side turned to the front is the side in front', () {
    for (var slot = 0; slot < 6; slot++) {
      final (rx, ry) = dieFrontAngles(slot);
      expect(dieFrontSlot(rx, ry), slot, reason: 'slot $slot');
    }
  });

  testWidgets('a drag turns the cube and lets go on a side', (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: InteractiveDie(
            faces: _faces(),
            skin: boneSkin,
            selected: 0,
            onSelect: picked.add,
          ),
        ),
      ),
    ));
    // A quarter turn to the left brings the right side round.
    await tester.drag(
        find.byKey(const ValueKey('interactive_die')), const Offset(-112, 0));
    await tester.pumpAndSettle();
    expect(picked, [1]);
    // A drag down tips the top toward the viewer.
    await tester.drag(
        find.byKey(const ValueKey('interactive_die')), const Offset(0, 112));
    await tester.pumpAndSettle();
    expect(picked.last, isNot(1));
  });

  testWidgets('a tap on the front side acts on it', (tester) async {
    final acted = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: InteractiveDie(
            faces: _faces(),
            skin: boneSkin,
            selected: 0,
            onSelect: (_) {},
            onActivate: acted.add,
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('interactive_die')));
    await tester.pumpAndSettle();
    expect(acted, [0]);
  });

  testWidgets(
      'the loadout shows the die as a cube, and the odds only in Edit '
      'Mode', (tester) async {
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

    expect(find.byKey(const ValueKey('interactive_die')), findsOneWidget);
    // The owned dice are small cubes to pick from.
    expect(find.byKey(const Key('die_pick_iron_die')), findsOneWidget);

    // Edit Mode (the default) tells the odds.
    expect(container.read(appModeProvider), AppMode.edit);
    expect(find.textContaining('of rolls'), findsWidgets);

    // In-game, the numbers go.
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    expect(find.textContaining('of rolls'), findsNothing);

    // A face tapped in the list is the one the die stands on.
    final before = tester.widget<Text>(find.byKey(const Key('die_face_name')));
    await tester.tap(find.byKey(const Key('face_slot_1')));
    await _settle(tester);
    final after = tester.widget<Text>(find.byKey(const Key('die_face_name')));
    expect(after.data, isNot(before.data));
    expect(tester.takeException(), isNull);
  });
}

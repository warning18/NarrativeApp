// The fight lab's ship parts (v1.186.1): picked slot by slot, never more
// than the Eel has slots for -- two guns, one shield, one fitting, one
// sail -- so a test battle arms her as the Harbor could.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_lab_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the lab fits no more guns than the Eel has gun slots',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FightLabScreen())));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FightLabScreen)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'shipPartIds': ['ballista'],
        })));
    await _settle(tester);

    final pick = find.byKey(const Key('fight_lab_pick_parts'));
    await tester.ensureVisible(pick);
    await tester.tap(pick);
    await _settle(tester);
    expect(find.byKey(const Key('fight_lab_parts')), findsOneWidget);

    bool picked(String id) => tester
        .widget<FilterChip>(find.byKey(Key('fight_lab_part_$id')))
        .selected;
    Future<void> tapPart(String id) async {
      final chip = find.byKey(Key('fight_lab_part_$id'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }

    // The boat as she is: her ballista.
    expect(picked('ballista'), isTrue);
    await tapPart('harpoon_rack');
    expect(picked('ballista'), isTrue);
    expect(picked('harpoon_rack'), isTrue);
    // A third gun takes the oldest one's place.
    await tapPart('fire_pots');
    expect(picked('ballista'), isFalse);
    expect(picked('harpoon_rack'), isTrue);
    expect(picked('fire_pots'), isTrue);
    expect(find.textContaining('2 of 2 filled'), findsWidgets);
    // One shield slot: a second shield replaces the first.
    await tapPart('iron_plating');
    await tapPart('leviathan_bone_plating');
    expect(picked('iron_plating'), isFalse);
    expect(picked('leviathan_bone_plating'), isTrue);
  });
}

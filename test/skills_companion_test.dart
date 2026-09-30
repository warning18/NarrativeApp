// A companion's Skills screen (v1.179): no tabs and no essence, their
// class's skills in one list, each learned there for one of their points.
// Its own file: widget tests in one file share state.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a companion learns from their own list', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SkillsScreen(allyId: 'sable')),
    ));
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'recruitedAllies': [
            AllyState(companionId: 'sable', currentHealth: 50, skillPoints: 1)
                .toJson(),
          ],
        })));
    await _settle(tester);
    // No tabs, no essence: their points and their class's skills.
    expect(find.byKey(const Key('skills_tab_tree')), findsNothing);
    expect(find.byKey(const Key('purse_essence')), findsNothing);
    // Known first, then by id: Backstab heads the list, to learn.
    final learn = find.byKey(const Key('learn_rogue_backstab'));
    expect(learn, findsOneWidget);
    const id = 'rogue_backstab';
    await tester.tap(learn.first);
    await _settle(tester);
    final ally = container
        .read(playerSessionProvider)
        .recruitedAllies
        .firstWhere((a) => a.companionId == 'sable');
    expect(ally.unlockedSkillIds, contains(id));
    expect(ally.skillPoints, 0);
    await tester.pump(const Duration(seconds: 3));
  });
}

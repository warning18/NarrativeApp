// Companion remarks in the story (v1.167): a kind choice made with Maren in
// the party opens the next scene with her words about it, and the next
// choice retires them.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/approval.dart';
import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/remark_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/companion_remark_view.dart';

import 'player_session_provider_test.dart' show baseSession;

Future<void> _settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _closeDialogs(WidgetTester tester) async {
  final button = find.descendant(
      of: find.byType(AlertDialog), matching: find.byType(FilledButton));
  while (button.evaluate().isNotEmpty) {
    await tester.tap(button.first, warnIfMissed: false);
    await _settle(tester);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a companion remarks on a kind choice in the next scene',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await container.read(playerSessionProvider.notifier).loadSession(
          baseSession(
            recruitedAllies: const [
              AllyState(
                companionId: 'maren',
                currentHealth: AllyState.fullHealthSentinel,
                approval: startingApproval,
              ),
            ],
            activeAllyIds: const ['maren'],
          ),
        );
    container.read(storyPlayProvider.notifier).jumpTo('100');
    await _settle(tester);
    await _closeDialogs(tester);
    expect(find.byType(CompanionRemarkView), findsNothing);

    await tester.tap(find.text('Help a neighbor out of the smoke first'));
    // The approval notice, then the next scene.
    await _settle(tester, rounds: 12);
    await _closeDialogs(tester);

    expect(container.read(storyPlayProvider).currentNodeId, '250');
    final remark = container.read(pendingRemarksProvider).firstOrNull;
    expect(remark?.companionId, 'maren');
    expect(remark?.kind, RemarkKind.kindApproved);
    expect(find.byType(CompanionRemarkView), findsOneWidget);
    expect(find.text('SISTER MAREN'), findsOneWidget);
    final line =
        remark!.lineFor(container.read(remarkBookProvider), french: false);
    expect(line, isNotEmpty, reason: 'from the Companion Remarks table');
    expect(find.text('“$line”'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The next choice moves on, and the remark goes with the scene it
    // opened.
    await tester.tap(find.text('Take the Stone Bridge'));
    await _settle(tester, rounds: 12);
    await _closeDialogs(tester);
    expect(container.read(storyPlayProvider).currentNodeId, isNot('250'));
    expect(find.byType(CompanionRemarkView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

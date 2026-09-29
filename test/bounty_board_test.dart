// The camp's bounty board on screen: a met contract pays out at Claim and
// leaves the board; one still in progress can't be claimed yet.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/contracts.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/bounty_board.dart';

void main() {
  testWidgets('claiming a met contract pays it and takes it off the board',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Let the notifier's own first load finish before seeding the session.
    container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    final chapter = container.read(reachedChapterProvider);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({'gold': 5}).copyWith(
          contracts: const [
            Contract(
              id: 'board1_0',
              kind: ContractKind.packs,
              required: 2,
              progress: 2,
              rewardGold: 55,
              rewardEssence: 100,
            ),
            Contract(
              id: 'board1_1',
              kind: ContractKind.weakness,
              required: 4,
              progress: 1,
              rewardGold: 55,
              rewardEssence: 100,
            ),
          ],
          contractsChapter: chapter,
          contractBoards: 1,
        )));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: BountyBoard())),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key('contract_board1_0')), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    final unmet = tester
        .widget<FilledButton>(find.byKey(const Key('contract_claim_board1_1')));
    expect(unmet.onPressed, isNull);

    final essenceBefore = container.read(playerSessionProvider).skillEssence;
    await tester.tap(find.byKey(const Key('contract_claim_board1_0')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    final session = container.read(playerSessionProvider);
    expect(session.gold, 60);
    expect(session.skillEssence, essenceBefore + 100);
    expect(session.contracts.map((c) => c.id), ['board1_1']);
    expect(find.byKey(const Key('contract_board1_0')), findsNothing);
    expect(find.textContaining('+55'), findsWidgets);
  });
}

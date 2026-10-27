// The notice board on screen (v1.561): the chapter and what waits, each note
// with its progress, a seal that is live once a contract is met; a met
// contract pays out at Claim, is stamped PAID and leaves the board; with
// reduced motion it just leaves; one still in progress can't be claimed yet.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/contracts.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/bounty_board.dart';

const _contracts = [
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
];

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    ('Spectral', ['Spectral-Regular.ttf', 'Spectral-Medium.ttf']),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.view(
          Uint8List.fromList(File('assets/fonts/$f').readAsBytesSync())
              .buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(
          ByteData.view(Uint8List.fromList(icons.readAsBytesSync()).buffer)));
    await loader.load();
  }
}

/// Opens the board with [contracts] posted; returns the container.
Future<ProviderContainer> _open(WidgetTester tester,
    {List<Contract> contracts = _contracts, GlobalKey? boundary}) async {
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
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  final chapter = container.read(reachedChapterProvider);
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({'gold': 5}).copyWith(
        contracts: contracts,
        contractsChapter: chapter,
        contractBoards: 1,
      )));
  Widget board = const SingleChildScrollView(
      padding: EdgeInsets.all(16), child: BountyBoard());
  if (boundary != null) {
    board = RepaintBoundary(key: boundary, child: board);
  }
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(body: board),
    ),
  ));
  await tester.pump();
  return container;
}

void main() {
  testWidgets(
      'claiming a met contract pays it, stamps it PAID and takes it off',
      (tester) async {
    final container = await _open(tester);
    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(const Key('contract_board1_0')), findsOneWidget);
    // The board reads: the chapter and what waits, each note's progress.
    expect(find.byKey(const Key('board_header')), findsOneWidget);
    expect(find.textContaining('1 to claim'), findsOneWidget);
    expect(find.text('2 of 2'), findsOneWidget);
    expect(find.text('1 of 4'), findsOneWidget);
    // The seal of a met note is live; the other's is flat.
    InkResponse seal(String id) => tester.widget<InkResponse>(find.descendant(
        of: find.byKey(Key('contract_claim_$id')),
        matching: find.byType(InkResponse)));
    expect(seal('board1_1').onTap, isNull);
    expect(seal('board1_0').onTap, isNotNull);

    final essenceBefore = container.read(playerSessionProvider).skillEssence;
    await tester.tap(find.byKey(const Key('contract_claim_board1_0')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    final session = container.read(playerSessionProvider);
    expect(session.gold, 60);
    expect(session.skillEssence, essenceBefore + 100);
    expect(session.contracts.map((c) => c.id), ['board1_1']);
    expect(find.textContaining('+55'), findsWidgets);
    // The note is stamped PAID where it hung, then drops off the board.
    expect(find.byKey(const Key('contract_paid_stamp')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byKey(const Key('contract_board1_0')), findsNothing);
    expect(find.byKey(const Key('contract_paid_stamp')), findsNothing);
    expect(find.byKey(const Key('contract_board1_1')), findsOneWidget);
  });

  testWidgets('with reduced motion a claimed note is simply gone',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = await _open(tester);
    await tester.pump();
    await tester.tap(find.byKey(const Key('contract_claim_board1_0')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(container.read(playerSessionProvider).contracts, hasLength(1));
    expect(find.byKey(const Key('contract_paid_stamp')), findsNothing);
    expect(find.byKey(const Key('contract_board1_0')), findsNothing);
  });

  testWidgets('with nothing met the header counts the notices up',
      (tester) async {
    await _open(tester, contracts: [_contracts[1]]);
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('1 notices up'), findsOneWidget);
    expect(find.textContaining('to claim'), findsNothing);
  });

  // A picture of the board (UX_SHOTS=<folder>).
  testWidgets('a picture of the board', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    await tester.runAsync(_loadFonts);
    final key = GlobalKey();
    await _open(tester, boundary: key, contracts: const [
      Contract(
          id: 'b0',
          kind: ContractKind.hunt,
          targetEnemyId: 'cave_rat',
          required: 5,
          progress: 5,
          rewardGold: 55,
          rewardEssence: 100),
      Contract(
          id: 'b1',
          kind: ContractKind.flawless,
          required: 3,
          progress: 2,
          rewardGold: 55,
          rewardEssence: 100),
      Contract(
          id: 'b2',
          kind: ContractKind.weakness,
          required: 4,
          progress: 0,
          rewardGold: 55,
          rewardEssence: 100),
    ]);
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/notice-board-built.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

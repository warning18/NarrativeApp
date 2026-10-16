// The unlock moment (v1.423, docs/proposals/unlock-moment-ux.md): a bar's
// item is hidden until its feature opens, a part of a screen is greyed with
// a lock and says when it opens, and the "New: X" card tells the player of
// each feature once, one at a time, never over a fight.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/feature_unlocks.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/combat_active_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/feature_unlock.dart';

import 'player_session_provider_test.dart' show baseSession;

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 130),
          // A bar's button: gone until it opens.
          FeatureGate(
              feature: GameFeature.politics,
              child: Row(children: [
                Icon(Icons.balance, key: Key('bar_politics')),
                UnlockDot(feature: GameFeature.politics),
              ])),
          // A part of a screen: greyed with a lock.
          FeatureGate(
            feature: GameFeature.quests,
            locked: FeatureLockedTile(feature: GameFeature.quests),
            child: Row(children: [
              Text('Quests list', key: Key('part_quests')),
              UnlockDot(feature: GameFeature.quests),
            ]),
          ),
        ],
      );
}

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

Future<ProviderContainer> _pump(WidgetTester tester,
    {List<String> flags = const [featureLadderFlag],
    bool still = false,
    Size size = const Size(360, 640)}) async {
  SharedPreferences.setMockInitialValues({});
  if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: still),
          child: child!),
      home: Scaffold(
        body: RepaintBoundary(
          key: const Key('shot'),
          child: Container(
            color: Colors.white,
            child: const FeatureUnlockHost(
                child: Padding(padding: EdgeInsets.all(16), child: _Bars())),
          ),
        ),
      ),
    ),
  ));
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(baseSession().copyWith(flags: flags)));
  await tester.pump();
  return container;
}

Future<void> _save(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('shut: the bar button is gone, the part is greyed and says when',
      (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('bar_politics')), findsNothing);
    expect(find.byKey(const Key('part_quests')), findsNothing);
    expect(find.byKey(const Key('feature_locked_quests')), findsOneWidget);
    expect(find.byKey(const Key('unlock_card_quests')), findsNothing);
    await _save(tester, 'unlock-locked');

    await tester.tap(find.byKey(const Key('feature_locked_quests')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Opens in chapter 1: Quests'), findsOneWidget);
  });

  testWidgets('a game off the ladder has everything open, and no card',
      (tester) async {
    await _pump(tester, flags: const []);
    expect(find.byKey(const Key('bar_politics')), findsOneWidget);
    expect(find.byKey(const Key('part_quests')), findsOneWidget);
    expect(find.textContaining('New:'), findsNothing);
  });

  testWidgets('a feature opens: its card, its dot, then Later clears both',
      (tester) async {
    final container = await _pump(tester, flags: const [
      featureLadderFlag,
      'feat_quests',
    ]);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('unlock_card_quests')), findsOneWidget);
    expect(find.text('New: Quests'), findsOneWidget);
    expect(find.byKey(const Key('part_quests')), findsOneWidget);
    expect(find.byKey(const Key('unlock_dot_quests')), findsOneWidget);
    await _save(tester, 'unlock-card');

    await tester.tap(find.byKey(const Key('unlock_later')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('unlock_card_quests')), findsNothing);
    expect(find.byKey(const Key('unlock_dot_quests')), findsNothing);
    expect(
        container.read(playerSessionProvider).acknowledgedFeatures, ['quests']);
  });

  testWidgets('two at once queue: one card at a time', (tester) async {
    final container = await _pump(tester, flags: const [
      featureLadderFlag,
      'feat_quests',
      'feat_politics',
    ]);
    await tester.pump(const Duration(milliseconds: 400));
    // Ladder order: quests first.
    expect(find.byKey(const Key('unlock_card_quests')), findsOneWidget);
    expect(find.byKey(const Key('unlock_card_politics')), findsNothing);
    await tester.tap(find.byKey(const Key('unlock_later')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('unlock_card_politics')), findsOneWidget);
    expect(find.text('New: Clans & Politics'), findsOneWidget);
    // Politics has no tour: the button is plain OK.
    expect(find.text('OK'), findsOneWidget);
    await tester.tap(find.byKey(const Key('unlock_show')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FilledButton), findsNothing);
    expect(container.read(playerSessionProvider).acknowledgedFeatures,
        ['quests', 'politics']);
  });

  testWidgets('left alone the card goes after 6 s, the dot stays',
      (tester) async {
    final container = await _pump(tester, flags: const [
      featureLadderFlag,
      'feat_quests',
    ]);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('unlock_card_quests')), findsOneWidget);
    await tester.pump(unlockCardStay + const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('unlock_card_quests')), findsNothing);
    expect(find.byKey(const Key('unlock_dot_quests')), findsOneWidget);
    expect(container.read(playerSessionProvider).acknowledgedFeatures, isEmpty);
  });

  testWidgets('a fight in progress holds the card back', (tester) async {
    final container = await _pump(tester);
    container.read(combatActiveProvider.notifier).state = true;
    await container.read(playerSessionProvider.notifier).loadSession(
        baseSession().copyWith(flags: const [featureLadderFlag, 'feat_chest']));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('unlock_card_chest')), findsNothing);
    container.read(combatActiveProvider.notifier).state = false;
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('unlock_card_chest')), findsOneWidget);
    // The chest has no tour: OK, not Show me.
    expect(find.text('Show me'), findsNothing);
  });

  testWidgets('reduced motion: the card fades in place, the dot is still',
      (tester) async {
    await _pump(tester,
        flags: const [
          featureLadderFlag,
          'feat_quests',
        ],
        still: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('unlock_card_quests')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('unlock_card_quests')),
            matching: find.byType(SlideTransition)),
        findsNothing);
    expect(find.byKey(const Key('unlock_dot_quests')), findsOneWidget);
  });

  testWidgets('French, at 320 px', (tester) async {
    final container = await _pump(tester,
        flags: const [featureLadderFlag, 'feat_skills'],
        size: const Size(320, 640));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Nouveau : Compétences'), findsOneWidget);
    expect(find.text('Montre-moi'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
    await _save(tester, 'unlock-card-fr-320');
    expect(tester.takeException(), isNull);
  });
}

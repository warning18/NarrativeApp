// The Party tab as a formation, and a companion's page (v1.606): the seats and
// the bench, an open seat, one plain line that other companions are out there,
// and a page for each with the seat button under Core's rules (Vica stays
// seated while she is the only one), approval read from approval.dart, and
// the note that benched companions do not see your choices.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';

const _party = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
  'level': 8,
  'builtHouseIds': ['keldas_hall'],
  'activeAllyIds': ['kelda', 'sable'],
  'recruitedAllies': [
    {'companionId': 'kelda', 'currentHealth': 1 << 30, 'approval': 14},
    {'companionId': 'sable', 'currentHealth': 22, 'approval': 6},
    {'companionId': 'maren', 'currentHealth': 1 << 30, 'approval': 0},
  ],
};

const _onlyVica = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
  'level': 8,
  'activeAllyIds': ['vica'],
  'recruitedAllies': [
    {'companionId': 'vica', 'currentHealth': 1 << 30, 'approval': 3},
  ],
};

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ProviderContainer> _open(WidgetTester tester, Map<String, dynamic> save,
    {double width = 412, bool french = false}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      reachedChapterProvider.overrideWithValue(8),
      campTabProvider.overrideWith((ref) => CampTab.party),
    ],
    child: const MaterialApp(home: Scaffold(body: CampScreen(embedded: true))),
  ));
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(appLanguageProvider.notifier)
      .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
  container.read(playerSessionProvider);
  await _settle(tester);
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson(save)));
  await _settle(tester, n: 6);
  return container;
}

void main() {
  setUp(rootBundle.clear);

  testWidgets('the seats, the bench, a locked seat and one line of mention',
      (tester) async {
    await _open(tester, _party);
    expect(find.byKey(const Key('party_seat_kelda')), findsOneWidget);
    expect(find.byKey(const Key('party_seat_sable')), findsOneWidget);
    expect(find.byKey(const Key('party_bench_maren')), findsOneWidget);
    // The third seat a house would add, locked and named by the house.
    expect(find.text('Barracks Annex'), findsOneWidget);
    // One plain line: companions still to meet, with no name and no quest.
    expect(find.byKey(const Key('party_still_out_there')), findsOneWidget);
    expect(find.textContaining('Liora'), findsNothing);
    expect(find.textContaining('???'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hero with only Vica: her seat, an open seat, an empty bench',
      (tester) async {
    await _open(tester, _onlyVica);
    expect(find.byKey(const Key('party_seat_vica')), findsOneWidget);
    expect(find.byKey(const Key('party_open_seat_0')), findsOneWidget);
    expect(find.text('Companions you recruit sit here'), findsOneWidget);
    expect(find.byKey(const Key('companion_portrait_vica')), findsOneWidget);
    // Her own picture, not the class mark.
    expect(
        find.descendant(
            of: find.byKey(const Key('companion_portrait_vica')),
            matching: find.byType(Image)),
        findsOneWidget);
    // Her page: she cannot be benched while she is the only one seated.
    await tester.tap(find.byKey(const Key('party_seat_vica')));
    await _settle(tester);
    final toggle = tester
        .widget<OutlinedButton>(find.byKey(const Key('party_toggle_vica')));
    expect(toggle.onPressed, isNull);
    expect(find.byKey(const Key('companion_stays_vica')), findsOneWidget);
    expect(find.textContaining('Guide dog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a companion\'s page: approval, the bench note, the seat button',
      (tester) async {
    final container = await _open(tester, _party);
    await tester.tap(find.byKey(const Key('party_seat_kelda')));
    await _settle(tester);
    expect(find.byKey(const Key('approval_tier_kelda')), findsOneWidget);
    expect(find.text('Devoted'), findsWidgets);
    expect(find.byKey(const Key('companion_bench_note')), findsOneWidget);
    // Seated: the button moves them to the bench.
    await tester.tap(find.byKey(const Key('party_toggle_kelda')));
    await _settle(tester);
    expect(container.read(playerSessionProvider).activeAllyIds, ['sable']);
    // Benched: the seat button takes a seat again (there is one open).
    await tester.tap(find.byKey(const Key('party_toggle_kelda')));
    await _settle(tester);
    expect(container.read(playerSessionProvider).activeAllyIds,
        containsAll(['kelda', 'sable']));
    // Any notice the seat earned finishes before the test does.
    await tester.pump(const Duration(seconds: 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('at 320 px in French the formation does not overflow',
      (tester) async {
    await _open(tester, _party, width: 320, french: true);
    expect(find.byKey(const Key('party_seat_kelda')), findsOneWidget);
    expect(find.byKey(const Key('party_still_out_there')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

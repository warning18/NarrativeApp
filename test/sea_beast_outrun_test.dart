// A beast outrun on a small phone (v1.185): the day's words keep their
// room (the Eel's picture is left out on a short screen), and a beast
// outrun leaves a sign of itself, as one let pass does, but no edge: only
// a fight seen through teaches the crew its ways.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _data(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// The app's own fonts, so the words take the room they take on a phone.
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
}

const _quiet = SeaEvent(
  kind: SeaEventKind.sighting,
  description: 'Nothing on the water.',
  descriptionFr: 'Rien sur l\'eau.',
  choiceText: 'Sail on',
  choiceTextFr: 'Poursuivre',
);

void main() {
  testWidgets('a beast outrun is a sign of it, read on a small phone',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    // A 360x640 phone: its status bar, and the app's own bottom margin.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);

    final ports = _data('ports');
    final brinejaw = _data('enemy_ships')['brinejaw'] as Map<String, dynamic>;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    // Hands quick enough that the run can't fail.
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 100,
          'dexterity': 40,
        })));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.dark()),
        builder: (context, child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: VoyageScreen(
          fromPortId: 'port_ashen_landing',
          toPortId: 'port_smugglers_wharf',
          toPort: ports['port_smugglers_wharf'] as Map<String, dynamic>,
          debugEvents:
              withBeastDay(const [_quiet, _quiet], 1, 'brinejaw', brinejaw),
        ),
      ),
    ));
    final sailOn = find.byKey(const Key('sea_choice_sailOn'));
    await _pumpUntil(tester, () => sailOn.evaluate().isNotEmpty);
    await tester.tap(sailOn);
    final run = find.byKey(const Key('sea_choice_outrun'));
    await _pumpUntil(tester, () => run.evaluate().isNotEmpty);
    await tester.pump(const Duration(seconds: 1));

    // A short screen: no picture, and the beast's words have the room.
    expect(find.byKey(const Key('ship_at_sea')), findsNothing);
    final words = find.ancestor(
        of: find.byKey(const Key('sea_event_kind')),
        matching: find.byType(SingleChildScrollView));
    expect(tester.getSize(words).height, greaterThan(100));
    expect(find.text('The Brinejaw'), findsOneWidget);

    await tester.tap(run);
    await _pumpUntil(tester,
        () => container.read(playerSessionProvider).currentPortId.isNotEmpty);
    final beast = container.read(playerSessionProvider).seaBeasts['brinejaw']!;
    expect(beast.seen, isTrue);
    expect(beast.clues, 1, reason: 'outrun, it leaves a sign');
    expect(beast.encounters, 0, reason: 'no fight, no edge');
    expect(find.textContaining('The Eel outruns the Brinejaw'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}

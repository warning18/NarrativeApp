// A hunt the Harbor sends out (v1.185): a day at sea, then the beast. The
// signs that led the Eel there are spent once the beast is met, not
// before, and the hunt's own day tells nothing new of it. The fight is on
// the beast's own waters, and it keeps its own look in French too.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';

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

/// The app's own fonts: the test font's square glyphs make the French
/// weather's chip crowd the beast's weapons off the sea.
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

/// A shape under the keel: on any other crossing, a sign of a beast
/// tracked in these waters.
const _shape = SeaEvent(
  kind: SeaEventKind.sighting,
  description: 'Something very large passes beneath the keel.',
  descriptionFr: 'Quelque chose de très grand passe sous la quille.',
  choiceText: 'Sail on',
  choiceTextFr: 'Poursuivre',
);

void main() {
  testWidgets('the signs are spent on meeting the beast, on its own waters',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ports = _data('ports');
    final leviathan =
        _data('enemy_ships')['pale_leviathan'] as Map<String, dynamic>;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    final language = container.read(appLanguageProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => language.setLanguage(AppLanguage.fr));
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 100,
          'currentPortId': 'port_ashen_landing',
          'seaBeasts': {
            'pale_leviathan': {'seen': true, 'clues': 2, 'encounters': 1},
          },
        })));
    int clues() => container
        .read(playerSessionProvider)
        .seaBeasts['pale_leviathan']!
        .clues;

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.dark()),
        home: VoyageScreen(
          fromPortId: 'port_ashen_landing',
          toPortId: 'port_ashen_landing',
          toPort: ports['port_ashen_landing'] as Map<String, dynamic>,
          huntBeastId: 'pale_leviathan',
          debugEvents: [
            _shape,
            beastDayFor('pale_leviathan', leviathan, hunt: true),
          ],
        ),
      ),
    ));
    final sailOn = find.byKey(const Key('sea_choice_sailOn'));
    await _pumpUntil(tester, () => sailOn.evaluate().isNotEmpty);

    // The day out: the hunted beast gives no sign of itself.
    await tester.tap(sailOn);
    final loose = find.byKey(const Key('sea_choice_fight'));
    await _pumpUntil(tester, () => loose.evaluate().isNotEmpty);
    expect(clues(), 2, reason: 'the signs are kept until it is met');

    // The beast: the signs are spent, and it is fought in its own waters
    // (the Black Reliquary's abyss, not the camp's ashen chop), by its own
    // id whatever the language.
    await tester.tap(loose);
    final panel = find.byType(ShipBattlePanel);
    await _pumpUntil(tester, () => panel.evaluate().isNotEmpty);
    expect(clues(), 0);
    final battle = tester.widget<ShipBattlePanel>(panel);
    expect(battle.enemyShipId, 'pale_leviathan');
    expect(battle.enemyName, 'Le Léviathan pâle');
    expect(battle.waters, SeaWaters.abyss);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}

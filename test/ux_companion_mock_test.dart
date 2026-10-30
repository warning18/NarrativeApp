// Review and mock of the camp's Companion interface (docs/proposals/
// companion-interface.md). First the real Party tab at 320 and 412 px, then
// two proposed versions drawn from the same data. Drawn only with UX_SHOTS (a
// folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_companion_mock_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';

import 'ux_companion_mock_parts.dart';
import 'support/fonts.dart';

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _session = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
  'level': 8,
  'builtHouseIds': ['keldas_hall'],
  'activeAllyIds': ['kelda', 'sable'],
  'recruitedAllies': [
    {
      'companionId': 'kelda',
      'currentHealth': 1 << 30,
      'approval': 14,
      'unlockedSkillIds': ['warrior_shield_bash', 'dwarf_stoneskin'],
    },
    {
      'companionId': 'sable',
      'currentHealth': 22,
      'approval': 6,
      'unlockedSkillIds': ['rogue_backstab'],
      'skillPoints': 1,
    },
    {
      'companionId': 'maren',
      'currentHealth': 1 << 30,
      'approval': 0,
      'unlockedSkillIds': ['cleric_holy_light'],
      'skillPoints': 2,
    },
    {
      'companionId': 'grosh',
      'currentHealth': 1 << 30,
      'approval': -8,
      'unlockedSkillIds': ['warrior_shield_bash', 'orc_berserk_rage'],
    },
  ],
};

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the companion review is drawn only with UX_SHOTS', () {});
    return;
  }

  setUp(rootBundle.clear);

  Future<void> settle(WidgetTester tester, {int n = 4}) =>
      _settle(tester, n: n);

  /// The real Party tab at [width]: the top, and scrolled to the end.
  Future<(ui.Image, ui.Image)> real(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 780);
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [
        reachedChapterProvider.overrideWithValue(8),
        campTabProvider.overrideWith((ref) => CampTab.party),
      ],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:
              buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light)),
          home: const Scaffold(body: CampScreen(embedded: true)),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    container.read(playerSessionProvider);
    await settle(tester, n: 4);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(_session)));
    await settle(tester, n: 6);
    Future<ui.Image> grab() async {
      late ui.Image image;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await b.toImage(pixelRatio: 1.5);
      });
      return image;
    }

    final top = await grab();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await settle(tester, n: 3);
    return (top, await grab());
  }

  Widget picture(ui.Image image, double width) => RawImage(
        image: image,
        width: width,
        height: image.height / 1.5,
        fit: BoxFit.fill,
      );

  Future<void> board(
      WidgetTester tester, String file, List<(double, String, Widget)> frames,
      {double height = 780,
      Widget? notes,
      ProviderContainer? container}) async {
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    var width = 48.0 + 24 * frames.length;
    for (final f in frames) {
      width += f.$1;
    }
    if (notes != null) width += 300;
    tester.view.physicalSize = Size(width, height + 110);
    final key = GlobalKey();
    Widget scoped(Widget child) => container == null
        ? ProviderScope(key: UniqueKey(), child: child)
        : UncontrolledProviderScope(container: container, child: child);
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Material(
          color: const Color(0xFF17151B),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in frames) ...[
                  Column(children: [
                    scoped(Phone(
                        width: f.$1,
                        height: height,
                        chrome: container != null,
                        child: f.$3)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: f.$1,
                      child: Text(f.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Spectral',
                              fontSize: 15,
                              color: Color(0xFFEDE6DC))),
                    ),
                  ]),
                  const SizedBox(width: 24),
                ],
                if (notes != null) notes,
              ],
            ),
          ),
        ),
      ),
    ));
    await settle(tester, n: 6);
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('the real tab, then the two versions', (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final (t320, s320) = await real(tester, 320);
    final (t412, s412) = await real(tester, 412);
    await board(tester, 'companion-today.png', [
      (320, 'Today · 320 px · top', picture(t320, 320 - 4)),
      (320, 'Today · 320 px · the end', picture(s320, 320 - 4)),
      (412, 'Today · 412 px · top', picture(t412, 412 - 4)),
      (412, 'Today · 412 px · the end', picture(s412, 412 - 4)),
    ]);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(playerSessionProvider);
    await settle(tester, n: 3);
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(_session)));
    await settle(tester, n: 4);

    await board(
      tester,
      'companion-a.png',
      [
        (412, 'A · the seats, then a row each', const APage()),
        (320, 'A · 320 px', const APage()),
        (412, 'A · "Swap in" when the seats are full', const SwapSheet()),
      ],
      container: container,
      notes: const NotesPanel(title: 'A · The same list, calmer', sections: [
        (
          'Seats first',
          'A strip of the seats shows the party as it will fight: who sits, their health, and the third seat (the Barracks Annex) locked. Seated companions come first; the bench is its own heading.'
        ),
        (
          'One tap to swap',
          '"Swap in" on a benched companion: if the seats are full, a sheet asks who steps out (one more tap). Today it takes two taps on two cards and a scroll.'
        ),
        (
          'A row says more in less',
          'Health as a bar, the tier as a chip (no label, no effect line), the die by name, skills known and points to learn, and Gear / Skills / Dice as three small buttons with a dot when a point waits. "Share a drink" shows only when it can be done.'
        ),
        ('Needs from Core', 'Nothing.'),
      ]),
    );

    await board(
      tester,
      'companion-b.png',
      [
        (412, 'B · the party as a formation', const BPage()),
        (320, 'B · 320 px', const BPage()),
        (412, 'B · a companion’s page', const CompanionPage(id: 'kelda')),
        (412, 'B · the guide dog’s page', const DogPage()),
      ],
      container: container,
      notes:
          const NotesPanel(title: 'B · A formation and a page each', sections: [
        (
          'The party screen',
          'The seats are large portraits with health and tier; the bench is a small grid; below, who is not with you: a "???" with the quest to find them (Vica is not one of them: she comes to every hero), and who left. A tap on any companion opens their page.'
        ),
        (
          'A companion’s page',
          'Approval as a meter with its thresholds named (leaves at −12, wary, friendly at 5, devoted at 12), what the tier does, what they like and dislike as chips, and the rule that benched companions do not see your choices. Then their die (look and name), skills, gear, and the seat button.'
        ),
        (
          'The guide dog (Vica)',
          'The one companion every hero has: her sprite from the tutorial, the first seat, a bench when a stronger companion comes, a replacement. She joins by herself before the city after the desert (Narrative pins the scene). Health (about 42 at level 8) and the Hound Die are Core’s note (#568). Her likes are not set yet.'
        ),
        (
          'Needs from Core',
          'Nothing for the screens. The dog is already in Core’s note (#568): no race, class ranger, hound_die. Open: her likes and dislikes.'
        ),
        (
          'Needs from UX',
          'A portrait per companion: today only the class mark exists (the dog has its sprite).'
        ),
      ]),
    );

    await board(
      tester,
      'companion-dog.png',
      [
        (
          412,
          'Tutorial: the guide, named by the player',
          const DogMoment(
            speaker: 'Vica',
            text:
                'Party: companions you recruit rest here. Choose who fights at your side.',
            counter: '4 / 6',
          )
        ),
        (
          412,
          'Every hero: the guide joins, same sprite, same name',
          const DogMoment(
            speaker: 'Vica',
            text: 'Vica falls in beside you, nose to your heel.',
            nextLabel: 'Walk on',
            walking: true,
            tag: 'New companion',
          )
        ),
        (
          412,
          'The camp with only Vica: first seat, an open one',
          const BPage(onlyVica: true)
        ),
        (
          412,
          'A stronger companion arrives, the seats are full',
          const ArrivalSheet()
        ),
        (
          412,
          'After: Vica waits at camp, and it says so',
          const BPage(withVica: true)
        ),
      ],
      height: 860,
      container: container,
      notes: const NotesPanel(
        title: 'The dog: from the tutorial to the bench',
        sections: [
          (
            'The tutorial guide',
            'Today the guide is a walking and sitting dog with a speech bubble, named by the player in Settings (default "your companion"), and it looks different for a good or an evil hero (an angel or a demon). It is not on the Party tab.'
          ),
          (
            'The handover (before the city after the desert)',
            'When the scene Narrative pins plays, the same dog, with the same bubble, says one line, and the Party tab gets her card with a "New companion" tag. She keeps the name the player gave her (Vica when they never named her) and her look (neutral, angel or demon). One moment, one tap.'
          ),
          (
            'The camp with only Vica',
            'Every hero has her, so the Party tab is never empty: she holds the first seat, the second is an open seat that says what it is for, the third is locked until the Barracks Annex. The bench is empty and "Not with you" lists the companions still to find.'
          ),
          (
            'The swap moment',
            'Kelda arrives and the seats are full. Today she lands on the bench without a word (a recruit is seated only up to capacity). The proposal: a sheet that says who joins and asks who walks with you; each choice says who waits at camp, and what waiting means.'
          ),
          (
            'After',
            'The bench shows Vica with a note: she waits at camp, keeps her health and gear, does not see your choices, and can come back. Nothing is lost, so replacing her costs no regret.'
          ),
          (
            'Needs from Narrative and Core',
            'Narrative: the one line at the handover; the dog carrying the player\u2019s name for her (companionNameProvider) into her companion name; her look following the hero\u2019s alignment as the guide does. Core: the arrival rule (ask when the seats are full instead of benching silently).'
          ),
        ],
      ),
    );
  });
}

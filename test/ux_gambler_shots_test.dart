// The Gambler's Die on the real loadout screen (the die in the ring of slots
// and the owned-dice tile) and rolling at a fight's size (UX_SHOTS=<folder>,
// UX_TAG=today|d12). Drawn only with UX_SHOTS.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'shot';

  testWidgets('the gambler die', skip: shots == null, (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
    await tester.runAsync(loadAppFonts);
    final dice = jsonDecode(
      File('assets/gamedata/dice.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final n = (dice['gambler_die']['numberOfFaces'] as num).toInt();
    Directory(shots!).createSync(recursive: true);

    Future<void> save(GlobalKey key, String name) async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late Uint8List bytes;
      await tester.runAsync(() async {
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$name-$tag.png').writeAsBytesSync(bytes);
    }

    // The real loadout screen on the gambler's die.
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
    usePhone(tester, const Size(420, 900));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final key = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
              theme: buildAppTheme(container
                  .read(appPaletteProvider)
                  .schemeFor(Brightness.light)),
              home: const DiceLoadoutScreen()),
        ),
      ),
    );
    await settleApp(tester);
    await tester.runAsync(
      () => container.read(playerSessionProvider.notifier).loadSession(
            PlayerSession.fromJson({
              'raceId': 'dwarf',
              'professionId': 'warrior',
              'ownedDiceIds': ['starter_die', 'iron_die', 'gambler_die'],
              'equippedDiceId': 'gambler_die',
            }),
          ),
    );
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 2));
    await save(key, 'loadout');

    // Rolling at a fight's size, mid-roll and at rest.
    List<DieCubeFace> faces(int k) => [
          for (var i = 0; i < k; i++)
            DieCubeFace(
              glyph: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              color: FaceKind.values[i % 6].color,
            ),
        ];
    final skin = dieSkinOf('gambler_die');
    final size = n == 12 ? 80.0 : 87.0;
    Widget die(double? roll) => SizedBox(
          width: size * 2.1,
          height: size * 2.1,
          child: Center(
            child: Die3D(
              faces: faces(6),
              facets: faces(n),
              accent: skin.edge,
              size: size,
              shape: dieShapeOf(n),
              skin: skin,
              roll: roll == null ? null : AlwaysStoppedAnimation<double>(roll),
              rolling: roll != null,
            ),
          ),
        );
    final key2 = GlobalKey();
    usePhone(tester, const Size(600, 260));
    await tester.pumpWidget(
      RepaintBoundary(
        key: key2,
        child: MaterialApp(
          theme: buildAppTheme(const ColorScheme.dark()),
          home: Scaffold(
            backgroundColor: const Color(0xFF1B1A22),
            body: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [die(0.2), die(0.55), die(null)],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await save(key2, 'fight');
  });
}

// Mock: a dice card on the Character tab's Overview (docs/proposals/
// character-dice-button.md). The left phone is the real Character screen; the
// right one is the same capture cut under the tabs, with the card drawn in.
// Drawn only with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_character_dice_mock_test.dart
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
import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/skills_radar_card.dart';
import 'package:narrative_data_app/widgets/inventory_parts.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('assets/fonts/$f');
      if (!file.existsSync()) continue;
      loader
          .addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A horizontal band of [image] (captured at [scale]) from [top] to [bottom]
/// logical pixels, drawn at its own size.
class _Slice extends StatelessWidget {
  const _Slice(this.image, this.scale, this.top, this.bottom);
  final ui.Image image;
  final double scale;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(image.width / scale, bottom - top),
        painter: _SlicePainter(image, scale, top, bottom),
      );
}

class _SlicePainter extends CustomPainter {
  _SlicePainter(this.image, this.scale, this.top, this.bottom);
  final ui.Image image;
  final double scale;
  final double top;
  final double bottom;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTRB(0, top * scale, image.width.toDouble(), bottom * scale),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_SlicePainter old) => false;
}

/// The card: the die in hand in its own look, its name and what it is, how
/// many more are in the bag, and a chevron; one tap opens the ring screen.
class _DiceCard extends StatelessWidget {
  const _DiceCard(
      {required this.dieId, required this.faces, required this.more});
  final String dieId;
  final int faces;
  final int more;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final skin = dieSkinOf(dieId);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: ink.gold.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(children: [
          InventoryDieTile(dieId: dieId, faces: faces, size: 46, lit: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR DICE',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
                Text(dieDisplayName(dieId),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontFamily: InkFonts.display)),
                Text('d$faces · $faces faces · ${skin.material}',
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              ],
            ),
          ),
          if (more > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkTag(label: '+$more', color: ink.ash),
            ),
          Icon(Icons.chevron_right, color: ink.ash),
        ]),
      ),
    );
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the character dice mock is drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('the Character tab with a dice card', (tester) async {
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    const width = 412.0;
    const height = 860.0;
    tester.view.physicalSize = const Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const Scaffold(body: CharacterScreen(embedded: true)),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    container.read(playerSessionProvider);
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'characterName': 'Mara',
          'flags': ['feat_clans'],
          'ownedDiceIds': ['starter_die', 'iron_die', 'bulwark_die'],
          'equippedDiceId': 'starter_die',
        })));
    await _settle(tester, n: 6);

    // The real screen, captured.
    const scale = 1.5;
    late ui.Image today;
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      today = await b.toImage(pixelRatio: scale);
    });
    // Just above the radar card, whose top label sits on its border.
    final cut = tester.getTopLeft(find.byType(SkillsRadarCard)).dy - 8;

    Widget phone(String caption, Widget screen) => Column(children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border.all(color: const Color(0xFF3A3642), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: OverflowBox(
                alignment: Alignment.topCenter, maxHeight: 2000, child: screen),
          ),
          const SizedBox(height: 10),
          Text(caption,
              style: const TextStyle(
                  fontFamily: 'Spectral',
                  fontSize: 15,
                  color: Color(0xFFEDE6DC))),
        ]);

    final withCard = Column(mainAxisSize: MainAxisSize.min, children: [
      _Slice(today, scale, 0, cut),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: const _DiceCard(dieId: 'starter_die', faces: 6, more: 2),
      ),
      _Slice(today, scale, cut, height),
    ]);

    tester.view.physicalSize = const Size(width * 2 + 28 + 48, height + 90);
    final board = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: board,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Theme(
          data: theme,
          child: Material(
            color: const Color(0xFF17151B),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  phone('Today: the dice are two taps away (Pages tab)',
                      _Slice(today, scale, 0, height)),
                  const SizedBox(width: 28),
                  phone('With a dice card under the tabs: one tap to the ring',
                      withCard),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    await tester.runAsync(() async {
      final b =
          board.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/character-dice-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

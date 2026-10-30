// Mock: the die in hand on the Character tab's portrait square
// (docs/proposals/character-dice-button.md, second round). Per width (412 and
// 320 px): the real header today, the die as a badge on the portrait's corner,
// and the die in a square beside it. Drawn only with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_character_dice_badge_mock_test.dart
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
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/widgets/skills_radar_card.dart';
import 'package:narrative_data_app/widgets/inventory_parts.dart';
import 'support/fonts.dart';

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

/// The die in hand as a badge on the portrait's lower right corner: its own
/// look, ringed in the page's colour so it reads as lying on the square; the
/// +N of the dice in the bag on its upper corner.
class _CornerBadge extends StatelessWidget {
  const _CornerBadge(
      {required this.dieId, required this.faces, required this.more});
  final String dieId;
  final int faces;
  final int more;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.scaffoldBackgroundColor,
          ),
          child:
              InventoryDieTile(dieId: dieId, faces: faces, size: 28, lit: true),
        ),
        if (more > 0)
          Positioned(
            left: -10,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: ink.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('+$more',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.scaffoldBackgroundColor,
                      fontWeight: FontWeight.w700,
                      height: 1.1)),
            ),
          ),
      ]),
    );
  }
}

/// The square beside the portrait: the die in hand large, in the portrait's
/// own frame, with the +N of the dice in the bag.
class _DieSquare extends StatelessWidget {
  const _DieSquare(
      {required this.dieId, required this.faces, required this.more});
  final String dieId;
  final int faces;
  final int more;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ink.gold.withValues(alpha: 0.6)),
      ),
      child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            InventoryDieTile(dieId: dieId, faces: faces, size: 36, lit: true),
            if (more > 0)
              Positioned(
                right: -4,
                bottom: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: ink.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('+$more',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.scaffoldBackgroundColor,
                          fontWeight: FontWeight.w700,
                          height: 1.1)),
                ),
              ),
          ]),
    );
  }
}

/// The header's first row drawn again with the die square beside the portrait
/// (the name column loses its width, as it would for real).
class _BesideHeader extends StatelessWidget {
  const _BesideHeader({
    required this.name,
    required this.subtitle,
    required this.level,
    required this.xp,
    required this.xpMax,
    required this.dieId,
    required this.faces,
    required this.more,
  });
  final String name;
  final String subtitle;
  final int level;
  final int xp;
  final int xpMax;
  final String dieId;
  final int faces;
  final int more;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Row(children: [
      Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ink.gold, width: 2),
        ),
        child: Text(name.characters.first.toUpperCase(),
            style: theme.textTheme.headlineMedium?.copyWith(color: ink.gold)),
      ),
      const SizedBox(width: 8),
      _DieSquare(dieId: dieId, faces: faces, more: more),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
            const SizedBox(height: 4),
            Row(children: [
              Text('Lvl $level',
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                    value: xpMax <= 0 ? 0 : xp / xpMax,
                    minHeight: 5,
                    color: ink.gold),
              ),
              const SizedBox(width: 8),
              Text('XP $xp/$xpMax',
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ]),
          ],
        ),
      ),
    ]);
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the character dice badge mock is drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('the Character tab with the die on the portrait', (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    const height = 860.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));

    // The real screen at [width], captured; with where its portrait square
    // is and where the tabs end.
    Future<
        ({
          ui.Image image,
          Rect portrait,
          double cut,
          String subtitle,
          double rowBottom
        })> capture(double width) async {
      tester.view.physicalSize = Size(width, height);
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
      late ui.Image image;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await b.toImage(pixelRatio: 1.5);
      });
      final initial = tester.getRect(find.text('M').first);
      final portrait =
          Rect.fromCenter(center: initial.center, width: 56, height: 56);
      final title = tester
          .widget<Text>(find.byKey(const Key('character_title')))
          .textSpan!
          .toPlainText();
      return (
        image: image,
        portrait: portrait,
        cut: tester.getTopLeft(find.byType(SkillsRadarCard)).dy - 8,
        subtitle: title,
        rowBottom: tester.getRect(find.textContaining("Lvl")).bottom + 4,
      );
    }

    final wide = await capture(412);
    final narrow = await capture(320);

    Widget phone(double width, double cut, String caption, Widget screen) =>
        Column(children: [
          Container(
            width: width,
            height: cut + 16,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border.all(color: const Color(0xFF3A3642), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: cut + 80,
                child: screen),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: width,
            child: Text(caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Spectral',
                    fontSize: 15,
                    color: Color(0xFFEDE6DC))),
          ),
        ]);

    Widget row(
        ({
          ui.Image image,
          Rect portrait,
          double cut,
          String subtitle,
          double rowBottom
        }) c,
        double width,
        String die,
        String label) {
      final top = _Slice(c.image, 1.5, 0, c.cut + 16);
      final corner = Stack(clipBehavior: Clip.none, children: [
        top,
        Positioned(
          left: c.portrait.right - 22,
          top: c.portrait.bottom - 22,
          child: _CornerBadge(dieId: die, faces: 6, more: 2),
        ),
      ]);
      // The same capture, its first row (the portrait and the name) replaced
      // by the redrawn one with the die square in it.
      final rowBottom = c.rowBottom;
      final beside = Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: width,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                c.portrait.left, c.portrait.top, c.portrait.left, 4),
            child: _BesideHeader(
              name: 'Mara',
              subtitle: c.subtitle,
              level: 1,
              xp: 0,
              xpMax: 100,
              dieId: die,
              faces: 6,
              more: 2,
            ),
          ),
        ),
        _Slice(c.image, 1.5, rowBottom, c.cut + 16),
      ]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        phone(width, c.cut, '$label · today', top),
        const SizedBox(width: 20),
        phone(width, c.cut, '$label · die on the portrait’s corner', corner),
        const SizedBox(width: 20),
        phone(width, c.cut, '$label · die in a square beside it', beside),
      ]);
    }

    tester.view.physicalSize =
        Size(412 * 3 + 40 + 48 + 6, wide.cut + narrow.cut + 48 + 20 + 2 * 72);
    final board = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: board,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Material(
          color: const Color(0xFF17151B),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                row(wide, 412, 'starter_die', '412 px'),
                const SizedBox(height: 20),
                row(narrow, 320, 'bulwark_die', '320 px'),
              ],
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
      File('$shots/character-dice-badge-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

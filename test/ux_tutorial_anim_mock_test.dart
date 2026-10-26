// A mock of the proposed main-tutorial animation (UX, for the user to approve
// before anything is built): a short guided animation (2 to 4 s) before the
// "New: Journey / Later / Show me" card: the screen dims, a pointer moves to
// the tab, the tab lifts and rings in gold, one line says what it is, a tap
// anywhere skips; then the same card, as today. The left picture is a frame
// (2.4 s into 3.2 s); the right is the card it ends on. The tab bar is the
// app's own labels and icons.
// UX_SHOTS=<folder> takes docs/ux-shots/tutorial-animation-mock.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';

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

const _tabs = [
  (Icons.menu_book, 'Story'),
  (Icons.alt_route, 'Journey'),
  (Icons.person_outline, 'Character'),
  (Icons.local_fire_department_outlined, 'Camp'),
  (Icons.more_horiz, 'Other'),
];

/// Dims everything but a rounded hole round [hole].
class _DimPainter extends CustomPainter {
  _DimPainter(this.hole);
  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
        path, Paint()..color = Colors.black.withValues(alpha: 0.62));
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.hole != hole;
}

/// A frame of the animation: [t] is how far through it (0 to 1).
class _Frame extends StatelessWidget {
  const _Frame({required this.t, required this.total});

  final double t;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.dark;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      const barH = 80.0;
      final tabW = w / _tabs.length;
      final centre = Offset(tabW * 1.5, h - barH / 2);
      // The tab lifts over the first two thirds, the pointer arrives first.
      final lift =
          Curves.easeOutBack.transform((t * 1.6 - 0.35).clamp(0.0, 1.0));
      final pointer = Curves.easeInOut.transform((t * 1.8).clamp(0.0, 1.0));
      final from = Offset(w * 0.82, h * 0.52);
      final pointAt = Offset.lerp(from, centre + const Offset(14, 30), pointer)!;
      final hole =
          Rect.fromCenter(center: centre, width: tabW - 6, height: barH - 8);
      return Stack(children: [
        // The screen under it: a page and the real tab bar.
        Scaffold(
          appBar: AppBar(title: const Text('Story')),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Chapter 1',
                style: theme.textTheme.labelMedium?.copyWith(color: ink.gold)),
            const SizedBox(height: 8),
            Text(
              'The wall comes in and the card game ends. Smoke from the '
              'Lower Town runs up the stair past the shuttered windows.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            destinations: [
              for (final (icon, label) in _tabs)
                NavigationDestination(icon: Icon(icon), label: label),
            ],
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _DimPainter(hole))),
        // The lifted tab: scaled, shadowed, ringed in gold.
        Positioned(
          left: centre.dx - (tabW - 6) / 2,
          top: centre.dy - (barH - 8) / 2 - 10 * lift,
          width: tabW - 6,
          height: barH - 8,
          child: Transform.scale(
            scale: 1 + 0.14 * lift,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ink.gold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: ink.gold.withValues(alpha: 0.35 * lift),
                      blurRadius: 14,
                      spreadRadius: 1),
                ],
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_tabs[1].$1, color: ink.gold),
                    const SizedBox(height: 4),
                    Text(_tabs[1].$2, style: theme.textTheme.labelMedium),
                  ]),
            ),
          ),
        ),
        // The caption: one line, over the lifted tab.
        Positioned(
          left: 20,
          right: 20,
          bottom: barH + 26,
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: ink.gold, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(children: [
                Icon(Icons.alt_route, color: ink.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('The Journey: your story, laid out as a map.',
                      style: theme.textTheme.bodyMedium),
                ),
              ]),
            ),
          ),
        ),
        // The pointer: a ring where it touches, and the hand.
        Positioned(
          left: pointAt.dx - 20,
          top: pointAt.dy - 20,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8), width: 2),
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            const Positioned(
              left: 8,
              top: 8,
              child: Icon(Icons.touch_app,
                  size: 44,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)]),
            ),
          ]),
        ),
        // How far through it is, and how to skip it.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: LinearProgressIndicator(
              value: t,
              minHeight: 3,
              color: ink.gold,
              backgroundColor: Colors.white12),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Text('Tap anywhere to skip',
              style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 4)
                  ])),
        ),
      ]);
    });
  }
}

/// The card the animation ends on, as the app draws it today.
class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.dark;
    return Stack(children: [
      Scaffold(
        appBar: AppBar(title: const Text('Journey')),
        body: const SizedBox.expand(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 1,
          destinations: [
            for (final (icon, label) in _tabs)
              NavigationDestination(icon: Icon(icon), label: label),
          ],
        ),
      ),
      Positioned(
        left: 14,
        right: 14,
        bottom: 96,
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: ink.gold, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      border: Border.all(color: ink.gold, width: 2),
                    ),
                    child: Icon(Icons.alt_route, color: ink.gold, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New: Journey',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: ink.gold)),
                        Text('Your story, laid out as a map.',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Later')),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                      onPressed: () {},
                      child: const Text('Show me'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('a picture of the tutorial animation (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1640, 1500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final theme = buildAppTheme(const ColorScheme.dark());
    Widget phone(String title, Widget child) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 15,
                      color: Color(0xFFE2B890))),
              const SizedBox(height: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Theme(
                    data: theme,
                    child: MediaQuery(
                      data: const MediaQueryData(size: Size(390, 700)),
                      child: child,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        backgroundColor: const Color(0xFF0C0B0F),
        body: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFF0C0B0F),
            child: Row(children: [
              phone('2.4 s into a 3.2 s animation (tap anywhere skips)',
                  const _Frame(t: 0.75, total: 3.2)),
              phone('It ends on today’s card', const _Card()),
            ]),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/tutorial-animation-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

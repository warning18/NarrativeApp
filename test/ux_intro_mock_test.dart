// The intro animation's storyboard (a proposal, nothing of it is in the app):
// eight frames of the first-launch intro, drawn from the widgets the game
// already has (the street-view kit at dusk with ash, the ronin walker, the
// banners, the title) with the timing under each. With UX_SHOTS (a folder)
// set it saves docs/ux-shots/intro-storyboard.png; UX_LAST is the picture of
// the real "choose your race and profession" screen (see the first test).
//   UX_SHOTS=docs/ux-shots UX_LAST=<png> flutter test test/ux_intro_mock_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/side_view/side_sprite.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';
import 'package:narrative_data_app/widgets/wind_banner.dart';

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
      loader.addFont(Future.value(
          ByteData.view(File('assets/fonts/$f').readAsBytesSync().buffer)));
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _save(WidgetTester tester, GlobalKey key, String path,
    {double ratio = 2}) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

const _bg = Color(0xFF0B0A0D);
const _cream = Color(0xFFEDE3C8);
const _ash = Color(0xFF9A93A6);
const _gold = Color(0xFFE2B890);
const _frameW = 210.0;
const _frameH = 373.0;

TextStyle _px(double size, {Color color = _cream, FontWeight? w}) => TextStyle(
    fontFamily: 'PixelifySans', fontSize: size, color: color, fontWeight: w);
TextStyle _serif(double size,
        {Color color = _cream, FontStyle style = FontStyle.normal}) =>
    TextStyle(
        fontFamily: 'Spectral', fontSize: size, color: color, fontStyle: style);

/// One of Narrative's lines (set A, "Grim", English): where it types
/// itself out over the picture, in the story's own text.
class _LineSlot extends StatelessWidget {
  const _LineSlot(this.n, this.text);
  final int n;
  final String text;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 26, 14, 14),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xDD000000)])),
          child: Text(text,
              textAlign: TextAlign.center,
              style: _serif(13.5, style: FontStyle.italic)),
        ),
      );
}

const _lines = {
  1: 'Alster at dusk. The ash had already begun to fall.',
  2: 'The bell rang for the Inquisition. Nobody on Tallow Street looked up.',
  3: 'Every clan wanted the city. None of them wanted you in it.',
  4: 'Tonight it burns. First, decide who you are.',
};

class _Bell extends CustomPainter {
  const _Bell(this.swing);
  final double swing;
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 40;
    canvas.save();
    canvas.translate(size.width / 2, 0);
    canvas.rotate(swing);
    final bronze = Paint()..color = const Color(0xFFB9803A);
    final dark = Paint()..color = const Color(0xFF6B4520);
    final lit = Paint()..color = const Color(0xFFE0B060);
    void px(Paint p, double x, double y, double w, double h) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), p);
    px(dark, -1, 0, 2, 5);
    px(bronze, -5, 5, 10, 3);
    px(bronze, -7, 8, 14, 5);
    px(bronze, -9, 13, 18, 6);
    px(lit, -7, 8, 3, 9);
    px(dark, -10, 19, 20, 2);
    px(dark, -1.5, 21, 3, 3);
    canvas.restore();
    // The tolling, three rings out from it.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.8;
    for (var i = 1; i <= 3; i++) {
      ring.color = _cream.withValues(alpha: 0.5 / i);
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(size.width / 2, 15 * u),
              width: (24 + i * 14) * u,
              height: (24 + i * 14) * u),
          0,
          math.pi * 2,
          false,
          ring);
    }
  }

  @override
  bool shouldRepaint(_Bell old) => old.swing != swing;
}

class _Walker extends CustomPainter {
  const _Walker(this.x, this.t);
  final double x;
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.height / 65;
    canvas.saveLayer(
        Offset.zero & size,
        Paint()
          ..colorFilter =
              const ColorFilter.mode(Color(0xFF07060A), BlendMode.srcATop));
    SideSprites.paint(canvas, u, x, 61, t, moving: true, east: true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Walker old) => old.x != x || old.t != t;
}

class _Cloth extends CustomPainter {
  const _Cloth();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xCC4A4850);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.42,
          size.width * 0.6, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.76,
          size.width * 0.2, size.height * 0.5)
      ..quadraticBezierTo(
          size.width * 0.1, size.height * 0.4, 0, size.height * 0.52)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_Cloth old) => false;
}

Widget _street(String kind, String name) => StreetViewScene(
    kind: kind,
    name: name,
    phase: DayPhase.dusk,
    sky: WeatherKind.ash,
    party: false);

class _Beat {
  const _Beat(this.time, this.title, this.how, this.scene,
      {this.line, this.isNew = ''});
  final String time;
  final String title;
  final String how;
  final Widget scene;
  final int? line;
  final String isNew;
}

Widget _frame(int n, _Beat b) => SizedBox(
      width: _frameW,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: _frameW,
          height: _frameH,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: Colors.black, child: b.scene),
              if (b.line != null) _LineSlot(b.line!, _lines[b.line!]!),
              Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: const Color(0xCC000000),
                    child: Text('$n', style: _px(13, color: _gold)),
                  )),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Text(b.time, style: _px(13, color: _gold, w: FontWeight.w600)),
        Text(b.title, style: _serif(12.5)),
        const SizedBox(height: 2),
        Text(b.how, style: _serif(10.5, color: _ash)),
        if (b.isNew.isNotEmpty)
          Text('new: ${b.isNew}',
              style: _px(10.5, color: const Color(0xFFE08A6A))),
      ]),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final last = Platform.environment['UX_LAST'];
  if (shots == null) {
    test('the intro storyboard is drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('the real "choose your race and profession" screen',
      (tester) async {
    if (last == null) return;
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.tap(find.byKey(const Key('menu_new_game')));
    for (var i = 0; i < 8; i++) {
      await _settle(tester);
    }
    // The story's first scene offers "Choose who you are": its Go opens
    // the race and profession screen.
    await tester.tap(find.text('Go'));
    for (var i = 0; i < 6; i++) {
      await _settle(tester);
    }
    final key = GlobalKey();
    // The route's own boundary: the whole screen.
    final boundary = tester.renderObject<RenderRepaintBoundary>(find
        .descendant(
            of: find.byType(MaterialApp),
            matching: find.byType(RepaintBoundary))
        .first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(last).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(key, isNotNull);
  });

  testWidgets('the storyboard', (tester) async {
    await tester.runAsync(_loadFonts);
    await tester.runAsync(SideSprites.preload);
    ui.Image? lastImage;
    if (last != null && File(last).existsSync()) {
      lastImage = await tester.runAsync(() async {
        final codec =
            await ui.instantiateImageCodec(File(last).readAsBytesSync());
        return (await codec.getNextFrame()).image;
      });
    }
    final clanIds = [
      for (final id in clanBannerFactionIds)
        if (clanBannerId(id) != null) id,
    ];

    Widget fill(Widget w) => Positioned.fill(child: w);
    Widget dimmed(Widget w, double a) => Stack(fit: StackFit.expand, children: [
          w,
          ColoredBox(color: Colors.black.withValues(alpha: a)),
        ]);

    final beats = <_Beat>[
      _Beat(
          '0.0 – 3.0 s',
          'Alster at dusk, ash falling',
          'Fades up from black; the rooftops, the chapel, the quay. Line 1 types itself out.',
          Stack(fit: StackFit.expand, children: [
            _street('temple', 'The Inquisition chapel'),
            Align(
                alignment: Alignment.topCenter,
                child: Container(
                    height: 150,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xDD000000), Color(0x00000000)])))),
          ]),
          line: 1),
      _Beat(
          '3.0 – 6.0 s',
          'The bell tolls',
          'Just a bell: it swings, rings spread over the rooftops, the ash shivers. Line 2.',
          Stack(fit: StackFit.expand, children: [
            _street('temple', 'The Inquisition chapel'),
            Align(
                alignment: const Alignment(0, -0.55),
                child: SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(painter: const _Bell(0.28)))),
          ]),
          line: 2,
          isNew: 'a pixel bell and its rings (about 30 lines)'),
      _Beat(
          '6.0 – 7.5 s',
          'The Inquisition’s banners',
          'The Dominion’s standards hang along the quay, blowing in the wind.',
          Stack(fit: StackFit.expand, children: [
            dimmed(_street('warehouse', 'The quay'), 0.2),
            Align(
                alignment: const Alignment(0, -0.45),
                child: FittedBox(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      for (var i = 0; i < 3; i++)
                        WindBanner(
                            id: clanBannerId('dominion')!,
                            scale: 2,
                            phase: i * 0.31),
                    ]))),
          ])),
      _Beat(
          '7.5 – 10.0 s',
          'The clans, one after another',
          'The thirteen clans’ banners light up in turn: the rivals who want the city. The last slot stays dark: yours. Line 3.',
          Container(
              color: const Color(0xFF17151B),
              padding: const EdgeInsets.fromLTRB(18, 90, 18, 120),
              child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 14,
                  children: [
                    for (final id in clanIds)
                      ClanFlag(factionId: id, height: 56),
                    SizedBox(
                        height: 56,
                        child: FittedBox(
                            child: PixelBanner(
                                id: titleBannerId, scale: 1, found: false))),
                  ])),
          line: 3),
      _Beat(
          '10.0 – 11.5 s',
          'One of the town walks home',
          'The ronin, a local, crosses the quay in silhouette against the dusk.',
          Stack(fit: StackFit.expand, children: [
            _street('warehouse', 'The quay'),
            fill(CustomPaint(painter: const _Walker(18, 0.3))),
          ])),
      _Beat(
          '11.5 – 12.5 s',
          'The Shroud, in six pieces',
          'A grey cloth falls over the picture and shows the player’s own standard torn into its six pieces, hanging in shreds.',
          Stack(fit: StackFit.expand, children: [
            dimmed(_street('temple', 'The Inquisition chapel'), 0.35),
            const CustomPaint(painter: _Cloth()),
            Align(
                alignment: const Alignment(0, -0.2),
                child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      for (final (i, id) in shroudPieceIds.indexed)
                        Padding(
                            padding: EdgeInsets.only(top: i.isEven ? 0 : 14),
                            child: Transform.rotate(
                                angle: (i - 2.5) * 0.045,
                                child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                        Color(0x66404048), BlendMode.srcATop),
                                    child: SizedBox(
                                        width: 50,
                                        height: 100,
                                        child: FittedBox(
                                            child: PixelBanner(
                                                id: id, scale: 1)))))),
                    ])),
          ]),
          isNew:
              'the falling cloth (one painter, a slide and a fade); the six pieces as the character screen draws them'),
      _Beat(
          '12.5 – 13.5 s',
          'The title',
          'Black. The title in the game’s pixel face; the Shroud small above it, still torn: six dark slots, one faintly lit. “Mine, to restore.” (The still frame with reduced motion.)',
          Container(
              color: Colors.black,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (final (i, id) in shroudPieceIds.indexed)
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: SizedBox(
                                width: 28,
                                height: 56,
                                child: Opacity(
                                    opacity: i == 0 ? 0.55 : 1,
                                    child: FittedBox(
                                        child: PixelBanner(
                                            id: id,
                                            scale: 1,
                                            found: i == 0))))),
                    ]),
                    const SizedBox(height: 18),
                    Text('The Grey Shroud',
                        textAlign: TextAlign.center,
                        style: _px(27, w: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Text(
                            'A tale of dice, debts and a shroud that should not exist',
                            textAlign: TextAlign.center,
                            style: _serif(12,
                                color: _ash, style: FontStyle.italic))),
                  ]))),
      _Beat(
          '13.5 – 15.0 s',
          'On to the choice',
          'The title melts into the real “choose your race and profession” screen; line 4 holds there while the player picks.',
          lastImage == null
              ? const ColoredBox(color: Color(0xFFF3EAD7))
              : RawImage(
                  image: lastImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter),
          line: 4),
    ];

    // The timeline under the frames: each beat to scale, the skip marker.
    const spans = [3.0, 3.0, 1.5, 2.5, 1.5, 1.0, 1.0, 1.5];
    final total = spans.fold<double>(0, (a, b) => a + b);
    const boardW = 4 * (_frameW + 16) + 16;
    final key = GlobalKey();
    tester.view.physicalSize = const Size(boardW, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget chip(String t, {Color c = _cream}) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(t, style: _serif(12, color: c)));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: RepaintBoundary(
          key: key,
          child: Container(
            width: boardW,
            color: _bg,
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('The first-launch intro · storyboard (15 s)',
                  style: _px(22, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  'Plays once, before the race and profession choice. Lines: Narrative\u2019s set A (Grim). A tap anywhere skips it; with reduced motion it shows frame 7 still, then frame 8 with line 4 shown at once. Replayable from Settings. Drawn from the game’s own widgets.',
                  style: _serif(12.5, color: _ash)),
              const SizedBox(height: 14),
              Wrap(spacing: 16, runSpacing: 14, children: [
                for (var i = 0; i < beats.length; i++) _frame(i + 1, beats[i]),
              ]),
              const SizedBox(height: 12),
              Text('Timing', style: _px(14, color: _gold)),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: Row(children: [
                  for (var i = 0; i < spans.length; i++)
                    Expanded(
                      flex: (spans[i] * 10).round(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 2),
                        color: Color.lerp(
                            const Color(0xFF3A3642), _gold, i / spans.length),
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: _px(13, color: Colors.black)),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                  '0 s · ${total.toStringAsFixed(0)} s — a short sound cue on the bell (frame 2) is optional',
                  style: _serif(11.5, color: _ash)),
              const SizedBox(height: 16),
              Text('What it is made of', style: _px(14, color: _gold)),
              const SizedBox(height: 6),
              chip(
                  'Reused as it is: the street-view kit at dusk with ash (frames 1, 2, 3, 5, 6), the ronin walker sprite (5), the banners and the clans\u2019 flags, dark ones as silhouettes (3, 4, 7), the six Shroud pieces as the character screen draws them (6, 7), the title screen\u2019s words (7), the story\u2019s typewriter for the four lines, the real Race & Profession screen (8), and the reduced-motion check.'),
              chip(
                  'New: a pixel bell with its rings (2), the falling cloth (6), the pieces hanging torn on it (6), one small intro screen that runs the eight beats on a clock and ends on a tap, a \u201cseen\u201d flag and a Replay row in Settings, Narrative\u2019s four lines (EN and FR).',
                  c: const Color(0xFFE08A6A)),
              chip(
                  'Build: about a day, one PR, about 350 lines and a test (the beats in order, a tap skips, reduced motion shows frame 7, the flag is set once). No new art files.',
                  c: _ash),
            ]),
          ),
        ),
      ),
    ));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await _save(tester, key, '$shots/intro-storyboard.png');
    expect(chip, isNotNull);
  });
}

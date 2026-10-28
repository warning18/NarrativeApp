// Mock: the fight with fixed sizes (docs/proposals/fight-fixed-sizes.md).
// First the fight as it is today (real captures, made by
// ux_fight_size_shots_test.dart into FIGHT_SHOTS_IN), then the stage with a
// fixed box for the hero, each ally, each foe and the boss. Drawn only with
// UX_SHOTS (a folder):
//   FIGHT_SHOTS_IN=/tmp/shots UX_SHOTS=docs/ux-shots flutter test \
//     test/ux_fight_fixed_mock_test.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

const _boxLabel = Color(0xFF2B2A33);

/// What a fixed box is: its size in logical pixels.
class _Boxes {
  const _Boxes(this.hero, this.ally, this.foe, this.boss);
  final double hero;
  final double ally;
  final double foe;
  final double boss;
}

const _wide = _Boxes(96, 64, 96, 144);
const _narrow = _Boxes(72, 48, 72, 108);

/// A figure of the stage: the art in its fixed box, bottom-aligned on the
/// ground line, with its bar over the box.
class _Slot {
  const _Slot(this.kind, this.label, this.asset, this.hp);
  final String kind; // hero, ally, foe, boss
  final String label;
  final String? asset;
  final double hp;
}

const _ronin = 'assets/visuals/walker/ronin_idle_east.png';
String _foe(String n) => 'assets/visuals/fighters/${n}_idle_west.png';

class _Stage extends StatelessWidget {
  const _Stage({
    required this.width,
    required this.party,
    required this.foes,
    required this.back,
    this.damageOn,
  });

  final double width;
  final List<_Slot> party; // hero first, then allies
  final List<_Slot> foes;
  final ui.Image back;

  /// 'foe0': a damage number floats over that box.
  final String? damageOn;

  @override
  Widget build(BuildContext context) {
    final boxes = width < 360 ? _narrow : _wide;
    const height = 215.0;
    const ground = 22.0;
    final boxFor = {
      'hero': boxes.hero,
      'ally': boxes.ally,
      'foe': boxes.foe,
      'boss': boxes.boss,
    };
    final out = <Widget>[];

    Widget box(_Slot s, double left, double lift, {String? key}) {
      final size = boxFor[s.kind]!;
      final isBack = lift > 0;
      return Positioned(
        left: left,
        bottom: ground + lift,
        child: SizedBox(
          width: size,
          height: size + 22,
          child: Stack(clipBehavior: Clip.none, children: [
            // The bar, anchored to the box.
            Positioned(
              left: size * 0.18,
              right: size * 0.18,
              top: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: s.hp,
                  minHeight: 5,
                  color: s.hp < 0.4
                      ? const Color(0xFFC0392B)
                      : const Color(0xFF3F8F5A),
                  backgroundColor: const Color(0x66000000),
                ),
              ),
            ),
            if (key == damageOn)
              Positioned(
                left: 0,
                right: 0,
                top: -22,
                child: Center(
                  child: Text('−24',
                      style: TextStyle(
                          fontFamily: 'PixelifySans',
                          fontSize: size > 100 ? 22 : 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE5532D),
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 3)
                          ])),
                ),
              ),
            if (!isBack)
              Positioned(
                left: 0,
                right: 0,
                top: 22 + size + 2,
                child: Center(
                  child: Text('${s.kind} ${size.round()}',
                      style: const TextStyle(
                          fontFamily: 'PixelifySans',
                          fontSize: 10,
                          color: Color(0xFF3A3A32))),
                ),
              ),
            // The box, dashed, the art inside it on the ground line.
            Positioned(
              left: 0,
              top: 22,
              child: CustomPaint(
                size: Size(size, size),
                painter: _DashedBox(
                    isBack ? const Color(0x99FFFFFF) : const Color(0xFFFFFFFF)),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: s.asset == null
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: size * 0.62,
                            height: size * 0.62,
                            margin: const EdgeInsets.only(bottom: 2),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xCCF3E8D0),
                              border: Border.all(
                                  color: const Color(0xFF8C6D3F), width: 2),
                            ),
                            child: Text(s.label.substring(0, 1),
                                style: TextStyle(
                                    fontFamily: 'IMFellEnglishSC',
                                    fontSize: size * 0.3,
                                    color: _boxLabel)),
                          ),
                        )
                      : Image.asset(s.asset!,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.none),
                ),
              ),
            ),
          ]),
        ),
      );
    }

    // The party: the hero in front on the right of its half, the allies in
    // a back row to the left of it.
    final zone = width * 0.47;
    final heroLeft = zone - boxes.hero - 4;
    final step = width < 360 ? 24.0 : 32.0;
    for (var i = party.length - 1; i >= 1; i--) {
      out.add(box(party[i], heroLeft - step * i - (width < 360 ? 6 : 0), 12));
    }
    out.add(box(party[0], heroLeft, 0));
    // The foes: slots fixed by position, whatever their number: front right,
    // front left, back middle; the boss has the middle of the half to itself.
    final foeZone = width * 0.53;
    final right = width - 12;
    if (foes.length == 1 && foes.first.kind == 'boss') {
      out.add(box(foes.first, right - boxes.boss, 0, key: 'foe0'));
    } else {
      final f1 = right - boxes.foe;
      final f2 = max(foeZone - 6, f1 - boxes.foe + 6);
      final f3 = (f1 + f2) / 2;
      if (foes.length > 2) {
        out.add(box(foes[2], f3, 12, key: 'foe2'));
      }
      if (foes.length > 1) out.add(box(foes[1], f2, 0, key: 'foe1'));
      out.add(box(foes[0], f1, 0, key: 'foe0'));
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(painter: _BackPainter(back)),
          ),
          // The ground line.
          Positioned(
            left: 0,
            right: 0,
            bottom: ground,
            child: Container(height: 1, color: const Color(0x55FFFFFF)),
          ),
          ...out,
        ]),
      ),
    );
  }
}

/// A plain stand-in for the fight's open-country ground: sky, two hills,
/// the field and a few trees (the real stage is drawn behind the cards).
class _BackPainter extends CustomPainter {
  _BackPainter(this.image);
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC7D0BA), Color(0xFFAEBB9F)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);
    Path hill(double base, double amp, double phase) {
      final p = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 6) {
        p.lineTo(
            x, size.height * base - amp * sin(x / size.width * 3.1 + phase));
      }
      return p
        ..lineTo(size.width, size.height)
        ..close();
    }

    canvas.drawPath(
        hill(0.52, 18, 0.4), Paint()..color = const Color(0xFF9FAD8E));
    canvas.drawPath(
        hill(0.66, 12, 2.0), Paint()..color = const Color(0xFF8E9F7B));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 36, size.width, 36),
      Paint()..color = const Color(0xFF8A9A70),
    );
    for (final x in [0.12, 0.44, 0.91]) {
      canvas.drawCircle(Offset(size.width * x, size.height * 0.6), 9,
          Paint()..color = const Color(0xFF7C8D69));
    }
  }

  @override
  bool shouldRepaint(_BackPainter old) => false;
}

class _DashedBox extends CustomPainter {
  _DashedBox(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 4.0;
    void line(Offset a, Offset b) {
      final d = (b - a);
      final len = d.distance;
      final dir = d / len;
      for (var t = 0.0; t < len; t += dash * 2) {
        canvas.drawLine(a + dir * t, a + dir * min(t + dash, len), paint);
      }
    }

    line(Offset.zero, Offset(size.width, 0));
    line(Offset(size.width, 0), Offset(size.width, size.height));
    line(Offset(size.width, size.height), Offset(0, size.height));
    line(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color;
}

Future<ui.Image> _load(String path) async {
  final bytes = File(path).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final input = Platform.environment['FIGHT_SHOTS_IN'];
  if (shots == null || input == null) {
    test('the fixed-size fight is drawn only with UX_SHOTS and FIGHT_SHOTS_IN',
        () {});
    return;
  }

  setUp(rootBundle.clear);

  Future<void> board(WidgetTester tester, String file,
      List<(double, String, Widget, double)> frames,
      {int perRow = 3, Widget? notes}) async {
    // Frames in rows of [perRow].
    final rows = <List<(double, String, Widget, double)>>[];
    for (var i = 0; i < frames.length; i += perRow) {
      rows.add(frames.sublist(i, min(i + perRow, frames.length)));
    }
    var width = 0.0;
    var height = 48.0;
    for (final row in rows) {
      width = max(width, 48.0 + row.fold<double>(0, (s, f) => s + f.$1 + 32));
      height += row.map((f) => f.$4).reduce(max) + 60;
    }
    tester.view.physicalSize = Size(width + (notes == null ? 0 : 324), height);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: const Color(0xFF17151B),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final row in rows) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final f in row) ...[
                        Column(children: [
                          f.$3,
                          const SizedBox(height: 8),
                          SizedBox(
                            width: f.$1,
                            child: Text(f.$2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Spectral',
                                    fontSize: 14,
                                    color: Color(0xFFEDE6DC))),
                          ),
                        ]),
                        const SizedBox(width: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ]),
              if (notes != null) notes,
            ]),
          ),
        ),
      ),
    ));
    await _settle(tester, n: 6);
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.25);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('the fight today, then with fixed sizes', (tester) async {
    await tester.runAsync(_loadFonts);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    // The real captures, by name.
    late final Map<String, ui.Image> real;
    await tester.runAsync(() async {
      real = {
        for (final n in [
          'solo-warden',
          'a3-soldier',
          'a1-pack3',
          'a3-pack3',
          's-solo-warden',
          's-a3-soldier',
          'a0-thug',
        ])
          n: await _load('$input/$n.png'),
      };
    });
    Widget shot(String name, double width) {
      final image = real[name]!;
      return Container(
        width: width,
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF3A3642), width: 2),
            borderRadius: BorderRadius.circular(6)),
        child: RawImage(
            image: image,
            width: width - 4,
            height: (width - 4) * image.height / image.width,
            fit: BoxFit.fill),
      );
    }

    await board(
      tester,
      'fight-sizes-today.png',
      [
        (
          412,
          'Alone against a warden: hero ×3, warden ×3',
          shot('solo-warden', 412),
          860.0
        ),
        (
          412,
          'Three allies, one soldier: the hero is gone, the soldier ×3',
          shot('a3-soldier', 412),
          860.0
        ),
        (
          412,
          'One ally, three soldiers: hero ×3, soldiers ×1',
          shot('a1-pack3', 412),
          860.0
        ),
        (
          412,
          'Three allies, three soldiers: no hero, soldiers ×1',
          shot('a3-pack3', 412),
          860.0
        ),
        (
          320,
          '320 px, alone: hero ×2, warden ×1',
          shot('s-solo-warden', 320),
          640.0
        ),
        (
          320,
          '320 px, three allies: the hero is gone, the soldier ×1',
          shot('s-a3-soldier', 320),
          640.0
        ),
      ],
      perRow: 4,
    );

    final back = real['a0-thug']!;
    const hero = _Slot('hero', 'You', _ronin, 0.8);
    _Slot ally(String n, double hp) => _Slot('ally', n, null, hp);
    final allies = [
      ally('Kelda', 1),
      ally('Sable', 0.45),
      ally('Sister Maren', 0.9)
    ];
    final soldier = _Slot('foe', 'Soldier', _foe('white_soldier'), 0.9);
    final inq2 = _Slot('foe', 'Soldier', _foe('inquisition_soldier_02'), 0.7);
    final inq3 = _Slot('foe', 'Auxiliary', _foe('inquisition_soldier_03'), 1);
    final warden = _Slot('foe', 'Warden', _foe('inquisition_warden'), 0.85);
    final boss = _Slot('boss', 'Aurel', _foe('aurel_vane'), 0.6);

    Widget stage(double width, List<_Slot> party, List<_Slot> foes,
            {String? damage}) =>
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF3A3642), width: 2),
              borderRadius: BorderRadius.circular(6)),
          clipBehavior: Clip.antiAlias,
          child: _Stage(
              width: width,
              party: party,
              foes: foes,
              back: back,
              damageOn: damage),
        );

    await board(
      tester,
      'fight-sizes-fixed.png',
      [
        (
          412,
          'Alone against a warden',
          stage(412, [hero], [warden], damage: 'foe0'),
          219.0
        ),
        (
          412,
          'Three allies, one soldier',
          stage(412, [hero, ...allies], [soldier], damage: 'foe0'),
          219.0
        ),
        (
          412,
          'One ally, three soldiers',
          stage(412, [hero, allies[0]], [soldier, inq2, inq3], damage: 'foe1'),
          219.0
        ),
        (
          412,
          'Three allies, three soldiers',
          stage(412, [hero, ...allies], [soldier, inq2, inq3], damage: 'foe2'),
          219.0
        ),
        (
          412,
          'Three allies against a boss',
          stage(412, [hero, ...allies], [boss], damage: 'foe0'),
          219.0
        ),
        (
          320,
          '320 px: smaller boxes, the same slots',
          stage(320, [hero, ...allies], [soldier, inq2, inq3], damage: 'foe0'),
          219.0
        ),
      ],
      perRow: 2,
    );
  });
}

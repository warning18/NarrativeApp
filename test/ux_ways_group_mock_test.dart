// A mock of the Journey's list of ways grouped by pin (UX, for the user to
// approve before anything is built): today every way is a row, so a pin that
// holds several choices spreads over several rows and the shape of the map is
// lost; the proposal is one row per pin, with the pin's name and a count,
// opening on a tap to its choices. A pin with one way stays a plain row. The
// words are scene 891's; the rows are built from the Journey's own pieces
// (BannerPin, the seam-ruled row, the kind disc).
// UX_SHOTS=<folder> takes docs/ux-shots/ways-grouped-mock.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/journey_banner_pin.dart';

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

class _Way {
  const _Way(this.label, this.icon, this.cat);
  final String label;
  final IconData icon;
  final JourneyPinCat? cat;
}

/// One pin of the map: its name, the ways it holds.
class _Pin {
  const _Pin(this.name, this.cat, this.ways);
  final String name;
  final JourneyPinCat cat;
  final List<_Way> ways;
}

const _pins = [
  _Pin('Whistle for the hound', JourneyPinCat.main, [
    _Way('Whistle for the hound', Icons.pets, JourneyPinCat.main),
    _Way('Bind your wounds with sailcloth', Icons.healing, null),
    _Way('Snatch a blade off the looted armory rack', Icons.hardware, null),
    _Way('Pull a buckler from the shieldwright’s overturned cart',
        Icons.shield_outlined, null),
  ]),
  _Pin('Talk to the mate at the gangway', JourneyPinCat.way, [
    _Way('Talk to the mate at the gangway', Icons.forum, JourneyPinCat.way),
  ]),
];

Widget _kindDisc(Color colour, IconData icon, {double size = 28}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colour.withValues(alpha: 0.16),
        border: Border.all(color: colour, width: 1.5),
      ),
      child: Icon(icon, size: size * 0.55, color: colour),
    );

/// The list, one row per pin; [open] pins are expanded.
Widget _list(BuildContext context, Set<int> open, {required bool grouped}) {
  final theme = Theme.of(context);
  final ink = InkColors.dark;
  Widget lead(_Way w, JourneyPinCat? cat, {double scale = 0.8}) => cat == null
      ? _kindDisc(ink.gold, w.icon)
      : BannerPin(
          cat: cat,
          color: cat.colorOn(ink, dark: true),
          dark: true,
          scale: scale,
        );
  Widget row(Widget lead, String label,
          {Widget? trailing, double indent = 0, bool first = true}) =>
      Container(
        padding: EdgeInsets.fromLTRB(indent, 7, 0, 7),
        decoration: BoxDecoration(
            border:
                Border(top: BorderSide(color: first ? ink.seam : ink.seam))),
        child: Row(children: [
          SizedBox(width: 30, child: Center(child: lead)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.2)),
          ),
          if (trailing != null) trailing,
        ]),
      );
  final rows = <Widget>[
    Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(grouped ? '2 PINS · 5 WAYS' : '5 WAYS',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: ink.ash, letterSpacing: 0.8)),
    ),
  ];
  for (final (p, pin) in _pins.indexed) {
    if (!grouped) {
      for (final w in pin.ways) {
        rows.add(row(lead(w, w.cat), w.label));
      }
      continue;
    }
    if (pin.ways.length == 1) {
      rows.add(row(lead(pin.ways.first, pin.ways.first.cat), pin.name));
      continue;
    }
    final isOpen = open.contains(p);
    rows.add(Container(
      color: isOpen ? ink.gold.withValues(alpha: 0.06) : null,
      child: Column(children: [
        row(
          lead(pin.ways.first, pin.cat),
          pin.name,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ink.ash.withValues(alpha: 0.7)),
              ),
              child:
                  Text('${pin.ways.length}', style: theme.textTheme.labelSmall),
            ),
            Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                size: 22, color: ink.ash),
          ]),
        ),
        if (isOpen)
          for (final w in pin.ways)
            row(
              lead(w, w.cat, scale: 0.65),
              w.label,
              indent: 22,
            ),
      ]),
    ));
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('a picture of the grouped ways (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    Widget panel(String title, Widget Function(BuildContext) list) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Spectral',
                        fontSize: 15,
                        color: Color(0xFFE2B890))),
                const SizedBox(height: 4),
                Builder(builder: list),
              ],
            ),
          ),
        );
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        backgroundColor: const Color(0xFF17151B),
        body: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFF17151B),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              panel('Today: one row per way',
                  (c) => _list(c, const {}, grouped: false)),
              panel('Proposed: one row per pin',
                  (c) => _list(c, const {}, grouped: true)),
              panel('Proposed: the pin opened',
                  (c) => _list(c, const {0}, grouped: true)),
            ]),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/ways-grouped-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  });
}

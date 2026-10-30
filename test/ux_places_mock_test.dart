// The district view as places (UX mock, nothing built): the user's call is
// that the pins and the list under the map are the PLACES of the district (the
// Lark's gangway, the looted armory...), not the scene's choice texts; a tap
// walks the party there and the choices appear on arrival, on the street view.
// The header and the map are the real screen (a capture of the app at scene
// 891, the High Quay: UX_TODAY, taken by the first test); the pins, the rows,
// the walk and the arrival are drawn with the app's own widgets (BannerPin,
// StreetViewScene).
//   UX_SHOTS=docs/ux-shots UX_TODAY=<png> flutter test test/ux_places_mock_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/climate.dart' show WeatherKind;
import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/journey_banner_pin.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/fonts.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

const _ivory = Color(0xFFF3EAD7);
const _ink = Color(0xFF2B2420);
const _inkSoft = Color(0xFF7A6F61);
const _gold = Color(0xFFB87A1E);
const _line = Color(0xFFD9CBAE);
const _phoneW = 400.0;
const _phoneH = 1110.0;

TextStyle _serif(double size,
        {Color color = _ink,
        FontStyle style = FontStyle.normal,
        FontWeight? w}) =>
    TextStyle(
        fontFamily: 'Spectral',
        fontSize: size,
        color: color,
        fontStyle: style,
        fontWeight: w);
TextStyle _px(double size, {Color color = _ink, FontWeight? w}) => TextStyle(
    fontFamily: 'PixelifySans', fontSize: size, color: color, fontWeight: w);

/// One place of the district: what the list says of it.
class _Place {
  const _Place(this.name, this.things,
      {this.main = false, this.locked = '', this.pin = Offset.zero});
  final String name;
  final int things;
  final bool main;
  final String locked;

  /// Where its pin stands on the map (hand-placed for the mock).
  final Offset pin;
}

const _places = [
  _Place("The Lark's gangway", 1, main: true, pin: Offset(262, 300)),
  _Place('The sailcloth rigging', 1, pin: Offset(150, 262)),
  _Place('The looted armory', 1, pin: Offset(118, 392)),
  _Place("The shieldwright's cart", 1, pin: Offset(206, 410)),
  _Place("The harbor master's loft", 1,
      locked: 'Shut until the quay is open to you', pin: Offset(334, 372)),
];

/// The real top of the screen (status line, crumbs, the map, the tabs), from
/// the capture of the app, [height] logical pixels of it.
Widget _realTop(ui.Image image, double height) => SizedBox(
      width: _phoneW,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: image.height / 2,
          maxWidth: _phoneW,
          child: RawImage(
              image: image,
              width: _phoneW,
              height: image.height / 2,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium),
        ),
      ),
    );

Widget _pinOnMap(_Place p, {bool lit = false, bool label = true}) {
  const ink = InkColors.light;
  final cat = p.main ? JourneyPinCat.main : JourneyPinCat.side;
  return Positioned(
    left: p.pin.dx - 40,
    top: p.pin.dy - 38,
    width: 80,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      BannerPin(
        cat: cat,
        color: p.locked.isNotEmpty ? ink.ash : cat.colorOn(ink, dark: false),
        dark: false,
        icon: p.locked.isNotEmpty ? Icons.lock_outline : null,
        scale: 0.85,
        lit: lit,
      ),
      if (label)
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
              color: const Color(0xCC17151B),
              borderRadius: BorderRadius.circular(3)),
          child: Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _serif(9.5, color: const Color(0xFFEDE3C8))),
        ),
    ]),
  );
}

Widget _count(int n) => Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _inkSoft, width: 1.3)),
      child: Text('$n', style: _px(11, color: _inkSoft)),
    );

Widget _placeRow(_Place p, {bool dim = false, bool hot = false}) {
  const ink = InkColors.light;
  final locked = p.locked.isNotEmpty;
  final cat = p.main ? JourneyPinCat.main : JourneyPinCat.side;
  return Container(
    color: hot ? const Color(0x22B87A1E) : null,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    child: Opacity(
      opacity: dim ? 0.45 : 1,
      child: Row(children: [
        SizedBox(
          width: 30,
          child: Center(
              child: BannerPin(
            cat: cat,
            color: locked ? ink.ash : cat.colorOn(ink, dark: false),
            dark: false,
            icon: locked ? Icons.lock_outline : null,
            scale: 0.62,
          )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: _serif(16.5, color: locked ? _inkSoft : _ink)),
            if (locked)
              Text(p.locked,
                  style: _serif(11.5, color: _inkSoft, style: FontStyle.italic))
            else if (p.main)
              Text('The story goes on here',
                  style: _serif(11.5, color: _gold, style: FontStyle.italic)),
          ]),
        ),
        if (p.main)
          const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.flag, size: 17, color: _gold)),
        if (!locked) _count(p.things),
        const SizedBox(width: 4),
        Icon(locked ? Icons.lock_outline : Icons.chevron_right,
            size: 18, color: _inkSoft),
      ]),
    ),
  );
}

/// "Here": the party's own place, always the first entry; the on-the-spot
/// choices (a fight, a check, a payment, a way with no place) are its things.
Widget _hereRow(int things, String where) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(children: [
        const SizedBox(
            width: 30, child: Icon(Icons.my_location, size: 20, color: _gold)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Here, on $where', style: _serif(16.5)),
            Text('Whistle for the hound',
                style: _serif(11.5, color: _inkSoft, style: FontStyle.italic)),
          ]),
        ),
        _count(things),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 18, color: _inkSoft),
      ]),
    );

Widget _section(String s) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 4),
    child: Text(s, style: _px(11.5, color: _inkSoft)));

Widget _plainRow(IconData icon, String text, String note) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(children: [
        SizedBox(width: 30, child: Icon(icon, size: 20, color: _inkSoft)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: _serif(15.5))),
        Text(note,
            style: _serif(11.5, color: _inkSoft, style: FontStyle.italic)),
      ]),
    );

/// A phone: the real top, the mock under it.
Widget _phone(
        {required String caption,
        required List<Widget> children,
        required Widget top}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: _phoneW,
        height: _phoneH,
        decoration: BoxDecoration(
            color: _ivory,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3A3642), width: 2)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          top,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      SizedBox(
          width: _phoneW,
          child: Text(caption,
              style: _serif(12.5, color: const Color(0xFFCFC7D6)))),
    ]);

/// The walk: a dotted gold path over the real map, from the party's mark to
/// the pin.
class _Path extends CustomPainter {
  const _Path(this.from, this.to);
  final Offset from;
  final Offset to;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold
      ..style = PaintingStyle.fill;
    const n = 14;
    for (var i = 1; i < n; i++) {
      final t = i / n;
      final bend = math.sin(t * math.pi) * 18;
      final p = Offset.lerp(from, to, t)! + Offset(-bend * 0.4, bend);
      canvas.drawCircle(p, i % 2 == 0 ? 2.6 : 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(_Path old) => false;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final today = Platform.environment['UX_TODAY'];
  if (shots == null || today == null) {
    test('the places mock is drawn only with UX_SHOTS and UX_TODAY', () {});
    return;
  }

  testWidgets('the real screen at the High Quay', (tester) async {
    if (File(today).existsSync() &&
        Platform.environment['UX_RECAPTURE'] == null) {
      return;
    }
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));
    final container = await openGame(tester);
    container.read(storyPlayProvider.notifier).jumpTo('891');
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(find
        .descendant(
            of: find.byType(MaterialApp),
            matching: find.byType(RepaintBoundary))
        .first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(today).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });

  testWidgets('the places mock', (tester) async {
    await tester.runAsync(loadAppFonts);
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final firstParagraph = (raw['895'] as Map)['description']
        .toString()
        .split('\n')
        .first
        .replaceAll('**', '');
    final arrivalText = firstParagraph.length > 170
        ? '${firstParagraph.substring(0, 167)}...'
        : firstParagraph;
    final image = (await tester.runAsync(() async {
      final codec =
          await ui.instantiateImageCodec(File(today).readAsBytesSync());
      return (await codec.getNextFrame()).image;
    }))!;

    // The top part of the capture: header, crumbs, map and the tabs.
    const topH = 516.0;
    final mapPins = [for (final p in _places) _pinOnMap(p)];
    const partyAt = Offset(307, 220);

    Widget top({List<Widget> over = const []}) => SizedBox(
          width: _phoneW,
          height: topH,
          child: Stack(children: [
            _realTop(image, topH),
            ...over,
          ]),
        );

    final list = <Widget>[
      const SizedBox(height: 6),
      Row(children: [
        Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFB02A3A))),
        const SizedBox(width: 10),
        Text('Held by Crows', style: _serif(15, color: _inkSoft)),
      ]),
      _section('PLACES · TAP ONE TO WALK THERE'),
      const Divider(height: 1, color: _line),
      for (final p in _places) ...[
        _placeRow(p),
        const Divider(height: 1, color: _line),
      ],
    ];

    final phone1 = _phone(
      caption:
          '1. The district as places, in Core\u2019s order: HERE first (the party\u2019s own place, holding what is done on the spot), then the place where the story goes on (the flag), then the others by distance, a locked one greyed last. A row says its place, a count of what there is to do there, and a padlock with its reason. No choice text. (As drawn this needs a place for each way: today the High Quay\u2019s five ways all lead back to the building the party stands at, so all five would sit under HERE until the places are named.)',
      top: top(over: [
        for (final w in mapPins) w,
      ]),
      children: [
        ...list.take(3),
        _hereRow(1, 'the quay'),
        const Divider(height: 1, color: _line),
        for (final p in _places) ...[
          _placeRow(p),
          const Divider(height: 1, color: _line),
        ],
        _section('WAYS OUT'),
        _plainRow(Icons.signpost_outlined, 'The Stone Bridge', 'walk'),
        _plainRow(Icons.sailing_outlined, 'Aboard the Lark', 'sail'),
      ],
    );

    final phone2 = _phone(
      caption:
          '2. The tap. The party’s mark walks to the pin along a dotted path (0.6 to 1.2 s, as the walk already does); the row lights and says where it is going. A tap anywhere skips the walk. The other rows wait, dimmed.',
      top: top(over: [
        for (final p in _places.skip(1)) _pinOnMap(p, label: false),
        Positioned.fill(
            child: CustomPaint(
                painter:
                    _Path(partyAt, _places.first.pin - const Offset(0, 6)))),
        _pinOnMap(_places.first, lit: true),
      ]),
      children: [
        const SizedBox(height: 6),
        Row(children: [
          Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFB02A3A))),
          const SizedBox(width: 10),
          Text('Held by Crows', style: _serif(15, color: _inkSoft)),
        ]),
        _section('WALKING · TAP TO SKIP'),
        const Divider(height: 1, color: _line),
        _placeRow(_places.first, hot: true),
        const Divider(height: 1, color: _line),
        for (final p in _places.skip(1)) ...[
          _placeRow(p, dim: true),
          const Divider(height: 1, color: _line),
        ],
      ],
    );

    final phone3 = _phone(
      caption:
          '3. The arrival. The street view opens on the place (its front, the hour, the weather) with the place’s choices as pins in the street, and the scene’s words in a band over the sky; a tap on the band opens the sheet. Back to the district is the arrow at the top.',
      top: SizedBox(
        width: _phoneW,
        height: 372,
        child: Stack(children: [
          _realTop(image, 118),
          Positioned(
              left: 0,
              right: 0,
              top: 118,
              height: 254,
              child: Stack(fit: StackFit.expand, children: [
                StreetViewScene(
                  kind: 'warehouse',
                  name: "The Lark's gangway",
                  phase: DayPhase.dusk,
                  sky: WeatherKind.ash,
                  pins: [
                    StreetPin(
                        index: 0,
                        label: 'Talk your way aboard',
                        child: BannerPin(
                            cat: JourneyPinCat.main,
                            color: JourneyPinCat.main
                                .colorOn(InkColors.dark, dark: true),
                            dark: true,
                            scale: 0.8)),
                    StreetPin(
                        index: 1,
                        label: 'Pass as crew from the manifest',
                        child: BannerPin(
                            cat: JourneyPinCat.main,
                            color: JourneyPinCat.main
                                .colorOn(InkColors.dark, dark: true),
                            dark: true,
                            scale: 0.8)),
                    StreetPin(
                        index: 2,
                        label: 'Climb the line as she lifts',
                        child: BannerPin(
                            cat: JourneyPinCat.main,
                            color: JourneyPinCat.main
                                .colorOn(InkColors.dark, dark: true),
                            dark: true,
                            scale: 0.8)),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                  alignment: Alignment.topLeft,
                  height: 74,
                  decoration: BoxDecoration(
                      color: const Color(0xCC17151B),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(arrivalText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _serif(11.5, color: const Color(0xFFEDE3C8))),
                ),
              ])),
        ]),
      ),
      children: [
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.arrow_back, size: 18, color: _inkSoft),
          const SizedBox(width: 8),
          Text('The High Quay', style: _serif(13.5, color: _inkSoft)),
        ]),
        _section("THE LARK'S GANGWAY · 3 THINGS TO DO HERE"),
        const Divider(height: 1, color: _line),
        for (final t in const [
          'Talk your way aboard',
          'Pass as crew from the manifest',
          'Climb the line as she lifts'
        ]) ...[
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(children: [
                const Icon(Icons.flag_outlined, size: 18, color: _gold),
                const SizedBox(width: 12),
                Expanded(child: Text(t, style: _serif(15.5))),
                const Icon(Icons.chevron_right, size: 18, color: _inkSoft),
              ])),
          const Divider(height: 1, color: _line),
        ],
      ],
    );

    // The ways that have no place of their own.
    Widget kindCard(IconData icon, String title, String body) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0x12000000),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _line)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20, color: _gold),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: _serif(14, w: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(body, style: _serif(12, color: _inkSoft)),
                ])),
          ]),
        );

    final phone4 = _phone(
      caption:
          '4. A way with no place of its own. Nothing is invented: it goes where it already goes, in a section that says so.',
      top: Container(
        width: _phoneW,
        height: 120,
        color: const Color(0xFF17151B),
        alignment: Alignment.center,
        child: Text('What a way with no place does',
            style: _px(18, color: const Color(0xFFEDE3C8))),
      ),
      children: [
        const SizedBox(height: 14),
        kindCard(Icons.signpost_outlined, 'A road, a gate, a way out',
            'Not a place of the district: one row under WAYS OUT for each gate or road, with where it leads and how (walk, sail). The pin stands on the district’s edge, never on a building. It is what the walk-to-a-neighbour rows already are.'),
        kindCard(Icons.pets_outlined, 'A thing done where you stand',
            'It is a thing of HERE, the first entry: no walk, opened by a tap as the sheet over the map. Fights, checks and payments always go here.'),
        kindCard(Icons.gavel_outlined, 'A fight or a roll',
            'Always a thing of HERE: counted there, and on the street its pin carries a small crossed-blades badge (the fight disc the pins already use).'),
        kindCard(Icons.lock_outline, 'A place you cannot enter yet',
            'Its row and pin are greyed with a padlock and say why, as the shut districts already do; it is not counted among the things to do.'),
        kindCard(Icons.help_outline, 'A way with only a stand-in building',
            'About 329 ways today have only a random stand-in building: they go to HERE, never to a place they do not belong to, until each gets a real one.'),
      ],
    );

    const boardW = 4 * (_phoneW + 20) + 20;
    final key = GlobalKey();
    usePhone(tester, const Size(boardW, 1480));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: RepaintBoundary(
          key: key,
          child: Container(
            width: boardW,
            color: const Color(0xFF0B0A0D),
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('The district as places, not choices',
                  style: _px(22,
                      color: const Color(0xFFEDE3C8), w: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  'The user’s call: the player first chooses where to go, then sees what to do there. The pins and the list under the map are the places of the district; the choices appear on arrival. The header and the map are the real screen at the High Quay (scene 891); the pins and rows are drawn with the app’s own widgets. Nothing is built.',
                  style: _serif(12.5, color: const Color(0xFF9A93A6))),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                phone1,
                const SizedBox(width: 20),
                phone2,
                const SizedBox(width: 20),
                phone3,
                const SizedBox(width: 20),
                phone4,
              ]),
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
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/places-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

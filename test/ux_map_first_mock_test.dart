// The district view, map first (wave 19 "What opens where", UX mock, nothing
// built): the user's call is that, on the Journey map, the list under it is
// gone and appears only when the map is fully zoomed on the district; the
// pins carry no names (a name shows when a pin is tapped); and each time the
// party arrives in a district the camera eases in a little and centers on it.
// The district is Smugglers' Quay in Saltmouth (scene 2015), as in the user's
// screenshot. The map is the app's own CityChartView on Saltmouth's stored
// plan with the quay's real ways, the building names taken off so no label
// stands on the map; the real screen today (French) is a capture (UX_TODAY,
// taken by the first test); the rest is drawn with the app's own widgets.
//   UX_SHOTS=docs/ux-shots UX_TODAY=<png> flutter test test/ux_map_first_mock_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/city_plan_record.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';
import 'package:narrative_data_app/widgets/journey_banner_pin.dart';
import 'support/fonts.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

const _ivory = Color(0xFFF3EAD7);
const _ink = Color(0xFF2B2420);
const _inkSoft = Color(0xFF7A6F61);
const _gold = Color(0xFFB87A1E);
const _line = Color(0xFFD9CBAE);
const _phoneW = 400.0;
const _phoneH = 860.0;
const _mapW = 368.0;
const _quay = 'saltmouth_wharf';

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

/// One place of the quay as the list says it: [name] null when Narrative has
/// not named the building yet.
class _Place {
  const _Place(this.building, this.name, {this.main = false});
  final String building;
  final String? name;
  final bool main;
}

/// Smugglers' Quay's places, by building, as the real data stands: five
/// buildings Narrative has named (city_plans.json `names`), five it has not.
const _places = [
  _Place('saltmouth_b140', 'The harbor master’s office', main: true),
  _Place('saltmouth_b150', 'The bounty door'),
  _Place('saltmouth_b141', 'The captain’s moorings'),
  _Place('saltmouth_b143', 'The spoiled-cargo crate'),
  _Place('saltmouth_b156', 'The Crow tout’s corner'),
  _Place('saltmouth_b157', null),
  _Place('saltmouth_b171', null),
  _Place('saltmouth_b149', null),
  _Place('saltmouth_b168', null),
  _Place('saltmouth_b147', null),
];

/// The real top of the screen (the header and the crumbs), from the capture.
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

Widget _count(int n) => Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _inkSoft, width: 1.3)),
      child: Text('$n', style: _px(11, color: _inkSoft)),
    );

Widget _placeRow(_Place p) {
  const ink = InkColors.light;
  final cat = p.main ? JourneyPinCat.main : JourneyPinCat.side;
  final named = p.name != null;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
    child: Row(children: [
      SizedBox(
        width: 30,
        child: Center(
            child: BannerPin(
          cat: cat,
          color: cat.colorOn(ink, dark: false),
          dark: false,
          scale: 0.6,
        )),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(named ? p.name! : '(no name yet)',
              style: _serif(16,
                  color: named ? _ink : _inkSoft,
                  style: named ? FontStyle.normal : FontStyle.italic)),
          if (p.main)
            Text('The story goes on here',
                style: _serif(11.5, color: _gold, style: FontStyle.italic)),
        ]),
      ),
      if (p.main)
        const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.flag, size: 17, color: _gold)),
      _count(1),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right, size: 18, color: _inkSoft),
    ]),
  );
}

Widget _wayOutRow(String name, String how, String reason) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: Opacity(
        opacity: 0.55,
        child: Row(children: [
          const SizedBox(
              width: 30,
              child: Icon(Icons.lock_outline, size: 19, color: _inkSoft)),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: _serif(15.5)),
              Text(reason,
                  style:
                      _serif(11.5, color: _inkSoft, style: FontStyle.italic)),
            ]),
          ),
          Text(how,
              style: _serif(11.5, color: _inkSoft, style: FontStyle.italic)),
        ]),
      ),
    );

Widget _section(String s) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(s, style: _px(11.5, color: _inkSoft)));

/// The tabs row of the real screen (District / Town / World).
Widget _tabs(int selected) => Container(
      decoration: BoxDecoration(
          color: const Color(0xFF3A3642),
          border: Border.all(color: const Color(0xFF6A6478), width: 2)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final (i, t) in const ['District', 'Town', 'World'].indexed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: i == selected ? const Color(0xFF6A5A3A) : null,
            child: Text(t,
                style: _px(13,
                    color: i == selected
                        ? const Color(0xFFE9B949)
                        : const Color(0xFFEDE3C8))),
          ),
      ]),
    );

/// A phone: the real top, the mock under it.
Widget _phone(
        {required String caption,
        required Widget top,
        required List<Widget> children,
        double height = _phoneH}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: _phoneW,
        height: height,
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

/// The handle on the map: "Places" with how many; tapped it zooms the map
/// fully and the list rises (or, open, folds it back).
Widget _handle({required bool open}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xEE17151B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9B949), width: 1.2)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            size: 18, color: const Color(0xFFE9B949)),
        const SizedBox(width: 4),
        Text(open ? 'Map' : 'Places · 10',
            style: _px(12.5, color: const Color(0xFFEDE3C8))),
      ]),
    );

/// A pin's card, shown when it is tapped on the map: the place's name, the
/// number of things there and the way there.
Widget _pinCard(String name, int things, {String? note}) => Container(
      width: 200,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
          color: const Color(0xF217151B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB8A9C9), width: 1)),
      child: Row(children: [
        Expanded(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: _serif(13.5,
                        color: const Color(0xFFEDE3C8), w: FontWeight.w600)),
                Text(note ?? '$things thing to do',
                    style: _serif(11,
                        color: const Color(0xFF9A93A6),
                        style: FontStyle.italic)),
              ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
              color: const Color(0xFFB87A1E),
              borderRadius: BorderRadius.circular(4)),
          child: Text('Go', style: _px(12.5, color: Colors.white)),
        ),
      ]),
    );

Widget _noteCard(IconData icon, String title, String body) => Container(
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: _serif(14, w: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(body, style: _serif(12, color: _inkSoft)),
        ])),
      ]),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final today = Platform.environment['UX_TODAY'];
  if (shots == null || today == null) {
    test('the map-first mock is drawn only with UX_SHOTS and UX_TODAY', () {});
    return;
  }

  testWidgets('the real screen at Smugglers’ Quay', (tester) async {
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
    container.read(storyPlayProvider.notifier).jumpTo('2015');
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

  testWidgets('the map-first mock', (tester) async {
    await tester.runAsync(loadAppFonts);
    final image = (await tester.runAsync(() async {
      final codec =
          await ui.instantiateImageCodec(File(today).readAsBytesSync());
      return (await codec.getNextFrame()).image;
    }))!;

    // Saltmouth's stored plan, with the buildings' names taken off so that no
    // label stands on the map, and the quay's real ways from scene 2015.
    final plansRaw =
        jsonDecode(File('assets/gamedata/city_plans.json').readAsStringSync())
            as Map<String, dynamic>;
    final salt = Map<String, dynamic>.from(plansRaw['saltmouth'] as Map);
    final bare = cityPlanRecordsFrom({
      'saltmouth': {...salt, 'names': <String, dynamic>{}}
    })['saltmouth']!;
    final dag =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    final choices = ((dag['2015'] as Map)['choices'] as List).cast<Map>();
    final ways = <CityWayInput>[];
    for (final (i, c) in choices.indexed) {
      final next = c['next_id'] as String;
      final b = bare.building(bare.anchors[next] ?? '');
      if (b == null || b.district != _quay) continue;
      final text = c['text'] as String;
      ways.add(CityWayInput(
        id: '$i',
        districtId: _quay,
        kind: text.startsWith('Try the first arch') ||
                text.startsWith('Look across the footbridge')
            ? CityWayKind.road
            : text.startsWith('Deal with') ||
                    text.startsWith('Fend off') ||
                    text.startsWith('Break up')
                ? CityWayKind.fight
                : text.startsWith('Force')
                    ? CityWayKind.check
                    : CityWayKind.quest,
        // No name on the map: it shows on a tap (the card), never as a label.
        name: '',
        sceneId: next,
      ));
    }
    final chart = CityChart.fromRecord(bare,
        districtNames: {
          for (final id in bare.districts.keys)
            id: id.replaceFirst('saltmouth_', '').replaceAll('_', ' '),
        },
        ways: ways);
    CityChartBuilding building(String id) => chart.buildings
        .firstWhere((b) => b.key == id, orElse: () => chart.buildings.first);
    final quay = chart.districtById(_quay)!;
    final party = building('saltmouth_b140').at;

    Widget map(Key key, double h, {Offset? partyAt}) => SizedBox(
          key: key,
          width: _mapW,
          height: h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CityChartView(
              chart: chart,
              look: MapLook.night,
              focus: _quay,
              focusToken: 1,
              hereDistrict: _quay,
              partyAt: partyAt ?? party,
              locked: const {'saltmouth_tern_row', 'saltmouth_lantern_alleys'},
              cards: false,
              animate: false,
            ),
          ),
        );

    const aKey = Key('map_a');
    const nKey = Key('map_n');
    const bKey = Key('map_b');
    const aH = 540.0;
    const bH = 330.0;

    // Where a plan point stands on a map at the district's fit (the view's own
    // first placement).
    Offset fitted(Offset plan, double h) {
      final box = quay.box;
      final scale = (_mapW / box.width) < (h / box.height)
          ? _mapW / box.width
          : h / box.height;
      return Offset(_mapW / 2, h * 0.5) - box.center * scale + plan * scale;
    }

    final tapped = fitted(building('saltmouth_b141').at, aH);
    final cardLeft = (tapped.dx - 100).clamp(6.0, _mapW - 206.0);

    final phoneToday =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: _phoneW,
        height: _phoneH,
        decoration: BoxDecoration(
            color: _ivory,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3A3642), width: 2)),
        clipBehavior: Clip.antiAlias,
        child: Image(
            image: _Mem(image),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium),
      ),
      const SizedBox(height: 8),
      SizedBox(
          width: _phoneW,
          child: Text(
              'Today (the real screen, scene 2015). The map carries the way texts as labels that overlap each other and the pins, and the list under it repeats them as long rows: 10 pins, 11 ways.',
              style: _serif(12.5, color: const Color(0xFFCFC7D6)))),
    ]);

    final phoneA = _phone(
      caption:
          'A. Default zoom: the map and nothing else. Pins carry no names; the chart\u2019s own shapes say the kind (diamond: a thing to do, cross: a fight, square: a check, chevron: a way out). A tap on a pin shows a small card with the place’s name; "Go" walks there. A "Places" handle at the foot tells there is a list.',
      top: _realTop(image, 170),
      children: [
        const SizedBox(height: 0),
        Stack(clipBehavior: Clip.none, children: [
          map(aKey, aH),
          Positioned(
              left: cardLeft,
              top: (tapped.dy - 86).clamp(6.0, aH - 60),
              child: _pinCard('The captain’s moorings', 1)),
          Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(child: _handle(open: false))),
        ]),
        const SizedBox(height: 6),
        _tabs(0),
      ],
    );

    final phoneN = _phone(
      caption:
          'Arriving. Each time the party arrives in a district the camera eases in 25% from the district fit and centers on the party’s mark: 0.6 s, ease in and out; a tap anywhere skips it; with reduced motion it is a jump. Walking between places in the district does not do it again.',
      top: _realTop(image, 170),
      children: [
        Stack(clipBehavior: Clip.none, children: [
          map(nKey, aH),
          Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('after the ease: 1.25×, on you',
                    style: _px(11, color: const Color(0xFFE9B949))),
              )),
          Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(child: _handle(open: false))),
        ]),
        const SizedBox(height: 6),
        _tabs(0),
      ],
    );

    final phoneB = _phone(
      height: 1180,
      caption:
          'B. Fully zoomed on the district: the map shrinks to make room and the list of places rises under it (the places, not the choice texts: name, a count, a flag where the story goes on, and the shut doors under WAYS OUT). The handle now says "Map" and folds the list away. Pinching to full zoom does the same as the handle.',
      top: _realTop(image, 170),
      children: [
        Stack(clipBehavior: Clip.none, children: [
          map(bKey, bH),
          Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Center(child: _handle(open: true))),
        ]),
        const SizedBox(height: 6),
        _tabs(0),
        _section('PLACES · TAP ONE TO WALK THERE'),
        const Divider(height: 1, color: _line),
        for (final p in _places) ...[
          _placeRow(p),
          const Divider(height: 1, color: _line),
        ],
        _section('WAYS OUT'),
        _wayOutRow('Tern Row', 'footbridge', 'Shut until the toll is settled'),
        _wayOutRow('The Lantern Alleys', 'first arch',
            'Shut until the informant is named'),
      ],
    );

    final notes = _phone(
      height: 1180,
      caption: 'Answers and what it needs.',
      top: Container(
        width: _phoneW,
        height: 90,
        color: const Color(0xFF17151B),
        alignment: Alignment.center,
        child: Text('How it works',
            style: _px(18, color: const Color(0xFFEDE3C8))),
      ),
      children: [
        const SizedBox(height: 12),
        _noteCard(Icons.keyboard_arrow_up, 'How the player knows',
            'A "Places · 10" handle sits at the foot of the map at every district zoom. Tapping it zooms the map to the full district view and the list rises; at that zoom it reads "Map" and folds the list back. Pinching to full zoom does the same, so the list follows the zoom and the handle is the way there.'),
        _noteCard(Icons.map_outlined, 'Town and World',
            'Town: the districts as today (their names on the plan with the crest, the lock, the holder); no pins and no list, the district card at the foot when one is tapped. World: unchanged. The list belongs to the district view only.'),
        _noteCard(Icons.flag_outlined, 'A pin with no name',
            'The chart\u2019s own shapes carry the kind (diamond: a thing to do, cross: a fight, square: a check, chevron: a way out). Proposed additions: a gold ring on the pin where the story goes on, a grey padlock on a shut one, as the shut districts already wear. A tap shows the name and the count; the way texts appear only on arrival.'),
        _noteCard(Icons.zoom_in, 'The arrival',
            'On arriving in a district: ease in 25% from the district fit, centered on the party’s mark, 0.6 s, tap to skip, a jump with reduced motion. Moving to another place in the same district does not repeat it.'),
        _noteCard(Icons.engineering_outlined, 'What it needs from Core',
            'Camera state: a trigger on arriving in a district (partyDistrictProvider changing), a way to set the camera’s zoom and center (CityChartView has only focus today), and a signal when the map reaches full zoom (or leaves it) so the list can follow. Places per way and the place names, as asked in the places mock.'),
        _noteCard(Icons.edit_outlined, 'What it needs from Narrative',
            'Names for the five quay buildings that have none (Vane’s three spots, the crane, Liora’s skiff) and for the door to the footbridge, so the list never says "no name yet".'),
      ],
    );

    const boardW = 5 * (_phoneW + 20) + 20;
    final key = GlobalKey();
    usePhone(tester, const Size(boardW, 1500));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Material(
        color: const Color(0xFF0B0A0D),
        child: RepaintBoundary(
          key: key,
          child: Container(
            width: boardW,
            color: const Color(0xFF0B0A0D),
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('The district, map first',
                  style: _px(22,
                      color: const Color(0xFFEDE3C8), w: FontWeight.w600)),
              const SizedBox(height: 4),
              SizedBox(
                width: 1700,
                child: Text(
                    'The user’s call (wave 19, "What opens where"): on the Journey map the list under it is gone and comes back only when the map is fully zoomed on the district; the pins carry no names (a name shows on a tap); and each arrival in a district eases in a little and centers on you. Smugglers’ Quay, as in their screenshot. The map is the app’s own, drawn on Saltmouth’s stored plan with the quay’s real ways; nothing is built.',
                    style: _serif(12.5, color: const Color(0xFF9A93A6))),
              ),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                phoneToday,
                const SizedBox(width: 20),
                phoneA,
                const SizedBox(width: 20),
                phoneN,
                const SizedBox(width: 20),
                phoneB,
                const SizedBox(width: 20),
                notes,
              ]),
            ]),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // The arrival: the view eases in 25% about the party, which is then
    // centered.
    Future<void> scrollZoom(Key mapKey, Offset local, double dy) async {
      final origin = tester.getTopLeft(find.byKey(mapKey));
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(origin + local));
      await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
      await tester.pump(const Duration(milliseconds: 600));
    }

    final partyAtFit = fitted(party, aH);
    await scrollZoom(nKey, partyAtFit, -100);
    // The party stays where it was under the pointer; bring it to the center.
    final nOrigin = tester.getTopLeft(find.byKey(nKey));
    await tester.dragFrom(
        nOrigin + partyAtFit, const Offset(_mapW / 2, aH * 0.5) - partyAtFit);
    await tester.pump(const Duration(milliseconds: 600));

    // The full zoom: the zoom button twice.
    Finder zoomIn(Key mapKey) => find.descendant(
        of: find.byKey(mapKey),
        matching: find.byKey(const Key('city_chart_zoom_in')));
    await tester.tap(zoomIn(bKey));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(zoomIn(bKey));
    await tester.pump(const Duration(milliseconds: 700));

    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 1.3);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/map-first-mock.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

/// An in-memory image as an ImageProvider (the capture of the real screen).
class _Mem extends ImageProvider<_Mem> {
  const _Mem(this.image);
  final ui.Image image;
  @override
  Future<_Mem> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);
  @override
  ImageStreamCompleter loadImage(_Mem key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
          Future.value(ImageInfo(image: image.clone())));
}

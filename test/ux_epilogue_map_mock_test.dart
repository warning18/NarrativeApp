// Mock: the epilogue map (docs/proposals/epilogue-map.md), 412 and 320 px: the
// realm at the end, each town tinted by its holder (town_rulers.dart on the
// real geography and factions, with sample holdings until Core's
// epilogueHoldings lands), the clans' roads, a line for each big town. Drawn
// only with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_epilogue_map_mock_test.dart
import 'dart:convert';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/town_rulers.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'ux_epilogue_map_parts.dart';
import 'ux_skills_mock_parts.dart' show NotesPanel, Phone;
import 'support/fonts.dart';

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// Sample holdings for the ending (Core's epilogueHoldings will give the
/// real ones): how each big town was taken, as the clan log would say it.
const _how = {
  'alster': 'since the start',
  'candlehold': 'since the start',
  'saltmouth': 'by influence, chapter 4',
  'ashen_quarter': 'by war, chapter 5',
  'drowned_cloister': 'by war, chapter 3',
  'black_reliquary': 'by the seat, chapter 7',
  'white_anchorage': 'by war, chapter 6',
};

/// Each town joined to its two nearest neighbours (sample roads: the real
/// ones are Core's clan roads, wave 18 item 5).
List<(String, String)> nearestRoads(List<EpilogueTown> towns) {
  final seen = <String>{};
  final out = <(String, String)>[];
  for (final a in towns) {
    final near = [...towns]..remove(a);
    near.sort(
        (x, y) => (x.at - a.at).distance.compareTo((y.at - a.at).distance));
    for (final b in near.take(2)) {
      final key = [a.id, b.id]..sort();
      if (seen.add(key.join('|'))) out.add((a.id, b.id));
    }
  }
  return out;
}

EpilogueData sample() {
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final factions = parseFactions(_table('factions'));
  final plans = _table('city_plans');
  final raw = _table('geography');
  List<String> districts(String town) => [
        for (final c in geo.childrenOf(town))
          if (c.level == GeoLevel.district) c.id,
      ];
  final control = <String, String>{
    'alster': 'dominion',
    'saltmouth': 'crows',
    'drowned_cloister': 'mire',
    'black_reliquary': 'penitents',
    'white_anchorage': 'vigil',
    'wracks_end': 'pit',
    'rimewell': 'vigil',
    'greyhithe': 'vigil',
    'akagiri': 'compact',
  };
  // Saltmouth's one district the Mire still holds; the Ashen Quarter's
  // districts split between the Compact, the Dominion and the Mire.
  control[districts('saltmouth').first] = 'mire';
  final ash = districts('ashen_quarter');
  control[ash[2]] = 'compact';
  control[ash[3]] = 'compact';
  control[ash[4]] = 'mire';
  final rulers = townRulers(geo, PoliticsState(control: control), factions,
      planIds: plans.keys);
  final chart = chartOf(MapShape.story);
  final landmarkTown = {
    for (final id in townIds(geo, planIds: plans.keys))
      raw[id]['landmark'].toString(): id,
  };
  final towns = <EpilogueTown>[];
  var number = 0;
  for (final l in worldMapLandmarks) {
    final id = landmarkTown[l.id];
    if (id == null) continue;
    final place = geo.place(id)!;
    final big = place.kind == 'city' || place.kind == 'town';
    final ruler = rulers[id]!;
    towns.add(EpilogueTown(
      id: id,
      name: raw[id]['name'].toString(),
      at: chart.places[l.id]!,
      big: big,
      clanId: ruler.clanId,
      clanName: ruler.clanId.isEmpty
          ? ''
          : factions[ruler.clanId]!.shortFor(AppLanguage.en),
      color: Color(ruler.color),
      accent: Color(ruler.accent),
      how: _how[id] ?? '',
      number: big ? ++number : 0,
      differing: [
        for (final d in districts(id))
          if (rulers[d]!.clanId != ruler.clanId) d,
      ].length,
    ));
  }
  return EpilogueData(
    towns: towns,
    roads: nearestRoads(towns),
    chart: chart,
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the epilogue map is drawn only with UX_SHOTS', () {});
    return;
  }

  /// [frames] side by side on a dark board, each with a caption; written to
  /// [file].
  Future<void> board(WidgetTester tester, String file,
      List<(ProviderContainer, double, String, Widget)> frames,
      {double height = 780, Widget? notes, bool bare = false}) async {
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    var width = 48.0 + 24 * frames.length;
    for (final f in frames) {
      width += f.$2;
    }
    if (notes != null) width += 300;
    tester.view.physicalSize = Size(width, height + 110);
    final key = GlobalKey();
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
                    UncontrolledProviderScope(
                      container: f.$1,
                      child: Phone(
                          width: f.$2,
                          height: height,
                          bare: bare,
                          title: 'Epilogue',
                          child: f.$4),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: f.$2,
                      child: Text(f.$3,
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
    await _settle(tester, n: 4);
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('the epilogue map', (tester) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final data = sample();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    Widget screen() => EpilogueScreen(data: data);
    await board(
      tester,
      'epilogue-map.png',
      [
        (container, 412.0, 'The ending · 412 px', screen()),
        (container, 320.0, 'The ending · 320 px', screen()),
      ],
      notes: const NotesPanel(title: 'The epilogue map', sections: [
        (
          'What it is',
          'At the ending the realm is shown as the clans hold it: the world’s coast, each of the 16 towns tinted by its holder (the tint the world chart and the town views already use), the roads between towns of one holder drawn in that clan’s colour, and a line for each big town: who holds it and how it was taken.'
        ),
        (
          'Reading it',
          'The seven big towns are numbered on the map and in the list; villages are the small dots. A road in a clan’s colour joins two towns it holds; a grey dashed road joins towns of different holders. A town whose districts are held by others says so (“2 districts differ”). The chips under the map count the towns each clan holds.'
        ),
        (
          'Sample data',
          'The holdings and the “how it was taken” lines are samples (the real ones come from the clan log givePlace keeps, through Core’s epilogueHoldings). The tints are the real ones: townRulers on the real geography and factions.'
        ),
        (
          'Needs',
          'Core: epilogueHoldings(politics, geography) (holder, source, chapter, cause for each town and district). Narrative: the “how it was taken” wording (here “by war, chapter 5”) in both languages. UX: one new screen (the map painter and the rows); the ending’s own scene opens it.'
        ),
      ]),
      height: 940,
    );
  });
}

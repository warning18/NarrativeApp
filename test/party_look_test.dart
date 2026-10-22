// The party's faces (wave 17, UX, item 5, the stand-in): each of the eight
// companions has a face of their own on the land walk and on the Eel's
// deck, a companion the table does not know gets one made from their id,
// and every figure paints. UX_SHOTS=<folder> takes a picture of them.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/providers/walking_party_provider.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/side_view/deck_crew.dart';
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/party_look.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

Map<String, dynamic> _companions() =>
    jsonDecode(File('assets/gamedata/companions.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('every companion has a look of their own', () {
    final ids = _companions().keys.toList();
    expect(ids.length, 8);
    final looks = {for (final id in ids) id: partyLookFor(id)};
    expect(looks.values.toSet().length, ids.length);
  });

  test('the marks of their people: beards, tusks, ears', () {
    final data = _companions();
    for (final entry in data.entries) {
      final race = (entry.value as Map)['raceId'];
      final look = partyLookFor(entry.key);
      expect(look.beard, race == 'dwarf', reason: entry.key);
      expect(look.tusks, race == 'orc', reason: entry.key);
      expect(look.ears, race == 'elf', reason: entry.key);
    }
  });

  test('a companion the table does not know has a face, the same each time',
      () {
    final a = partyLookFor('someone_new');
    expect(partyLookFor('someone_new'), a);
    expect(partyLookFor('someone_else'), isNotNull);
  });

  testWidgets('the land walk and the deck paint every companion',
      (tester) async {
    final ids = _companions().keys.toList();
    final party = [
      const WalkingPartyMember(id: heroWalkerId, spriteKey: heroWalkerId),
      for (final id in ids.take(2))
        WalkingPartyMember(id: id, spriteKey: 'companion_$id'),
    ];
    for (var from = 0; from < ids.length; from += 2) {
      final group = [
        const WalkingPartyMember(id: heroWalkerId, spriteKey: heroWalkerId),
        for (final id in ids.skip(from).take(2))
          WalkingPartyMember(id: id, spriteKey: 'companion_$id'),
      ];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            SideViewScene(
              layers: desertLayers(progress: 0.5),
              actors: desertActors(party: group, moving: false),
              moving: false,
            ),
            SeaSideScene(
              waters: SeaWaters.open,
              crew: deckCrewOf(group),
              moving: false,
            ),
          ]),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    }
    expect(party.length, 3);
  });

  testWidgets('pictures of the party (UX_SHOTS=<folder>)', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    final ids = _companions().keys.toList();
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    List<WalkingPartyMember> group(int from) => [
          const WalkingPartyMember(id: heroWalkerId, spriteKey: heroWalkerId),
          for (final id in ids.skip(from).take(2))
            WalkingPartyMember(id: id, spriteKey: 'companion_$id'),
        ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Row(children: [
            Expanded(
              child: Column(children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: SideViewScene(
                      layers: desertLayers(progress: 0.5),
                      actors: desertActors(party: group(i * 2), moving: false),
                      moving: false,
                      height: 240,
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: Column(children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: SeaSideScene(
                      waters: SeaWaters.open,
                      crew: deckCrewOf(group(i * 2)),
                      moving: false,
                      height: 240,
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/party-faces.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}

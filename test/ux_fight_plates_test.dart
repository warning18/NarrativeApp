// The fight's background pictures (fight_plates.dart): the city road has a
// picture per region (Alster by default, Saltmouth, the grey frost towns,
// Candlehold), every stage has a bundled picture, and a backdrop given a
// picture draws it.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/widgets/fight_backdrop.dart';
import 'package:narrative_data_app/widgets/fight_plates.dart';

void main() {
  test('the city road picks its picture by settlement', () {
    String? of(String? s) => fightPlateAsset(FightStage.cityRoad, s);
    expect(of('alster'), endsWith('/cityroad.png'));
    expect(of(null), endsWith('/cityroad.png'));
    expect(of('white_anchorage'), endsWith('/cityroad_whiteanchorage.png'));
    expect(of('white_wells'), endsWith('/cityroad.png'));
    expect(of('saltmouth'), endsWith('/cityroad_saltmouth.png'));
    expect(of('black_reliquary'), endsWith('/cityroad_frost.png'));
    expect(of('ashen_quarter'), endsWith('/cityroad_frost.png'));
    expect(of('candlehold'), endsWith('/cityroad_candlehold.png'));
  });

  test('a stage version is worn by its places, the shared picture elsewhere',
      () {
    String of(FightStage st, String? s, {String? p}) =>
        fightPlateAsset(st, s, placeId: p);
    expect(of(FightStage.glass, 'greyhithe'), endsWith('/glass_greyhithe.png'));
    expect(of(FightStage.glass, 'hollow_shore', p: 'beyond_the_tear'),
        endsWith('/glass_greyhithe.png'));
    expect(of(FightStage.glass, 'somewhere'), endsWith('/glass.png'));
    expect(of(FightStage.ash, 'emberwick'), endsWith('/ash_emberwick.png'));
    expect(of(FightStage.ash, null), endsWith('/ash.png'));
    expect(
        of(FightStage.terraces, 'akagiri'), endsWith('/terraces_akagiri.png'));
    expect(
        of(FightStage.waves, 'the_crossing'), endsWith('/waves_crossing.png'));
    expect(of(FightStage.waves, null), endsWith('/waves.png'));
    expect(of(FightStage.hall, 'drowned_cloister'), endsWith('/hall_wet.png'));
    expect(of(FightStage.hall, 'alster', p: 'alster_undercroft'),
        endsWith('/hall_wet.png'));
    expect(
        of(FightStage.hall, 'alster', p: 'alster_hall'), endsWith('/hall.png'));
    // A version belongs to its stage: a city road at Greyhithe is no glass.
    expect(of(FightStage.cityRoad, 'greyhithe'), endsWith('/cityroad.png'));
  });

  test('every stage has its picture, bundled, a 180 x 320 palette PNG', () {
    for (final stage in FightStage.values) {
      final asset = fightPlateAsset(stage, null);
      final file = File(asset);
      expect(file.existsSync(), isTrue, reason: '$stage: $asset');
      final data = ByteData.sublistView(file.readAsBytesSync());
      expect(data.getUint32(16), 180, reason: asset);
      expect(data.getUint32(20), 320, reason: asset);
      expect(data.getUint8(25), 3, reason: asset);
    }
  });

  test('every picture named is in the bundle, 180 x 320', () {
    for (final s in [
      null,
      'saltmouth',
      'black_reliquary',
      'candlehold',
      'white_anchorage',
    ]) {
      final asset = fightPlateAsset(FightStage.cityRoad, s);
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  testWidgets('a backdrop with a picture draws it, none draws the code stage',
      (tester) async {
    FightPlateImages.reset();
    final asset = fightPlateAsset(FightStage.cityRoad, 'saltmouth');
    await tester.pumpWidget(MaterialApp(
        home: SizedBox(
            width: 200,
            height: 300,
            child: FightBackdrop(
                key: const Key('b'),
                stage: FightStage.cityRoad,
                plate: asset,
                weather: false,
                events: false))));
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && FightPlateImages.of(asset) == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    expect(FightPlateImages.of(asset), isNotNull);
    // The board leans towards the picture's ground: a colour, not black.
    expect(FightPlateImages.tintOf(asset), isNotNull);
    expect(FightPlateImages.tintOf(asset)!.toARGB32(), isNot(0xFF000000));
    expect(tester.takeException(), isNull);
  });
}

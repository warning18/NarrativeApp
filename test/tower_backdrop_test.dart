// The Tower floor's backdrop (v1.895, lib/screens/tower/tower_backdrop.dart):
// one PixelLab picture a band (floors 1 to 10, 11 to 20, 21 to 30), each a
// palette PNG of 180 x 320; the page's own colour lies over it.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';

void main() {
  test('a floor belongs to its band', () {
    expect([
      for (final f in [1, 10, 11, 20, 21, 30]) towerBandOf(f)
    ], [
      1,
      1,
      2,
      2,
      3,
      3
    ]);
    expect(towerBackdropAsset(1), endsWith('tower_band1.png'));
    expect(towerBackdropAsset(9), endsWith('tower_band3.png'));
  });

  test('each band has its picture, a 180 x 320 palette PNG', () {
    for (final band in [1, 2, 3]) {
      final path = towerBackdropAsset(band);
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final data = ByteData.sublistView(file.readAsBytesSync());
      expect(data.getUint32(16), 180, reason: path);
      expect(data.getUint32(20), 320, reason: path);
      // IHDR colour type 3: a palette (the QA palette guard's rule).
      expect(data.getUint8(25), 3, reason: path);
    }
  });

  test('the wardens and the bosses have their own picture, 180 x 320', () {
    expect(
        [
          for (final f in [4, 5, 10, 15, 20, 25, 30]) towerFloorPlate(f)
        ],
        [
          null,
          endsWith('tower_ward5.png'),
          endsWith('tower_boss10.png'),
          endsWith('tower_ward15.png'),
          endsWith('tower_boss20.png'),
          endsWith('tower_ward25.png'),
          endsWith('tower_boss30.png'),
        ].map((m) => m is Matcher ? m : isNull).toList());
    for (final path in [
      for (final f in [5, 10, 15, 20, 25, 30]) towerFloorPlate(f)!,
      towerEndPlate(won: true),
      towerEndPlate(won: false),
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final data = ByteData.sublistView(file.readAsBytesSync());
      expect(data.getUint32(16), 180, reason: path);
      expect(data.getUint32(20), 320, reason: path);
      expect(data.getUint8(25), 3, reason: path);
    }
  });

  testWidgets('the child is drawn over the picture', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: TowerBackdrop(floor: 15, child: Text('over the picture')))));
    expect(find.byKey(const Key('tower_backdrop')), findsOneWidget);
    expect(find.text('over the picture'), findsOneWidget);
  });
}

// A companion with art stands as a figure in the Party tab (v1.898): Kelda and
// Sable wear their PixelLab sprites wherever CompanionPortrait appears; the
// others keep the class mark's circle.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/widgets/companion_parts.dart';
import 'package:narrative_data_app/widgets/fight_sprites.dart';

CompanionView _view(String id) => CompanionView(
      id: id,
      record: const {},
      ally: AllyState(companionId: id, currentHealth: 10),
      name: id,
      raceName: 'Human',
      professionName: 'Warrior',
      professionRecord: const {},
      hp: 10,
      maxHp: 10,
      active: true,
    );

void main() {
  test('Kelda and Sable have their sprite files, 48 x 48 palette PNGs', () {
    for (final id in ['kelda', 'sable']) {
      final set = companionFightSprite(id);
      expect(set, isNotNull, reason: id);
      expect(set!.frameWidth, 48);
      final data = ByteData.sublistView(
          Uint8List.fromList(File(set.idleAsset).readAsBytesSync()));
      expect(data.getUint32(16), 48, reason: id);
      expect(data.getUint32(20), 48, reason: id);
      expect(data.getUint8(25), 3, reason: '$id is a palette PNG');
    }
    expect(companionFightSprite('maren'), isNull);
    expect(companionFightSprite('vica'), isNull);
  });

  testWidgets('a companion with art is a figure, the others a circle',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Row(children: [
            CompanionPortrait(_view('kelda'), size: 52),
            CompanionPortrait(_view('maren'), size: 52),
          ]),
        ),
      ),
    ));
    final kelda = find.byKey(const Key('companion_portrait_kelda'));
    final maren = find.byKey(const Key('companion_portrait_maren'));
    expect(kelda, findsOneWidget);
    expect(maren, findsOneWidget);
    // Kelda: a bare box with the figure's painter; Maren: the ringed circle.
    expect(tester.widget(kelda), isA<SizedBox>());
    expect(tester.widget<Container>(maren).decoration, isA<BoxDecoration>());
    expect(tester.takeException(), isNull);
  });
}

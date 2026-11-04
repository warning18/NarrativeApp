// Heads (v1.701): every enemy has a head image to wear, the ones that borrow
// another's icon wear that icon's head (Aurel Vane his own), and a card shows
// the head, falling back to the letter only when none exists.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/head_avatar.dart';

void main() {
  test('every enemy, the hero and Vica have a head file', () {
    final enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    final missing = [
      for (final id in [...enemies.keys, 'hero', 'vica'])
        if (!File(headAssetOf(id)).existsSync()) id,
    ];
    expect(missing, isEmpty, reason: 'a card would show a letter for these');
  });

  test('borrowed icons give their head; Aurel Vane has his own', () {
    expect(headAssetOf('den_bouncer'), endsWith('/slum_thug.png'));
    expect(headAssetOf('brother_clement'), endsWith('/masked_penitent.png'));
    expect(headAssetOf('aurel_vane'), endsWith('/aurel_vane.png'));
    expect(headAssetOf('vica'), endsWith('/vica.png'));
  });

  testWidgets('no head: the initial; a voice icon when given', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          HeadAvatar(id: 'kelda', name: 'Kelda'),
          HeadAvatar(
              id: '',
              name: '',
              fallback: Icon(Icons.record_voice_over_outlined)),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.text('K'), findsOneWidget);
    expect(find.byIcon(Icons.record_voice_over_outlined), findsOneWidget);
  });
}

// QA: a player's run through the Tower in the real app (door, creation, floors
// with REAL fights, spoils, oaths and boons, Level Up, leaving, the end, the
// marks), dark theme. Only with QA_PLAY=<folder>: it draws a picture of each
// stage there and writes `_trace.txt` (what the player sees and can press at
// each step, and every place it is stuck) and `_overflow.txt`. QA_PLAY_FLOORS,
// QA_PLAY_RACE, QA_PLAY_CALLING, and QA_PLAY_CFG=WxH:lang:scale (default
// 412x860:en:1). The run is in test/support/tower_playthrough.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';

import 'support/tower_playthrough.dart';

void main() {
  final out = Platform.environment['QA_PLAY'];
  if (out == null || out.isEmpty) {
    test('the Tower playthrough runs only with QA_PLAY', () {});
    return;
  }
  final cfg =
      (Platform.environment['QA_PLAY_CFG'] ?? '412x860:en:1').split(':');
  final wh = cfg[0].split('x').map(double.parse).toList();
  testWidgets('a player climbs the Tower', (tester) async {
    await playTower(
      tester,
      out: out,
      size: Size(wh[0], wh[1]),
      lang: cfg[1] == 'fr' ? AppLanguage.fr : AppLanguage.en,
      textScale: double.parse(cfg[2]),
      race: Platform.environment['QA_PLAY_RACE'] ?? 'human',
      calling: Platform.environment['QA_PLAY_CALLING'] ?? 'warrior',
      maxFloors:
          int.tryParse(Platform.environment['QA_PLAY_FLOORS'] ?? '') ?? 8,
    );
  }, timeout: const Timeout(Duration(minutes: 30)));
}

// The training paths (training_paths.json, training.dart) the stat picks
// draw from: ten of them, each a five-point bundle of stat gains at the
// exchange, named in both languages. The picks themselves are tested in
// stat_picks_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/training.dart';

void main() {
  final paths = trainingPathsFrom(
      jsonDecode(File('assets/gamedata/training_paths.json').readAsStringSync())
          as Map<String, dynamic>);

  test('ten paths, each worth five points, named in both languages', () {
    expect(paths, hasLength(10));
    for (final p in paths.values) {
      expect(trainingPointsOf(p.gains), 5, reason: p.id);
      expect(p.gains.keys.every(trainingStats.contains), isTrue, reason: p.id);
      expect(p.name, isNotEmpty);
      expect(p.nameFr, isNotEmpty, reason: p.id);
      expect(p.blurb, isNotEmpty, reason: p.id);
      expect(p.blurbFr, isNotEmpty, reason: p.id);
    }
  });
}

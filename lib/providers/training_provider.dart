import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/training.dart';

/// The training paths a level-up offers (training_paths.json, see
/// training.dart), by id.
final trainingPathsProvider =
    FutureProvider<Map<String, TrainingPath>>((ref) async {
  final raw = jsonDecode(
          await rootBundle.loadString('assets/gamedata/training_paths.json'))
      as Map<String, dynamic>;
  return trainingPathsFrom(raw);
});

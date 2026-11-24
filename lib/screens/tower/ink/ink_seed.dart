// What a seed picks on an ink piece (v2.1, UX-2): the tint (a red, a paper),
// a small tilt, a tear pattern, a chipped or folded corner, a burn, stains and
// a pin. The seed is hashed from the piece's key or label, so the same piece
// always looks the same and its neighbours differ. All code; Art's tear masks
// and stains would replace the drawn ones later.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show Key, ValueKey;

import 'package:flutter/painting.dart';

import 'ink_palette.dart';

/// The reds of a variant: red, rust, dried blood, faded red and two between.
const List<Color> inkReds = [
  inkRed,
  Color(0xFFA8321C),
  Color(0xFF7A2A22),
  Color(0xFF9E4A48),
  Color(0xFFB5121B),
  inkRedDeep,
];

/// The papers: paper, warm grey, cold grey, ochre-tinged and two between.
const List<Color> inkPapers = [
  inkPaper,
  Color(0xFFE5DFCE),
  Color(0xFFDCE2E5),
  Color(0xFFEFE6D2),
  Color(0xFFE9E9E4),
  Color(0xFFE2DCCB),
];

/// The contrast ratio of two colours (WCAG): 4.5 is AA for body text.
double inkContrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a), l2 = lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

/// The seed of a piece: its key's value when it has a string or an int one
/// (the same piece looks the same on every run), else its [label].
InkSeed inkSeedOf(Key? key, String label) {
  if (key is ValueKey && (key.value is String || key.value is int)) {
    return InkSeed.of('${key.value}');
  }
  return InkSeed.of(label);
}

class InkSeed {
  const InkSeed(this.n);

  /// The seed of a key or a label: a stable hash (FNV-1a), the same across
  /// runs and platforms.
  factory InkSeed.of(String text) {
    var h = 0x811C9DC5;
    for (final c in text.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7FFFFFFF;
    }
    return InkSeed(h);
  }

  final int n;

  Color get red => inkReds[n % inkReds.length];
  Color get paper => inkPapers[(n ~/ 7) % inkPapers.length];

  /// 1 to 3 degrees either way, in radians.
  double get tilt => ((n ~/ 3) % 3 + 1) * (n.isEven ? 1 : -1) * math.pi / 180;

  bool get fold => (n ~/ 5) % 3 == 0;
  bool get burn => (n ~/ 11) % 4 == 1;
  bool get pin => (n ~/ 13).isEven;
  bool get chip => (n ~/ 17) % 3 == 2;
  int get stains => 1 + (n ~/ 19) % 3;
  int get splatters => 3 + (n ~/ 23) % 4;

  /// The depths of the torn edge's teeth.
  List<double> teeth(int count) => [
        for (var i = 0; i < count; i++)
          2 + math.Random(n * 31 + i).nextDouble() * 9,
      ];

  @override
  bool operator ==(Object other) => other is InkSeed && other.n == n;

  @override
  int get hashCode => n;
}
